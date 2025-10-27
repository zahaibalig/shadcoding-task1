# Project Location Fix - Complete Guide

**Problem**: Your project is at `/home/ubuntu/shadcoding-task1` but deployment scripts expect `/home/deploy/shadcoding-task1`

**Server**: 18.223.101.101

---

## Quick Decision Guide

### Choose Option A if:
- ✅ You want to follow best practices
- ✅ You want better security (separate admin from application user)
- ✅ You plan to use this for production long-term
- ✅ You want scripts to work as designed without modifications

### Choose Option B if:
- ✅ You want the quickest fix right now
- ✅ You're comfortable with project in ubuntu's home
- ✅ You're testing/developing (not production-critical yet)
- ✅ You don't want to move files around

---

## Option A: Relocate Project (Recommended)

**Time**: ~10 minutes
**Difficulty**: Easy
**Best for**: Production deployments

### What This Does

Safely moves your project from:
```
/home/ubuntu/shadcoding-task1  →  /home/deploy/shadcoding-task1
```

Then you can use all the original deployment scripts without modification.

### Steps

#### 1. Make scripts executable

```bash
# On your server as ubuntu user
cd /home/ubuntu/shadcoding-task1

sudo chmod +x deployment/relocate-project.sh
sudo chmod +x deployment/install-gunicorn-service.sh
```

#### 2. Run relocation script

```bash
# Run the relocation script
sudo bash deployment/relocate-project.sh

# The script will:
# - Verify source and destination
# - Ask if you want to create a backup (say YES)
# - Move the project to /home/deploy/shadcoding-task1
# - Set correct ownership and permissions
# - Ask if you want to remove the original (optional)
```

**Expected output**:
```
==========================================
Relocation Complete!
==========================================

Summary:
  Source:      /home/ubuntu/shadcoding-task1 (removed)
  Destination: /home/deploy/shadcoding-task1 (✓ exists)
  Owner:       deploy:deploy
  Size:        ~500M
  Backup:      /home/ubuntu/shadcoding-task1.backup.20250127_120000 (✓ exists)
```

#### 3. Install Gunicorn service

```bash
# Navigate to new location
cd /home/deploy/shadcoding-task1

# Run the original installation script (now it will work!)
sudo bash deployment/install-gunicorn-service.sh
```

#### 4. Verify everything works

```bash
# Check services
sudo systemctl status gunicorn nginx

# Test backend
curl http://127.0.0.1:8000/api/projects/
curl http://18.223.101.101/api/projects/

# Test in browser
# Visit: http://18.223.101.101
```

#### 5. Clean up backup (optional)

Once you've verified everything works, you can remove the backup:

```bash
# List backups
ls -lh /home/ubuntu/*.backup*

# Remove backup (only after verifying everything works!)
sudo rm -rf /home/ubuntu/shadcoding-task1.backup.*
```

### Advantages of Option A

✅ **Best practice architecture**
  - Separates admin user (ubuntu) from application user (deploy)
  - Better security isolation

✅ **Standard deployment pattern**
  - Follows industry conventions
  - Makes it easier to troubleshoot and get help

✅ **Scripts work as-is**
  - No modification needed
  - Future updates work without changes

✅ **Better permissions management**
  - Deploy user owns application files only
  - Ubuntu user keeps admin privileges

✅ **Production-ready**
  - Proper setup for long-term use

### Disadvantages of Option A

❌ Takes a few extra minutes
❌ Requires moving ~500MB of files
❌ Need to remember new path when SSHing as deploy user

---

## Option B: Use Ubuntu Path (Quick Fix)

**Time**: ~5 minutes
**Difficulty**: Easy
**Best for**: Quick testing or development

### What This Does

Installs Gunicorn service with a modified configuration that works with your current project location at `/home/ubuntu/shadcoding-task1`.

### Steps

#### 1. Make script executable

```bash
# On your server as ubuntu user
cd /home/ubuntu/shadcoding-task1

sudo chmod +x deployment/install-gunicorn-service-ubuntu-path.sh
```

#### 2. Run the ubuntu-path installation script

```bash
# Run the modified installation script
sudo bash deployment/install-gunicorn-service-ubuntu-path.sh

# The script will:
# - Create virtual environment at /home/ubuntu/shadcoding-task1/venv
# - Install all Python dependencies
# - Create custom Gunicorn service file (configured for ubuntu user)
# - Run database migrations
# - Collect static files
# - Start Gunicorn service
# - Configure Nginx
# - Optionally build and deploy frontend
```

**Expected output**:
```
==========================================
Installation Complete!
==========================================

Service Status:
  Gunicorn: active
  Nginx:    active

Configuration:
  Project location: /home/ubuntu/shadcoding-task1
  Running as user:  ubuntu
  Virtual env:      /home/ubuntu/shadcoding-task1/venv
```

#### 3. Verify everything works

```bash
# Check services
sudo systemctl status gunicorn nginx

# Test backend
curl http://127.0.0.1:8000/api/projects/
curl http://18.223.101.101/api/projects/

# Test in browser
# Visit: http://18.223.101.101
```

### Advantages of Option B

✅ **Fastest solution**
  - No file moving required
  - Get up and running in 5 minutes

✅ **No data migration**
  - Project stays where it is
  - Lower risk of file issues

✅ **Simple**
  - One script, done

### Disadvantages of Option B

❌ **Less secure**
  - Ubuntu user runs both system admin AND application
  - No separation of concerns

❌ **Not standard practice**
  - Harder to get help from community
  - Doesn't follow deployment best practices

❌ **Permission complications**
  - Ubuntu user needs write access to application files
  - Potential sudo requirement for application tasks

❌ **Not ideal for production**
  - Fine for testing/development
  - Not recommended for production use

---

## Comparison Table

| Feature | Option A (Relocate) | Option B (Ubuntu Path) |
|---------|---------------------|------------------------|
| **Time to complete** | ~10 minutes | ~5 minutes |
| **Security** | ⭐⭐⭐⭐⭐ Excellent | ⭐⭐⭐ Good |
| **Best practice** | ✅ Yes | ❌ No |
| **Production ready** | ✅ Yes | ⚠️ Acceptable for small projects |
| **Scripts work as-is** | ✅ Yes | ⚠️ Need modified version |
| **User separation** | ✅ Yes (ubuntu admin, deploy app) | ❌ No (ubuntu does both) |
| **Risk** | ⭐⭐ Low (backup created) | ⭐ Very low (no file moves) |
| **Recommended for** | Production | Development/Testing |

---

## Troubleshooting

### If Relocation Script Fails

**Issue**: "Permission denied" errors

**Fix**:
```bash
# Make sure you're running with sudo
sudo bash deployment/relocate-project.sh

# If still failing, check disk space
df -h
```

**Issue**: "Deploy user doesn't exist"

**Fix**: The script will create it automatically, but you can create manually:
```bash
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG www-data deploy
```

---

### If Installation Script Fails

**Issue**: "Gunicorn not found"

**Fix**:
```bash
# Make sure virtual environment was created
ls -lh /home/ubuntu/shadcoding-task1/venv/

# If missing, create it manually:
cd /home/ubuntu/shadcoding-task1
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**Issue**: "Module not found" errors

**Fix**:
```bash
# Reinstall dependencies
cd /home/ubuntu/shadcoding-task1
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

**Issue**: Gunicorn service won't start

**Fix**:
```bash
# Check logs
sudo journalctl -u gunicorn -n 50

# Common causes:
# 1. Missing .env file → Deploy .env file (see DEPLOYMENT_INSTRUCTIONS.md)
# 2. Database not migrated → Run: python manage.py migrate
# 3. Port 8000 in use → sudo netstat -tlnp | grep :8000
```

---

## After Installation (Both Options)

### 1. Deploy .env File

If you haven't already, you need to deploy your .env configuration:

**On local machine**:
```bash
# Generate SECRET_KEY
python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'

# Update .env.phase1-http with the key
nano deployment/.env.phase1-http

# Copy to server
scp deployment/.env.phase1-http ubuntu@18.223.101.101:/tmp/.env.phase1
```

**On server**:
```bash
# For Option A (relocated to /home/deploy/):
sudo mv /tmp/.env.phase1 /home/deploy/shadcoding-task1/backend/.env
sudo chown deploy:deploy /home/deploy/shadcoding-task1/backend/.env
sudo chmod 600 /home/deploy/shadcoding-task1/backend/.env

# For Option B (stays at /home/ubuntu/):
sudo mv /tmp/.env.phase1 /home/ubuntu/shadcoding-task1/backend/.env
sudo chown ubuntu:ubuntu /home/ubuntu/shadcoding-task1/backend/.env
sudo chmod 600 /home/ubuntu/shadcoding-task1/backend/.env

# Restart Gunicorn
sudo systemctl restart gunicorn
```

### 2. Verify Deployment

```bash
# Check services
sudo systemctl status gunicorn nginx

# Test API
curl http://18.223.101.101/api/projects/

# Visit in browser
# http://18.223.101.101
```

### 3. Next Steps

Follow the main deployment guide:

1. **Configure DNS** → See `DNS_CONFIGURATION_GUIDE.md`
2. **Set up SSL** → See `DEPLOYMENT_INSTRUCTIONS.md` Phase 3
3. **Enable HTTPS** → Use `.env.phase2-https` configuration

---

## Switching from Option B to Option A Later

If you chose Option B initially but want to switch to Option A later:

```bash
# 1. Stop Gunicorn
sudo systemctl stop gunicorn

# 2. Run relocation script
cd /home/ubuntu/shadcoding-task1
sudo bash deployment/relocate-project.sh

# 3. Reinstall service with correct paths
cd /home/deploy/shadcoding-task1
sudo bash deployment/install-gunicorn-service.sh

# 4. Restart services
sudo systemctl restart gunicorn nginx
```

---

## FAQs

### Q: Can I use a different location entirely?

**A**: Yes, but you'll need to:
1. Edit all deployment scripts
2. Update paths in:
   - `gunicorn.service`
   - `nginx.conf`
   - `deploy.sh`
   - Any other scripts

It's easier to use one of the two standard locations.

### Q: What if I already have files in /home/deploy/?

**A**: The relocation script will ask if you want to remove them before proceeding. Make sure to back up any important files first.

### Q: Can the deploy user have sudo access?

**A**: You can, but it defeats the purpose of having separate users. The whole point is that deploy should NOT have sudo access for security.

### Q: Will I lose my database or uploaded files?

**A**: No, the relocation script copies everything including:
- SQLite database (`db.sqlite3`)
- Virtual environment
- Static files
- Media uploads
- Git repository
- All configuration files

### Q: How much disk space do I need?

**A**: You need enough space for:
- Original project (~500MB)
- Relocated project (~500MB)
- Backup (~500MB if you choose to create one)

Total: ~1.5GB temporarily, ~500MB after cleanup

### Q: Can I delete the backup immediately?

**A**: It's recommended to wait until you've verified everything works for a day or two. The backup only takes up disk space, so there's no harm in keeping it for a while.

---

## Summary

### Recommendation

**For production**: Use **Option A** (Relocate Project)
- Better security
- Follows best practices
- Future-proof

**For development/testing**: Use **Option B** (Ubuntu Path)
- Quick and easy
- Good enough for testing
- Can migrate to Option A later if needed

### What You Have Now

After completing either option, you'll have:
- ✅ Gunicorn service running
- ✅ Django backend accessible
- ✅ Nginx configured
- ✅ Virtual environment with all dependencies
- ✅ Database migrated
- ✅ Static files collected
- ✅ Frontend deployed (if you chose to)

### Next Documentation

1. `DEPLOYMENT_INSTRUCTIONS.md` - Full deployment guide
2. `DNS_CONFIGURATION_GUIDE.md` - DNS setup
3. `TROUBLESHOOTING_CHECKLIST.md` - Problem solving

---

## Need Help?

If you're stuck:

1. **Check service status**:
   ```bash
   sudo systemctl status gunicorn nginx
   ```

2. **Check logs**:
   ```bash
   sudo journalctl -u gunicorn -f
   sudo tail -f /var/log/nginx/error.log
   ```

3. **Refer to troubleshooting**:
   See `TROUBLESHOOTING_CHECKLIST.md`

---

**Choose your option and let's get your application running!** 🚀
