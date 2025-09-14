# 🚀 TikTok Auto Scheduler - Full Stack Deployment Guide

## 📋 **Architecture Overview**

```
┌─────────────────────────────────────────────┐
│                AWS EC2                      │
├─────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────────────┐ │
│  │    Nginx    │    │       PM2           │ │
│  │  (Port 80)  │────│ (Backend: Port 4000)│ │
│  │  (Port 443) │    │                     │ │
│  └─────────────┘    └─────────────────────┘ │
│           │                    │            │
│  ┌─────────────┐    ┌─────────────────────┐ │
│  │  Frontend   │    │     Backend API     │ │
│  │   Static    │    │   Express.js +      │ │
│  │   Files     │    │   TypeScript        │ │
│  └─────────────┘    └─────────────────────┘ │
└─────────────────────────────────────────────┘
```

## 🛠 **Backend Structure**

### **📁 Directory Structure**
```
backend/
├── src/
│   └── index.ts          # Main server file
├── dist/                 # Compiled JavaScript
├── logs/                 # PM2 logs
├── package.json          # Dependencies & scripts
├── tsconfig.json         # TypeScript config
├── ecosystem.config.js   # PM2 configuration
├── nodemon.json          # Development config
└── env.example           # Environment variables template
```

### **🔧 Key Features**
- ✅ **Express.js + TypeScript**
- ✅ **Security middleware** (Helmet, CORS, Rate limiting)
- ✅ **PM2 cluster mode** for production
- ✅ **Comprehensive logging**
- ✅ **Health check endpoint**
- ✅ **Environment-based configuration**
- ✅ **Graceful shutdown handling**

### **📡 API Endpoints**
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| POST | `/api/callback` | TikTok webhook |
| POST | `/api/schedule` | Schedule video |
| GET | `/api/schedules` | Get scheduled videos |
| GET | `/api/analytics` | Get analytics data |

## 🚀 **Step-by-Step Deployment**

### **1. Prepare Backend Code**
```bash
# Navigate to project root
cd /path/to/your/project

# The backend files are already created:
# - backend/package.json
# - backend/src/index.ts
# - backend/tsconfig.json
# - backend/ecosystem.config.js
```

### **2. Deploy Infrastructure**
```bash
# On your EC2 instance
ssh -i "your-key.pem" ubuntu@YOUR_EC2_IP

# Run full stack deployment script
bash deploy-fullstack.sh
```

### **3. Upload Application Files**
```bash
# From your local machine
bash upload-fullstack.sh YOUR_EC2_IP YOUR_PEM_FILE_PATH
```

### **4. Configure Environment**
```bash
# On EC2 server
sudo nano /var/www/tiktok-scheduler/backend/.env

# Add your configuration:
NODE_ENV=production
PORT=4000
FRONTEND_URL=https://your-domain.com
# ... other environment variables
```

### **5. Update Domain Configuration**
```bash
# Update Nginx config
sudo nano /etc/nginx/sites-available/tiktok-scheduler

# Replace 'your-domain.com' with your actual domain
# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

### **6. Configure DNS (GoDaddy)**
- A record: `@` → `YOUR_EC2_IP`
- A record: `www` → `YOUR_EC2_IP`
- A record: `api` → `YOUR_EC2_IP` (optional subdomain)

### **7. Setup SSL**
```bash
# After DNS propagation
sudo certbot --nginx -d your-domain.com -d www.your-domain.com -d api.your-domain.com
```

## 🔄 **PM2 Management**

### **Available Commands**
```bash
# Use the management script
bash pm2-management.sh [command]

# Available commands:
start      # Start the application
stop       # Stop the application  
restart    # Restart the application
reload     # Zero-downtime reload
status     # Show status
logs       # View live logs
monit      # PM2 monitoring interface
health     # Health check
update     # Update and restart
```

### **Common PM2 Operations**
```bash
# Check application status
pm2 status

# View logs
pm2 logs tiktok-scheduler-api

# Monitor resources
pm2 monit

# Restart with zero downtime
pm2 reload tiktok-scheduler-api

# Save PM2 configuration
pm2 save

# Auto-start on server reboot
pm2 startup
```

## 🔍 **Monitoring & Debugging**

### **Health Checks**
```bash
# API health check
curl https://your-domain.com/api/health

# PM2 status
pm2 status

# System resources
htop
df -h
free -h
```

### **Log Locations**
```bash
# PM2 logs
/var/www/tiktok-scheduler/backend/logs/

# Nginx logs  
/var/log/nginx/access.log
/var/log/nginx/error.log

# System logs
journalctl -u nginx
journalctl -f
```

### **Common Issues & Solutions**

#### **Backend not starting**
```bash
# Check logs
pm2 logs tiktok-scheduler-api

# Check dependencies
cd /var/www/tiktok-scheduler/backend
npm install

# Check TypeScript compilation
npm run build
```

#### **API not accessible**
```bash
# Check if backend is running
curl http://localhost:4000/api/health

# Check Nginx proxy configuration
sudo nginx -t

# Check firewall
sudo ufw status
```

#### **SSL issues**
```bash
# Check certificate status
sudo certbot certificates

# Renew certificates
sudo certbot renew --dry-run
```

## 📊 **Performance Optimization**

### **Backend Optimizations**
- ✅ **Cluster mode** with PM2
- ✅ **Gzip compression**
- ✅ **Security headers**
- ✅ **Rate limiting**
- ✅ **Request logging**

### **Frontend Optimizations**
- ✅ **Static file caching**
- ✅ **Gzip compression**
- ✅ **CDN-ready setup**
- ✅ **Minified assets**

### **Server Optimizations**
- ✅ **Nginx reverse proxy**
- ✅ **SSL/TLS termination**
- ✅ **Load balancing ready**
- ✅ **Monitoring setup**

## 🔐 **Security Features**

### **Backend Security**
- ✅ **Helmet.js** - Security headers
- ✅ **CORS** - Cross-origin protection
- ✅ **Rate limiting** - DDoS protection
- ✅ **Input validation** - Data sanitization
- ✅ **Environment isolation**

### **Infrastructure Security**
- ✅ **UFW Firewall**
- ✅ **SSL/TLS encryption**
- ✅ **Fail2ban** (optional)
- ✅ **Security headers**
- ✅ **Hidden server version**

## 📈 **Scaling Considerations**

### **Horizontal Scaling**
```bash
# Add more EC2 instances
# Use Application Load Balancer
# Configure PM2 cluster mode
PM2_INSTANCES=max pm2 start ecosystem.config.js
```

### **Database Integration**
```bash
# Add to backend/.env
DATABASE_URL=postgresql://user:pass@host:5432/db
REDIS_URL=redis://host:6379
```

### **External Services**
```bash
# S3 for file storage
AWS_S3_BUCKET=your-bucket
AWS_REGION=us-west-2

# CloudWatch for logging
# CloudFront for CDN
```

## 🧪 **Testing Checklist**

### **Backend Tests**
- [ ] `/api/health` returns 200
- [ ] `/api/callback` accepts POST data
- [ ] Rate limiting works
- [ ] CORS headers present
- [ ] Error handling works

### **Integration Tests**
- [ ] Frontend can call backend API
- [ ] SSL certificate valid
- [ ] Domain redirects work
- [ ] Mobile responsive
- [ ] Performance acceptable

### **Production Tests**
- [ ] PM2 auto-restart works
- [ ] Logs are being written
- [ ] Monitoring is active
- [ ] Backups are working
- [ ] Security headers present

---

## 🎯 **Final Checklist**

- [ ] ✅ Backend API running on PM2
- [ ] ✅ Frontend serving static files
- [ ] ✅ Nginx proxy configuration
- [ ] ✅ SSL certificates installed
- [ ] ✅ Domain DNS configured
- [ ] ✅ Environment variables set
- [ ] ✅ Monitoring and logging active
- [ ] ✅ Security features enabled
- [ ] ✅ Performance optimized
- [ ] ✅ Error handling tested

**🎉 Your TikTok Auto Scheduler full stack application is now ready for production!**
