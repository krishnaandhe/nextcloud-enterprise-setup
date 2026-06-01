#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Nextcloud Community Edition - Automated Installer (Nginx + PHP-FPM + MariaDB + Redis)
# Target: Ubuntu (tested with Ubuntu 26.04 LTS GUI by repository owner)
# Purpose: Turn old on-prem hardware into private company storage with remote access
# ============================================================

# ----------------------------
# User-configurable variables
# ----------------------------
NC_DOMAIN="${NC_DOMAIN:-$(hostname -I | awk '{print $1}') }"
NC_SITE_NAME="${NC_SITE_NAME:-Nextcloud}"
NC_ADMIN_USER="${NC_ADMIN_USER:-ncadmin}"
NC_ADMIN_PASS="${NC_ADMIN_PASS:-}"
NC_DB_NAME="${NC_DB_NAME:-nextcloud}"
NC_DB_USER="${NC_DB_USER:-ncuser}"
NC_DB_PASS="${NC_DB_PASS:-}"
NC_WEB_ROOT="${NC_WEB_ROOT:-/var/www/nextcloud}"
NC_DATA_DIR="${NC_DATA_DIR:-/srv/nextcloud-data}"
NC_DOWNLOAD_URL="${NC_DOWNLOAD_URL:-https://download.nextcloud.com/server/releases/latest.tar.bz2}"
NC_TIMEZONE="${NC_TIMEZONE:-Africa/Kampala}"
NC_DEFAULT_PHONE_REGION="${NC_DEFAULT_PHONE_REGION:-UG}"
PHP_MEMORY_LIMIT="${PHP_MEMORY_LIMIT:-512M}"
PHP_UPLOAD_MAX_FILESIZE="${PHP_UPLOAD_MAX_FILESIZE:-2G}"
PHP_POST_MAX_SIZE="${PHP_POST_MAX_SIZE:-2G}"
PHP_MAX_EXECUTION_TIME="${PHP_MAX_EXECUTION_TIME:-300}"
ENABLE_UFW="${ENABLE_UFW:-true}"

# ----------------------------
# Helpers
# ----------------------------
log() {
  echo -e "\n[INFO] $*"
}

warn() {
  echo -e "\n[WARN] $*" >&2
}

err() {
  echo -e "\n[ERROR] $*" >&2
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    err "Run this script as root or with sudo."
    exit 1
  fi
}

rand_pw() {
  tr -dc 'A-Za-z0-9!@#%^*_+=' </dev/urandom | head -c 24
}

cleanup_on_error() {
  local line_no="$1"
  err "Installation failed near line ${line_no}. Check the messages above."
}
trap 'cleanup_on_error ${LINENO}' ERR

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "Required command '$1' not found."
    exit 1
  }
}

# ----------------------------
# Pre-flight
# ----------------------------
require_root
export DEBIAN_FRONTEND=noninteractive

NC_DOMAIN="$(echo "${NC_DOMAIN}" | xargs)"
[[ -z "${NC_ADMIN_PASS}" ]] && NC_ADMIN_PASS="$(rand_pw)"
[[ -z "${NC_DB_PASS}" ]] && NC_DB_PASS="$(rand_pw)"

log "Starting Nextcloud automated installation..."
log "Domain/IP: ${NC_DOMAIN}"
log "Web root : ${NC_WEB_ROOT}"
log "Data dir : ${NC_DATA_DIR}"

require_cmd apt-get
require_cmd systemctl
require_cmd runuser

# ----------------------------
# Install base packages
# ----------------------------
log "Updating package index and installing prerequisites..."
apt-get update -y
apt-get upgrade -y
apt-get install -y \
  nginx mariadb-server redis-server curl wget unzip bzip2 tar ca-certificates \
  php-fpm php-cli php-common php-mysql php-xml php-curl php-gd php-mbstring \
  php-zip php-intl php-bcmath php-gmp php-imagick php-apcu php-redis \
  imagemagick ffmpeg libreoffice-common

# ----------------------------
# Detect PHP version/socket
# ----------------------------
PHP_VERSION="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
PHP_FPM_SOCKET="/run/php/php${PHP_VERSION}-fpm.sock"
PHP_FPM_INI="/etc/php/${PHP_VERSION}/fpm/conf.d/99-nextcloud.ini"
PHP_CLI_INI="/etc/php/${PHP_VERSION}/cli/conf.d/99-nextcloud.ini"

if [[ ! -S "${PHP_FPM_SOCKET}" ]]; then
  warn "Expected PHP-FPM socket ${PHP_FPM_SOCKET} not found. Trying auto-discovery..."
  PHP_FPM_SOCKET="$(find /run/php -maxdepth 1 -type s -name 'php*-fpm.sock' | sort | head -n 1 || true)"
fi

if [[ -z "${PHP_FPM_SOCKET}" ]]; then
  err "Could not find a PHP-FPM socket under /run/php."
  exit 1
fi

# ----------------------------
# Services
# ----------------------------
log "Enabling and starting core services..."
systemctl enable --now nginx mariadb redis-server
systemctl enable --now "php${PHP_VERSION}-fpm"

# ----------------------------
# MariaDB setup
# ----------------------------
log "Creating Nextcloud database and database user..."
mysql <<MYSQL_EOF
CREATE DATABASE IF NOT EXISTS \`${NC_DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '${NC_DB_USER}'@'localhost' IDENTIFIED BY '${NC_DB_PASS}';
GRANT ALL PRIVILEGES ON \`${NC_DB_NAME}\`.* TO '${NC_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
MYSQL_EOF

# ----------------------------
# Download and verify Nextcloud
# ----------------------------
log "Downloading Nextcloud release archive and checksum..."
TMP_DIR="$(mktemp -d)"
cd "${TMP_DIR}"
wget -q -O nextcloud.tar.bz2 "${NC_DOWNLOAD_URL}"
wget -q -O nextcloud.tar.bz2.sha256 "${NC_DOWNLOAD_URL}.sha256"

log "Validating archive checksum..."
EXPECTED_SHA="$(awk '{print $1}' nextcloud.tar.bz2.sha256)"
ACTUAL_SHA="$(sha256sum nextcloud.tar.bz2 | awk '{print $1}')"
if [[ "${EXPECTED_SHA}" != "${ACTUAL_SHA}" ]]; then
  err "Checksum validation failed for downloaded Nextcloud archive."
  exit 1
fi

# ----------------------------
# Extract application
# ----------------------------
log "Deploying Nextcloud files..."
mkdir -p /var/www
if [[ -d "${NC_WEB_ROOT}" ]]; then
  warn "Existing directory ${NC_WEB_ROOT} detected. It will be replaced."
  rm -rf "${NC_WEB_ROOT}"
fi

tar -xjf nextcloud.tar.bz2 -C /var/www/
if [[ "${NC_WEB_ROOT}" != "/var/www/nextcloud" ]]; then
  mv /var/www/nextcloud "${NC_WEB_ROOT}"
fi
mkdir -p "${NC_DATA_DIR}"
chown -R www-data:www-data "${NC_WEB_ROOT}" "${NC_DATA_DIR}"
find "${NC_WEB_ROOT}" -type d -exec chmod 750 {} \;
find "${NC_WEB_ROOT}" -type f -exec chmod 640 {} \;
chmod 750 "${NC_DATA_DIR}"

# ----------------------------
# PHP tuning
# ----------------------------
log "Applying PHP tuning..."
cat > "${PHP_FPM_INI}" <<PHPCONF
memory_limit = ${PHP_MEMORY_LIMIT}
upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}
post_max_size = ${PHP_POST_MAX_SIZE}
max_execution_time = ${PHP_MAX_EXECUTION_TIME}
max_input_time = ${PHP_MAX_EXECUTION_TIME}
output_buffering = Off
date.timezone = ${NC_TIMEZONE}
apc.enable_cli = 1
PHPCONF

cat > "${PHP_CLI_INI}" <<PHPCONF
memory_limit = ${PHP_MEMORY_LIMIT}
upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}
post_max_size = ${PHP_POST_MAX_SIZE}
max_execution_time = ${PHP_MAX_EXECUTION_TIME}
max_input_time = ${PHP_MAX_EXECUTION_TIME}
output_buffering = Off
date.timezone = ${NC_TIMEZONE}
apc.enable_cli = 1
PHPCONF

systemctl restart "php${PHP_VERSION}-fpm"

# ----------------------------
# Nginx site config
# ----------------------------
log "Writing Nginx site configuration..."
cat > /etc/nginx/sites-available/nextcloud <<NGINXCONF
upstream php-handler {
    server unix:${PHP_FPM_SOCKET};
}

server {
    listen 80;
    listen [::]:80;
    server_name ${NC_DOMAIN};
    root ${NC_WEB_ROOT};

    add_header Referrer-Policy "no-referrer" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Permitted-Cross-Domain-Policies "none" always;
    add_header X-Robots-Tag "noindex, nofollow" always;
    add_header X-XSS-Protection "1; mode=block" always;

    client_max_body_size 2048M;
    client_body_timeout 300s;
    fastcgi_buffers 64 4K;

    index index.php index.html /index.php\$request_uri;

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location = /.well-known/carddav {
        return 301 /remote.php/dav/;
    }

    location = /.well-known/caldav {
        return 301 /remote.php/dav/;
    }

    location /.well-known/acme-challenge    { try_files \$uri \$uri/ =404; }
    location /.well-known/pki-validation    { try_files \$uri \$uri/ =404; }

    location / {
        rewrite ^ /index.php\$request_uri;
    }

    location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)/ {
        deny all;
    }

    location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console) {
        deny all;
    }

    location ~ \.php(?:\$|/) {
        rewrite ^/(?!index|remote|public|cron|core/ajax/update|status|ocs/v1.php|ocs/v2.php|updater/.+|oc[ms]-provider/.+|.+/richdocumentscode/proxy) /index.php\$request_uri;
        fastcgi_split_path_info ^(.+?\.php)(/.*)\$;
        set \$path_info \$fastcgi_path_info;
        try_files \$fastcgi_script_name =404;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$path_info;
        fastcgi_param HTTPS off;
        fastcgi_param modHeadersAvailable true;
        fastcgi_param front_controller_active true;
        fastcgi_pass php-handler;
        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;
        fastcgi_read_timeout 3600;
    }

    location ~ \. (?:css|js|svg|gif|png|jpg|ico|wasm|tflite|map|ogg|flac)$ {
        try_files \$uri /index.php\$request_uri;
        expires 6M;
        access_log off;
    }

    location ~ \. (?:woff2?|eot|ttf|otf)$ {
        try_files \$uri /index.php\$request_uri;
        expires 7d;
        access_log off;
    }

    location ~ /(?:updater|ocs-provider)(?:\$|/) {
        try_files \$uri/ =404;
        index index.php;
    }

    location ~ /(?:\\.|htaccess|data|config|db_structure\.xml|README) {
        deny all;
    }
}
NGINXCONF

# Fix accidental regex spacing introduced to keep shell readable
sed -i 's/location ~ \\. (?:/location ~ \\.(?:/g' /etc/nginx/sites-available/nextcloud

rm -f /etc/nginx/sites-enabled/default
ln -sfn /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/nextcloud
nginx -t
systemctl reload nginx

# ----------------------------
# Install Nextcloud via OCC
# ----------------------------
log "Running unattended Nextcloud installation..."
runuser -u www-data -- php "${NC_WEB_ROOT}/occ" maintenance:install \
  --database "mysql" \
  --database-name "${NC_DB_NAME}" \
  --database-user "${NC_DB_USER}" \
  --database-pass "${NC_DB_PASS}" \
  --admin-user "${NC_ADMIN_USER}" \
  --admin-pass "${NC_ADMIN_PASS}" \
  --data-dir "${NC_DATA_DIR}"

# ----------------------------
# Post-install system configuration
# ----------------------------
log "Applying Nextcloud system settings..."
runuser -u www-data -- php "${NC_WEB_ROOT}/occ" config:system:set trusted_domains 1 --value="${NC_DOMAIN}"
runuser -u www-data -- php "${NC_WEB_ROOT}/occ" config:system:set overwrite.cli.url --value="http://${NC_DOMAIN}"
runuser -u www-data -- php "${NC_WEB_ROOT}/occ" config:system:set default_phone_region --value="${NC_DEFAULT_PHONE_REGION}"
runuser -u www-data -- php "${NC_WEB_ROOT}/occ" config:system:set filelocking.enabled --type=boolean --value=true
runuser -u www-data -- php "${NC_WEB_ROOT}/occ" config:system:set memcache.local --value="\\OC\\Memcache\\APCu"
runuser -u www-data -- php "${NC_WEB_ROOT}/occ" config:system:set memcache.locking --value="\\OC\\Memcache\\Redis"
runuser -u www-data -- php "${NC_WEB_ROOT}/occ" config:system:set redis host --value="127.0.0.1"
runuser -u www-data -- php "${NC_WEB_ROOT}/occ" config:system:set redis port --type=integer --value=6379
runuser -u www-data -- php "${NC_WEB_ROOT}/occ" background:cron

# Optional app baseline
runuser -u www-data -- php "${NC_WEB_ROOT}/occ" app:enable files_pdfviewer || true
runuser -u www-data -- php "${NC_WEB_ROOT}/occ" app:enable activity || true
runuser -u www-data -- php "${NC_WEB_ROOT}/occ" app:enable firstrunwizard || true

# ----------------------------
# Cron job
# ----------------------------
log "Configuring cron background job..."
cat > /etc/cron.d/nextcloud <<CRONCONF
*/5 * * * * www-data php -f ${NC_WEB_ROOT}/cron.php >/dev/null 2>&1
CRONCONF
chmod 644 /etc/cron.d/nextcloud

# ----------------------------
# Firewall (optional)
# ----------------------------
if [[ "${ENABLE_UFW}" == "true" ]] && command -v ufw >/dev/null 2>&1; then
  log "Configuring UFW firewall rules..."
  ufw allow 80/tcp || true
  ufw allow 443/tcp || true
  ufw --force enable || true
else
  warn "UFW skipped (either disabled by variable or not installed)."
fi

# ----------------------------
# Final ownership and cleanup
# ----------------------------
chown -R www-data:www-data "${NC_WEB_ROOT}" "${NC_DATA_DIR}"
rm -rf "${TMP_DIR}"

# ----------------------------
# Save credentials
# ----------------------------
CRED_FILE="/root/nextcloud-credentials.txt"
cat > "${CRED_FILE}" <<CREDS
Nextcloud installation completed successfully.

URL: http://${NC_DOMAIN}
Admin user: ${NC_ADMIN_USER}
Admin pass: ${NC_ADMIN_PASS}
Database name: ${NC_DB_NAME}
Database user: ${NC_DB_USER}
Database pass: ${NC_DB_PASS}
Web root: ${NC_WEB_ROOT}
Data dir: ${NC_DATA_DIR}
PHP version: ${PHP_VERSION}
PHP-FPM socket: ${PHP_FPM_SOCKET}
CREDS
chmod 600 "${CRED_FILE}"

# ----------------------------
# Summary
# ----------------------------
cat <<SUMMARY

============================================================
Nextcloud installation completed successfully
============================================================
URL              : http://${NC_DOMAIN}
Admin user       : ${NC_ADMIN_USER}
Admin password   : ${NC_ADMIN_PASS}
Database         : ${NC_DB_NAME}
Database user    : ${NC_DB_USER}
Data directory   : ${NC_DATA_DIR}
Credential file  : ${CRED_FILE}

Next recommended steps:
1. Enable HTTPS with a valid certificate
2. Point DNS to this server and update NC_DOMAIN if needed
3. Verify backups for database + data directory + config
4. Mount your larger data disk to ${NC_DATA_DIR} if not already mounted
5. Review security, backup, and business-usecase docs in this repo
============================================================
SUMMARY
