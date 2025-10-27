# ShadCoding Task1 - Deployment Guide

Complete guide for deploying the ShadCoding Task1 application to an AWS Ubuntu server with Nginx and Gunicorn.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Server Setup](#initial-server-setup)
3. [Deploying Updates](#deploying-updates)
4. [Service Management](#service-management)
5. [Troubleshooting](#troubleshooting)
6. [Configuration Files](#configuration-files)

---

## Prerequisites

### Server Requirements
- **OS**: Ubuntu 20.04 or 22.04 LTS
- **RAM**: Minimum 1GB (2GB recommended)
- **Storage**: 10GB minimum
- **Access**: SSH access with sudo privileges

### Local Requirements
- Git repository hosted on GitHub/GitLab/etc.
- SSH key configured for server access

### AWS Security Group Rules
Make sure your AWS security group allows:
- **Port 22** (SSH)
- **Port 80** (HTTP)

---

## Initial Server Setup

This is a **one-time setup** when deploying to a fresh server.

### Step 1: Connect to Your Server

```bash
ssh ubuntu@18.217.70.110
```

### Step 2: Clone Your Repository

```bash
cd ~
git clone https://github.com/YOUR_USERNAME/shadcoding-task1.git
cd shadcoding-task1
```

### Step 3: Run Setup Script

```bash
sudo bash deployment/setup_server.sh
```

**What this script does:**
- ✅ Updates system packages
- ✅ Installs Python 3.11, Node.js 20, Nginx
- ✅ Creates `deploy` user
- ✅ Sets up Python virtual environment
- ✅ Installs dependencies
- ✅ Creates `.env` file with generated SECRET_KEY
- ✅ Runs Django migrations
- ✅ Builds frontend
- ✅ Configures Nginx
- ✅ Sets up Gunicorn systemd service
- ✅ Configures UFW firewall

**Duration**: 5-10 minutes

### Step 4: Configure Environment Variables

Edit the `.env` file with your actual values:

```bash
sudo nano /home/deploy/shadcoding-task1/backend/.env
```

**Important variables to update:**
- `STATENS_VEGVESEN_API_KEY` - Your actual API key
- `SECRET_KEY` - Already generated, but you can change it
- Other settings as needed

### Step 5: Restart Services

```bash
sudo systemctl restart gunicorn
sudo systemctl restart nginx
```

### Step 6: Verify Installation

Visit your application:
- **Frontend**: http://18.217.70.110
- **Admin Panel**: http://18.217.70.110/admin/
- **API**: http://18.217.70.110/api/projects/

---

## Deploying Updates

After making changes to your code, deploy updates using this script.

### As Deploy User (Recommended)

```bash
# SSH to server
ssh ubuntu@18.217.70.110

# Switch to deploy user
sudo su - deploy

# Navigate to project
cd ~/shadcoding-task1

# Run deployment script
bash deployment/deploy.sh
```

### What the Deploy Script Does

1. ✅ Pulls latest code from Git
2. ✅ Updates Python dependencies
3. ✅ Updates frontend API URL to production
4. ✅ Builds Vue.js frontend
5. ✅ Runs Django migrations
6. ✅ Collects static files
7. ✅ Copies frontend to Nginx directory
8. ✅ Restarts Gunicorn
9. ✅ Reloads Nginx

**Duration**: 2-5 minutes

---

## Service Management

### Check Service Status

```bash
# Gunicorn (Django backend)
sudo systemctl status gunicorn

# Nginx (web server)
sudo systemctl status nginx
```

### Start/Stop/Restart Services

```bash
# Gunicorn
sudo systemctl start gunicorn
sudo systemctl stop gunicorn
sudo systemctl restart gunicorn
sudo systemctl reload gunicorn

# Nginx
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
sudo systemctl reload nginx  # Reload config without downtime
```

### Enable/Disable Auto-Start on Boot

```bash
# Enable
sudo systemctl enable gunicorn
sudo systemctl enable nginx

# Disable
sudo systemctl disable gunicorn
sudo systemctl disable nginx
```

### View Logs

```bash
# Gunicorn logs (real-time)
sudo journalctl -u gunicorn -f

# Gunicorn logs (last 100 lines)
sudo journalctl -u gunicorn -n 100

# Gunicorn error log
sudo tail -f /var/log/gunicorn/error.log

# Gunicorn access log
sudo tail -f /var/log/gunicorn/access.log

# Nginx error log
sudo tail -f /var/log/nginx/shadcoding_error.log

# Nginx access log
sudo tail -f /var/log/nginx/shadcoding_access.log
```

---

## Troubleshooting

### Issue: "502 Bad Gateway" Error

**Cause**: Gunicorn is not running or not accessible.

**Solution**:
```bash
# Check if Gunicorn is running
sudo systemctl status gunicorn

# If not running, start it
sudo systemctl start gunicorn

# Check logs for errors
sudo journalctl -u gunicorn -n 50
```

### Issue: Frontend Not Loading

**Cause**: Nginx not serving files correctly.

**Solution**:
```bash
# Check if files exist
ls -la /var/www/shadcoding/frontend/

# Check Nginx configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### Issue: API Calls Failing (CORS Errors)

**Cause**: CORS not configured properly.

**Solution**:
```bash
# Edit .env file
sudo nano /home/deploy/shadcoding-task1/backend/.env

# Make sure CORS_ALLOWED_ORIGINS includes your frontend URL
CORS_ALLOWED_ORIGINS=http://18.217.70.110

# Restart Gunicorn
sudo systemctl restart gunicorn
```

### Issue: Database Errors

**Cause**: Migrations not applied.

**Solution**:
```bash
# Switch to deploy user
sudo su - deploy

# Navigate to project
cd ~/shadcoding-task1/backend

# Activate virtual environment
source ../venv/bin/activate

# Run migrations
python manage.py migrate

# Exit deploy user
exit

# Restart Gunicorn
sudo systemctl restart gunicorn
```

### Issue: Static Files Not Loading (Django Admin)

**Cause**: Static files not collected.

**Solution**:
```bash
sudo su - deploy
cd ~/shadcoding-task1/backend
source ../venv/bin/activate
python manage.py collectstatic --noinput
exit
sudo systemctl restart nginx
```

### Issue: Permission Denied Errors

**Cause**: File permissions incorrect.

**Solution**:
```bash
# Fix ownership
sudo chown -R deploy:deploy /home/deploy/shadcoding-task1

# Fix Nginx directory
sudo chown -R www-data:www-data /var/www/shadcoding

# Fix log directory
sudo chown -R deploy:deploy /var/log/gunicorn
```

---

## Configuration Files

### File Locations

```
/home/deploy/shadcoding-task1/              # Project root
├── backend/
│   └── .env                                 # Environment variables
├── deployment/
│   ├── nginx.conf                          # Nginx configuration (template)
│   ├── gunicorn.service                    # Systemd service (template)
│   ├── gunicorn.conf.py                    # Gunicorn settings
│   └── .env.example                        # Environment template
│
/etc/nginx/sites-available/shadcoding       # Nginx config (installed)
/etc/nginx/sites-enabled/shadcoding         # Nginx config (enabled)
/etc/systemd/system/gunicorn.service        # Gunicorn service (installed)
/var/www/shadcoding/frontend/               # Frontend files (production)
/var/log/gunicorn/                          # Gunicorn logs
/var/log/nginx/                             # Nginx logs
```

### Key Configuration Values

**Nginx**:
- Listen: Port 80
- Server Name: 18.217.70.110, zohaib.no
- Frontend: `/var/www/shadcoding/frontend/`
- Upstream: `127.0.0.1:8000` (Gunicorn)

**Gunicorn**:
- Bind: `127.0.0.1:8000`
- Workers: CPU cores * 2 + 1
- Timeout: 30 seconds
- User: deploy

**Django**:
- Database: SQLite (`backend/db.sqlite3`)
- Static: `backend/staticfiles/`
- Debug: False (production)

---

## Useful Commands Cheat Sheet

```bash
# Deploy updates
sudo su - deploy
cd ~/shadcoding-task1
bash deployment/deploy.sh

# Check logs
sudo journalctl -u gunicorn -f
sudo tail -f /var/log/nginx/shadcoding_error.log

# Restart services
sudo systemctl restart gunicorn nginx

# Check service status
sudo systemctl status gunicorn nginx

# Django management
sudo su - deploy
cd ~/shadcoding-task1/backend
source ../venv/bin/activate
python manage.py migrate
python manage.py createsuperuser
python manage.py collectstatic

# Test Nginx config
sudo nginx -t

# Check disk space
df -h

# Check memory usage
free -h

# Check running processes
ps aux | grep gunicorn
ps aux | grep nginx
```

---

## Security Recommendations

1. **Change default passwords**
   - Create strong Django admin password
   - Use SSH keys instead of passwords

2. **Keep software updated**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

3. **Monitor logs regularly**
   - Check for unusual access patterns
   - Monitor error logs

4. **Backup database**
   ```bash
   cp /home/deploy/shadcoding-task1/backend/db.sqlite3 \
      ~/backups/db_$(date +%Y%m%d).sqlite3
   ```

5. **Add SSL/HTTPS** (future enhancement)
   - Use Let's Encrypt for free SSL certificates
   - Update Nginx config to redirect HTTP → HTTPS

---

## Support

For issues or questions:
- Check logs first: `sudo journalctl -u gunicorn -f`
- Review this troubleshooting guide
- Check Django documentation: https://docs.djangoproject.com/
- Check Gunicorn documentation: https://docs.gunicorn.org/

---

**Last Updated**: 2025-01-27
