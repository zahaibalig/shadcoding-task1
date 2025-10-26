#!/bin/bash

# SSL Setup Script using Let's Encrypt
# Run this after server setup and nginx configuration
# Usage: sudo bash setup-ssl.sh

set -e

echo "=========================================="
echo "Let's Encrypt SSL Setup"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get domain from user
read -p "Enter your domain name (e.g., example.com): " DOMAIN
read -p "Enter your email for SSL notifications: " EMAIL

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo -e "${RED}Domain and email are required!${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Setting up SSL for: $DOMAIN${NC}"
echo -e "${YELLOW}Notification email: $EMAIL${NC}"
echo ""

# Check if domain points to this server
SERVER_IP=$(curl -s ifconfig.me)
DOMAIN_IP=$(dig +short $DOMAIN | tail -n1)

echo "Server IP: $SERVER_IP"
echo "Domain IP: $DOMAIN_IP"

if [ "$SERVER_IP" != "$DOMAIN_IP" ]; then
    echo -e "${RED}WARNING: Domain does not point to this server!${NC}"
    echo "Please update your DNS A record to point to $SERVER_IP"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Stop nginx temporarily
echo -e "${GREEN}Stopping Nginx...${NC}"
systemctl stop nginx

# Obtain certificate
echo -e "${GREEN}Obtaining SSL certificate from Let's Encrypt...${NC}"
certbot certonly \
    --standalone \
    --preferred-challenges http \
    --agree-tos \
    --no-eff-email \
    --email $EMAIL \
    -d $DOMAIN \
    -d www.$DOMAIN

# Update nginx configuration with actual domain
echo -e "${GREEN}Updating Nginx configuration...${NC}"
sed -i "s/YOUR_DOMAIN/$DOMAIN/g" /etc/nginx/sites-available/shadcoding

# Test nginx configuration
echo -e "${GREEN}Testing Nginx configuration...${NC}"
nginx -t

# Start nginx
echo -e "${GREEN}Starting Nginx...${NC}"
systemctl start nginx

# Set up auto-renewal
echo -e "${GREEN}Setting up SSL auto-renewal...${NC}"
systemctl enable certbot.timer
systemctl start certbot.timer

# Test auto-renewal
certbot renew --dry-run

echo ""
echo -e "${GREEN}=========================================="
echo "SSL Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "Certificate details:"
echo "  Domain: $DOMAIN, www.$DOMAIN"
echo "  Certificate: /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
echo "  Private Key: /etc/letsencrypt/live/$DOMAIN/privkey.pem"
echo ""
echo "Your site should now be accessible at:"
echo "  https://$DOMAIN"
echo "  https://www.$DOMAIN"
echo ""
echo "SSL certificates will auto-renew via systemd timer"
echo "Check status: systemctl status certbot.timer"
