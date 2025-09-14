#!/bin/bash

# TikTok Auto Scheduler Backend - Development Setup
echo "🚀 Setting up TikTok Auto Scheduler Backend for development..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check Node version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version 18+ is required. Current version: $(node -v)"
    exit 1
fi

echo "✅ Node.js version: $(node -v)"

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Create environment file
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file..."
    cp env.example .env
    echo "✅ Environment file created. Please update .env with your configuration."
else
    echo "⚠️  .env file already exists"
fi

# Create logs directory
mkdir -p logs
echo "✅ Logs directory created"

# Type check
echo "🔍 Running type check..."
npm run type-check

echo ""
echo "🎉 Development setup completed!"
echo ""
echo "📋 Available commands:"
echo "  npm run dev        - Start development server"
echo "  npm run build      - Build for production"  
echo "  npm run start      - Start production server"
echo "  npm run type-check - Check TypeScript types"
echo "  npm run lint       - Run ESLint"
echo ""
echo "🚀 To start development:"
echo "  npm run dev"
echo ""
echo "📡 API will be available at: http://localhost:4000"
echo "🔍 Health check: http://localhost:4000/api/health"
