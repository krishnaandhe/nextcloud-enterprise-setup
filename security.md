# Security Guide – Nextcloud Community Setup

This document provides **security best practices** for running Nextcloud Community Edition on on-prem infrastructure (old servers or desktops).

---
## 📌 Security Overview

| Area | Importance |
|------|-----------|
| Data Protection | Prevent unauthorized access to company files |
| Network Security | Protect server from external threats |
| Access Control | Ensure users only access permitted data |
| System Updates | Reduce vulnerabilities |
| Backup Strategy | Recover data in case of failure or attack |

---
## 🔐 1. Enable HTTPS (Mandatory for Remote Access)

### Why
- Encrypts traffic between users and server  
- Prevents data interception (MITM attacks)  
- Required for secure remote access  

### Recommended Approach

| Method | Description |
|--------|------------|
| Let’s Encrypt | Free SSL certificate with auto-renewal |
| Reverse Proxy SSL | Use Nginx/Apache as SSL terminator |
| VPN Access | Limit access internally |

### Example (Certbot)

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx
```
---
👤 2. Authentication & User Security
|Recommendation|Description|
|--------|------------|
|Strong Passwords|Minimum 12+ characters|
|Unique Accounts|No shared login credentials|
|Admin Account Protection|Limit admin access|
|Disable Guest Access|Not recommended for business|
---

🌐 3. Network Security
Firewall Configuration
```
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```
|Rule|Purpose|
|--------|------------|
|Port80|HTTP (Temporary / Redirect)|
|Port 443|HTTPS (Secure access)|
|Block Others|Reduce attack surface|

---
🔒 4. File & Directory Permissions

|Path|Permission|
|--------|------------|
|Nextcloud Root|www-data:www-data|
|Data Directory|Restricted (750)|
|Config Files|Limited access|

Commands
```
sudo chown -R www-data:www-data /var/www/nextcloud
sudo chmod -R 750 /var/www/nextcloud
```
---
⚙️ 5. System Hardening
|Action|Description|
|--------|------------|
|Disable unused services|Reduce attack surface|
|Secure SSH|Disable root login|
|Change SSH Port|Optional|
|Install Fail2ban|Prevent brute-force attacks|

Install Fail2ban
```
sudo apt install fail2ban -y
```
---
🔄 6. System & Application Updates
|Component|Frequency|
|--------|------------|
|OS Updates|Weekly|
|Nextcloud Updates|As released|
|Security Patches|Immediate|

Commands:
```
sudo apt update && sudo apt upgrade -y
```
---
📁 7. Data Protection Strategy
|Area|Action|
|--------|------------|
|Data Directory|Store outside web root|
|Backup|Daily|
|Encryption|Optional (Nextcloud encryption app)|
|Logs|Monitor regularly|
---
🔐 8. Access Control & Sharing
|Control|Best Practice|
|--------|------------|
|User Groups|Department-wise access|
|File Sharing|Restrict external links|
|Public Links|Use password + expiry|
|Permissions|Read/Write control|
---
🧠 9. Logging & Monitoring
|Log Type|Location|
|--------|------------|
|Nextcloud Logs|/data/nextcloud.log|
|Nginx Logs|/var/log/nginx/
|System Logs|/var/log/syslog|

Recommendation
.Regular log review
.Enable alerting if possible
.Monitor disk usage and errors
