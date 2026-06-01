# Installation Guide – Nextcloud Community Setup

This guide provides a **step-by-step manual installation** of Nextcloud Community Edition on a Linux VM or physical machine.

---

## 📌 Assumptions

| Component | Details |
|----------|--------|
| OS | Ubuntu 26.04 LTS (GUI) |
| RAM | 8 GB |
| Storage | 1 TB (Data) |
| OS Disk | 256 GB SSD |
| Access | Root / sudo user |
| Network | Static IP recommended |
| Database | MariaDB (MySql) |

---

## 🧱 Architecture Overview

- Web Server → Nginx  
- Database → MariaDB  
- Backend → PHP-FPM  
- Application → Nextcloud  
- Storage → Local Disk (`/var/www/nextcloud/data`)  

---
## ⚙️ Step 1 – Update System

```bash
sudo apt update && sudo apt upgrade -y
```
---
## 📦 Step 2 – Install Required Packages
```bash
sudo apt install -y nginx mariadb-server redis-server \
php-fpm php-mysql php-xml php-curl php-gd php-mbstring \
php-zip php-intl php-bcmath php-gmp php-imagick unzip wget
```
---
🗄️ Step 3 – Configure Database (MariaDB)
Login to MariaDB
```bash
sudo mysql
```
Create Database and User
```
CREATE DATABASE nextcloud;
CREATE USER 'ncuser'@'localhost' IDENTIFIED BY 'StrongPassword123!';
GRANT ALL PRIVILEGES ON nextcloud.* TO 'ncuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```
---
🌐 Step 4 – Download Nextcloud
```
cd /var/www/
sudo wget https://download.nextcloud.com/server/releases/latest.zip
sudo unzip latest.zip
sudo chown -R www-data:www-data nextcloud
sudo chmod -R 755 nextcloud
```
---
🔧 Step 5 – Configure Nginx
Create Config File
```
sudo nano /etc/nginx/sites-available/nextcloud
```
Add Configuration
```
server {
    listen 80;
    server_name _;

    root /var/www/nextcloud;

    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
```
Enable Site
```sudo ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```
---
🐘 Step 6 – Configure PHP
Edit PHP configuration:
```
sudo nano /etc/php/*/fpm/php.ini
```
Update values:
```
memory_limit = 512M
upload_max_filesize = 2G
post_max_size = 2G
max_execution_time = 300
```
Restart PHP:
```
sudo systemctl restart php*-fpm
```
---
🔐 Step 7 – Set Directory Permissions
```
sudo chown -R www-data:www-data /var/www/nextcloud
sudo chmod -R 750 /var/www/nextcloud
```
---
🌍 Step 8 – Access Web Installer
Open browser and navigate to:
```
http://<your-server-ip>
```
Setup Details
|Field|Value|
|Admin Username|admin|
|Admin Password|StrongPassword|
|Data Folder|/var/www/nextcloud/data|
|Database|MySQL/MariaDBDB|
|User|ncuser|
|DB Password|StrongPassword123!|
|DB Name|nextclouddb|
|DB Host|localhost|

Click Install
---
⚡ Step 9 – Enable Background Jobs (Cron)
```
sudo crontab -u www-data -e
```
Add:
```
*/5  *  *  *  * php -f /var/www/nextcloud/cron.php
```
---
🚀 Step 10 – Enable Redis (Optional but Recommended)
Edit config:
```
sudo nano /var/www/nextcloud/config/config.php
```
Add:
```
'memcache.local' => '\\OC\\Memcache\\APCu',
'memcache.locking' => '\\OC\\Memcache\\Redis',
'redis' => [
    'host' => 'localhost',
    'port' => 6379,
],
```
Restart Redis:
```
sudo systemctl restart redis
```
---
🔒 Step 11 – Basic Firewall Setup
```
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```
---
✅ Installation Complete
You now have:

✅ Private file storage server
✅ Web access for users
✅ Central data repository
✅ Ready for remote access setup (HTTPS recommended)
---
⚠️ Post-Installation (Recommended)
|Task|Status|
|Enable HTTPS (SSL)|✅ Recommended|
|Configure backup|✅ Required|
|Setup users/groups|✅ Required|
|Tune performance|Optional|
|External storage mount|Optional|
---
🧠 Tips
.Use SSD for OS and HDD for data storage
.Avoid storing data inside web root for high security setups
.Regularly update system and Nextcloud
.Monitor disk usage and performance


