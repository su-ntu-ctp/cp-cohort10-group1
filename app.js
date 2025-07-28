require('dotenv').config();
const express = require('express');
const session = require('express-session');
const bodyParser = require('body-parser');
const path = require('path');

// Import routes
const productRoutes = require('./routes/products');
const cartRoutes = require('./routes/cart');
const orderRoutes = require('./routes/orders');
const aiRoutes = require('./routes/ai');

const app = express();
const PORT = process.env.PORT || 3000;
const ENV = process.env.NODE_ENV || 'development';

// Middleware
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// Configure session with secure cookies
app.use(session({
  secret: process.env.SESSION_SECRET || 'shopmate-default-secret',
  resave: false,
  saveUninitialized: true,
  cookie: { 
    secure: process.env.NODE_ENV === 'production', // Secure in production only
    sameSite: 'lax',
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000 // 24 hours
  }
}));

// Set view engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Logging middleware
app.use((req, res, next) => {
  console.log(`[${ENV}] ${req.method} ${req.url}`);
  next();
});

// Initialize cart in session
app.use((req, res, next) => {
  if (!req.session.cart) {
    req.session.cart = [];
  }
  if (!req.session.orders) {
    req.session.orders = [];
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

// Routes
app.use('/products', productRoutes);
app.use('/shop', productRoutes);
app.use('/cart', cartRoutes);
app.use('/orders', orderRoutes);
app.use('/api/ai', aiRoutes);

// Health check endpoint for AWS
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok', 
    environment: ENV,
    timestamp: new Date().toISOString()
  });
});

// CPU stress test endpoint for autoscaling testing
app.get('/stress', (req, res) => {
  const start = Date.now();
  // CPU-intensive calculation for 5 seconds
  while (Date.now() - start < 5000) {
    Math.random() * Math.random();
  }
  res.json({ message: 'CPU stress test completed', duration: Date.now() - start });
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