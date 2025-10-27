#!/bin/bash

################################################################################
# Server Setup Script for ShadCoding Task1
#
# This script performs initial one-time setup on a fresh Ubuntu server
# Run as: sudo bash deployment/setup_server.sh
#
# Requirements:
# - Ubuntu 20.04 or 22.04 LTS
# - Run with sudo privileges
# - Internet connection
################################################################################

set -e  # Exit on any error

echo "=================================="
echo "  ShadCoding Server Setup"
echo "=================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run this script with sudo"
    exit 1
fi

echo "Step 1: Updating system packages..."
apt-get update
apt-get upgrade -y

echo ""
echo "Step 2: Installing system dependencies..."
apt-get install -y \
    python3 \
    python3-venv \
    python3-pip \
    nginx \
    git \
    curl \
    build-essential \
    ufw

echo ""
echo "Step 3: Installing Node.js 20..."
# Install Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Verify installations
echo ""
echo "Verifying installations..."
python3 --version
node --version
npm --version
nginx -v

echo ""
echo "Step 4: Creating deploy user..."
if id "deploy" &>/dev/null; then
    echo "User 'deploy' already exists, skipping..."
else
    useradd -m -s /bin/bash deploy
    echo "User 'deploy' created successfully"
fi

# Add deploy user to www-data group for Nginx permissions
usermod -aG www-data deploy

echo ""
echo "Step 5: Setting up project directory..."
PROJECT_DIR="/home/deploy/shadcoding-task1"

# Clone repository if not exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Please enter your Git repository URL:"
    read -r REPO_URL

    sudo -u deploy git clone "$REPO_URL" "$PROJECT_DIR"
    echo "Repository cloned to $PROJECT_DIR"
else
    echo "Project directory already exists: $PROJECT_DIR"
fi

# Set proper permissions
chown -R deploy:deploy /home/deploy

echo ""
echo "Step 6: Creating Python virtual environment..."
sudo -u deploy python3 -m venv "$PROJECT_DIR/venv"
echo "Virtual environment created at $PROJECT_DIR/venv"

echo ""
echo "Step 7: Installing Python dependencies..."
sudo -u deploy bash -c "cd $PROJECT_DIR && source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"

echo ""
echo "Step 8: Creating .env file..."
if [ ! -f "$PROJECT_DIR/backend/.env" ]; then
    cp "$PROJECT_DIR/deployment/.env.example" "$PROJECT_DIR/backend/.env"
    echo ".env file created. IMPORTANT: Edit $PROJECT_DIR/backend/.env with your actual values!"
    echo ""
    echo "Generating SECRET_KEY..."
    SECRET_KEY=$(python3 -c 'import secrets; print("".join(secrets.choice("abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*(-_=+)") for i in range(50)))')
    sudo -u deploy sed -i "s/your-secret-key-here-generate-a-new-one/$SECRET_KEY/" "$PROJECT_DIR/backend/.env"
    echo "SECRET_KEY generated and added to .env"
else
    echo ".env file already exists, skipping..."
fi

echo ""
echo "Step 9: Running Django setup..."
sudo -u deploy bash -c "cd $PROJECT_DIR/backend && source ../venv/bin/activate && python manage.py migrate"
sudo -u deploy bash -c "cd $PROJECT_DIR/backend && source ../venv/bin/activate && python manage.py collectstatic --noinput"

echo ""
echo "Step 10: Creating Django superuser..."
echo "You can create a superuser now (or skip and do it later):"
read -p "Create superuser now? (y/n): " -r CREATE_SUPER
if [[ $CREATE_SUPER =~ ^[Yy]$ ]]; then
    sudo -u deploy bash -c "cd $PROJECT_DIR/backend && source ../venv/bin/activate && python manage.py createsuperuser"
else
    echo "Skipped. You can create a superuser later with:"
    echo "  sudo -u deploy bash -c 'cd /home/deploy/shadcoding-task1/backend && source ../venv/bin/activate && python manage.py createsuperuser'"
fi

echo ""
echo "Step 11: Installing frontend dependencies and building..."
sudo -u deploy bash -c "cd $PROJECT_DIR/frontend && npm install"

# Update API URL to production
echo "Updating frontend API URL to production..."
sudo -u deploy sed -i "s|http://localhost:8000/api|http://18.223.101.101/api|g" "$PROJECT_DIR/frontend/src/services/api.ts"

sudo -u deploy bash -c "cd $PROJECT_DIR/frontend && npm run build"

echo ""
echo "Step 12: Setting up Nginx directory..."
mkdir -p /var/www/shadcoding/frontend
cp -r "$PROJECT_DIR/frontend/dist/"* /var/www/shadcoding/frontend/
chown -R www-data:www-data /var/www/shadcoding

echo ""
echo "Step 13: Installing Nginx configuration..."
cp "$PROJECT_DIR/deployment/nginx.conf" /etc/nginx/sites-available/shadcoding
ln -sf /etc/nginx/sites-available/shadcoding /etc/nginx/sites-enabled/shadcoding

# Remove default Nginx site
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

echo ""
echo "Step 14: Installing Gunicorn systemd service..."
cp "$PROJECT_DIR/deployment/gunicorn.service" /etc/systemd/system/gunicorn.service
systemctl daemon-reload
systemctl enable gunicorn
systemctl start gunicorn

echo ""
echo "Step 15: Starting Nginx..."
systemctl restart nginx

echo ""
echo "Step 16: Configuring UFW firewall..."
ufw --force enable
ufw allow OpenSSH
ufw allow 'Nginx HTTP'
ufw status

echo ""
echo "Step 17: Creating log directories..."
mkdir -p /var/log/gunicorn
chown -R deploy:deploy /var/log/gunicorn

echo ""
echo "=================================="
echo "  Setup Complete!"
echo "=================================="
echo ""
echo "Service Status:"
systemctl status gunicorn --no-pager | head -10
echo ""
systemctl status nginx --no-pager | head -10
echo ""
echo "Your application should now be running!"
echo ""
echo "Access your application at:"
echo "  http://18.223.101.101"
echo ""
echo "Django Admin:"
echo "  http://18.223.101.101/admin/"
echo ""
echo "IMPORTANT NEXT STEPS:"
echo "1. Edit /home/deploy/shadcoding-task1/backend/.env with your actual values"
echo "2. Restart services: sudo systemctl restart gunicorn nginx"
echo "3. Check logs if issues: sudo journalctl -u gunicorn -f"
echo ""
echo "To deploy updates, run:"
echo "  sudo -u deploy bash /home/deploy/shadcoding-task1/deployment/deploy.sh"
echo ""
