#!/bin/bash

# Project Relocation Script
# Safely moves project from /home/ubuntu/shadcoding-task1 to /home/deploy/shadcoding-task1
# Run this script with sudo as the ubuntu user

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SOURCE_DIR="/home/ubuntu/shadcoding-task1"
DEST_DIR="/home/deploy/shadcoding-task1"
DEPLOY_USER="deploy"
BACKUP_DIR="/home/ubuntu/shadcoding-task1.backup.$(date +%Y%m%d_%H%M%S)"

echo -e "${BLUE}=========================================="
echo "Project Relocation Script"
echo "==========================================${NC}"
echo ""
echo "This script will move your project from:"
echo "  ${YELLOW}$SOURCE_DIR${NC}"
echo "to:"
echo "  ${GREEN}$DEST_DIR${NC}"
echo ""

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run with sudo${NC}"
    echo "Usage: sudo bash deployment/relocate-project.sh"
    exit 1
fi

# Step 1: Verify source directory exists
echo -e "${GREEN}[1/8] Checking source directory...${NC}"
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Error: Source directory does not exist: $SOURCE_DIR${NC}"
    exit 1
fi
echo "  Source directory exists: $SOURCE_DIR"

# Step 2: Check if destination already exists
echo ""
echo -e "${GREEN}[2/8] Checking destination directory...${NC}"
if [ -d "$DEST_DIR" ]; then
    echo -e "${YELLOW}Warning: Destination directory already exists: $DEST_DIR${NC}"
    read -p "Do you want to remove it and continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$DEST_DIR"
        echo "  Existing destination removed"
    else
        echo "Relocation cancelled"
        exit 0
    fi
else
    echo "  Destination directory does not exist (will be created)"
fi

# Step 3: Check if deploy user exists
echo ""
echo -e "${GREEN}[3/8] Checking deploy user...${NC}"
if id "$DEPLOY_USER" &>/dev/null; then
    echo "  Deploy user exists"
else
    echo "  Deploy user does not exist. Creating..."
    useradd -m -s /bin/bash $DEPLOY_USER
    usermod -aG www-data $DEPLOY_USER
    echo "  Deploy user created"
fi

# Step 4: Create backup
echo ""
echo -e "${GREEN}[4/8] Creating backup...${NC}"
echo "  Backup location: $BACKUP_DIR"
read -p "Do you want to create a backup before moving? (recommended) (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cp -a "$SOURCE_DIR" "$BACKUP_DIR"
    echo -e "  ${GREEN}Backup created successfully${NC}"
    echo "  You can remove it later with: sudo rm -rf $BACKUP_DIR"
else
    echo "  Skipping backup (not recommended)"
fi

# Step 5: Ensure deploy user home directory exists
echo ""
echo -e "${GREEN}[5/8] Preparing deploy user home directory...${NC}"
if [ ! -d "/home/$DEPLOY_USER" ]; then
    mkdir -p "/home/$DEPLOY_USER"
    chown $DEPLOY_USER:$DEPLOY_USER "/home/$DEPLOY_USER"
    echo "  Deploy user home directory created"
else
    echo "  Deploy user home directory already exists"
fi

# Step 6: Move the project
echo ""
echo -e "${GREEN}[6/8] Moving project...${NC}"
echo "  This may take a moment..."

# Use rsync if available for better progress, otherwise use cp
if command -v rsync &> /dev/null; then
    rsync -a --info=progress2 "$SOURCE_DIR/" "$DEST_DIR/"
    echo "  Project copied with rsync"
else
    cp -a "$SOURCE_DIR" "$DEST_DIR"
    echo "  Project copied with cp"
fi

# Verify the move
if [ -d "$DEST_DIR" ]; then
    echo -e "  ${GREEN}Project successfully copied to $DEST_DIR${NC}"
else
    echo -e "${RED}  Error: Failed to copy project${NC}"
    exit 1
fi

# Step 7: Set ownership
echo ""
echo -e "${GREEN}[7/8] Setting ownership and permissions...${NC}"
chown -R $DEPLOY_USER:$DEPLOY_USER "$DEST_DIR"
echo "  Ownership set to $DEPLOY_USER:$DEPLOY_USER"

# Set proper permissions for .env if it exists
if [ -f "$DEST_DIR/backend/.env" ]; then
    chmod 600 "$DEST_DIR/backend/.env"
    echo "  .env file permissions set to 600"
fi

# Step 8: Verify and clean up
echo ""
echo -e "${GREEN}[8/8] Verifying relocation...${NC}"

# Check key directories
if [ -d "$DEST_DIR/backend" ] && [ -d "$DEST_DIR/frontend" ] && [ -d "$DEST_DIR/deployment" ]; then
    echo -e "  ${GREEN}✓ All key directories present${NC}"
else
    echo -e "  ${RED}✗ Some directories missing${NC}"
    exit 1
fi

# Check Git repository
if [ -d "$DEST_DIR/.git" ]; then
    echo -e "  ${GREEN}✓ Git repository preserved${NC}"
else
    echo -e "  ${YELLOW}⚠ Git repository not found (this may be normal if not using git)${NC}"
fi

# Show disk usage
DEST_SIZE=$(du -sh "$DEST_DIR" 2>/dev/null | cut -f1)
echo "  Project size: $DEST_SIZE"

# Ask about removing original
echo ""
echo -e "${YELLOW}Original directory still exists at: $SOURCE_DIR${NC}"
read -p "Do you want to remove the original directory? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$SOURCE_DIR"
    echo -e "  ${GREEN}Original directory removed${NC}"
else
    echo "  Original directory kept at: $SOURCE_DIR"
    echo "  You can remove it manually later with: sudo rm -rf $SOURCE_DIR"
fi

# Final summary
echo ""
echo -e "${BLUE}=========================================="
echo "Relocation Complete!"
echo "==========================================${NC}"
echo ""
echo -e "${GREEN}Summary:${NC}"
echo "  Source:      $SOURCE_DIR ($([ -d "$SOURCE_DIR" ] && echo "still exists" || echo "removed"))"
echo "  Destination: $DEST_DIR (✓ exists)"
echo "  Owner:       $DEPLOY_USER:$DEPLOY_USER"
echo "  Size:        $DEST_SIZE"
if [ -d "$BACKUP_DIR" ]; then
    echo "  Backup:      $BACKUP_DIR (✓ exists)"
fi
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "  1. Verify project at new location:"
echo "     sudo ls -lh $DEST_DIR"
echo ""
echo "  2. Run the Gunicorn installation script:"
echo "     cd $DEST_DIR"
echo "     sudo bash deployment/install-gunicorn-service.sh"
echo ""
echo "  3. If everything works, remove backup (optional):"
if [ -d "$BACKUP_DIR" ]; then
    echo "     sudo rm -rf $BACKUP_DIR"
fi
echo ""
echo -e "${BLUE}==========================================${NC}"
