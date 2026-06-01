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

📦 Step 2 – Install Required Packages
```bash
sudo apt install -y nginx mariadb-server redis-server \
php-fpm php-mysql php-xml php-curl php-gd php-mbstring \
php-zip php-intl php-bcmath php-gmp php-imagick unzip wget
