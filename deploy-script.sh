#!/bin/bash

# TikTok Auto Scheduler - AWS EC2 Deployment Script
# Usage: bash deploy-script.sh

set -e

echo "🚀 Starting TikTok Auto Scheduler deployment on AWS EC2..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

print_status "Installing required packages..."
sudo apt install -y nginx git curl wget unzip software-properties-common

print_status "Installing Node.js (for potential future features)..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

print_status "Installing Certbot for SSL certificates..."
sudo apt install -y certbot python3-certbot-nginx

print_status "Starting and enabling Nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx

print_status "Creating web directory..."
sudo mkdir -p /var/www/tiktok-scheduler
sudo chown -R www-data:www-data /var/www/tiktok-scheduler
sudo chmod -R 755 /var/www/tiktok-scheduler

print_status "Backing up default Nginx configuration..."
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup

print_status "Creating Nginx configuration for TikTok Scheduler..."
sudo tee /etc/nginx/sites-available/tiktok-scheduler > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    
    # Replace with your actual domain
    server_name your-domain.com www.your-domain.com;
    
    root /var/www/tiktok-scheduler;
    index index.html index.htm;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' https://fonts.googleapis.com https://fonts.gstatic.com; script-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; img-src 'self' data:;" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Security: deny access to hidden files
    location ~ /\. {
        deny all;
    }
    
    # Custom error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
}
EOF

print_status "Enabling site configuration..."
sudo ln -sf /etc/nginx/sites-available/tiktok-scheduler /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

print_status "Testing Nginx configuration..."
sudo nginx -t

print_status "Reloading Nginx..."
sudo systemctl reload nginx

print_status "Setting up UFW firewall..."
sudo ufw --force enable
sudo ufw allow 'Nginx Full'
sudo ufw allow OpenSSH

print_status "Creating deployment directory..."
mkdir -p ~/tiktok-scheduler-deploy

print_status "Deployment script completed successfully!"
print_warning "Next steps:"
echo "1. Upload your website files to /var/www/tiktok-scheduler/"
echo "2. Update the server_name in /etc/nginx/sites-available/tiktok-scheduler"
echo "3. Configure your domain DNS to point to this server"
echo "4. Run: sudo certbot --nginx -d your-domain.com -d www.your-domain.com"

print_status "Server is ready for your TikTok Scheduler website!"
