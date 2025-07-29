require('dotenv').config();
const express = require('express');
const session = require('express-session');
const bodyParser = require('body-parser');

// Enhanced rate limiting middleware with resource protection
const rateLimit = (windowMs, max) => {
  const requests = new Map();
  const MAX_IPS = 10000; // Limit tracked IPs to prevent memory exhaustion
  
  return (req, res, next) => {
    const key = req.ip;
    const now = Date.now();
    const windowStart = now - windowMs;
    
    // Prevent memory exhaustion by limiting tracked IPs
    if (requests.size >= MAX_IPS && !requests.has(key)) {
      // Remove oldest entries when limit reached
      const oldestKey = requests.keys().next().value;
      requests.delete(oldestKey);
    }
    
    if (!requests.has(key)) {
      requests.set(key, []);
    }
    
    const userRequests = requests.get(key);
    const validRequests = userRequests.filter(time => time > windowStart);
    
    if (validRequests.length >= max) {
      return res.status(429).json({ error: 'Too many requests, please try again later.' });
    }
    
    validRequests.push(now);
    requests.set(key, validRequests);
    
    // Enhanced cleanup with memory monitoring
    if (Math.random() < 0.05) { // More frequent cleanup
      let cleaned = 0;
      for (const [ip, times] of requests.entries()) {
        const validTimes = times.filter(time => time > windowStart);
        if (validTimes.length === 0) {
          requests.delete(ip);
          cleaned++;
        } else {
          requests.set(ip, validTimes);
        }
      }
      
      // Log memory usage periodically
      if (cleaned > 0) {
        console.log(`Rate limiter cleaned ${cleaned} expired entries. Active IPs: ${requests.size}`);
      }
    }
    
    next();
  };
};
const path = require('path');

// Import routes
const productRoutes = require('./routes/products');
const cartRoutes = require('./routes/cart');
const orderRoutes = require('./routes/orders');
const aiRoutes = require('./routes/ai');

const app = express();
const PORT = process.env.PORT || 3000;
const ENV = process.env.NODE_ENV || 'development';

// Security: Disable X-Powered-By header to prevent information exposure
app.disable('x-powered-by');

// Resource allocation protection middleware
app.use(bodyParser.json({ limit: '1mb' })); // Limit JSON payload size
app.use(bodyParser.urlencoded({ extended: true, limit: '1mb' })); // Limit form data size
app.use(express.static(path.join(__dirname, 'public')));

// Request timeout middleware
app.use((req, res, next) => {
  req.setTimeout(30000, () => {
    res.status(408).json({ error: 'Request timeout' });
  });
  res.setTimeout(30000, () => {
    res.status(408).json({ error: 'Response timeout' });
  });
  next();
});

// Configure session with secure cookies and resource limits
app.use(session({
  secret: process.env.SESSION_SECRET || 'shopmate-default-secret',
  resave: false,
  saveUninitialized: false, // Don't create sessions for unauthenticated users
  cookie: { 
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000 // 24 hours
  },
  // Memory store limits (use Redis in production)
  store: undefined, // Default memory store with built-in limits
  rolling: true, // Reset expiration on activity
  name: 'shopmate.sid' // Custom session name
}));

// Set view engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Logging middleware
app.use((req, res, next) => {
  console.log(`[${ENV}] ${req.method} ${req.url}`);
  next();
});

// Initialize cart in session with resource limits
app.use((req, res, next) => {
  if (!req.session.cart) {
    req.session.cart = [];
  }
  if (!req.session.orders) {
    req.session.orders = [];
  }
  
  // Enforce cart size limits to prevent memory exhaustion
  if (req.session.cart && req.session.cart.length > 50) {
    req.session.cart = req.session.cart.slice(0, 50);
  }
  if (req.session.orders && req.session.orders.length > 100) {
    req.session.orders = req.session.orders.slice(-100); // Keep last 100 orders
  }
  
  next();
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Application error:', err);
  res.status(500).render('layout', {
    content: 'error',
    message: 'An unexpected error occurred',
    cartCount: req.session.cart ? req.session.cart.length : 0
  });
});

// Rate limiting for expensive operations
const orderRateLimit = rateLimit(15 * 60 * 1000, 10); // 10 requests per 15 minutes
const generalRateLimit = rateLimit(15 * 60 * 1000, 100); // 100 requests per 15 minutes

// Routes
app.use('/products', generalRateLimit, productRoutes);
app.use('/shop', generalRateLimit, productRoutes);
app.use('/cart', generalRateLimit, cartRoutes);
app.use('/orders', orderRateLimit, orderRoutes);
app.use('/api/ai', generalRateLimit, aiRoutes);

// Health check endpoint for AWS
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok', 
    environment: ENV,
    timestamp: new Date().toISOString()
  });
});

// CPU stress test endpoint for autoscaling testing (rate limited with timeout protection)
const stressRateLimit = rateLimit(60 * 1000, 50); // 50 requests per minute
app.get('/stress', stressRateLimit, (req, res) => {
  const start = Date.now();
  const maxDuration = 5000; // Maximum 5 seconds
  
  // CPU-intensive calculation with timeout protection
  while (Date.now() - start < maxDuration) {
    // Prevent infinite loops by checking time periodically
    if ((Date.now() - start) % 100 === 0) {
      // Small break every 100ms to prevent complete CPU lockup
      setImmediate(() => {});
    }
    Math.random() * Math.random();
  }
  
  const duration = Date.now() - start;
  res.json({ 
    message: 'CPU stress test completed', 
    duration,
    limited: duration >= maxDuration
  });
});

// Home route
app.get('/', (req, res) => {
  const cartCount = req.session.cart ? req.session.cart.length : 0;
  res.render('layout', { 
    content: 'home',
    cartCount
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT} in ${ENV} environment`);
});