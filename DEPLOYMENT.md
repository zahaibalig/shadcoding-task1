# Deployment Guide

Complete guide for deploying the ShadCoding full-stack application to Ubuntu using CircleCI, Gunicorn, and Nginx with SSL.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Server Setup](#server-setup)
- [CircleCI Configuration](#circleci-configuration)
- [Manual Deployment](#manual-deployment)
- [SSL Certificate Setup](#ssl-certificate-setup)
- [Environment Variables](#environment-variables)
- [Monitoring and Logs](#monitoring-and-logs)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### What You Need

- **Ubuntu Server** (20.04 or 22.04 LTS)
  - VPS from DigitalOcean, AWS EC2, Linode, or similar
  - Minimum: 1GB RAM, 1 CPU, 25GB storage
  - Root or sudo access

- **Domain Name**
  - A registered domain (e.g., example.com)
  - DNS A record pointing to your server's IP

- **CircleCI Account**
  - Free tier works fine
  - Connected to your GitHub/GitLab repository

- **SSH Key Pair**
  - For CircleCI to deploy to your server

---

## Server Setup

### 1. Initial Server Configuration

SSH into your Ubuntu server:

```bash
ssh root@your-server-ip
```

### 2. Run the Server Setup Script

```bash
# Clone your repository (or upload deployment scripts)
git clone https://github.com/yourusername/shadcoding-task1.git
cd shadcoding-task1

# Make scripts executable
chmod +x deployment/*.sh

# Run server setup (as root/sudo)
sudo bash deployment/setup-server.sh
```

This script will:
- Update system packages
- Install Python 3, Node.js 20, Nginx, Certbot
- Create a `deploy` user
- Set up directory structure
- Configure firewall (UFW)

### 3. Set Up SSH Key for Deploy User

On your **local machine**, generate an SSH key for CircleCI:

```bash
ssh-keygen -t ed25519 -C "circleci-deploy" -f ~/.ssh/circleci_deploy
```

Copy the public key to your server:

```bash
ssh-copy-id -i ~/.ssh/circleci_deploy.pub deploy@your-server-ip
```

Or manually:

```bash
# On server (as root)
cat >> /home/deploy/.ssh/authorized_keys << 'EOF'
your-public-key-here
EOF

chmod 600 /home/deploy/.ssh/authorized_keys
chown deploy:deploy /home/deploy/.ssh/authorized_keys
```

### 4. Clone Your Repository

As the `deploy` user:

```bash
sudo su - deploy
cd /home/deploy
git clone https://github.com/yourusername/shadcoding-task1.git
cd shadcoding-task1
```

### 5. Set Up Environment Variables

```bash
cd /home/deploy/shadcoding-task1/backend
cp ../deployment/.env.production .env

# Edit the .env file with your actual values
nano .env
```

Fill in:
- `SECRET_KEY` - Generate a random key
- `ALLOWED_HOSTS` - Your domain and IP
- `STATENS_VEGVESEN_API_KEY` - Your API key
- `CSRF_TRUSTED_ORIGINS` - Your domain with https://

Generate a secret key:
```python
python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

### 6. Install Gunicorn Service

```bash
# Copy the service file
sudo cp /home/deploy/shadcoding-task1/deployment/gunicorn.service /etc/systemd/system/

# Create log directories
sudo mkdir -p /var/log/gunicorn
sudo chown deploy:www-data /var/log/gunicorn

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable gunicorn
sudo systemctl start gunicorn

# Check status
sudo systemctl status gunicorn
```

### 7. Configure Nginx

```bash
# Copy nginx config
sudo cp /home/deploy/shadcoding-task1/deployment/nginx.conf /etc/nginx/sites-available/shadcoding

# Update with your domain (replace YOUR_DOMAIN)
sudo sed -i 's/YOUR_DOMAIN/yourdomain.com/g' /etc/nginx/sites-available/shadcoding

# Enable the site
sudo ln -s /etc/nginx/sites-available/shadcoding /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

---

## CircleCI Configuration

### 1. Add Project to CircleCI

1. Go to [CircleCI](https://circleci.com/)
2. Click "Set Up Project"
3. Select your repository
4. CircleCI will detect `.circleci/config.yml`

### 2. Add Environment Variables

In CircleCI project settings → Environment Variables, add:

| Variable | Value | Description |
|----------|-------|-------------|
| `SERVER_IP` | `123.456.789.0` | Your server's IP address |
| `DEPLOY_USER` | `deploy` | Username on server |
| `SSH_KEY_FINGERPRINT` | `xx:xx:xx...` | SSH key fingerprint (see below) |

### 3. Add SSH Key to CircleCI

1. In CircleCI: Project Settings → SSH Keys
2. Click "Add SSH Key"
3. Hostname: `your-server-ip`
4. Private Key: Paste content of `~/.ssh/circleci_deploy` (private key)
5. Copy the fingerprint and add to environment variables

### 4. Test the Pipeline

Push a commit to `main` branch:

```bash
git add .
git commit -m "Test CircleCI deployment"
git push origin main
```

Watch the pipeline in CircleCI:
- ✅ Backend tests (17 tests)
- ✅ Frontend tests (35 tests)
- ✅ Frontend build
- ✅ Deploy to server

---

## SSL Certificate Setup

### Run the SSL Setup Script

```bash
sudo bash /home/deploy/shadcoding-task1/deployment/setup-ssl.sh
```

Enter your:
- Domain name (e.g., example.com)
- Email for SSL notifications

The script will:
- Obtain Let's Encrypt SSL certificate
- Update Nginx configuration
- Set up automatic renewal

**Note:** Your domain's DNS must already be pointing to the server!

### Verify SSL

Visit your site:
- https://yourdomain.com
- https://www.yourdomain.com

Both should show a valid SSL certificate.

### Check Auto-Renewal

```bash
sudo systemctl status certbot.timer
sudo certbot renew --dry-run
```

---

## Manual Deployment

If you need to deploy without CircleCI:

```bash
# SSH to server
ssh deploy@your-server-ip

# Run deployment script
cd /home/deploy/shadcoding-task1
bash deployment/deploy.sh
```

The script will:
1. Pull latest code from git
2. Install Python dependencies
3. Run database migrations
4. Collect static files
5. Build and deploy frontend
6. Restart Gunicorn
7. Reload Nginx

---

## Environment Variables

### Backend (.env file)

Located at: `/home/deploy/shadcoding-task1/backend/.env`

```bash
# Required
SECRET_KEY=your-secret-key
DEBUG=False
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com,server-ip
STATENS_VEGVESEN_API_KEY=your-api-key

# Security
CSRF_TRUSTED_ORIGINS=https://yourdomain.com
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
```

### CircleCI Environment Variables

Set in CircleCI dashboard:

- `SERVER_IP` - Server IP address
- `DEPLOY_USER` - Usually "deploy"
- `SSH_KEY_FINGERPRINT` - From SSH key setup

---

## Monitoring and Logs

### Check Service Status

```bash
# Gunicorn
sudo systemctl status gunicorn

# Nginx
sudo systemctl status nginx

# SSL renewal timer
sudo systemctl status certbot.timer
```

### View Logs

```bash
# Gunicorn logs
sudo tail -f /var/log/gunicorn/access.log
sudo tail -f /var/log/gunicorn/error.log

# Nginx logs
sudo tail -f /var/log/nginx/shadcoding_access.log
sudo tail -f /var/log/nginx/shadcoding_error.log

# System journal
sudo journalctl -u gunicorn -f
sudo journalctl -u nginx -f
```

### Django Admin

Access at: `https://yourdomain.com/admin/`

Create superuser:
```bash
cd /home/deploy/shadcoding-task1/backend
source ../venv/bin/activate
python manage.py createsuperuser
```

---

## Troubleshooting

### Gunicorn Won't Start

```bash
# Check logs
sudo journalctl -u gunicorn -n 50

# Check if port 8000 is in use
sudo lsof -i :8000

# Restart service
sudo systemctl restart gunicorn
```

### Nginx 502 Bad Gateway

This means Nginx can't reach Gunicorn:

```bash
# Check if Gunicorn is running
sudo systemctl status gunicorn

# Check if listening on port 8000
sudo netstat -tlnp | grep 8000

# Test Gunicorn manually
cd /home/deploy/shadcoding-task1/backend
source ../venv/bin/activate
gunicorn --bind 127.0.0.1:8000 backend.wsgi:application
```

### Static Files Not Loading

```bash
# Collect static files
cd /home/deploy/shadcoding-task1/backend
source ../venv/bin/activate
python manage.py collectstatic --noinput

# Check permissions
sudo chown -R deploy:www-data /home/deploy/shadcoding-task1/backend/staticfiles/
```

### Frontend Not Updating

```bash
# Check if files exist
ls -la /var/www/shadcoding/frontend/

# Rebuild frontend
cd /home/deploy/shadcoding-task1/frontend
npm ci
npm run build
sudo rm -rf /var/www/shadcoding/frontend/*
sudo cp -r dist/* /var/www/shadcoding/frontend/
sudo chown -R deploy:www-data /var/www/shadcoding/frontend/
```

### CircleCI Can't Connect to Server

```bash
# On server, check SSH access
sudo tail -f /var/log/auth.log

# Verify deploy user can SSH
ssh deploy@your-server-ip

# Check SSH key is added
cat /home/deploy/.ssh/authorized_keys
```

### SSL Certificate Issues

```bash
# Check certificate status
sudo certbot certificates

# Renew manually
sudo certbot renew

# Check Nginx SSL config
sudo nginx -t
```

### Database Migrations Failing

```bash
cd /home/deploy/shadcoding-task1/backend
source ../venv/bin/activate

# Check migration status
python manage.py showmigrations

# Run migrations
python manage.py migrate

# If stuck, reset migrations (CAREFUL!)
# python manage.py migrate --fake app_name zero
# python manage.py migrate app_name
```

---

## Common Commands

```bash
# Restart services
sudo systemctl restart gunicorn nginx

# View service status
sudo systemctl status gunicorn nginx

# Reload Nginx (no downtime)
sudo systemctl reload nginx

# Check open ports
sudo netstat -tlnp

# Check disk space
df -h

# Check memory usage
free -m

# Monitor server resources
htop
```

---

## Production Checklist

Before going live:

- [ ] `DEBUG=False` in production .env
- [ ] Strong `SECRET_KEY` set
- [ ] Domain DNS points to server
- [ ] SSL certificate installed
- [ ] Firewall configured (UFW)
- [ ] All tests passing in CircleCI
- [ ] Environment variables set
- [ ] Database backed up
- [ ] Monitoring set up
- [ ] Error notifications configured
- [ ] Static files serving correctly
- [ ] CORS configured properly
- [ ] Rate limiting considered
- [ ] Security headers in place

---

## Architecture Diagram

```
┌─────────────┐
│   GitHub    │
│  Repository │
└──────┬──────┘
       │
       │ Push to main
       │
       ▼
┌─────────────┐
│  CircleCI   │
│   Pipeline  │
│ ┌─────────┐ │
│ │  Tests  │ │
│ │  Build  │ │
│ │ Deploy  │ │
│ └─────────┘ │
└──────┬──────┘
       │
       │ SSH Deploy
       │
       ▼
┌────────────────────────────────────┐
│      Ubuntu Server (VPS)           │
│                                    │
│  ┌──────────────────────────────┐ │
│  │   Nginx (Port 80/443)        │ │
│  │   - SSL Termination          │ │
│  │   - Reverse Proxy            │ │
│  │   - Static Files             │ │
│  └───────┬──────────────────────┘ │
│          │                         │
│          ├─→ Frontend /var/www/   │
│          │                         │
│          └─→ Backend /api/*        │
│              ↓                     │
│  ┌──────────────────────────────┐ │
│  │   Gunicorn (Port 8000)       │ │
│  │   - Django WSGI Server       │ │
│  │   - Multiple Workers         │ │
│  └───────┬──────────────────────┘ │
│          │                         │
│          ▼                         │
│  ┌──────────────────────────────┐ │
│  │   Django Application         │ │
│  │   - API Endpoints            │ │
│  │   - Database (SQLite)        │ │
│  └──────────────────────────────┘ │
└────────────────────────────────────┘
```

---

## Support

For issues or questions:
- Check logs first
- Review this troubleshooting section
- Check CircleCI build logs
- Verify environment variables

---

**Happy Deploying! 🚀**
