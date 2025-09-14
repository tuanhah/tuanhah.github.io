#!/bin/bash

# PM2 Management Script for TikTok Auto Scheduler
# Usage: bash pm2-management.sh [command]

APP_NAME="tiktok-scheduler-api"
BACKEND_DIR="/var/www/tiktok-scheduler/backend"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}[PM2]${NC} $1"
}

show_help() {
    echo "🚀 TikTok Auto Scheduler - PM2 Management"
    echo ""
    echo "Usage: bash pm2-management.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start      - Start the application"
    echo "  stop       - Stop the application"
    echo "  restart    - Restart the application"
    echo "  reload     - Reload the application (zero-downtime)"
    echo "  delete     - Delete the application from PM2"
    echo "  status     - Show application status"
    echo "  logs       - Show application logs (live)"
    echo "  monit      - Open PM2 monitoring interface"
    echo "  save       - Save current PM2 configuration"
    echo "  resurrect  - Restore saved PM2 configuration"
    echo "  update     - Update and restart application"
    echo "  health     - Check application health"
    echo "  help       - Show this help message"
}

check_backend_dir() {
    if [ ! -d "$BACKEND_DIR" ]; then
        print_error "Backend directory not found: $BACKEND_DIR"
        exit 1
    fi
}

start_app() {
    print_header "Starting TikTok Scheduler API..."
    check_backend_dir
    cd "$BACKEND_DIR"
    
    if pm2 describe "$APP_NAME" > /dev/null 2>&1; then
        print_warning "Application already exists. Use 'restart' or 'reload' instead."
        pm2 restart "$APP_NAME"
    else
        pm2 start ecosystem.config.js --env production
        pm2 save
    fi
    
    print_status "Application started successfully!"
    pm2 status
}

stop_app() {
    print_header "Stopping TikTok Scheduler API..."
    pm2 stop "$APP_NAME"
    print_status "Application stopped!"
}

restart_app() {
    print_header "Restarting TikTok Scheduler API..."
    pm2 restart "$APP_NAME"
    print_status "Application restarted!"
}

reload_app() {
    print_header "Reloading TikTok Scheduler API (zero-downtime)..."
    pm2 reload "$APP_NAME"
    print_status "Application reloaded!"
}

delete_app() {
    print_header "Deleting TikTok Scheduler API from PM2..."
    pm2 delete "$APP_NAME"
    pm2 save
    print_status "Application deleted from PM2!"
}

show_status() {
    print_header "PM2 Status:"
    pm2 status
    echo ""
    print_header "Application Info:"
    pm2 describe "$APP_NAME"
}

show_logs() {
    print_header "Showing live logs for TikTok Scheduler API..."
    print_warning "Press Ctrl+C to exit logs"
    pm2 logs "$APP_NAME" --lines 50
}

show_monit() {
    print_header "Opening PM2 monitoring interface..."
    print_warning "Press Ctrl+C to exit monitoring"
    pm2 monit
}

save_config() {
    print_header "Saving PM2 configuration..."
    pm2 save
    print_status "PM2 configuration saved!"
}

resurrect_config() {
    print_header "Restoring PM2 configuration..."
    pm2 resurrect
    print_status "PM2 configuration restored!"
}

update_app() {
    print_header "Updating TikTok Scheduler API..."
    check_backend_dir
    cd "$BACKEND_DIR"
    
    print_status "Installing dependencies..."
    npm install --production
    
    print_status "Building application..."
    npm run build
    
    print_status "Reloading application..."
    pm2 reload "$APP_NAME"
    
    print_status "Update completed!"
    pm2 status
}

check_health() {
    print_header "Checking application health..."
    
    # Check if PM2 process is running
    if pm2 describe "$APP_NAME" > /dev/null 2>&1; then
        print_status "✅ PM2 process is running"
        
        # Check API health endpoint
        print_status "Checking API health endpoint..."
        if curl -f -s http://localhost:4000/api/health > /dev/null; then
            print_status "✅ API health endpoint is responding"
            echo ""
            echo "📊 API Response:"
            curl -s http://localhost:4000/api/health | head -n 10
        else
            print_error "❌ API health endpoint is not responding"
        fi
    else
        print_error "❌ PM2 process is not running"
    fi
    
    echo ""
    print_header "PM2 Status:"
    pm2 status
    
    echo ""
    print_header "System Resources:"
    echo "CPU Usage:"
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}'
    
    echo ""
    echo "Memory Usage:"
    free -h | grep Mem
    
    echo ""
    echo "Disk Usage:"
    df -h / | tail -1
}

# Main script logic
case "${1:-help}" in
    start)
        start_app
        ;;
    stop)
        stop_app
        ;;
    restart)
        restart_app
        ;;
    reload)
        reload_app
        ;;
    delete)
        delete_app
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    monit)
        show_monit
        ;;
    save)
        save_config
        ;;
    resurrect)
        resurrect_config
        ;;
    update)
        update_app
        ;;
    health)
        check_health
        ;;
    help|*)
        show_help
        ;;
esac
