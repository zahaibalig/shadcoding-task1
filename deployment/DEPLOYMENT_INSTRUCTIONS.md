# Complete Deployment Instructions for AWS Ubuntu Server

**Server Details**:
- **IP Address**: 18.223.101.101
- **Domain**: zohaib.no, www.zohaib.no
- **SSH User**: ubuntu
- **Deploy User**: deploy
- **Current Status**: DNS not configured, using SQLite

---

## Table of Contents
1. [Phase 1: Immediate Deployment (HTTP via IP)](#phase-1-immediate-deployment-http-via-ip)
2. [Phase 2: DNS Configuration](#phase-2-dns-configuration)
3. [Phase 3: SSL Setup and HTTPS Migration](#phase-3-ssl-setup-and-https-migration)
4. [Verification and Testing](#verification-and-testing)
5. [Troubleshooting](#troubleshooting)
6. [Maintenance and Monitoring](#maintenance-and-monitoring)

---

## Phase 1: Immediate Deployment (HTTP via IP)

**Goal**: Get your site working via HTTP at `http://18.223.101.101`

### Step 1: Generate SECRET_KEY

On your **local machine**, generate a secure SECRET_KEY:

```bash
python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

**Example output**:
```
django-insecure-k#7h)o@m_45x&$8w!t9yx^n2%f3g+j-5m=z*6$2p@q7r8s
```

**Copy this key** - you'll need it for the next step.

---

### Step 2: Update .env.phase1-http Configuration

On your **local machine**, edit the Phase 1 configuration:

```bash
# Edit the file
nano deployment/.env.phase1-http

# Find this line:
SECRET_KEY=REPLACE_THIS_WITH_GENERATED_SECRET_KEY

# Replace with your generated key:
SECRET_KEY=django-insecure-k#7h)o@m_45x&$8w!t9yx^n2%f3g+j-5m=z*6$2p@q7r8s

# Save and exit (Ctrl+O, Enter, Ctrl+X)
```

---

### Step 3: Deploy .env File to Server

From your **local machine**:

```bash
# Copy the configured .env file to server
scp deployment/.env.phase1-http ubuntu@18.223.101.101:/tmp/.env.phase1

# SSH into the server
ssh ubuntu@18.223.101.101
```

Now on the **server**:

```bash
# Move the file to the correct location
sudo mv /tmp/.env.phase1 /home/deploy/shadcoding-task1/backend/.env

# Set correct ownership and permissions
sudo chown deploy:deploy /home/deploy/shadcoding-task1/backend/.env
sudo chmod 600 /home/deploy/shadcoding-task1/backend/.env

# Verify the file is in place
sudo cat /home/deploy/shadcoding-task1/backend/.env | head -20
```

---

### Step 4: Restart Services

On the **server**:

```bash
# Restart Gunicorn (Django backend)
sudo systemctl restart gunicorn

# Check Gunicorn status
sudo systemctl status gunicorn

# If Gunicorn is active and running, reload Nginx
sudo systemctl reload nginx

# Check Nginx status
sudo systemctl status nginx
```

**Expected Output for Gunicorn**:
```
● gunicorn.service - Gunicorn daemon for ShadCoding Django app
   Loaded: loaded (/etc/systemd/system/gunicorn.service; enabled)
   Active: active (running) since ...
```

**Expected Output for Nginx**:
```
● nginx.service - A high performance web server
   Loaded: loaded (/lib/systemd/system/nginx.service; enabled)
   Active: active (running) since ...
```

---

### Step 5: Verify Deployment

On the **server**, test the API:

```bash
# Test backend directly
curl http://127.0.0.1:8000/api/projects/

# Test through Nginx
curl http://18.223.101.101/api/projects/
```

**Expected Response** (example):
```json
[
  {
    "id": 1,
    "name": "Sample Project",
    "description": "A sample project",
    "status": "completed",
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-01-20T14:45:00Z"
  }
]
```

From your **local machine** (or browser):

```bash
# Test from outside
curl http://18.223.101.101/api/projects/

# Or open in browser:
# http://18.223.101.101
```

---

### Step 6: Check Logs (if issues occur)

On the **server**:

```bash
# Gunicorn logs
sudo journalctl -u gunicorn -n 50

# Gunicorn error log
sudo tail -50 /var/log/gunicorn/error.log

# Nginx error log
sudo tail -50 /var/log/nginx/error.log

# Nginx access log
sudo tail -50 /var/log/nginx/access.log
```

---

### Phase 1 Complete! ✅

At this point, your site should be accessible via:
- **Frontend**: http://18.223.101.101
- **API**: http://18.223.101.101/api/projects/
- **Admin**: http://18.223.101.101/admin/

**Important Notes**:
- SSL is NOT enabled yet (that's expected)
- Access is via IP address only
- HTTPS will not work until DNS is configured and SSL certificates are installed

---

## Phase 2: DNS Configuration

**Goal**: Point your domain (zohaib.no) to your server IP (18.223.101.101)

### Step 1: Access Your Domain Registrar

Log in to your domain registrar (where you bought zohaib.no).

Common registrars:
- GoDaddy
- Namecheap
- Google Domains
- Cloudflare
- Route 53 (AWS)

---

### Step 2: Add DNS Records

Add the following **A Records**:

| Type | Name/Host | Value/Points To | TTL |
|------|-----------|-----------------|-----|
| A    | @         | 18.223.101.101 | 3600 |
| A    | www       | 18.223.101.101 | 3600 |

**What this does**:
- `@` = Root domain (zohaib.no)
- `www` = www subdomain (www.zohaib.no)
- Both point to your server IP

**Screenshots (Generic Instructions)**:

1. Find "DNS Settings" or "DNS Management" or "Manage DNS"
2. Click "Add Record" or "Add DNS Record"
3. Select type: "A"
4. For first record:
   - Name/Host: `@` (or leave blank)
   - Value: `18.223.101.101`
   - TTL: `3600` (or leave default)
5. For second record:
   - Name/Host: `www`
   - Value: `18.223.101.101`
   - TTL: `3600` (or leave default)
6. Save changes

---

### Step 3: Wait for DNS Propagation

DNS changes can take **5 minutes to 48 hours** to propagate worldwide, but typically:
- 15-30 minutes for most changes
- Up to 2-4 hours for full global propagation

---

### Step 4: Verify DNS Propagation

From your **local machine** or any computer:

```bash
# Check if DNS is resolving
nslookup zohaib.no

# Expected output:
# Server:  ...
# Address: ...
#
# Non-authoritative answer:
# Name:    zohaib.no
# Address: 18.223.101.101

# Also check www subdomain
nslookup www.zohaib.no

# Expected output:
# Name:    www.zohaib.no
# Address: 18.223.101.101
```

**Alternative verification**:

```bash
# Using dig (if available)
dig zohaib.no +short
# Expected output: 18.223.101.101

# Using ping
ping zohaib.no
# Should ping 18.223.101.101
```

**Online tools**:
- https://dnschecker.org/
- Enter "zohaib.no" and check if it resolves to 18.223.101.101 globally

---

### Step 5: Test HTTP Access via Domain

Once DNS propagates:

```bash
# From your local machine
curl http://zohaib.no/api/projects/

# Or open in browser:
# http://zohaib.no
```

**Note**: HTTPS (https://zohaib.no) will NOT work yet - that's Phase 3.

---

### Phase 2 Complete! ✅

At this point:
- ✅ DNS is configured and propagated
- ✅ Site is accessible via http://zohaib.no
- ✅ Site is still accessible via http://18.223.101.101
- ❌ HTTPS does not work yet (Phase 3)

---

## Phase 3: SSL Setup and HTTPS Migration

**Goal**: Enable HTTPS with Let's Encrypt SSL certificates

### Step 1: Verify Prerequisites

On the **server**:

```bash
# Verify DNS is working from server
nslookup zohaib.no
# Should return: 18.223.101.101

# Verify port 80 and 443 are accessible
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
```

---

### Step 2: Check if SSL Script Exists

On the **server**:

```bash
# Check if setup-ssl.sh exists
ls -lh /home/deploy/shadcoding-task1/deployment/setup-ssl.sh

# If it exists, check if it's executable
file /home/deploy/shadcoding-task1/deployment/setup-ssl.sh

# Make it executable if needed
sudo chmod +x /home/deploy/shadcoding-task1/deployment/setup-ssl.sh
```

---

### Step 3: Run SSL Setup Script

On the **server**:

```bash
# Run the SSL setup script
sudo bash /home/deploy/shadcoding-task1/deployment/setup-ssl.sh

# The script will:
# 1. Install Certbot (if not already installed)
# 2. Obtain SSL certificates from Let's Encrypt for zohaib.no and www.zohaib.no
# 3. Update Nginx configuration to use SSL
# 4. Set up auto-renewal
```

**Follow the prompts**:
1. Enter email address for urgent renewal and security notices
2. Agree to terms of service
3. Choose whether to share email with EFF (optional)
4. Certbot will automatically obtain certificates

**Expected Output**:
```
Obtaining a new certificate
Performing the following challenges:
http-01 challenge for zohaib.no
http-01 challenge for www.zohaib.no
...
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/zohaib.no/fullchain.pem
Key is saved at: /etc/letsencrypt/live/zohaib.no/privkey.pem
...
```

---

### Step 4: Verify SSL Certificates

On the **server**:

```bash
# Check certificate status
sudo certbot certificates

# Expected output:
# Found the following certs:
#   Certificate Name: zohaib.no
#     Domains: zohaib.no www.zohaib.no
#     Expiry Date: 2025-04-XX ...
#     Certificate Path: /etc/letsencrypt/live/zohaib.no/fullchain.pem
#     Private Key Path: /etc/letsencrypt/live/zohaib.no/privkey.pem
```

---

### Step 5: Test HTTPS Access

From your **local machine** or browser:

```bash
# Test HTTPS
curl https://zohaib.no/api/projects/

# Test HTTP redirect (should redirect to HTTPS)
curl -I http://zohaib.no

# Expected output:
# HTTP/1.1 301 Moved Permanently
# Location: https://zohaib.no/
```

**In browser**:
1. Visit https://zohaib.no
2. Check for the padlock icon in the address bar
3. Click padlock → should show "Connection is secure"

---

### Step 6: Switch to Phase 2 .env Configuration

Now that SSL is working, enable all security features.

On your **local machine**:

```bash
# First, get the SECRET_KEY from Phase 1 .env
# (You should have saved this earlier)

# Edit Phase 2 .env configuration
nano deployment/.env.phase2-https

# Update the SECRET_KEY with the SAME key from Phase 1
# (IMPORTANT: Use the SAME key, don't generate a new one!)
SECRET_KEY=django-insecure-k#7h)o@m_45x&$8w!t9yx^n2%f3g+j-5m=z*6$2p@q7r8s

# Save and exit
```

---

### Step 7: Deploy Phase 2 .env to Server

From your **local machine**:

```bash
# Copy the Phase 2 .env file to server
scp deployment/.env.phase2-https ubuntu@18.223.101.101:/tmp/.env.phase2

# SSH into the server
ssh ubuntu@18.223.101.101
```

On the **server**:

```bash
# Backup the current (Phase 1) .env
sudo cp /home/deploy/shadcoding-task1/backend/.env \
       /home/deploy/shadcoding-task1/backend/.env.phase1.backup

# Verify backup was created
ls -lh /home/deploy/shadcoding-task1/backend/.env*

# Replace with Phase 2 .env
sudo mv /tmp/.env.phase2 /home/deploy/shadcoding-task1/backend/.env

# Set correct ownership and permissions
sudo chown deploy:deploy /home/deploy/shadcoding-task1/backend/.env
sudo chmod 600 /home/deploy/shadcoding-task1/backend/.env
```

---

### Step 8: Restart Services and Verify

On the **server**:

```bash
# Restart Gunicorn
sudo systemctl restart gunicorn

# Check status
sudo systemctl status gunicorn

# Reload Nginx
sudo systemctl reload nginx

# Check status
sudo systemctl status nginx
```

---

### Step 9: Test Full HTTPS Deployment

From your **local machine**:

```bash
# Test HTTPS API
curl https://zohaib.no/api/projects/

# Test HTTP → HTTPS redirect
curl -I http://zohaib.no
# Should return 301/302 redirect to https://

# Test www subdomain
curl https://www.zohaib.no/api/projects/
```

**In browser**:
1. Visit http://zohaib.no → should redirect to https://zohaib.no
2. Visit https://zohaib.no → should load with padlock
3. Visit https://www.zohaib.no → should work
4. Test all pages:
   - Landing page
   - Projects page
   - Car registration lookup
   - Admin login
   - Dashboard (after login)

---

### Step 10: Verify Security Settings

On the **server**:

```bash
# Check security headers
curl -I https://zohaib.no

# Should include headers like:
# Strict-Transport-Security: max-age=...
# X-Content-Type-Options: nosniff
# X-Frame-Options: DENY
```

**Online tools**:
- SSL Labs: https://www.ssllabs.com/ssltest/
  - Enter "zohaib.no"
  - Should get A or A+ rating
- Security Headers: https://securityheaders.com/
  - Enter "https://zohaib.no"
  - Check security header grades

---

### Phase 3 Complete! ✅

Your production deployment is now complete with:
- ✅ HTTPS enabled with valid SSL certificate
- ✅ All HTTP requests redirect to HTTPS
- ✅ Secure cookies enabled
- ✅ CSRF protection enabled
- ✅ Security headers configured
- ✅ Auto-renewal configured for SSL certificates

---

## Verification and Testing

### Complete System Check

On the **server**:

```bash
# Check all services are running
sudo systemctl status gunicorn nginx

# Check ports
sudo netstat -tlnp | grep -E ':(80|443|8000)'

# Check SSL certificate expiry
sudo certbot certificates

# Check auto-renewal timer
sudo systemctl status certbot.timer
```

---

### Test All Endpoints

```bash
# Public endpoints (no auth required)
curl https://zohaib.no/api/projects/
curl "https://zohaib.no/api/vehicles/lookup/?registration=ABC123"

# Test login
curl -X POST https://zohaib.no/api/auth/jwt/create/ \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"yourpassword"}'

# Should return:
# {"access":"eyJ...","refresh":"eyJ..."}

# Test authenticated endpoint
curl -X POST https://zohaib.no/api/projects/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","description":"Test project","status":"planning"}'
```

---

### Browser Testing Checklist

- [ ] Visit https://zohaib.no → loads correctly with padlock
- [ ] Visit http://zohaib.no → redirects to HTTPS
- [ ] Visit https://www.zohaib.no → works
- [ ] Visit http://18.223.101.101 → redirects to HTTPS or loads
- [ ] Landing page loads
- [ ] Projects page loads and displays projects
- [ ] Car registration lookup works
- [ ] Admin login page loads
- [ ] Can login with credentials
- [ ] Dashboard loads after login
- [ ] Can create new project (authenticated)
- [ ] Can update project (authenticated)
- [ ] Can delete project (authenticated)
- [ ] Logout works
- [ ] Protected routes redirect to login when not authenticated

---

## Troubleshooting

### Issue: Gunicorn won't start

**Symptoms**:
```
sudo systemctl status gunicorn
# Shows: failed, inactive (dead)
```

**Solutions**:

```bash
# Check error logs
sudo journalctl -u gunicorn -n 50
sudo cat /var/log/gunicorn/error.log

# Common causes and fixes:

# 1. .env file not found or invalid
sudo ls -lh /home/deploy/shadcoding-task1/backend/.env
sudo cat /home/deploy/shadcoding-task1/backend/.env | head -10

# 2. Python dependencies missing
sudo su - deploy
cd ~/shadcoding-task1/backend
source ../venv/bin/activate
pip install -r requirements.txt

# 3. Database migration needed
python manage.py migrate

# 4. Static files not collected
python manage.py collectstatic --noinput

# 5. Permission issues
exit  # Back to ubuntu user
sudo chown -R deploy:deploy /home/deploy/shadcoding-task1/
```

---

### Issue: 502 Bad Gateway

**Symptoms**: Nginx returns "502 Bad Gateway"

**Solutions**:

```bash
# Check if Gunicorn is running
sudo systemctl status gunicorn

# Check if Gunicorn is listening on port 8000
sudo netstat -tlnp | grep :8000

# Check Nginx error log
sudo tail -50 /var/log/nginx/error.log

# Test backend directly
curl http://127.0.0.1:8000/api/projects/

# If Gunicorn is not running, start it
sudo systemctl start gunicorn
sudo systemctl restart nginx
```

---

### Issue: SSL certificate errors

**Symptoms**: "Your connection is not private" or SSL errors

**Solutions**:

```bash
# Check if certificates exist
sudo certbot certificates

# Check Nginx SSL configuration
sudo nginx -t
sudo cat /etc/nginx/sites-available/shadcoding | grep ssl

# Renew certificates manually
sudo certbot renew

# Check certificate files
sudo ls -lh /etc/letsencrypt/live/zohaib.no/

# Restart Nginx
sudo systemctl restart nginx
```

---

### Issue: CSRF errors

**Symptoms**: "CSRF verification failed" when submitting forms

**Solutions**:

```bash
# Check .env configuration
sudo grep CSRF_TRUSTED_ORIGINS /home/deploy/shadcoding-task1/backend/.env

# Should be:
# CSRF_TRUSTED_ORIGINS=https://zohaib.no,https://www.zohaib.no

# Make sure you're accessing via HTTPS, not HTTP
# Make sure the domain in the .env matches your browser URL

# Restart Gunicorn after .env changes
sudo systemctl restart gunicorn
```

---

### Issue: Frontend shows API errors

**Symptoms**: Frontend can't connect to backend API

**Solutions**:

```bash
# Check frontend build configuration
# In frontend/src/services/api.ts, verify baseURL:

# For production, should be:
# baseURL: 'https://zohaib.no/api'

# Check CORS configuration
sudo grep CORS_ALLOWED_ORIGINS /home/deploy/shadcoding-task1/backend/backend/settings.py

# Should include your domain:
# CORS_ALLOWED_ORIGINS = [
#     'https://zohaib.no',
#     'https://www.zohaib.no',
# ]

# If changed, rebuild frontend and restart services
```

---

### Issue: "DisallowedHost" error

**Symptoms**: Django returns "Invalid HTTP_HOST header"

**Solutions**:

```bash
# Check ALLOWED_HOSTS in .env
sudo grep ALLOWED_HOSTS /home/deploy/shadcoding-task1/backend/.env

# Should include all domains and IPs you want to access:
# ALLOWED_HOSTS=zohaib.no,www.zohaib.no,18.223.101.101

# Add any missing hosts
# Restart Gunicorn after changes
sudo systemctl restart gunicorn
```

---

### Issue: Database locked error

**Symptoms**: "database is locked" errors in logs

**Solutions**:

```bash
# SQLite can have issues with multiple writers

# Check database permissions
ls -lh /home/deploy/shadcoding-task1/backend/db.sqlite3

# Should be owned by deploy:deploy
sudo chown deploy:deploy /home/deploy/shadcoding-task1/backend/db.sqlite3

# Reduce Gunicorn workers to 2
sudo nano /home/deploy/shadcoding-task1/backend/gunicorn.conf.py
# Change: workers = 2

# Restart Gunicorn
sudo systemctl restart gunicorn

# For production with higher traffic, consider migrating to PostgreSQL
```

---

### Issue: Permission denied errors

**Symptoms**: Various "permission denied" errors in logs

**Solutions**:

```bash
# Fix ownership of entire project
sudo chown -R deploy:deploy /home/deploy/shadcoding-task1/

# Fix staticfiles directory
sudo chown -R deploy:deploy /home/deploy/shadcoding-task1/backend/staticfiles/

# Fix media directory (if exists)
sudo chown -R deploy:deploy /home/deploy/shadcoding-task1/backend/media/

# Fix frontend directory
sudo chown -R www-data:www-data /var/www/shadcoding/frontend/

# Fix log directories
sudo chown -R deploy:deploy /var/log/gunicorn/

# Restart services
sudo systemctl restart gunicorn nginx
```

---

## Maintenance and Monitoring

### Regular Maintenance Tasks

#### Daily
```bash
# Check service status
sudo systemctl status gunicorn nginx

# Check recent errors
sudo journalctl -u gunicorn --since today
sudo tail -100 /var/log/nginx/error.log
```

#### Weekly
```bash
# Check disk space
df -h

# Check SSL certificate expiry
sudo certbot certificates

# Check for system updates
sudo apt update
sudo apt list --upgradable

# Review access logs
sudo tail -500 /var/log/nginx/access.log
```

#### Monthly
```bash
# Apply system updates
sudo apt update && sudo apt upgrade -y

# Backup database
sudo cp /home/deploy/shadcoding-task1/backend/db.sqlite3 \
       /home/deploy/backups/db_$(date +%Y%m%d).sqlite3

# Review and rotate logs
sudo journalctl --vacuum-time=30d

# Check SSL certificate auto-renewal
sudo certbot renew --dry-run
```

---

### Monitoring Commands

```bash
# Real-time Gunicorn logs
sudo journalctl -u gunicorn -f

# Real-time Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Check CPU and memory usage
top
htop  # If installed

# Check network connections
sudo netstat -an | grep ESTABLISHED

# Check disk I/O
iostat  # If installed

# Check Django application health
curl -I https://zohaib.no/api/projects/
```

---

### Database Backup Script

Create a backup script on the **server**:

```bash
# Create backup directory
sudo mkdir -p /home/deploy/backups
sudo chown deploy:deploy /home/deploy/backups

# Create backup script
sudo nano /home/deploy/scripts/backup-database.sh
```

Add this content:

```bash
#!/bin/bash
# Database backup script

BACKUP_DIR="/home/deploy/backups"
DB_FILE="/home/deploy/shadcoding-task1/backend/db.sqlite3"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/db_$DATE.sqlite3"

# Create backup
cp "$DB_FILE" "$BACKUP_FILE"

# Compress backup
gzip "$BACKUP_FILE"

# Keep only last 30 days of backups
find "$BACKUP_DIR" -name "db_*.sqlite3.gz" -mtime +30 -delete

echo "Backup completed: $BACKUP_FILE.gz"
```

Make executable and schedule:

```bash
# Make executable
sudo chmod +x /home/deploy/scripts/backup-database.sh

# Add to crontab (daily at 2 AM)
sudo crontab -e -u deploy

# Add this line:
0 2 * * * /home/deploy/scripts/backup-database.sh >> /var/log/backup.log 2>&1
```

---

### Performance Optimization

```bash
# Enable Gzip compression in Nginx (if not already)
sudo nano /etc/nginx/sites-available/shadcoding

# Add to server block:
# gzip on;
# gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

# Adjust Gunicorn workers based on CPU cores
sudo nano /home/deploy/shadcoding-task1/backend/gunicorn.conf.py

# Formula: (2 * CPU cores) + 1
# For 2 cores: workers = 5
# For 4 cores: workers = 9

# Restart services
sudo systemctl restart gunicorn
sudo systemctl reload nginx
```

---

## Summary

### What You've Accomplished

1. ✅ Deployed Django backend with Gunicorn
2. ✅ Deployed Vue.js frontend with Nginx
3. ✅ Configured environment variables securely
4. ✅ Set up DNS for your domain
5. ✅ Obtained and configured SSL certificates
6. ✅ Enabled HTTPS with automatic HTTP redirect
7. ✅ Secured cookies and CSRF protection
8. ✅ Configured security headers
9. ✅ Set up automated SSL renewal
10. ✅ Implemented monitoring and logging

### Your Production URLs

- **Main Site**: https://zohaib.no
- **API**: https://zohaib.no/api/
- **Projects**: https://zohaib.no/api/projects/
- **Vehicle Lookup**: https://zohaib.no/api/vehicles/lookup/
- **Admin Panel**: https://zohaib.no/admin/
- **Authentication**: https://zohaib.no/api/auth/jwt/create/

### Important Files

- **Environment Config**: `/home/deploy/shadcoding-task1/backend/.env`
- **Database**: `/home/deploy/shadcoding-task1/backend/db.sqlite3`
- **Static Files**: `/var/www/shadcoding/frontend/`
- **Nginx Config**: `/etc/nginx/sites-available/shadcoding`
- **Gunicorn Service**: `/etc/systemd/system/gunicorn.service`
- **SSL Certificates**: `/etc/letsencrypt/live/zohaib.no/`

### Key Commands Reference

```bash
# Service management
sudo systemctl status gunicorn nginx
sudo systemctl restart gunicorn
sudo systemctl reload nginx

# Logs
sudo journalctl -u gunicorn -f
sudo tail -f /var/log/nginx/error.log

# SSL
sudo certbot certificates
sudo certbot renew

# Deployment
cd ~/shadcoding-task1
git pull
bash deployment/deploy.sh
```

### Next Steps (Optional)

1. **Set up monitoring**: Sentry, New Relic, or similar
2. **Configure email notifications**: For Django error emails
3. **Implement CI/CD**: CircleCI or GitHub Actions
4. **Add database backups**: Automated daily backups
5. **Set up logging aggregation**: ELK stack or similar
6. **Implement caching**: Redis for better performance
7. **Add CDN**: CloudFlare or similar for static assets
8. **Migrate to PostgreSQL**: For better performance at scale
9. **Set up staging environment**: For testing before production
10. **Implement automated testing in pipeline**

---

**Congratulations! Your application is now live in production!** 🎉

If you encounter any issues, refer to the Troubleshooting section or check the logs using the commands provided.
