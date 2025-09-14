#!/bin/bash

# Script to upload TikTok Scheduler Full Stack (Frontend + Backend) to EC2
# Usage: bash upload-fullstack.sh <EC2_IP> <PEM_FILE_PATH>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <EC2_IP> <PEM_FILE_PATH>"
    echo "Example: $0 13.123.45.67 ~/Downloads/my-key.pem"
    exit 1
fi

EC2_IP=$1
PEM_FILE=$2

echo "🚀 Uploading TikTok Scheduler Full Stack to EC2..."

# Check if PEM file exists
if [ ! -f "$PEM_FILE" ]; then
    echo "❌ Error: PEM file not found at $PEM_FILE"
    exit 1
fi

# Set correct permissions for PEM file
chmod 400 "$PEM_FILE"

echo "📁 Creating temporary package..."

# Create temporary deployment directory
mkdir -p temp-deploy/frontend
mkdir -p temp-deploy/backend

# Package Frontend files
echo "📦 Packaging frontend files..."
cp index.html temp-deploy/frontend/
cp style.css temp-deploy/frontend/
cp script.js temp-deploy/frontend/
cp privacy-policy.html temp-deploy/frontend/
cp terms-of-service.html temp-deploy/frontend/
cp standalone.html temp-deploy/frontend/

# Create 404 error page for frontend
cat > temp-deploy/frontend/404.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>404 - Page Not Found | TikTok Auto Scheduler</title>
    <style>
        body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #ff0050, #ff4081);
            color: white;
            text-align: center;
            padding: 2rem;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0;
        }
        .container {
            max-width: 500px;
        }
        h1 {
            font-size: 4rem;
            margin-bottom: 1rem;
        }
        h2 {
            font-size: 1.5rem;
            margin-bottom: 2rem;
        }
        .btn {
            display: inline-block;
            padding: 12px 24px;
            background: white;
            color: #ff0050;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            transition: transform 0.3s ease;
        }
        .btn:hover {
            transform: translateY(-2px);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>404</h1>
        <h2>Oops! Page not found</h2>
        <p>The page you're looking for doesn't exist or has been moved.</p>
        <a href="/" class="btn">Go to Homepage</a>
    </div>
</body>
</html>
EOF

# Create 50x error page for frontend
cat > temp-deploy/frontend/50x.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Server Error | TikTok Auto Scheduler</title>
    <style>
        body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #ff4081, #ff0050);
            color: white;
            text-align: center;
            padding: 2rem;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0;
        }
        .container {
            max-width: 500px;
        }
        h1 {
            font-size: 3rem;
            margin-bottom: 1rem;
        }
        h2 {
            font-size: 1.5rem;
            margin-bottom: 2rem;
        }
        .btn {
            display: inline-block;
            padding: 12px 24px;
            background: white;
            color: #ff0050;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            transition: transform 0.3s ease;
        }
        .btn:hover {
            transform: translateY(-2px);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>500</h1>
        <h2>Server Error</h2>
        <p>We're experiencing some technical difficulties. Please try again later.</p>
        <a href="/" class="btn">Go to Homepage</a>
    </div>
</body>
</html>
EOF

# Package Backend files
echo "📦 Packaging backend files..."
cp -r backend/* temp-deploy/backend/

echo "📤 Uploading files to EC2..."
scp -i "$PEM_FILE" -r temp-deploy/* ubuntu@$EC2_IP:~/

echo "🔧 Setting up files on server..."
ssh -i "$PEM_FILE" ubuntu@$EC2_IP << 'ENDSSH'
    echo "📁 Setting up directory structure..."
    sudo mkdir -p /var/www/tiktok-scheduler/frontend
    sudo mkdir -p /var/www/tiktok-scheduler/backend
    sudo mkdir -p /var/www/tiktok-scheduler/backend/logs
    
    echo "📄 Moving frontend files..."
    sudo cp -r ~/frontend/* /var/www/tiktok-scheduler/frontend/
    
    echo "📄 Moving backend files..."
    sudo cp -r ~/backend/* /var/www/tiktok-scheduler/backend/
    
    echo "🔑 Setting correct permissions..."
    sudo chown -R www-data:www-data /var/www/tiktok-scheduler/frontend/
    sudo chown -R ubuntu:ubuntu /var/www/tiktok-scheduler/backend/
    sudo chmod -R 755 /var/www/tiktok-scheduler/frontend/
    sudo chmod -R 755 /var/www/tiktok-scheduler/backend/
    
    echo "📦 Installing backend dependencies..."
    cd /var/www/tiktok-scheduler/backend
    npm install --production
    
    echo "🏗️  Building backend..."
    npm run build
    
    echo "🚀 Starting backend with PM2..."
    pm2 delete tiktok-scheduler-api 2>/dev/null || true
    pm2 start ecosystem.config.js --env production
    pm2 save
    
    echo "✅ PM2 status:"
    pm2 status
    
    echo "🧹 Cleaning up temporary files..."
    rm -rf ~/frontend ~/backend
    
    echo "🔧 Testing Nginx configuration..."
    sudo nginx -t
    
    echo "♻️  Reloading Nginx..."
    sudo systemctl reload nginx
    
    echo "✅ Full stack deployment completed!"
    echo "📊 Backend API status:"
    curl -s http://localhost:4000/api/health | head -n 5 || echo "Backend starting up..."
ENDSSH

echo "🧹 Cleaning up local temporary files..."
rm -rf temp-deploy

echo "✅ Full stack upload completed successfully!"
echo ""
echo "🌐 Your application should now be accessible at:"
echo "   Frontend: http://$EC2_IP"
echo "   Backend API: http://$EC2_IP/api/health"
echo ""
echo "📊 Check backend status:"
echo "   ssh -i \"$PEM_FILE\" ubuntu@$EC2_IP 'pm2 status'"
echo ""
echo "📝 View backend logs:"
echo "   ssh -i \"$PEM_FILE\" ubuntu@$EC2_IP 'pm2 logs tiktok-scheduler-api'"
echo ""
echo "Next steps:"
echo "1. Configure your domain DNS to point to $EC2_IP"
echo "2. Update server_name in Nginx config: sudo nano /etc/nginx/sites-available/tiktok-scheduler"
echo "3. Update backend environment: sudo nano /var/www/tiktok-scheduler/backend/.env"
echo "4. Setup SSL with: sudo certbot --nginx -d your-domain.com -d api.your-domain.com"
echo "5. Test API: curl https://your-domain.com/api/health"
