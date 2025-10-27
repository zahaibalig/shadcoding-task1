#!/bin/bash

# Automated Gunicorn Service Installation Script
# Fixes the "Unit gunicorn.service not found" error
# Run this on your Ubuntu server as ubuntu user with sudo

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEPLOY_USER="deploy"
APP_DIR="/home/$DEPLOY_USER/shadcoding-task1"
VENV_DIR="$APP_DIR/venv"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_DIR="$APP_DIR/frontend"
FRONTEND_DEST="/var/www/shadcoding/frontend"

echo -e "${BLUE}=========================================="
echo "Gunicorn Service Installation Script"
echo "==========================================${NC}"
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run with sudo${NC}"
    echo "Usage: sudo bash deployment/install-gunicorn-service.sh"
    exit 1
fi

# Check if running in correct directory
if [ ! -d "deployment" ]; then
    echo -e "${RED}Error: Please run this script from the project root directory${NC}"
    echo "Current directory: $(pwd)"
    echo "Expected: $APP_DIR"
    exit 1
fi

echo -e "${YELLOW}This script will:${NC}"
echo "  1. Create Python virtual environment"
echo "  2. Install Python dependencies (including Gunicorn)"
echo "  3. Install Gunicorn systemd service"
echo "  4. Run database migrations"
echo "  5. Collect static files"
echo "  6. Create necessary directories and set permissions"
echo "  7. Start Gunicorn service"
echo "  8. Configure and reload Nginx"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled"
    exit 0
fi

# Step 1: Create virtual environment
echo ""
echo -e "${GREEN}[1/10] Creating Python virtual environment...${NC}"
if [ -d "$VENV_DIR" ]; then
    echo "  Virtual environment already exists at $VENV_DIR"
else
    su - $DEPLOY_USER -c "cd $APP_DIR && python3 -m venv venv"
    echo "  Virtual environment created"
fi

# Step 2: Install Python dependencies
echo ""
echo -e "${GREEN}[2/10] Installing Python dependencies...${NC}"
su - $DEPLOY_USER -c "cd $APP_DIR && source venv/bin/activate && pip install --upgrade pip"
su - $DEPLOY_USER -c "cd $APP_DIR && source venv/bin/activate && pip install -r requirements.txt"
echo "  Python dependencies installed"

# Verify Gunicorn is installed
echo "  Verifying Gunicorn installation..."
GUNICORN_PATH=$(su - $DEPLOY_USER -c "source $VENV_DIR/bin/activate && which gunicorn")
if [ -z "$GUNICORN_PATH" ]; then
    echo -e "${RED}  Error: Gunicorn not found in virtual environment${NC}"
    exit 1
else
    echo "  Gunicorn found at: $GUNICORN_PATH"
fi

# Step 3: Install Gunicorn systemd service
echo ""
echo -e "${GREEN}[3/10] Installing Gunicorn systemd service...${NC}"
if [ -f "/etc/systemd/system/gunicorn.service" ]; then
    echo "  Service file already exists. Backing up..."
    cp /etc/systemd/system/gunicorn.service /etc/systemd/system/gunicorn.service.backup.$(date +%Y%m%d_%H%M%S)
fi

cp $APP_DIR/deployment/gunicorn.service /etc/systemd/system/gunicorn.service
echo "  Service file copied to /etc/systemd/system/gunicorn.service"

# Reload systemd
systemctl daemon-reload
echo "  Systemd daemon reloaded"

# Enable service
systemctl enable gunicorn
echo "  Gunicorn service enabled (will start on boot)"

# Step 4: Check for .env file
echo ""
echo -e "${GREEN}[4/10] Checking for .env file...${NC}"
if [ -f "$BACKEND_DIR/.env" ]; then
    echo "  .env file exists"
else
    echo -e "${YELLOW}  Warning: .env file not found at $BACKEND_DIR/.env${NC}"
    echo "  You will need to create this file before starting Gunicorn"
    echo "  See DEPLOYMENT_INSTRUCTIONS.md Phase 1 for instructions"
    read -p "  Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation paused. Please set up .env file first."
        exit 0
    fi
fi

# Step 5: Run database migrations
echo ""
echo -e "${GREEN}[5/10] Running database migrations...${NC}"
su - $DEPLOY_USER -c "cd $BACKEND_DIR && source $VENV_DIR/bin/activate && python manage.py migrate --noinput"
echo "  Database migrations completed"

# Step 6: Collect static files
echo ""
echo -e "${GREEN}[6/10] Collecting static files...${NC}"
su - $DEPLOY_USER -c "cd $BACKEND_DIR && source $VENV_DIR/bin/activate && python manage.py collectstatic --noinput"
echo "  Static files collected"

# Step 7: Create necessary directories
echo ""
echo -e "${GREEN}[7/10] Creating necessary directories...${NC}"
mkdir -p /var/log/gunicorn
mkdir -p /var/run/gunicorn
mkdir -p /var/www/shadcoding/frontend

# Set ownership
chown -R $DEPLOY_USER:www-data /var/log/gunicorn
chown -R $DEPLOY_USER:www-data /var/run/gunicorn
chown -R www-data:www-data /var/www/shadcoding/frontend

echo "  Directories created and ownership set"

# Step 8: Start Gunicorn service
echo ""
echo -e "${GREEN}[8/10] Starting Gunicorn service...${NC}"
systemctl start gunicorn

# Wait a moment for service to start
sleep 3

# Check if service is running
if systemctl is-active --quiet gunicorn; then
    echo -e "  ${GREEN}Gunicorn service is running!${NC}"
else
    echo -e "  ${RED}Warning: Gunicorn service failed to start${NC}"
    echo "  Check logs with: sudo journalctl -u gunicorn -n 50"
    read -p "  Continue with Nginx setup? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 9: Configure Nginx
echo ""
echo -e "${GREEN}[9/10] Configuring Nginx...${NC}"

# Check if Nginx config exists
if [ -f "/etc/nginx/sites-available/shadcoding" ]; then
    echo "  Nginx config already exists"
else
    echo "  Installing Nginx configuration..."
    cp $APP_DIR/deployment/nginx.conf /etc/nginx/sites-available/shadcoding
    echo "  Config file copied"
fi

# Create symbolic link if it doesn't exist
if [ -L "/etc/nginx/sites-enabled/shadcoding" ]; then
    echo "  Nginx site already enabled"
else
    ln -sf /etc/nginx/sites-available/shadcoding /etc/nginx/sites-enabled/shadcoding
    echo "  Nginx site enabled"
fi

# Remove default site if it exists
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    rm -f /etc/nginx/sites-enabled/default
    echo "  Default site disabled"
fi

# Test Nginx configuration
echo "  Testing Nginx configuration..."
if nginx -t 2>&1 | grep -q "successful"; then
    echo -e "  ${GREEN}Nginx configuration is valid${NC}"

    # Reload Nginx
    systemctl reload nginx
    echo "  Nginx reloaded"
else
    echo -e "  ${YELLOW}Warning: Nginx configuration test failed${NC}"
    echo "  You may need to adjust the Nginx config manually"
fi

# Step 10: Deploy frontend (optional)
echo ""
echo -e "${GREEN}[10/10] Checking frontend deployment...${NC}"

if [ -f "$FRONTEND_DEST/index.html" ]; then
    echo "  Frontend already deployed"
else
    echo "  Frontend not deployed yet"
    read -p "  Do you want to build and deploy frontend now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "  Building frontend..."
        su - $DEPLOY_USER -c "cd $FRONTEND_DIR && npm ci && npm run build"

        echo "  Deploying frontend..."
        cp -r $FRONTEND_DIR/dist/* $FRONTEND_DEST/
        chown -R www-data:www-data $FRONTEND_DEST
        echo -e "  ${GREEN}Frontend deployed${NC}"
    else
        echo "  Skipping frontend deployment"
        echo "  You can deploy it later with:"
        echo "    cd $FRONTEND_DIR && npm ci && npm run build"
        echo "    sudo cp -r dist/* $FRONTEND_DEST/"
    fi
fi

# Final verification
echo ""
echo -e "${BLUE}=========================================="
echo "Installation Complete!"
echo "==========================================${NC}"
echo ""
echo -e "${GREEN}Service Status:${NC}"
echo "  Gunicorn: $(systemctl is-active gunicorn)"
echo "  Nginx:    $(systemctl is-active nginx)"
echo ""

# Test backend
echo -e "${GREEN}Testing backend...${NC}"
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/api/projects/ | grep -q "200"; then
    echo -e "  ${GREEN}✓ Backend responding at http://127.0.0.1:8000${NC}"
else
    echo -e "  ${YELLOW}⚠ Backend may not be responding yet${NC}"
    echo "  Check logs: sudo journalctl -u gunicorn -n 50"
fi

echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "  1. If .env file is not set up, deploy it now (see DEPLOYMENT_INSTRUCTIONS.md)"
echo "  2. Test your site: http://18.223.101.101"
echo "  3. Configure DNS: see DNS_CONFIGURATION_GUIDE.md"
echo "  4. Set up SSL: see DEPLOYMENT_INSTRUCTIONS.md Phase 3"
echo ""
echo -e "${GREEN}Useful commands:${NC}"
echo "  Check Gunicorn status:  sudo systemctl status gunicorn"
echo "  Check Gunicorn logs:    sudo journalctl -u gunicorn -f"
echo "  Restart Gunicorn:       sudo systemctl restart gunicorn"
echo "  Check Nginx status:     sudo systemctl status nginx"
echo "  Check Nginx logs:       sudo tail -f /var/log/nginx/error.log"
echo "  Test backend:           curl http://127.0.0.1:8000/api/projects/"
echo "  Test via IP:            curl http://18.223.101.101/api/projects/"
echo ""
echo -e "${BLUE}==========================================${NC}"
