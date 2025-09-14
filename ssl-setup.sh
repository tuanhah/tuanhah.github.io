#!/bin/bash

# SSL Setup Script for TikTok Auto Scheduler
# Run this AFTER DNS is properly configured and propagated

echo "🔒 Setting up SSL certificate for TikTok Auto Scheduler..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get domain from user
read -p "Enter your domain name (e.g., tiktokscheduler.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    print_error "Domain name is required!"
    exit 1
fi

print_status "Domain: $DOMAIN"

# Check if DNS is properly configured
print_status "Checking DNS configuration..."
CURRENT_IP=$(curl -s ifconfig.me)
DOMAIN_IP=$(dig +short $DOMAIN | tail -n1)

if [ "$CURRENT_IP" = "$DOMAIN_IP" ]; then
    print_status "✅ DNS is properly configured!"
else
    print_warning "⚠️  DNS may not be fully propagated yet."
    print_warning "Current server IP: $CURRENT_IP"
    print_warning "Domain points to: $DOMAIN_IP"
    
    read -p "Continue anyway? (y/N): " CONTINUE
    if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
        print_error "Please wait for DNS to propagate and try again."
        exit 1
    fi
fi

# Update Nginx configuration with actual domain
print_status "Updating Nginx configuration with domain $DOMAIN..."
sudo sed -i "s/your-domain\.com/$DOMAIN/g" /etc/nginx/sites-available/tiktok-scheduler

# Test Nginx configuration
print_status "Testing Nginx configuration..."
if sudo nginx -t; then
    print_status "✅ Nginx configuration is valid"
    sudo systemctl reload nginx
else
    print_error "❌ Nginx configuration error!"
    exit 1
fi

# Get SSL certificate
print_status "Obtaining SSL certificate from Let's Encrypt..."
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN --redirect

if [ $? -eq 0 ]; then
    print_status "✅ SSL certificate obtained successfully!"
else
    print_error "❌ Failed to obtain SSL certificate"
    print_warning "Common reasons:"
    print_warning "1. DNS not fully propagated"
    print_warning "2. Domain not pointing to this server"
    print_warning "3. Firewall blocking port 80/443"
    exit 1
fi

# Setup auto-renewal
print_status "Setting up auto-renewal for SSL certificate..."
sudo crontab -l | grep -q certbot || (sudo crontab -l; echo "0 12 * * * /usr/bin/certbot renew --quiet") | sudo crontab -

# Test auto-renewal
print_status "Testing SSL auto-renewal..."
sudo certbot renew --dry-run

# Security headers update
print_status "Adding security headers..."
sudo tee /etc/nginx/snippets/security-headers.conf > /dev/null <<EOF
# Security Headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Content-Security-Policy "default-src 'self' https://fonts.googleapis.com https://fonts.gstatic.com; script-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; img-src 'self' data:;" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

# Remove server version
server_tokens off;
EOF

# Update Nginx config to include security headers
sudo sed -i '/server_name/a\\tinclude /etc/nginx/snippets/security-headers.conf;' /etc/nginx/sites-available/tiktok-scheduler

# Test and reload
print_status "Testing final configuration..."
if sudo nginx -t; then
    sudo systemctl reload nginx
    print_status "✅ Security headers added successfully!"
else
    print_error "❌ Configuration error with security headers"
fi

# Final verification
print_status "Performing final verification..."
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" http://$DOMAIN)
HTTPS_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" https://$DOMAIN)

print_status "HTTP Status: $HTTP_STATUS (should redirect to HTTPS)"
print_status "HTTPS Status: $HTTPS_STATUS (should be 200)"

if [ "$HTTPS_STATUS" = "200" ]; then
    print_status "🎉 SSL setup completed successfully!"
    print_status "Your website is now available at:"
    print_status "🌐 https://$DOMAIN"
    print_status "🌐 https://www.$DOMAIN"
    print_status ""
    print_status "SSL Certificate will auto-renew every 90 days"
    print_status "Check SSL rating: https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN"
else
    print_warning "SSL setup completed but there might be issues."
    print_warning "Check the logs: sudo tail -f /var/log/nginx/error.log"
fi

print_status "🔒 SSL setup script completed!"
