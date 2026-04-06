const express = require('express');
const cors = require('cors');
const winston = require('winston');

const app = express();
const PORT = process.env.PORT || 3001;

// Logger setup
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: '/tmp/app.log' })
  ]
});

app.use(cors());
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
  logger.info({
    method: req.method,
    path: req.path,
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  next();
});

// Routes
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  });
});

app.get('/api', (req, res) => {
  res.json({
    message: 'Welcome to Zahir DevOps API',
    endpoints: ['/health', '/api', '/api/info'],
    timestamp: new Date().toISOString()
  });
});

app.get('/api/info', (req, res) => {
  res.json({
    project: 'Zahir DevOps',
    stack: {
      backend: 'Node.js + Express',
      frontend: 'React + Vite',
      containerization: 'Docker + ECS Fargate',
      ci_cd: 'GitHub Actions',
      cloud: 'AWS',
      logging: 'OpenSearch + Kibana'
    },
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });
});

app.listen(PORT, '0.0.0.0', () => {
  logger.info(`Backend API running on port ${PORT}`);
});

module.exports = app;
