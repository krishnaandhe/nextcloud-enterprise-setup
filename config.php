<?php
$CONFIG = array (
  /**
   * ------------------------------------------------------------
   * Basic instance settings
   * ------------------------------------------------------------
   */
  'trusted_domains' =>
  array (
    0 => 'your-domain-or-ip',
    1 => 'localhost',
  ),

  'datadirectory' => '/srv/nextcloud-data',

  'overwrite.cli.url' => 'https://your-domain-or-ip',

  'default_phone_region' => 'UG',

  /**
   * ------------------------------------------------------------
   * Database settings
   * ------------------------------------------------------------
   * These values are usually written by the installer.
   * Keep here only if you want a reusable reference/sample.
   */
  'dbtype' => 'mysql',
  'dbhost' => 'localhost',
  'dbport' => '',
  'dbname' => 'nextcloud',
  'dbuser' => 'ncuser',
  'dbpassword' => 'ChangeThisPassword',
  'dbtableprefix' => 'oc_',
  'mysql.utf8mb4' => true,

  /**
   * ------------------------------------------------------------
   * File locking / cache
   * ------------------------------------------------------------
   */
  'filelocking.enabled' => true,
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' =>
  array (
    'host' => '127.0.0.1',
    'port' => 6379,
  ),

  /**
   * ------------------------------------------------------------
   * Logging
   * ------------------------------------------------------------
   */
  'log_type' => 'file',
  'logfile' => '/srv/nextcloud-data/nextcloud.log',
  'loglevel' => 2,
  'log_rotate_size' => 104857600,

  /**
   * ------------------------------------------------------------
   * Mail settings (optional)
   * ------------------------------------------------------------
   */
  /*
  'mail_from_address' => 'nextcloud',
  'mail_domain' => 'your-domain.com',
  'mail_smtpmode' => 'smtp',
  'mail_smtphost' => 'smtp.your-domain.com',
  'mail_smtpport' => '587',
  'mail_smtpsecure' => 'tls',
  'mail_smtpauth' => true,
  'mail_smtpname' => 'smtp-user',
  'mail_smtppassword' => 'smtp-password',
  */

  /**
   * ------------------------------------------------------------
   * Reverse proxy settings (optional)
   * Uncomment if using Nginx Proxy Manager, HAProxy, etc.
   * ------------------------------------------------------------
   */
  /*
  'trusted_proxies' =>
  array (
    0 => '127.0.0.1',
    1 => '10.0.0.10',
  ),
  'overwritehost' => 'your-domain-or-ip',
  'overwriteprotocol' => 'https',
  */

  /**
   * ------------------------------------------------------------
   * Maintenance / behavior
   * ------------------------------------------------------------
   */
  'maintenance_window_start' => 2,
  'knowledgebaseenabled' => false,
  'allow_user_to_change_display_name' => true,
  'auth.bruteforce.protection.enabled' => true,
);
