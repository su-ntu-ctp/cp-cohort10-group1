require('dotenv').config();
const express = require('express');
const session = require('express-session');
const bodyParser = require('body-parser');
const promClient = require('prom-client');

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

// ============================================================================
// PROMETHEUS METRICS SETUP
// ============================================================================
// Enable default Node.js metrics (memory, CPU, etc.)
promClient.collectDefaultMetrics({
  prefix: 'nodejs_',
  timeout: 5000
});

// HTTP request metrics
const httpRequestsTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route']
});

// Business metrics
const ordersCreated = new promClient.Counter({
  name: 'orders_created_total',
  help: 'Total orders created'
});

const cartItemsAdded = new promClient.Counter({
  name: 'cart_items_added_total',
  help: 'Total items added to cart'
});

const productViews = new promClient.Counter({
  name: 'product_views_total',
  help: 'Total product views'
});

const orderValue = new promClient.Counter({
  name: 'order_value_total',
  help: 'Total order value in currency'
});

// Product-specific metrics
const productOrdersCounter = new promClient.Counter({
  name: 'product_orders_total',
  help: 'Total products ordered by type',
  labelNames: ['product_id', 'product_name', 'category']
});

const productViewsCounter = new promClient.Counter({
  name: 'product_views_by_type_total',
  help: 'Total product views by type',
  labelNames: ['product_id', 'product_name', 'category']
});

const cartItemsByProduct = new promClient.Counter({
  name: 'cart_items_by_product_total',
  help: 'Total cart items by product type',
  labelNames: ['product_id', 'product_name', 'category']
});

// Custom Node.js metrics
const activeHandles = new promClient.Gauge({
  name: 'nodejs_active_handles_total',
  help: 'Number of active handles'
});

const eventLoopLag = new promClient.Gauge({
  name: 'nodejs_eventloop_lag_seconds',
  help: 'Event loop lag in seconds'
});

// Export metrics for use in other modules
module.exports.metrics = {
  httpRequestsTotal,
  httpRequestDuration,
  ordersCreated,
  cartItemsAdded,
  productViews,
  orderValue,
  productOrdersCounter,
  productViewsCounter,
  cartItemsByProduct
};

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

// Configure DynamoDB session store for stateless architecture
const DynamoDBStore = require('connect-dynamodb')(session);

app.use(session({
  secret: process.env.SESSION_SECRET || 'shopmate-default-secret',
  resave: false,
  saveUninitialized: false,
  cookie: { 
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000 // 24 hours
  },
  store: new DynamoDBStore({
    table: process.env.SESSIONS_TABLE || 'shopmate-sessions-dev',
    AWSConfigJSON: {
      region: process.env.AWS_REGION || 'ap-southeast-1'
    },
    reapInterval: 86400000 // Clean up expired sessions daily
  }),
  rolling: true,
  name: 'shopmate.sid'
}));

// Set view engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Prometheus metrics middleware
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route?.path || req.path;
    
    httpRequestsTotal.inc({ 
      method: req.method, 
      route: route,
      status_code: res.statusCode 
    });
    
    httpRequestDuration.observe({ 
      method: req.method, 
      route: route 
    }, duration);
  });
  
  next();
});

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

// Metrics endpoint for Prometheus
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', promClient.register.contentType);
    const metrics = await promClient.register.metrics();
    res.send(metrics);
  } catch (error) {
    console.error('Error generating metrics:', error);
    res.status(500).send('Error generating metrics');
  }
});

// Balanced CPU stress test endpoint for safe autoscaling testing
const stressRateLimit = rateLimit(60 * 1000, 200); // 200 requests per minute
app.get('/stress', stressRateLimit, (req, res) => {
  const start = Date.now();
  const duration = parseInt(req.query.duration) || 20000; // Default 20 seconds
  const maxDuration = Math.min(duration, 30000); // Maximum 30 seconds
  
  let result = 0;
  let cycles = 0;
  
  const performBalancedWork = () => {
    const cycleStart = Date.now();
    
    // Work for 150ms intensively
    while (Date.now() - cycleStart < 150) {
      for (let i = 0; i < 75000; i++) {
        result += Math.sqrt(Math.random() * 1000);
        result += Math.sin(i * 0.01) * Math.cos(i * 0.01);
        result += Math.pow(Math.random() * 50, 2);
        result = result % 1000000;
      }
    }
    
    cycles++;
    
    // Continue if time remaining
    if (Date.now() - start < maxDuration) {
      // 20ms break to allow other requests and health checks
      setTimeout(performBalancedWork, 20);
    } else {
      // Send response
      const actualDuration = Date.now() - start;
      res.json({ 
        message: 'Balanced CPU stress completed', 
        duration: actualDuration,
        cycles,
        result: Math.floor(result),
        avgCycleTime: Math.round(actualDuration / cycles)
      });
    }
  };
  
  // Start balanced work
  performBalancedWork();
});

// Home route
app.get('/', (req, res) => {
  const cartCount = req.session.cart ? req.session.cart.length : 0;
  res.render('layout', { 
    content: 'home',
    cartCount
  });
});

// Update custom metrics periodically
setInterval(() => {
  // Update active handles count
  try {
    activeHandles.set(process._getActiveHandles().length);
  } catch (error) {
    // Fallback if _getActiveHandles is not available
    activeHandles.set(0);
  }
  
  // Measure event loop lag
  const start = process.hrtime.bigint();
  setImmediate(() => {
    const lag = Number(process.hrtime.bigint() - start) / 1e9;
    eventLoopLag.set(lag);
  });
}, 5000);

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT} in ${ENV} environment`);
  console.log(`Prometheus metrics available at http://localhost:${PORT}/metrics`);
});