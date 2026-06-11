# Backup & Restore Guide – Nextcloud Community Setup

This document provides a **simple and practical backup strategy** for Nextcloud Community Edition running on on-prem servers or older hardware.

---

## 📌 Backup Overview

A proper backup ensures:

- ✅ Protection from hardware failure  
- ✅ Protection from accidental deletion  
- ✅ Recovery from system crashes or attacks  
- ✅ Business continuity  

---

## 💾 What Needs to Be Backed Up

| Component | Description | Critical |
|----------|-------------|----------|
| Data Directory | All user files | ✅ Yes |
| Database | User info, metadata, sharing | ✅ Yes |
| Config File | `config.php` settings | ✅ Yes |
| Custom Apps | Optional apps/plugins | Optional |

---

## 📁 Default Backup Locations

| Component | Path |
|----------|------|
| Nextcloud Files | `/var/www/nextcloud` |
| Data Directory | `/srv/nextcloud-data` |
| Config File | `/var/www/nextcloud/config/config.php` |

---

## 🔄 Backup Types

| Type | Description | Frequency |
|------|-------------|-----------|
| Full Backup | Complete copy of all data | Weekly |
| Incremental | Only changed files | Daily |
| Database Backup | Dump of DB | Daily |

---

## 🗄️ Database Backup (MariaDB)

### Manual Backup

```bash
mysqldump -u ncuser -p nextcloud > /backup/nextcloud_db.sql
```
## Automated Backup Script
```
#!/bin/bash

BACKUP_DIR="/backup"
DATE=$(date +%F)

mysqldump -u ncuser -p'YourDBPassword' nextcloud > $BACKUP_DIR/db_$DATE.sql
```

## 📁 Data Backup
Backup Data Directory
```
rsync -Aax /srv/nextcloud-data/ /backup/data/
```
Backup Nextcloud Application & Config
```
rsync -Aax /var/www/nextcloud/ /backup/app/
```
