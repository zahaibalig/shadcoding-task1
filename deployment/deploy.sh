#!/bin/bash

# Deployment Script for ShadCoding Full-Stack App
# This script is run by CircleCI after tests pass
# Can also be run manually for deployments

set -e  # Exit on error

echo "=========================================="
echo "ShadCoding Deployment Script"
echo "=========================================="

# Configuration
APP_DIR="/home/deploy/shadcoding-task1"
VENV_DIR="$APP_DIR/venv"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_BUILD="/tmp/frontend-dist"
FRONTEND_DEST="/var/www/shadcoding/frontend"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if running as deploy user
if [ "$USER" != "deploy" ]; then
    echo -e "${YELLOW}Switching to deploy user...${NC}"
    sudo -u deploy bash "$0"
    exit $?
fi

echo -e "${GREEN}[1/8] Pulling latest code from repository...${NC}"
cd $APP_DIR
git pull origin main || git pull origin master

echo -e "${GREEN}[2/8] Setting up Python virtual environment...${NC}"
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv $VENV_DIR
fi
source $VENV_DIR/bin/activate

echo -e "${GREEN}[3/8] Installing/updating Python dependencies...${NC}"
pip install --upgrade pip
pip install -r requirements.txt

echo -e "${GREEN}[4/8] Running database migrations...${NC}"
cd $BACKEND_DIR
python manage.py migrate --noinput

echo -e "${GREEN}[5/8] Collecting static files...${NC}"
python manage.py collectstatic --noinput

echo -e "${GREEN}[6/8] Deploying frontend build...${NC}"
if [ -d "$FRONTEND_BUILD" ]; then
    sudo rm -rf $FRONTEND_DEST/*
    sudo cp -r $FRONTEND_BUILD/* $FRONTEND_DEST/
    sudo chown -R deploy:www-data $FRONTEND_DEST
    echo "Frontend deployed from CircleCI build"
else
    echo -e "${YELLOW}No frontend build found in /tmp. Building locally...${NC}"
    cd $APP_DIR/frontend
    npm ci
    npm run build
    sudo rm -rf $FRONTEND_DEST/*
    sudo cp -r dist/* $FRONTEND_DEST/
    sudo chown -R deploy:www-data $FRONTEND_DEST
fi

echo -e "${GREEN}[7/8] Restarting Gunicorn...${NC}"
sudo systemctl restart gunicorn
sudo systemctl status gunicorn --no-pager

echo -e "${GREEN}[8/8] Reloading Nginx...${NC}"
sudo nginx -t
sudo systemctl reload nginx

echo ""
echo -e "${GREEN}=========================================="
echo "Deployment Complete!"
echo "==========================================${NC}"
echo ""
echo "Service status:"
echo "  Gunicorn: $(sudo systemctl is-active gunicorn)"
echo "  Nginx: $(sudo systemctl is-active nginx)"
echo ""
echo "Logs:"
echo "  Gunicorn access: /var/log/gunicorn/access.log"
echo "  Gunicorn error:  /var/log/gunicorn/error.log"
echo "  Nginx access:    /var/log/nginx/shadcoding_access.log"
echo "  Nginx error:     /var/log/nginx/shadcoding_error.log"
