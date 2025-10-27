#!/bin/bash
# Simple Gunicorn Installation Script
# Run from anywhere: sudo bash /home/deploy/shadcoding-task1/deployment/SIMPLE_INSTALL.sh

set -e

echo "==========================================="
echo "Simple Gunicorn Installation"
echo "==========================================="
echo ""

# Fixed paths
APP_DIR="/home/deploy/shadcoding-task1"
VENV_DIR="$APP_DIR/venv"
BACKEND_DIR="$APP_DIR/backend"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Run with sudo"
    echo "Usage: sudo bash /home/deploy/shadcoding-task1/deployment/SIMPLE_INSTALL.sh"
    exit 1
fi

# Step 1: Fix permissions so ubuntu can access deploy directory
echo "[1/8] Fixing permissions..."
chmod 755 /home/deploy
chmod 755 $APP_DIR
chown -R deploy:deploy $APP_DIR
echo "  Done"

# Step 2: Create virtual environment
echo ""
echo "[2/8] Creating virtual environment..."
if [ -d "$VENV_DIR" ]; then
    echo "  Already exists"
else
    su - deploy -c "cd $APP_DIR && python3 -m venv venv"
    echo "  Created"
fi

# Step 3: Install Python dependencies
echo ""
echo "[3/8] Installing dependencies..."
su - deploy -c "cd $APP_DIR && source venv/bin/activate && pip install --upgrade pip --quiet"
su - deploy -c "cd $APP_DIR && source venv/bin/activate && pip install -r requirements.txt --quiet"
echo "  Installed"

# Step 4: Run migrations
echo ""
echo "[4/8] Running database migrations..."
su - deploy -c "cd $BACKEND_DIR && source $VENV_DIR/bin/activate && python manage.py migrate --noinput"
echo "  Done"

# Step 5: Collect static files
echo ""
echo "[5/8] Collecting static files..."
su - deploy -c "cd $BACKEND_DIR && source $VENV_DIR/bin/activate && python manage.py collectstatic --noinput"
echo "  Done"

# Step 6: Create directories
echo ""
echo "[6/8] Creating directories..."
mkdir -p /var/log/gunicorn
mkdir -p /var/www/shadcoding/frontend
chown -R deploy:www-data /var/log/gunicorn
chown -R www-data:www-data /var/www/shadcoding
echo "  Done"

# Step 7: Install Gunicorn service
echo ""
echo "[7/8] Installing Gunicorn service..."
cp $APP_DIR/deployment/gunicorn.service /etc/systemd/system/gunicorn.service
systemctl daemon-reload
systemctl enable gunicorn
systemctl start gunicorn
sleep 2
echo "  Done"

# Step 8: Configure Nginx
echo ""
echo "[8/8] Configuring Nginx..."
if [ ! -f /etc/nginx/sites-available/shadcoding ]; then
    cp $APP_DIR/deployment/nginx.conf /etc/nginx/sites-available/shadcoding
fi
ln -sf /etc/nginx/sites-available/shadcoding /etc/nginx/sites-enabled/shadcoding
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
echo "  Done"

# Summary
echo ""
echo "==========================================="
echo "Installation Complete!"
echo "==========================================="
echo ""
echo "Services:"
echo "  Gunicorn: $(systemctl is-active gunicorn)"
echo "  Nginx: $(systemctl is-active nginx)"
echo ""
echo "Test your site:"
echo "  curl http://127.0.0.1:8000/api/projects/"
echo "  curl http://18.223.101.101/api/projects/"
echo ""
echo "Next: Deploy your .env file"
echo "See: /home/deploy/shadcoding-task1/deployment/.env.production"
echo ""
