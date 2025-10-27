#!/bin/bash

# Server Setup Script for ShadCoding Full-Stack App
# Run this ONCE on a fresh Ubuntu server
# Usage: sudo bash setup-server.sh

set -e  # Exit on error

echo "=========================================="
echo "ShadCoding Server Setup"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DEPLOY_USER="deploy"
APP_DIR="/home/$DEPLOY_USER/shadcoding-task1"
DOMAIN="zohaib.no"  # Replace with your domain

echo -e "${YELLOW}This script will:${NC}"
echo "  1. Update system packages"
echo "  2. Install Python, Node.js, Nginx, and dependencies"
echo "  3. Create deployment user"
echo "  4. Set up directory structure"
echo "  5. Configure firewall"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Update system
echo -e "${GREEN}[1/8] Updating system packages...${NC}"
apt-get update
apt-get upgrade -y

# Install system dependencies
echo -e "${GREEN}[2/8] Installing system dependencies...${NC}"
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    libpq-dev \
    nginx \
    curl \
    git \
    ufw \
    certbot \
    python3-certbot-nginx

# Install Node.js 20.x
echo -e "${GREEN}[3/8] Installing Node.js 20.x...${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Create deployment user
echo -e "${GREEN}[4/8] Creating deployment user...${NC}"
if id "$DEPLOY_USER" &>/dev/null; then
    echo "User $DEPLOY_USER already exists"
else
    useradd -m -s /bin/bash $DEPLOY_USER
    usermod -aG www-data $DEPLOY_USER
    echo "User $DEPLOY_USER created"
fi

# Create directory structure
echo -e "${GREEN}[5/8] Creating directory structure...${NC}"
mkdir -p /var/log/gunicorn
mkdir -p /var/run/gunicorn
mkdir -p /var/www/shadcoding/frontend
mkdir -p /var/www/certbot

# Set ownership
chown -R $DEPLOY_USER:www-data /var/log/gunicorn
chown -R $DEPLOY_USER:www-data /var/run/gunicorn
chown -R $DEPLOY_USER:www-data /var/www/shadcoding

# Configure firewall
echo -e "${GREEN}[6/8] Configuring firewall...${NC}"
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

# Set up SSH for deploy user
echo -e "${GREEN}[7/8] Setting up SSH for deploy user...${NC}"
mkdir -p /home/$DEPLOY_USER/.ssh
chmod 700 /home/$DEPLOY_USER/.ssh

echo -e "${YELLOW}Add your SSH public key to /home/$DEPLOY_USER/.ssh/authorized_keys${NC}"
echo -e "${YELLOW}Then run: chmod 600 /home/$DEPLOY_USER/.ssh/authorized_keys${NC}"
echo -e "${YELLOW}And: chown -R $DEPLOY_USER:$DEPLOY_USER /home/$DEPLOY_USER/.ssh${NC}"

# Create application directory
echo -e "${GREEN}[8/8] Creating application directory...${NC}"
su - $DEPLOY_USER -c "mkdir -p $APP_DIR"

echo ""
echo -e "${GREEN}=========================================="
echo "Server setup complete!"
echo "==========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Add your SSH key to /home/$DEPLOY_USER/.ssh/authorized_keys"
echo "  2. Clone your repository to $APP_DIR"
echo "  3. Set up environment variables"
echo "  4. Run the SSL setup script: bash deployment/setup-ssl.sh"
echo "  5. Run the deployment script: bash deployment/deploy.sh"
echo ""
echo "Installed versions:"
python3 --version
node --version
npm --version
nginx -v
