const Product = require('../models/product');

// Get all products
exports.getAllProducts = async (req, res) => {
  try {
    const products = await Product.getAllProducts();
    
    // Fallback to empty array if products is undefined
    const productList = Array.isArray(products) ? products : [];
    
    res.render('layout', { 
      content: 'products',
      products: productList,
      cartCount: req.session.cart ? req.session.cart.length : 0
    });
  } catch (error) {
    console.error('Error getting products:', error);
    res.render('layout', { 
      content: 'products',
      products: [],
      cartCount: req.session.cart ? req.session.cart.length : 0
    });
  }
};

// Get product details
exports.getProductDetails = async (req, res) => {
  try {
    const product = await Product.getProductById(req.params.id);
    if (!product) {
      return res.status(404).render('layout', { 
        content: 'error',
        message: 'Product not found',
        cartCount: req.session.cart ? req.session.cart.length : 0
      });
    }
    res.render('layout', { 
      content: 'product-details',
      product,
      cartCount: req.session.cart ? req.session.cart.length : 0
    });
  } catch (error) {
    console.error('Error getting product details:', error);
    res.status(500).render('layout', { 
      content: 'error',
      message: 'Error loading product details',
      cartCount: req.session.cart ? req.session.cart.length : 0
    });
  }
};