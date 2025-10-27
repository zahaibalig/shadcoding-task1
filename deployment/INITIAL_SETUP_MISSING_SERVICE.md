# Fixing Missing Gunicorn Service - Complete Setup Guide

**Problem**: `Unit gunicorn.service could not be found`

This guide will help you complete the initial server setup and install the missing Gunicorn service.

**Server**: 18.223.101.101 (ubuntu@18.223.101.101)

---

## Quick Status Check

First, let's see what's already set up on your server.

On your **server** (as ubuntu user):

```bash
# Make sure you're ubuntu user
whoami
# Should show: ubuntu

# Check what exists
echo "=== Checking Server Status ==="

# 1. Check if project directory exists
ls -lh /home/deploy/shadcoding-task1/ 2>/dev/null && echo "✅ Project directory exists" || echo "❌ Project directory missing"

# 2. Check if virtual environment exists
ls -lh /home/deploy/shadcoding-task1/venv/ 2>/dev/null && echo "✅ Virtual environment exists" || echo "❌ Virtual environment missing"

# 3. Check if gunicorn service file exists
ls -lh /etc/systemd/system/gunicorn.service 2>/dev/null && echo "✅ Gunicorn service exists" || echo "❌ Gunicorn service missing"

# 4. Check if .env file exists
ls -lh /home/deploy/shadcoding-task1/backend/.env 2>/dev/null && echo "✅ .env file exists" || echo "❌ .env file missing"

# 5. Check if Nginx is installed
nginx -v 2>&1 && echo "✅ Nginx installed" || echo "❌ Nginx not installed"

# 6. Check if Python3 is installed
python3 --version && echo "✅ Python3 installed" || echo "❌ Python3 not installed"

echo "=== Status Check Complete ==="
```

---

## Option A: Automated Installation (Recommended)

**Fastest method** - Run the automated script:

```bash
# On server as ubuntu user
cd /home/deploy/shadcoding-task1

# Run the installation script
sudo bash deployment/install-gunicorn-service.sh

# If successful, skip to "Verification" section below
```

If the script works, you're done! Skip to the **Verification** section at the bottom.

---

## Option B: Manual Step-by-Step Installation

If you prefer to understand each step or the script doesn't work, follow these manual instructions.

### Prerequisites Check

Make sure you're on the server as the **ubuntu** user:

```bash
whoami
# Should output: ubuntu

# If you're deploy, exit first
exit
```

---

### Step 1: Create Python Virtual Environment

```bash
# Switch to deploy user
sudo su - deploy

# Create virtual environment
cd ~/shadcoding-task1
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Verify activation (should see (venv) in prompt)
which python
# Should show: /home/deploy/shadcoding-task1/venv/bin/python

# Exit deploy user for now
exit
```

**Expected output**: Virtual environment created at `/home/deploy/shadcoding-task1/venv/`

---

### Step 2: Install Python Dependencies

```bash
# Switch to deploy user
sudo su - deploy

# Navigate to project
cd ~/shadcoding-task1

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt

# Verify Gunicorn is installed
which gunicorn
# Should show: /home/deploy/shadcoding-task1/venv/bin/gunicorn

gunicorn --version
# Should show: gunicorn (version 21.2.0)

# Exit deploy user
exit
```

**Expected output**: All Python packages installed, including Gunicorn 21.2.0

---

### Step 3: Install Gunicorn Systemd Service

Now we'll install the Gunicorn service file.

```bash
# As ubuntu user, copy service file
sudo cp /home/deploy/shadcoding-task1/deployment/gunicorn.service \
        /etc/systemd/system/gunicorn.service

# Verify file was copied
ls -lh /etc/systemd/system/gunicorn.service

# View the service file
cat /etc/systemd/system/gunicorn.service

# Reload systemd to recognize new service
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable gunicorn

# Check service status (will be inactive, that's OK for now)
sudo systemctl status gunicorn
```

**Expected output**: Service file installed at `/etc/systemd/system/gunicorn.service`

---

### Step 4: Set Up .env File

If you haven't deployed your .env file yet, do it now:

```bash
# Check if .env already exists
ls -lh /home/deploy/shadcoding-task1/backend/.env

# If .env doesn't exist, you need to deploy it
# See DEPLOYMENT_INSTRUCTIONS.md Phase 1 for detailed steps

# Quick version:
# 1. On local machine, update deployment/.env.phase1-http with SECRET_KEY
# 2. Copy to server: scp deployment/.env.phase1-http ubuntu@18.223.101.101:/tmp/.env.phase1
# 3. On server, move it:
sudo mv /tmp/.env.phase1 /home/deploy/shadcoding-task1/backend/.env
sudo chown deploy:deploy /home/deploy/shadcoding-task1/backend/.env
sudo chmod 600 /home/deploy/shadcoding-task1/backend/.env

# Verify .env exists and has content
sudo head -5 /home/deploy/shadcoding-task1/backend/.env
```

**Expected output**: .env file exists at `/home/deploy/shadcoding-task1/backend/.env`

---

### Step 5: Run Database Migrations

```bash
# Switch to deploy user
sudo su - deploy

# Navigate to backend directory
cd ~/shadcoding-task1/backend

# Activate virtual environment
source ../venv/bin/activate

# Run migrations
python manage.py migrate

# Expected output should show migrations being applied:
# Running migrations:
#   Applying contenttypes.0001_initial... OK
#   Applying auth.0001_initial... OK
#   ...

# Exit deploy user
exit
```

**Expected output**: Database migrations applied successfully

---

### Step 6: Collect Static Files

```bash
# Switch to deploy user
sudo su - deploy

# Navigate to backend directory
cd ~/shadcoding-task1/backend

# Activate virtual environment
source ../venv/bin/activate

# Collect static files
python manage.py collectstatic --noinput

# Expected output:
# X static files copied to '/home/deploy/shadcoding-task1/backend/staticfiles'

# Exit deploy user
exit
```

**Expected output**: Static files collected to `backend/staticfiles/`

---

### Step 7: Create Gunicorn Log Directory

```bash
# As ubuntu user, create log directory if it doesn't exist
sudo mkdir -p /var/log/gunicorn

# Set ownership to deploy user
sudo chown -R deploy:www-data /var/log/gunicorn

# Verify
ls -lh /var/log/ | grep gunicorn
# Should show: drwxr-xr-x ... deploy www-data ... gunicorn
```

**Expected output**: Log directory created with correct permissions

---

### Step 8: Start Gunicorn Service

Now we can start the Gunicorn service:

```bash
# As ubuntu user, start the service
sudo systemctl start gunicorn

# Wait a few seconds for it to start
sleep 3

# Check status
sudo systemctl status gunicorn

# Expected output:
# ● gunicorn.service - Gunicorn daemon for ShadCoding Django Backend
#    Loaded: loaded (/etc/systemd/system/gunicorn.service; enabled)
#    Active: active (running) since ...
```

**Expected output**: Gunicorn service is **active (running)**

---

### Step 9: Test Backend Directly

```bash
# Test if backend responds
curl http://127.0.0.1:8000/api/projects/

# Expected output (example):
# []
# Or if you have projects:
# [{"id":1,"name":"Sample Project",...}]

# If you get an error, check logs:
sudo journalctl -u gunicorn -n 50
```

**Expected output**: JSON response from API

---

### Step 10: Configure Nginx (if needed)

Check if Nginx configuration exists:

```bash
# Check if Nginx config exists
ls -lh /etc/nginx/sites-available/shadcoding

# If it doesn't exist, copy it
sudo cp /home/deploy/shadcoding-task1/deployment/nginx.conf \
        /etc/nginx/sites-available/shadcoding

# Create symbolic link to enable it
sudo ln -sf /etc/nginx/sites-available/shadcoding \
            /etc/nginx/sites-enabled/shadcoding

# Remove default Nginx site (if it exists)
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# If test passes, reload Nginx
sudo systemctl reload nginx
```

**Expected output**: Nginx configuration loaded successfully

---

### Step 11: Deploy Frontend (if needed)

```bash
# Check if frontend is deployed
ls -lh /var/www/shadcoding/frontend/

# If frontend directory is empty or missing, deploy it
# Switch to deploy user
sudo su - deploy

cd ~/shadcoding-task1/frontend

# Install npm dependencies
npm ci

# Build frontend
npm run build

# Exit deploy user
exit

# Copy frontend build to web directory
sudo mkdir -p /var/www/shadcoding/frontend
sudo cp -r /home/deploy/shadcoding-task1/frontend/dist/* \
           /var/www/shadcoding/frontend/

# Set correct ownership
sudo chown -R www-data:www-data /var/www/shadcoding/frontend/

# Verify
ls -lh /var/www/shadcoding/frontend/
# Should show index.html and assets/ directory
```

**Expected output**: Frontend built and deployed

---

## Verification

After completing all steps, verify everything works:

### 1. Check Services

```bash
# Check Gunicorn status
sudo systemctl status gunicorn
# Should show: active (running)

# Check Nginx status
sudo systemctl status nginx
# Should show: active (running)
```

### 2. Test Backend

```bash
# Test backend directly
curl http://127.0.0.1:8000/api/projects/

# Test through Nginx
curl http://18.223.101.101/api/projects/

# Both should return JSON
```

### 3. Test Frontend

```bash
# Test if frontend HTML loads
curl http://18.223.101.101/

# Should return HTML content starting with <!DOCTYPE html>
```

### 4. Test in Browser

Open your browser and visit:
- **Frontend**: http://18.223.101.101
- **API**: http://18.223.101.101/api/projects/
- **Admin**: http://18.223.101.101/admin/

All should load without errors.

---

## Troubleshooting

### Issue: Gunicorn won't start

**Check logs**:
```bash
sudo journalctl -u gunicorn -n 50
sudo tail -50 /var/log/gunicorn/error.log
```

**Common causes**:
1. Virtual environment not created
2. Gunicorn not installed in venv
3. .env file missing
4. Database not migrated
5. Permission issues

**Fix**:
```bash
# Ensure venv exists and has gunicorn
sudo su - deploy
source ~/shadcoding-task1/venv/bin/activate
which gunicorn
pip install gunicorn
exit

# Restart service
sudo systemctl restart gunicorn
```

---

### Issue: Permission denied errors

**Fix ownership**:
```bash
sudo chown -R deploy:www-data /home/deploy/shadcoding-task1/
sudo chown -R deploy:www-data /var/log/gunicorn/
sudo systemctl restart gunicorn
```

---

### Issue: Module not found errors

**Reinstall dependencies**:
```bash
sudo su - deploy
cd ~/shadcoding-task1
source venv/bin/activate
pip install -r requirements.txt
exit

sudo systemctl restart gunicorn
```

---

### Issue: Database errors

**Run migrations**:
```bash
sudo su - deploy
cd ~/shadcoding-task1/backend
source ../venv/bin/activate
python manage.py migrate
exit

sudo systemctl restart gunicorn
```

---

## Complete Command Summary

Here's a quick reference of all commands in order:

```bash
# 1. Create virtual environment
sudo su - deploy
cd ~/shadcoding-task1
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
exit

# 2. Install Gunicorn service
sudo cp /home/deploy/shadcoding-task1/deployment/gunicorn.service \
        /etc/systemd/system/gunicorn.service
sudo systemctl daemon-reload
sudo systemctl enable gunicorn

# 3. Set up .env (if needed)
# See DEPLOYMENT_INSTRUCTIONS.md Phase 1

# 4. Run migrations
sudo su - deploy
cd ~/shadcoding-task1/backend
source ../venv/bin/activate
python manage.py migrate
python manage.py collectstatic --noinput
exit

# 5. Create log directory
sudo mkdir -p /var/log/gunicorn
sudo chown -R deploy:www-data /var/log/gunicorn

# 6. Start services
sudo systemctl start gunicorn
sudo systemctl status gunicorn

# 7. Configure Nginx (if needed)
sudo cp /home/deploy/shadcoding-task1/deployment/nginx.conf \
        /etc/nginx/sites-available/shadcoding
sudo ln -sf /etc/nginx/sites-available/shadcoding \
            /etc/nginx/sites-enabled/shadcoding
sudo nginx -t
sudo systemctl reload nginx

# 8. Deploy frontend (if needed)
sudo su - deploy
cd ~/shadcoding-task1/frontend
npm ci
npm run build
exit
sudo mkdir -p /var/www/shadcoding/frontend
sudo cp -r /home/deploy/shadcoding-task1/frontend/dist/* \
           /var/www/shadcoding/frontend/
sudo chown -R www-data:www-data /var/www/shadcoding/frontend/

# 9. Verify
curl http://127.0.0.1:8000/api/projects/
curl http://18.223.101.101/api/projects/
```

---

## What's Next?

After completing this setup and verification:

1. ✅ Your backend is running with Gunicorn
2. ✅ Nginx is serving your frontend and proxying to backend
3. ✅ Site is accessible via http://18.223.101.101

**Next steps**:
1. Configure DNS (see `DNS_CONFIGURATION_GUIDE.md`)
2. Set up SSL certificates (see `DEPLOYMENT_INSTRUCTIONS.md` Phase 3)
3. Switch to Phase 2 .env configuration with full HTTPS security

---

## Need Help?

If you're stuck:

1. **Check logs**:
   ```bash
   sudo journalctl -u gunicorn -f
   sudo tail -f /var/log/nginx/error.log
   ```

2. **Run health check**:
   ```bash
   bash /home/deploy/scripts/health-check.sh
   ```

3. **Refer to troubleshooting guide**:
   See `TROUBLESHOOTING_CHECKLIST.md`

---

**Remember**: You only need to do this initial setup ONCE. After this, you can use the regular `deployment/deploy.sh` script for updates.
