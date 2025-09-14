#!/bin/bash

# TikTok Auto Scheduler - Full Stack Deployment Script (Frontend + Backend)
# Usage: bash deploy-fullstack.sh

set -e

echo "🚀 Starting TikTok Auto Scheduler Full Stack deployment on AWS EC2..."

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
sudo apt install -y nginx git curl wget unzip software-properties-common build-essential

print_status "Installing Node.js 18.x LTS..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

print_status "Installing PM2 globally..."
sudo npm install -g pm2

print_status "Installing Certbot for SSL certificates..."
sudo apt install -y certbot python3-certbot-nginx

print_status "Starting and enabling Nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx

print_status "Creating web directories..."
sudo mkdir -p /var/www/tiktok-scheduler/frontend
sudo mkdir -p /var/www/tiktok-scheduler/backend
sudo mkdir -p /var/www/tiktok-scheduler/backend/logs
sudo chown -R www-data:www-data /var/www/tiktok-scheduler
sudo chmod -R 755 /var/www/tiktok-scheduler

print_status "Creating Nginx configuration for Full Stack setup..."
sudo tee /etc/nginx/sites-available/tiktok-scheduler > /dev/null <<EOF
# Frontend server block
server {
    listen 80;
    listen [::]:80;
    
    # Replace with your actual domain
    server_name your-domain.com www.your-domain.com;
    
    root /var/www/tiktok-scheduler/frontend;
    index index.html index.htm;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' https://fonts.googleapis.com https://fonts.gstatic.com; script-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; img-src 'self' data:; connect-src 'self' https://your-domain.com;" always;
    
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
    
    # API proxy to backend
    location /api/ {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeouts
        proxy_connect_timeout       60s;
        proxy_send_timeout          60s;
        proxy_read_timeout          60s;
    }
    
    # Frontend static files
    location / {
        try_files \$uri \$uri/ /index.html;
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
    
    # Security: deny access to sensitive files
    location ~* \.(env|log|ini)$ {
        deny all;
    }
    
    # Custom error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
}

# API server block (optional: separate subdomain)
server {
    listen 80;
    listen [::]:80;
    
    server_name api.your-domain.com;
    
    location / {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
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
sudo ufw allow 4000/tcp  # Backend port

print_status "Setting up PM2 startup script..."
sudo pm2 startup systemd -u ubuntu --hp /home/ubuntu

print_status "Creating backend environment file..."
sudo tee /var/www/tiktok-scheduler/backend/.env > /dev/null <<EOF
NODE_ENV=production
PORT=4000
FRONTEND_URL=https://your-domain.com
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
CORS_ORIGIN=https://your-domain.com,https://www.your-domain.com
EOF

print_status "Setting proper permissions..."
sudo chown -R ubuntu:ubuntu /var/www/tiktok-scheduler/backend
sudo chown -R www-data:www-data /var/www/tiktok-scheduler/frontend

print_status "Creating deployment directory..."
mkdir -p ~/tiktok-scheduler-deploy

print_status "Full stack deployment script completed successfully!"
print_warning "Next steps:"
echo "1. Upload your frontend files to /var/www/tiktok-scheduler/frontend/"
echo "2. Upload your backend files to /var/www/tiktok-scheduler/backend/"
echo "3. Update the server_name in /etc/nginx/sites-available/tiktok-scheduler"
echo "4. Install backend dependencies: cd /var/www/tiktok-scheduler/backend && npm install"
echo "5. Build backend: npm run build"
echo "6. Start backend with PM2: pm2 start ecosystem.config.js --env production"
echo "7. Configure your domain DNS to point to this server"
echo "8. Run: sudo certbot --nginx -d your-domain.com -d www.your-domain.com"

print_status "Server is ready for your TikTok Scheduler full stack application!"
