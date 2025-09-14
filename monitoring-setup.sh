#!/bin/bash

# Monitoring and Optimization Setup for TikTok Auto Scheduler
echo "📊 Setting up monitoring and optimization..."

# Install monitoring tools
sudo apt update
sudo apt install -y htop iotop netstat-nat fail2ban

# Setup fail2ban for security
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Create monitoring script
sudo tee /usr/local/bin/server-status.sh > /dev/null <<'EOF'
#!/bin/bash

echo "🖥️  TikTok Auto Scheduler - Server Status Report"
echo "================================================"
echo ""

echo "📅 Date: $(date)"
echo "⏰ Uptime: $(uptime -p)"
echo ""

echo "💾 Memory Usage:"
free -h
echo ""

echo "💿 Disk Usage:"
df -h /
echo ""

echo "🌐 Nginx Status:"
sudo systemctl status nginx --no-pager -l
echo ""

echo "🔒 SSL Certificate Status:"
sudo certbot certificates
echo ""

echo "🔍 Recent Nginx Access (last 10):"
sudo tail -10 /var/log/nginx/access.log
echo ""

echo "❌ Recent Nginx Errors (if any):"
sudo tail -5 /var/log/nginx/error.log
echo ""

echo "🔥 Top Processes:"
ps aux --sort=-%cpu | head -10
EOF

chmod +x /usr/local/bin/server-status.sh

# Create daily backup script
sudo tee /usr/local/bin/backup-website.sh > /dev/null <<'EOF'
#!/bin/bash

BACKUP_DIR="/home/ubuntu/backups"
DATE=$(date +%Y%m%d_%H%M%S)
WEBSITE_DIR="/var/www/tiktok-scheduler"

mkdir -p $BACKUP_DIR

# Backup website files
tar -czf $BACKUP_DIR/website_backup_$DATE.tar.gz -C /var/www tiktok-scheduler

# Backup Nginx config
tar -czf $BACKUP_DIR/nginx_config_$DATE.tar.gz /etc/nginx/sites-available/tiktok-scheduler

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /usr/local/bin/backup-website.sh

# Add cron jobs
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/backup-website.sh >> /home/ubuntu/backup.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "0 */6 * * * /usr/local/bin/server-status.sh >> /home/ubuntu/status.log 2>&1") | crontab -

# Create performance optimization
sudo tee -a /etc/nginx/nginx.conf > /dev/null <<'EOF'

# Performance Optimizations
worker_processes auto;
worker_connections 1024;
keepalive_timeout 65;
keepalive_requests 100;

# Enable gzip compression
gzip on;
gzip_vary on;
gzip_comp_level 6;
gzip_min_length 1000;
gzip_types
    text/plain
    text/css
    application/json
    application/javascript
    text/xml
    application/xml
    application/xml+rss
    text/javascript;
EOF

echo "✅ Monitoring and optimization setup completed!"
echo ""
echo "📋 Available commands:"
echo "• server-status.sh - Check server status"
echo "• backup-website.sh - Manual backup"
echo "• sudo fail2ban-client status - Security status"
echo ""
echo "📊 Logs locations:"
echo "• Access: /var/log/nginx/access.log"
echo "• Errors: /var/log/nginx/error.log" 
echo "• Backup: ~/backup.log"
echo "• Status: ~/status.log"
