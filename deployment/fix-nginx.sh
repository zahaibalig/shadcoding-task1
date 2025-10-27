#!/bin/bash
# Fix Nginx SSL Configuration Error
# Run with: sudo bash /home/deploy/shadcoding-task1/deployment/fix-nginx.sh

set -e

echo "Fixing Nginx configuration..."

APP_DIR="/home/deploy/shadcoding-task1"

# Remove old configuration
rm -f /etc/nginx/sites-enabled/shadcoding
rm -f /etc/nginx/sites-available/shadcoding

# Copy HTTP-only configuration
cp $APP_DIR/deployment/nginx-http.conf /etc/nginx/sites-available/shadcoding

# Create symlink
ln -s /etc/nginx/sites-available/shadcoding /etc/nginx/sites-enabled/shadcoding

# Remove default site if exists
rm -f /etc/nginx/sites-enabled/default

# Test configuration
echo "Testing Nginx configuration..."
nginx -t

# Reload Nginx
echo "Reloading Nginx..."
systemctl reload nginx

echo "Done! Nginx is now using HTTP-only configuration."
echo ""
echo "Test with:"
echo "  curl http://18.217.70.110/api/projects/"
