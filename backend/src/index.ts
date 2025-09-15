import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import rateLimit from 'express-rate-limit';

dotenv.config();

const app = express();
const port = process.env.PORT || 4000;

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      imgSrc: ["'self'", "data:", "https:"],
      scriptSrc: ["'self'"],
    },
  },
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});

app.use(limiter);

// Compression middleware
app.use(compression());

// CORS configuration
const corsOptions = {
  origin: process.env.FRONTEND_URL || ['http://localhost:3000', 'https://your-domain.com'],
  credentials: true,
  optionsSuccessStatus: 200,
};

app.use(cors(corsOptions));

// Body parsing middlewares
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Request logging
if (process.env.NODE_ENV !== 'production') {
  app.use(morgan('dev'));
}

// Custom request logger
app.use((req: Request, _res: Response, next: NextFunction) => {
  const { method, originalUrl, params, query, headers } = req;
  
  if (process.env.NODE_ENV === 'development') {
    console.log('--- Incoming Request ----------------------------------');
    console.log('Time:', new Date().toISOString());
    console.log('Method:', method);
    console.log('URL:', originalUrl);
    console.log('User-Agent:', headers['user-agent']);
    console.log('Params:', params);
    console.log('Query:', query);
  }
  
  next();
});

// API Routes
app.get('/api/health', (_req: Request, res: Response) => {
  res.json({ 
    ok: true, 
    time: new Date().toISOString(),
    service: 'TikTok Auto Scheduler API',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  });
});

// TikTok callback endpoint
app.post('/api/callback', (req: Request, res: Response) => {
  console.log('--- /api/callback payload --------------------------------');
  console.log('Body:', req.body);
  console.log('Headers:', req.headers);
  console.log('-------------------------------------------------------');

  // Here you would process TikTok webhook data
  // Example: update video status, handle upload completion, etc.
  
  res.status(200).json({ 
    received: true,
    timestamp: new Date().toISOString(),
    message: 'Callback processed successfully'
  });
});

// Video scheduling endpoint
app.post('/api/schedule', (req: Request, res: Response) => {
  console.log('--- Schedule video request ----------------------------');
  console.log('Body:', req.body);
  
  // TODO: Implement video scheduling logic
  // - Validate request data
  // - Store schedule in database
  // - Set up cron job or queue job
  
  res.status(200).json({
    success: true,
    message: 'Video scheduled successfully',
    scheduleId: `schedule_${Date.now()}`,
    scheduledTime: req.body.scheduledTime || new Date().toISOString()
  });
});

// Get scheduled videos
app.get('/api/schedules', (_req: Request, res: Response) => {
  // TODO: Implement get schedules logic
  res.status(200).json({
    schedules: [],
    total: 0,
    page: 1,
    limit: 10
  });
});

// Analytics endpoint
app.get('/api/analytics', (_req: Request, res: Response) => {
  // TODO: Implement analytics logic
  res.status(200).json({
    totalScheduled: 0,
    totalPosted: 0,
    successRate: 0,
    lastWeekStats: {
      scheduled: 0,
      posted: 0,
      failed: 0
    }
  });
});

// Error handling middleware
// @ts-ignore
app.use((err: Error, req: Request, res: Response, _next: NextFunction) => {
  console.error('Error:', err.message);
  console.error('Stack:', err.stack);
  
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong',
    timestamp: new Date().toISOString()
  });
});

// Catch-all 404
app.use((req: Request, res: Response) => {
  res.status(404).json({ 
    error: 'Not Found', 
    path: req.originalUrl,
    timestamp: new Date().toISOString()
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  process.exit(0);
});

app.listen(port, () => {
  console.log(`🚀 [TikTok Scheduler API]: Server listening on http://localhost:${port}`);
  console.log(`📝 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔍 Health check: http://localhost:${port}/api/health`);
});
