# Troubleshooting and Verification Checklist

**Quick reference for diagnosing and fixing common deployment issues**

**Server**: 18.223.101.101 (ubuntu@18.223.101.101)
**Domain**: zohaib.no, www.zohaib.no

---

## Quick Diagnosis Commands

Run these commands on the **server** to get a quick health check:

```bash
#!/bin/bash
# Copy this entire script and run it on your server for a complete health check

echo "=== SYSTEM HEALTH CHECK ==="
echo ""

echo "1. Services Status:"
sudo systemctl is-active gunicorn && echo "✅ Gunicorn: Running" || echo "❌ Gunicorn: Not Running"
sudo systemctl is-active nginx && echo "✅ Nginx: Running" || echo "❌ Nginx: Not Running"
echo ""

echo "2. Ports:"
sudo netstat -tlnp | grep :8000 > /dev/null && echo "✅ Port 8000: Listening (Gunicorn)" || echo "❌ Port 8000: Not Listening"
sudo netstat -tlnp | grep :80 > /dev/null && echo "✅ Port 80: Listening (Nginx)" || echo "❌ Port 80: Not Listening"
sudo netstat -tlnp | grep :443 > /dev/null && echo "✅ Port 443: Listening (Nginx)" || echo "❌ Port 443: Not Listening"
echo ""

echo "3. Configuration Files:"
[ -f /home/deploy/shadcoding-task1/backend/.env ] && echo "✅ .env file exists" || echo "❌ .env file missing"
[ -f /home/deploy/shadcoding-task1/backend/db.sqlite3 ] && echo "✅ Database exists" || echo "❌ Database missing"
[ -d /var/www/shadcoding/frontend ] && echo "✅ Frontend deployed" || echo "❌ Frontend missing"
echo ""

echo "4. SSL Certificates:"
sudo certbot certificates 2>/dev/null | grep -q "zohaib.no" && echo "✅ SSL certificates exist" || echo "❌ SSL certificates missing"
echo ""

echo "5. DNS Resolution:"
nslookup zohaib.no | grep -q "18.223.101.101" && echo "✅ DNS configured correctly" || echo "❌ DNS not configured"
echo ""

echo "6. Backend Health:"
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/api/projects/ | grep -q "200" && echo "✅ Backend responding" || echo "❌ Backend not responding"
echo ""

echo "7. Recent Errors:"
echo "Gunicorn errors (last 10):"
sudo journalctl -u gunicorn --no-pager -n 10 | grep -i error || echo "No recent errors"
echo ""
echo "Nginx errors (last 10):"
sudo tail -10 /var/log/nginx/error.log 2>/dev/null || echo "No recent errors"
echo ""

echo "=== END HEALTH CHECK ==="
```

**Save this as** `/home/deploy/scripts/health-check.sh` and run:
```bash
bash /home/deploy/scripts/health-check.sh
```

---

## Issue Categories

1. [Service Issues](#service-issues)
2. [Network Issues](#network-issues)
3. [Configuration Issues](#configuration-issues)
4. [SSL/HTTPS Issues](#sslhttps-issues)
5. [Database Issues](#database-issues)
6. [Permission Issues](#permission-issues)
7. [Application Errors](#application-errors)

---

## Service Issues

### Gunicorn Won't Start

**Symptoms**:
```bash
sudo systemctl status gunicorn
# Shows: failed, inactive (dead)
```

**Diagnostic Steps**:
```bash
# 1. Check detailed logs
sudo journalctl -u gunicorn -n 50 --no-pager

# 2. Check error log
sudo cat /var/log/gunicorn/error.log

# 3. Check if .env file exists
ls -lh /home/deploy/shadcoding-task1/backend/.env

# 4. Check if venv exists
ls -lh /home/deploy/shadcoding-task1/venv/

# 5. Try running Gunicorn manually
sudo su - deploy
cd ~/shadcoding-task1/backend
source ../venv/bin/activate
gunicorn backend.wsgi:application
# Press Ctrl+C to stop
exit
```

**Common Fixes**:

**Fix 1: .env file missing or misconfigured**
```bash
# Check if .env exists
sudo ls -lh /home/deploy/shadcoding-task1/backend/.env

# If missing, deploy it from local machine
# (See DEPLOYMENT_INSTRUCTIONS.md Phase 1 Step 3)

# If exists, check SECRET_KEY is set
sudo grep SECRET_KEY /home/deploy/shadcoding-task1/backend/.env
# Should NOT be the placeholder value
```

**Fix 2: Python dependencies missing**
```bash
sudo su - deploy
cd ~/shadcoding-task1/backend
source ../venv/bin/activate
pip install -r requirements.txt
exit

sudo systemctl restart gunicorn
```

**Fix 3: Database migration needed**
```bash
sudo su - deploy
cd ~/shadcoding-task1/backend
source ../venv/bin/activate
python manage.py migrate
exit

sudo systemctl restart gunicorn
```

**Fix 4: Port 8000 already in use**
```bash
# Check what's using port 8000
sudo netstat -tlnp | grep :8000

# If another process is using it, kill it
sudo kill <PID>

# Restart Gunicorn
sudo systemctl restart gunicorn
```

**Fix 5: Permission issues**
```bash
# Fix ownership
sudo chown -R deploy:deploy /home/deploy/shadcoding-task1/

# Restart
sudo systemctl restart gunicorn
```

---

### Nginx Won't Start

**Symptoms**:
```bash
sudo systemctl status nginx
# Shows: failed, inactive (dead)
```

**Diagnostic Steps**:
```bash
# 1. Test Nginx configuration
sudo nginx -t

# 2. Check error log
sudo tail -50 /var/log/nginx/error.log

# 3. Check if port 80/443 is in use
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
```

**Common Fixes**:

**Fix 1: Configuration syntax error**
```bash
# Test config
sudo nginx -t

# If errors, check configuration file
sudo nano /etc/nginx/sites-available/shadcoding

# Fix any syntax errors
# Test again
sudo nginx -t

# If OK, restart
sudo systemctl restart nginx
```

**Fix 2: Port already in use**
```bash
# Check what's using ports
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# If Apache or other service, stop it
sudo systemctl stop apache2  # if Apache is running
sudo systemctl disable apache2

# Restart Nginx
sudo systemctl restart nginx
```

**Fix 3: SSL certificate path issues**
```bash
# Check if SSL certificates exist
sudo ls -lh /etc/letsencrypt/live/zohaib.no/

# If missing, run SSL setup
sudo bash /home/deploy/shadcoding-task1/deployment/setup-ssl.sh

# Or temporarily disable SSL in Nginx config
sudo nano /etc/nginx/sites-available/shadcoding
# Comment out SSL-related lines
sudo nginx -t
sudo systemctl restart nginx
```

---

## Network Issues

### 502 Bad Gateway

**Symptoms**: Browser shows "502 Bad Gateway"

**Diagnostic Steps**:
```bash
# 1. Check if Gunicorn is running
sudo systemctl status gunicorn

# 2. Check if Gunicorn is listening
sudo netstat -tlnp | grep :8000

# 3. Test backend directly
curl http://127.0.0.1:8000/api/projects/

# 4. Check Nginx error log
sudo tail -20 /var/log/nginx/error.log
```

**Fix**:
```bash
# Usually means Gunicorn is not running or not responding

# Start Gunicorn
sudo systemctl start gunicorn

# Wait a few seconds
sleep 5

# Restart Nginx
sudo systemctl restart nginx

# Test again
curl http://127.0.0.1:8000/api/projects/
```

---

### 504 Gateway Timeout

**Symptoms**: Browser shows "504 Gateway Timeout"

**Diagnostic Steps**:
```bash
# Check if backend is slow or hanging
time curl http://127.0.0.1:8000/api/projects/

# Check Gunicorn logs for slow queries
sudo journalctl -u gunicorn -n 50
```

**Fix**:
```bash
# Increase timeout in Gunicorn config
sudo nano /home/deploy/shadcoding-task1/backend/gunicorn.conf.py

# Change:
timeout = 30  # Change to 60 or 120

# Restart Gunicorn
sudo systemctl restart gunicorn

# Increase timeout in Nginx config
sudo nano /etc/nginx/sites-available/shadcoding

# Add in location /api/ block:
proxy_read_timeout 120s;
proxy_connect_timeout 120s;

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

---

### Connection Refused

**Symptoms**: `curl: (7) Failed to connect to ... Connection refused`

**Diagnostic Steps**:
```bash
# 1. Check if services are running
sudo systemctl status gunicorn nginx

# 2. Check firewall
sudo ufw status

# 3. Check ports
sudo netstat -tlnp | grep -E ':(80|443|8000)'
```

**Fix**:
```bash
# Start services
sudo systemctl start gunicorn nginx

# Check firewall allows traffic
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload

# If on AWS, check Security Groups allow:
# - Port 80 (HTTP) from 0.0.0.0/0
# - Port 443 (HTTPS) from 0.0.0.0/0
```

---

## Configuration Issues

### ALLOWED_HOSTS Error

**Symptoms**: Django returns "Invalid HTTP_HOST header: 'xxx'. You may need to add 'xxx' to ALLOWED_HOSTS."

**Diagnostic Steps**:
```bash
# Check current ALLOWED_HOSTS
sudo grep ALLOWED_HOSTS /home/deploy/shadcoding-task1/backend/.env
```

**Fix**:
```bash
# Edit .env file
sudo nano /home/deploy/shadcoding-task1/backend/.env

# Update ALLOWED_HOSTS to include the problematic host
ALLOWED_HOSTS=zohaib.no,www.zohaib.no,18.223.101.101,localhost

# Save and restart
sudo systemctl restart gunicorn
```

---

### CSRF Verification Failed

**Symptoms**: "CSRF verification failed. Request aborted."

**Diagnostic Steps**:
```bash
# Check CSRF_TRUSTED_ORIGINS
sudo grep CSRF_TRUSTED_ORIGINS /home/deploy/shadcoding-task1/backend/.env

# Check if you're accessing via HTTPS or HTTP
curl -I https://zohaib.no
```

**Fix**:
```bash
# Edit .env file
sudo nano /home/deploy/shadcoding-task1/backend/.env

# For HTTP access (Phase 1):
CSRF_TRUSTED_ORIGINS=http://18.223.101.101

# For HTTPS access (Phase 2):
CSRF_TRUSTED_ORIGINS=https://zohaib.no,https://www.zohaib.no

# Save and restart
sudo systemctl restart gunicorn

# Make sure to access via the same protocol (HTTP or HTTPS)
```

---

### CORS Errors

**Symptoms**: Browser console shows "CORS policy: No 'Access-Control-Allow-Origin' header"

**Diagnostic Steps**:
```bash
# Check if django-cors-headers is installed
sudo su - deploy
cd ~/shadcoding-task1/backend
source ../venv/bin/activate
pip list | grep cors
exit
```

**Fix**:
```bash
# Install django-cors-headers if missing
sudo su - deploy
cd ~/shadcoding-task1/backend
source ../venv/bin/activate
pip install django-cors-headers
exit

# Check settings.py has correct CORS configuration
sudo nano /home/deploy/shadcoding-task1/backend/backend/settings.py

# Should have:
# INSTALLED_APPS = [
#     ...
#     'corsheaders',
#     ...
# ]
#
# MIDDLEWARE = [
#     'corsheaders.middleware.CorsMiddleware',
#     ...
# ]
#
# CORS_ALLOWED_ORIGINS = [
#     'https://zohaib.no',
#     'https://www.zohaib.no',
# ]

# Restart
sudo systemctl restart gunicorn
```

---

## SSL/HTTPS Issues

### SSL Certificate Not Found

**Symptoms**: Nginx won't start, error about SSL certificate files not found

**Diagnostic Steps**:
```bash
# Check if certificates exist
sudo ls -lh /etc/letsencrypt/live/zohaib.no/

# Check Certbot
sudo certbot certificates
```

**Fix**:
```bash
# If certificates don't exist, obtain them
sudo bash /home/deploy/shadcoding-task1/deployment/setup-ssl.sh

# OR manually:
sudo certbot --nginx -d zohaib.no -d www.zohaib.no

# If DNS is not configured yet, temporarily disable SSL in Nginx
sudo nano /etc/nginx/sites-available/shadcoding
# Comment out SSL-related sections
sudo nginx -t
sudo systemctl restart nginx
```

---

### SSL Certificate Expired

**Symptoms**: Browser shows "Your connection is not private" with NET::ERR_CERT_DATE_INVALID

**Diagnostic Steps**:
```bash
# Check certificate expiry
sudo certbot certificates

# Check auto-renewal timer
sudo systemctl status certbot.timer
```

**Fix**:
```bash
# Renew certificates
sudo certbot renew

# If renewal fails, check DNS is pointing to server
nslookup zohaib.no

# Force renewal
sudo certbot renew --force-renewal

# Restart Nginx
sudo systemctl restart nginx
```

---

### Mixed Content Errors

**Symptoms**: Browser console shows "Mixed Content" warnings

**Fix**:
```bash
# Make sure frontend is making HTTPS requests to backend

# Check frontend API configuration
# In frontend/src/services/api.ts, baseURL should be:
# baseURL: 'https://zohaib.no/api'  (NOT http://)

# If you changed this, rebuild and redeploy frontend
cd /home/deploy/shadcoding-task1/frontend
npm run build
sudo cp -r dist/* /var/www/shadcoding/frontend/
```

---

## Database Issues

### Database Locked

**Symptoms**: "OperationalError: database is locked"

**Diagnostic Steps**:
```bash
# Check database permissions
ls -lh /home/deploy/shadcoding-task1/backend/db.sqlite3

# Check number of Gunicorn workers
sudo grep workers /home/deploy/shadcoding-task1/backend/gunicorn.conf.py

# Check for long-running queries
sudo journalctl -u gunicorn -n 100 | grep -i lock
```

**Fix**:
```bash
# Fix 1: Reduce Gunicorn workers (SQLite limitation)
sudo nano /home/deploy/shadcoding-task1/backend/gunicorn.conf.py

# Change to:
workers = 2  # SQLite works better with fewer workers

# Restart
sudo systemctl restart gunicorn

# Fix 2: Ensure correct permissions
sudo chown deploy:deploy /home/deploy/shadcoding-task1/backend/db.sqlite3
sudo chmod 644 /home/deploy/shadcoding-task1/backend/db.sqlite3

# Fix 3: For high traffic, migrate to PostgreSQL
# (See documentation for PostgreSQL setup)
```

---

### Database Migration Errors

**Symptoms**: "django.db.migrations.exceptions.InconsistentMigrationHistory"

**Fix**:
```bash
# Check migration status
sudo su - deploy
cd ~/shadcoding-task1/backend
source ../venv/bin/activate
python manage.py showmigrations

# If you see unapplied migrations, apply them
python manage.py migrate

# If migration conflicts, you may need to:
# 1. Backup database first!
sudo cp db.sqlite3 db.sqlite3.backup

# 2. Fake the migration if necessary
python manage.py migrate --fake app_name migration_name

# 3. Or reset migrations (DANGER: data loss)
# python manage.py migrate --run-syncdb

exit
sudo systemctl restart gunicorn
```

---

## Permission Issues

### Permission Denied Errors

**Symptoms**: Various "Permission denied" errors in logs

**Diagnostic Steps**:
```bash
# Check ownership of project files
ls -lh /home/deploy/shadcoding-task1/

# Check ownership of database
ls -lh /home/deploy/shadcoding-task1/backend/db.sqlite3

# Check log directory permissions
ls -lh /var/log/gunicorn/
```

**Fix**:
```bash
# Fix project ownership
sudo chown -R deploy:deploy /home/deploy/shadcoding-task1/

# Fix specific files
sudo chown deploy:deploy /home/deploy/shadcoding-task1/backend/db.sqlite3
sudo chown deploy:deploy /home/deploy/shadcoding-task1/backend/.env
sudo chmod 600 /home/deploy/shadcoding-task1/backend/.env

# Fix staticfiles
sudo chown -R deploy:deploy /home/deploy/shadcoding-task1/backend/staticfiles/

# Fix frontend
sudo chown -R www-data:www-data /var/www/shadcoding/frontend/

# Fix log directories
sudo chown -R deploy:deploy /var/log/gunicorn/

# Restart services
sudo systemctl restart gunicorn nginx
```

---

## Application Errors

### 500 Internal Server Error

**Symptoms**: Browser shows "500 Internal Server Error"

**Diagnostic Steps**:
```bash
# Check recent application errors
sudo journalctl -u gunicorn -n 50 | grep -i error

# Check Gunicorn error log
sudo tail -50 /var/log/gunicorn/error.log

# Check if DEBUG is enabled (should be False in production)
sudo grep DEBUG /home/deploy/shadcoding-task1/backend/.env
```

**Fix**:
```bash
# Temporarily enable detailed error messages
sudo nano /home/deploy/shadcoding-task1/backend/.env

# Change to:
DEBUG=True  # TEMPORARY - for debugging only!

# Restart
sudo systemctl restart gunicorn

# Reproduce the error and check logs
sudo journalctl -u gunicorn -f

# Once you identify the issue, set DEBUG back to False
DEBUG=False

# Restart
sudo systemctl restart gunicorn
```

---

### Import Errors

**Symptoms**: "ModuleNotFoundError: No module named '...'"

**Fix**:
```bash
# Reinstall dependencies
sudo su - deploy
cd ~/shadcoding-task1/backend
source ../venv/bin/activate
pip install -r requirements.txt --upgrade
exit

sudo systemctl restart gunicorn
```

---

### Frontend Not Loading

**Symptoms**: Blank page or "Cannot GET /"

**Diagnostic Steps**:
```bash
# Check if frontend is deployed
ls -lh /var/www/shadcoding/frontend/

# Check if index.html exists
ls -lh /var/www/shadcoding/frontend/index.html

# Check Nginx access log
sudo tail -20 /var/log/nginx/access.log
```

**Fix**:
```bash
# Redeploy frontend
cd /home/deploy/shadcoding-task1/frontend
npm run build

# Copy to web directory
sudo mkdir -p /var/www/shadcoding/frontend/
sudo cp -r dist/* /var/www/shadcoding/frontend/

# Fix permissions
sudo chown -R www-data:www-data /var/www/shadcoding/frontend/

# Reload Nginx
sudo systemctl reload nginx

# Clear browser cache and try again
```

---

## Verification Checklist

Use this checklist after making changes:

### Phase 1 (HTTP) Verification

- [ ] Services running: `sudo systemctl status gunicorn nginx`
- [ ] Backend responds: `curl http://127.0.0.1:8000/api/projects/`
- [ ] Nginx proxies: `curl http://18.223.101.101/api/projects/`
- [ ] Frontend loads: Visit `http://18.223.101.101` in browser
- [ ] No errors in logs: `sudo journalctl -u gunicorn -n 20`

### Phase 2 (DNS) Verification

- [ ] DNS resolves: `nslookup zohaib.no` returns `18.223.101.101`
- [ ] WWW resolves: `nslookup www.zohaib.no` returns `18.223.101.101`
- [ ] HTTP works via domain: `curl http://zohaib.no/api/projects/`
- [ ] WWW works: `curl http://www.zohaib.no/api/projects/`

### Phase 3 (HTTPS) Verification

- [ ] SSL certificates exist: `sudo certbot certificates`
- [ ] HTTPS works: `curl https://zohaib.no/api/projects/`
- [ ] WWW HTTPS works: `curl https://www.zohaib.no/api/projects/`
- [ ] HTTP redirects to HTTPS: `curl -I http://zohaib.no`
- [ ] Padlock shows in browser: Visit `https://zohaib.no`
- [ ] Security headers present: `curl -I https://zohaib.no`
- [ ] SSL grade A+: Test at https://www.ssllabs.com/ssltest/

### Application Verification

- [ ] Landing page loads
- [ ] Projects page loads
- [ ] Vehicle lookup works
- [ ] Admin login page loads
- [ ] Can login successfully
- [ ] Dashboard loads after login
- [ ] Can create project (authenticated)
- [ ] Can update project (authenticated)
- [ ] Can delete project (authenticated)
- [ ] Logout works
- [ ] Protected routes redirect when not authenticated

---

## Emergency Rollback

If something goes wrong and you need to quickly rollback:

### Rollback .env Configuration

```bash
# If you backed up your .env file
sudo cp /home/deploy/shadcoding-task1/backend/.env.phase1.backup \
       /home/deploy/shadcoding-task1/backend/.env

# Restart
sudo systemctl restart gunicorn
```

### Rollback Nginx Configuration

```bash
# If you backed up Nginx config
sudo cp /etc/nginx/sites-available/shadcoding.backup \
       /etc/nginx/sites-available/shadcoding

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

### Rollback to Previous Git Commit

```bash
sudo su - deploy
cd ~/shadcoding-task1

# See recent commits
git log --oneline -10

# Rollback to specific commit
git reset --hard <commit-hash>

# Reinstall dependencies and restart
cd backend
source ../venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
exit

sudo systemctl restart gunicorn nginx
```

---

## Getting More Information

### View Logs

```bash
# Real-time Gunicorn logs
sudo journalctl -u gunicorn -f

# Last 100 lines of Gunicorn
sudo journalctl -u gunicorn -n 100

# Gunicorn error log
sudo tail -f /var/log/gunicorn/error.log

# Nginx error log
sudo tail -f /var/log/nginx/error.log

# Nginx access log
sudo tail -f /var/log/nginx/access.log

# System log
sudo tail -f /var/log/syslog
```

### Check Resource Usage

```bash
# CPU and memory
top
htop  # If installed

# Disk space
df -h

# Disk I/O
iostat  # If installed

# Network
netstat -an | grep ESTABLISHED
```

---

## When to Ask for Help

If you've tried the above and still have issues:

1. **Gather information**:
   ```bash
   # Save diagnostic info
   sudo journalctl -u gunicorn -n 200 > ~/gunicorn.log
   sudo tail -200 /var/log/nginx/error.log > ~/nginx.log
   sudo nginx -t > ~/nginx-test.log 2>&1
   ```

2. **Include in your help request**:
   - Error message (exact text)
   - What you were trying to do
   - What phase you're in (Phase 1/2/3)
   - Service status outputs
   - Relevant log snippets
   - What you've already tried

3. **Where to ask**:
   - Project GitHub issues
   - Stack Overflow (tag: django, nginx, deployment)
   - Django Forum
   - DevOps Stack Exchange

---

## Quick Command Reference

```bash
# Service Management
sudo systemctl status gunicorn
sudo systemctl restart gunicorn
sudo systemctl reload nginx

# Logs
sudo journalctl -u gunicorn -f
sudo tail -f /var/log/nginx/error.log

# Testing
curl http://127.0.0.1:8000/api/projects/
curl https://zohaib.no/api/projects/

# DNS
nslookup zohaib.no
dig zohaib.no +short

# SSL
sudo certbot certificates
sudo certbot renew

# Permissions
sudo chown -R deploy:deploy /home/deploy/shadcoding-task1/

# Health Check
bash /home/deploy/scripts/health-check.sh
```

---

**Remember**: Always backup before making major changes, and test changes in a staging environment when possible!
