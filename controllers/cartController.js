const Product = require('../models/product');
const { get, put, CARTS_TABLE } = require('../utils/dynamodb');
const uuid = require('uuid');

// Helper function to get user ID (in a real app, this would come from authentication)
const getUserId = (req) => {
  if (!req.session.userId) {
    req.session.userId = uuid.v4();
  }
  return req.session.userId;
};

// Helper function to get cart from DynamoDB
const getCartFromDB = async (userId) => {
  try {
    const result = await get(CARTS_TABLE, { userId });
    return result ? result.items || [] : [];
  } catch (error) {
    console.error('Error getting cart from DynamoDB:', error);
    return [];
  }
};

// Helper function to save cart to DynamoDB
const saveCartToDB = async (userId, items) => {
  try {
    await put(CARTS_TABLE, {
      userId,
      items,
      updatedAt: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error saving cart to DynamoDB:', error);
  }
};

// View cart
exports.viewCart = async (req, res) => {
  const userId = getUserId(req);
  
  // Get cart items from DynamoDB
  const cartItems = await getCartFromDB(userId);
  
  // Store in session for convenience
  req.session.cart = cartItems;
  
  let total = 0;
  const cartPromises = cartItems.map(async (item) => {
    const product = await Product.getProductById(item.productId);
    const itemTotal = product.price * item.quantity;
    total += itemTotal;
    
    return {
      ...product,
      quantity: item.quantity,
      itemTotal
    };
  });
  
  const cart = await Promise.all(cartPromises);
  
  res.render('layout', { 
    content: 'cart',
    cart, 
    total,
    cartCount: cartItems.length
  });
};

// Add to cart
exports.addToCart = async (req, res) => {
  const userId = getUserId(req);
  const productId = parseInt(req.body.productId);
  const quantity = parseInt(req.body.quantity) || 1;
  
  const product = await Product.getProductById(productId);
  if (!product) {
    return res.status(404).json({ error: 'Product not found' });
  }
  
  // Get current cart
  const cartItems = await getCartFromDB(userId);
  
  // Check if product is already in cart
  const existingItemIndex = cartItems.findIndex(item => item.productId === productId);
  
  if (existingItemIndex >= 0) {
    // Update quantity if product already in cart
    cartItems[existingItemIndex].quantity += quantity;
  } else {
    // Add new item to cart
    cartItems.push({
      productId,
      quantity
    });
  }
  
  // Save updated cart
  await saveCartToDB(userId, cartItems);
  
  // Update session
  req.session.cart = cartItems;
  
  res.redirect('/cart');
};

// Update cart item
exports.updateCartItem = async (req, res) => {
  const userId = getUserId(req);
  const productId = parseInt(req.params.id);
  const quantity = parseInt(req.body.quantity);
  
  // Get current cart
  let cartItems = await getCartFromDB(userId);
  
  if (quantity <= 0) {
    // Remove item if quantity is 0 or negative
    cartItems = cartItems.filter(item => item.productId !== productId);
  } else {
    // Update quantity
    const itemIndex = cartItems.findIndex(item => item.productId === productId);
    if (itemIndex >= 0) {
      cartItems[itemIndex].quantity = quantity;
    }
  }
  
  // Save updated cart
  await saveCartToDB(userId, cartItems);
  
  // Update session
  req.session.cart = cartItems;
  
  res.redirect('/cart');
};

// Remove from cart
exports.removeFromCart = async (req, res) => {
  const userId = getUserId(req);
  const productId = parseInt(req.params.id);
  
  // Get current cart
  let cartItems = await getCartFromDB(userId);
  
  // Remove item
  cartItems = cartItems.filter(item => item.productId !== productId);
  
  // Save updated cart
  await saveCartToDB(userId, cartItems);
  
  // Update session
  req.session.cart = cartItems;
  
  res.redirect('/cart');
};

// Clear cart
exports.clearCart = async (req, res) => {
  const userId = getUserId(req);
  
  // Save empty cart
  await saveCartToDB(userId, []);
  
  // Update session
  req.session.cart = [];
  
  res.redirect('/cart');
};