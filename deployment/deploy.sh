#!/bin/bash

################################################################################
# Deployment Script for ShadCoding Task1
#
# This script deploys updates to the application
# Run as deploy user: bash deployment/deploy.sh
#
# What it does:
# 1. Pull latest code from Git
# 2. Install/update Python dependencies
# 3. Run Django migrations
# 4. Collect Django static files
# 5. Install frontend dependencies
# 6. Build frontend (uses .env.production for API URL)
# 7. Copy frontend build to Nginx directory
# 8. Restart Gunicorn
# 9. Reload Nginx
################################################################################

set -e  # Exit on any error

echo "=================================="
echo "  Deploying ShadCoding Task1"
echo "=================================="
echo ""

# Configuration
PROJECT_DIR="/home/deploy/shadcoding-task1"
VENV_DIR="$PROJECT_DIR/venv"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"
NGINX_DIR="/var/www/shadcoding/frontend"

# Check if running as deploy user
if [ "$(whoami)" != "deploy" ]; then
    echo "WARNING: This script should be run as 'deploy' user"
    echo "Run: sudo -u deploy bash deployment/deploy.sh"
    read -p "Continue anyway? (y/n): " -r CONTINUE
    if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Navigate to project directory
cd "$PROJECT_DIR" || exit 1

echo "Step 1: Syncing with latest code from Git..."
git fetch origin
git reset --hard origin/main

echo ""
echo "Step 2: Installing/updating Python dependencies..."
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install -r requirements.txt

echo ""
echo "Step 3: Running Django migrations..."
cd "$BACKEND_DIR"
python manage.py migrate

echo ""
echo "Step 4: Collecting Django static files..."
python manage.py collectstatic --noinput

echo ""
echo "Step 5: Installing frontend dependencies..."
cd "$FRONTEND_DIR"
npm install

echo ""
echo "Step 6: Building frontend for production..."
# Vite automatically uses .env.production when building
npm run build
echo "Frontend build completed. Size:"
du -sh dist/

echo ""
echo "Step 7: Copying frontend build to Nginx directory..."
sudo rm -rf "$NGINX_DIR"/*
sudo cp -r dist/* "$NGINX_DIR/"
sudo chown -R www-data:www-data "$NGINX_DIR"

echo ""
echo "Step 8: Reloading systemd and restarting Gunicorn..."
sudo systemctl daemon-reload
sudo systemctl restart gunicorn

echo ""
echo "Step 9: Reloading Nginx..."
sudo systemctl reload nginx

echo ""
echo "=================================="
echo "  Deployment Complete!"
echo "=================================="
echo ""
echo "Service Status:"
sudo systemctl status gunicorn --no-pager | head -10
echo ""
sudo systemctl status nginx --no-pager | head -10
echo ""
echo "Application is now running at:"
echo "  http://18.217.70.110"
echo ""
echo "To check logs:"
echo "  Backend:  sudo journalctl -u gunicorn -f"
echo "  Nginx:    sudo tail -f /var/log/nginx/error.log"
echo ""
