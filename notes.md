Notes for nginx.conf
This configuration is based on Nextcloud’s documented Nginx approach for running Nextcloud behind Nginx + PHP-FPM, 
including the need to adjust the server_name, root, certificate paths, 
and especially the upstream php-handler listener/socket to match the installed PHP-FPM configuration. 
Nextcloud’s docs also emphasize care with add_header placement and warn that broken line wrapping can invalidate copied configs.

What you should update before use

Replace your-domain-or-ip with your real hostname or server IP.
Replace SSL certificate paths with your real certificate and private key paths.
Update the PHP-FPM socket path if your system uses a different PHP version or socket location; a mismatch here can cause 502 Bad Gateway errors.
Enable HSTS only after confirming HTTPS works correctly, which is consistent with Nextcloud’s Nginx guidance.


Notes for config.php.sample
Nextcloud’s current configuration reference states that config/config.php is the main configuration file, 
that it supports parameters such as trusted_domains, datadirectory, 
cache settings, and many operational options, and that only the parameters you actually want to modify should be added manually. 
It also warns that additional *.config.php files inside the config directory are loaded automatically, 
so care must be taken with backups and extra config fragments.


Why these parameters are included

trusted_domains is a key security control used to prevent host-header poisoning and should include the exact hostname/IP users will use to access Nextcloud. [docs.nextcloud.com],
overwrite.cli.url should match the main URL used by users so background jobs and URL generation work properly.
datadirectory is shown outside the web root (/srv/nextcloud-data) because that is a practical and safer deployment pattern for self-hosted installations.
memcache.local, memcache.locking, and Redis settings are commonly used to improve performance and enable transactional file locking in multi-user setups.
default_phone_region is useful for phone number normalization and admin warning cleanup in regional deployments.
