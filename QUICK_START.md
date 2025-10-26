# Quick Start Deployment Guide

You have your AWS server IP and domain name. Follow these steps to deploy!

## Current Status ✅

- ✅ AWS server created
- ✅ Server IP address obtained
- ✅ Domain name registered

---

## Step 1: Configure DNS (Do This First!)

Point your domain to your AWS server.

### Go to Your Domain Registrar

(e.g., GoDaddy, Namecheap, Google Domains, Cloudflare)

### Add These DNS Records:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | @ | YOUR_AWS_IP | 3600 |
| A | www | YOUR_AWS_IP | 3600 |

**Example:**
```
Type: A
Name: @
Value: 54.123.45.67  (your AWS IP)
TTL: 3600

Type: A
Name: www
Value: 54.123.45.67  (your AWS IP)
TTL: 3600
```

**Wait 5-10 minutes** for DNS to propagate.

**Verify DNS is working:**
```bash
# Replace yourdomain.com with your actual domain
dig yourdomain.com +short
# Should show your AWS IP
```

---

## Step 2: Connect to Your AWS Server

### Get Your AWS SSH Key

When you created the EC2 instance, you downloaded a `.pem` file.

### Connect via SSH:

```bash
# Replace with your actual key file and IP
chmod 400 ~/Downloads/your-key.pem
ssh -i ~/Downloads/your-key.pem ubuntu@YOUR_AWS_IP
```

**Common AWS usernames:**
- Ubuntu: `ubuntu`
- Amazon Linux: `ec2-user`
- Debian: `admin`

---

## Step 3: Initial Server Setup

Once connected to your server:

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Clone your repository (replace with your GitHub repo)
cd /home/ubuntu
git clone https://github.com/YOUR_USERNAME/shadcoding-task1.git
cd shadcoding-task1

# Make scripts executable
chmod +x deployment/*.sh

# Run server setup script
sudo bash deployment/setup-server.sh
```

**What this does:**
- Installs Python, Node.js, Nginx, Certbot
- Creates a `deploy` user
- Sets up directories
- Configures firewall

---

## Step 4: Set Up SSH Key for Deploy User

### On Your Local Machine:

```bash
# Generate SSH key for deployment
ssh-keygen -t ed25519 -C "deployment-key" -f ~/.ssh/aws_deploy
# Press Enter for no passphrase

# Copy the public key
cat ~/.ssh/aws_deploy.pub
# Copy the output
```

### Back on AWS Server:

```bash
# Switch to deploy user
sudo su - deploy

# Add your public key
mkdir -p ~/.ssh
nano ~/.ssh/authorized_keys
# Paste the public key you copied
# Save and exit (Ctrl+X, Y, Enter)

chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
exit  # Back to ubuntu user
```

### Test Deploy User Access:

```bash
# From your local machine
ssh -i ~/.ssh/aws_deploy deploy@YOUR_AWS_IP
# Should work without password
```

---

## Step 5: Configure Environment Variables

### On AWS Server (as deploy user):

```bash
ssh -i ~/.ssh/aws_deploy deploy@YOUR_AWS_IP

cd /home/deploy/shadcoding-task1/backend

# Copy the environment template
cp ../deployment/.env.production .env

# Edit the .env file
nano .env
```

### Fill in these values:

```bash
# Generate a secret key first
python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
# Copy the output
```

**Edit .env:**
```
SECRET_KEY=paste-the-generated-secret-key-here
DEBUG=False
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com,YOUR_AWS_IP
STATENS_VEGVESEN_API_KEY=your-api-key-here
CSRF_TRUSTED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

Save and exit (Ctrl+X, Y, Enter).

---

## Step 6: Install and Start Services

### Still on AWS Server:

```bash
cd /home/deploy/shadcoding-task1

# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Run migrations
cd backend
python manage.py migrate

# Create superuser for admin access
python manage.py createsuperuser
# Enter username, email, and password

# Collect static files
python manage.py collectstatic --noinput

cd ..
```

### Set up Gunicorn service:

```bash
# Copy service file
sudo cp deployment/gunicorn.service /etc/systemd/system/

# Create log directory
sudo mkdir -p /var/log/gunicorn
sudo chown deploy:www-data /var/log/gunicorn

# Enable and start Gunicorn
sudo systemctl daemon-reload
sudo systemctl enable gunicorn
sudo systemctl start gunicorn

# Check status (should be active/running)
sudo systemctl status gunicorn
```

---

## Step 7: Configure Nginx

```bash
# Copy nginx config
sudo cp deployment/nginx.conf /etc/nginx/sites-available/shadcoding

# Replace YOUR_DOMAIN with your actual domain
sudo sed -i 's/YOUR_DOMAIN/yourdomain.com/g' /etc/nginx/sites-available/shadcoding

# Enable the site
sudo ln -s /etc/nginx/sites-available/shadcoding /etc/nginx/sites-enabled/

# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Build and deploy frontend
cd frontend
npm ci
npm run build

# Copy to web root
sudo mkdir -p /var/www/shadcoding/frontend
sudo cp -r dist/* /var/www/shadcoding/frontend/
sudo chown -R deploy:www-data /var/www/shadcoding

cd ..

# Test nginx config
sudo nginx -t

# Restart nginx (will fail on SSL for now - that's OK)
sudo systemctl restart nginx
```

**At this point, your site should be accessible via HTTP:**
- http://YOUR_AWS_IP
- http://yourdomain.com (if DNS propagated)

---

## Step 8: Set Up SSL (HTTPS)

### Make sure DNS is working first!

```bash
# Check if domain resolves to your IP
dig yourdomain.com +short
# Should show your AWS IP
```

### Run SSL setup script:

```bash
sudo bash deployment/setup-ssl.sh
```

**Enter when prompted:**
- Domain: `yourdomain.com`
- Email: `your-email@example.com`

**This will:**
- Obtain Let's Encrypt SSL certificate
- Update Nginx config for HTTPS
- Set up auto-renewal

**Your site should now work with HTTPS:**
- https://yourdomain.com ✅
- https://www.yourdomain.com ✅

---

## Step 9: Configure CircleCI (Optional but Recommended)

### 1. Push Your Code to GitHub

```bash
# On your local machine
cd /path/to/shadcoding-task1

git add .
git commit -m "Add deployment configuration"
git push origin main
```

### 2. Set Up CircleCI

1. Go to [CircleCI](https://circleci.com/)
2. Sign in with GitHub
3. Click "Projects" → "Set Up Project"
4. Select your `shadcoding-task1` repository
5. CircleCI will detect `.circleci/config.yml`

### 3. Add Environment Variables in CircleCI

Project Settings → Environment Variables → Add:

| Variable | Value |
|----------|-------|
| `SERVER_IP` | Your AWS IP (e.g., 54.123.45.67) |
| `DEPLOY_USER` | `deploy` |
| `SSH_KEY_FINGERPRINT` | See next step |

### 4. Add SSH Key to CircleCI

1. In CircleCI: Project Settings → SSH Keys → Add SSH Key
2. Hostname: `YOUR_AWS_IP`
3. Private Key: Content of `~/.ssh/aws_deploy` (your private key)
   ```bash
   # On your local machine
   cat ~/.ssh/aws_deploy
   # Copy the entire output including BEGIN/END lines
   ```
4. Click "Add SSH Key"
5. Copy the fingerprint (e.g., `aa:bb:cc:dd:...`)
6. Add `SSH_KEY_FINGERPRINT` to environment variables

### 5. Test Auto-Deployment

```bash
# Make a small change
echo "# Test deployment" >> README.md
git add README.md
git commit -m "Test CircleCI deployment"
git push origin main
```

Watch in CircleCI:
- ✅ Backend tests (17 tests)
- ✅ Frontend tests (35 tests)
- ✅ Build frontend
- ✅ Deploy to AWS

---

## Step 10: Verify Everything Works

### Check Your Site:

1. **Frontend**: https://yourdomain.com
2. **API**: https://yourdomain.com/api/projects/
3. **Admin**: https://yourdomain.com/admin/ (login with superuser)
4. **Car Lookup**: https://yourdomain.com/car-registration

### Check Services:

```bash
# SSH to server
ssh -i ~/.ssh/aws_deploy deploy@YOUR_AWS_IP

# Check services
sudo systemctl status gunicorn
sudo systemctl status nginx

# View logs
sudo tail -f /var/log/gunicorn/error.log
sudo tail -f /var/log/nginx/shadcoding_error.log
```

---

## 🎉 You're Live!

Your application is now deployed with:
- ✅ HTTPS (SSL certificate)
- ✅ Automated deployments via CircleCI
- ✅ Production-ready setup with Gunicorn + Nginx
- ✅ Auto-renewing SSL certificates

---

## Common Issues & Solutions

### Issue: Can't SSH to server

**Solution:**
```bash
# Make sure SSH key has correct permissions
chmod 400 ~/.ssh/aws_deploy

# Check AWS security group allows SSH (port 22)
# In AWS Console: EC2 → Security Groups → Inbound Rules
# Should have: SSH (22) from your IP or 0.0.0.0/0
```

### Issue: Gunicorn fails to start

**Solution:**
```bash
# Check logs
sudo journalctl -u gunicorn -n 50

# Common fix: Check .env file exists
ls -la /home/deploy/shadcoding-task1/backend/.env

# Restart
sudo systemctl restart gunicorn
```

### Issue: Nginx shows 502 Bad Gateway

**Solution:**
```bash
# Gunicorn probably not running
sudo systemctl status gunicorn
sudo systemctl start gunicorn

# Check if listening on port 8000
sudo netstat -tlnp | grep 8000
```

### Issue: SSL setup fails

**Solution:**
```bash
# Make sure DNS is working first!
dig yourdomain.com +short
# Should show your AWS IP

# Make sure ports 80 and 443 are open
# AWS Console: Security Groups → Inbound Rules
# HTTP (80): 0.0.0.0/0
# HTTPS (443): 0.0.0.0/0

# Try again
sudo bash deployment/setup-ssl.sh
```

---

## AWS Security Group Settings

Make sure these ports are open in your AWS Security Group:

| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 22 | TCP | Your IP or 0.0.0.0/0 | SSH |
| 80 | TCP | 0.0.0.0/0 | HTTP |
| 443 | TCP | 0.0.0.0/0 | HTTPS |

**How to check:**
1. AWS Console → EC2 → Instances
2. Click your instance
3. Security tab → Security groups → Edit inbound rules

---

## Next Steps

After deployment:

1. **Test all features**
   - Projects CRUD
   - Car registration lookup
   - Admin panel

2. **Set up monitoring** (optional)
   - AWS CloudWatch
   - Error notifications

3. **Configure backups** (optional)
   - Database backups
   - Code repository

4. **Update README** with your domain
   - Replace placeholder URLs
   - Add deployment badge from CircleCI

---

## Need Help?

Check these files:
- `DEPLOYMENT.md` - Full deployment documentation
- `deployment/` folder - All deployment scripts
- `.circleci/config.yml` - CI/CD configuration

Run diagnostics:
```bash
# Check all services
sudo systemctl status gunicorn nginx

# Check logs
sudo tail -f /var/log/gunicorn/error.log
sudo tail -f /var/log/nginx/shadcoding_error.log
```

---

**You're all set! Happy deploying! 🚀**
