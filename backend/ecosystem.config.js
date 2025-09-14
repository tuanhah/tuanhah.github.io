module.exports = {
  apps: [
    {
      name: 'tiktok-scheduler-api',
      script: 'dist/index.js',
      cwd: '/var/www/tiktok-scheduler/backend',
      instances: 'max',
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'development',
        PORT: 4000
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 4000
      },
      // Logging
      log_file: './logs/combined.log',
      out_file: './logs/out.log',
      error_file: './logs/error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      
      // Process management
      min_uptime: '10s',
      max_restarts: 10,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      
      // Graceful shutdown
      kill_timeout: 5000,
      listen_timeout: 3000,
      
      // Health monitoring
      health_check_http: {
        url: 'http://localhost:4000/api/health',
        max_redirects: 3,
        timeout: 5000
      },
      
      // Advanced settings
      node_args: '--max-old-space-size=1024',
      merge_logs: true,
      time: true,
      
      // Environment variables from file
      env_file: '.env'
    }
  ],
  
  deploy: {
    production: {
      user: 'ubuntu',
      host: ['your-server-ip'],
      ref: 'origin/main',
      repo: 'git@github.com:yourusername/tiktok-scheduler.git',
      path: '/var/www/tiktok-scheduler',
      'pre-deploy-local': '',
      'post-deploy': 'cd backend && npm install && npm run build && pm2 reload ecosystem.config.js --env production && pm2 save',
      'pre-setup': '',
      'ssh_options': 'ForwardAgent=yes'
    }
  }
};
