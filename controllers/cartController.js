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

// Add to cart with resource limits
exports.addToCart = async (req, res) => {
  const userId = getUserId(req);
  const productId = parseInt(req.body.productId);
  let quantity = parseInt(req.body.quantity) || 1;
  
  // Input validation and resource limits
  if (!productId || productId <= 0) {
    return res.redirect('/products?error=Invalid product ID');
  }
  
  if (quantity <= 0 || quantity > 99) {
    return res.redirect('/products?error=Invalid quantity (1-99 allowed)');
  }
  
  // Limit total cart items to prevent resource exhaustion
  const cartItems = await getCartFromDB(userId);
  if (cartItems.length >= 50) {
    return res.redirect('/products?error=Cart is full (maximum 50 items)');
  }
  
  // Limit total quantity per item
  const existingItem = cartItems.find(item => item.productId === productId);
  if (existingItem && (existingItem.quantity + quantity) > 99) {
    quantity = Math.max(0, 99 - existingItem.quantity);
    if (quantity === 0) {
      return res.redirect('/products?error=Maximum quantity per item reached (99)');
    }
  }
  
  try {
    const product = await Product.getProductById(productId);
    if (!product) {
      return res.redirect('/products?error=Product not found');
    }
    
    // Check stock availability
    if (product.stock < quantity) {
      return res.redirect('/products?error=Insufficient stock');
    }
    
    // Reduce product stock
    const newStock = product.stock - quantity;
    await Product.updateProduct(productId, { stock: newStock });
    
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
    
    console.log(`Added product ${productId} to cart, reduced stock to ${newStock}`);
    res.redirect('/cart');
  } catch (error) {
    console.error('Error adding to cart:', error);
    res.redirect('/products?error=Failed to add item to cart');
  }
};

// Update cart item
exports.updateCartItem = async (req, res) => {
  const userId = getUserId(req);
  const productId = parseInt(req.params.id);
  const newQuantity = parseInt(req.body.quantity);
  
  try {
    // Get current cart
    let cartItems = await getCartFromDB(userId);
    const itemIndex = cartItems.findIndex(item => item.productId === productId);
    
    if (itemIndex >= 0) {
      const currentQuantity = cartItems[itemIndex].quantity;
      const product = await Product.getProductById(productId);
      
      if (newQuantity <= 0) {
        // Remove item and restore all stock
        const newStock = product.stock + currentQuantity;
        await Product.updateProduct(productId, { stock: newStock });
        cartItems = cartItems.filter(item => item.productId !== productId);
        console.log(`Removed product ${productId}, restored stock to ${newStock}`);
      } else {
        // Update quantity and adjust stock
        const quantityDiff = currentQuantity - newQuantity;
        const newStock = product.stock + quantityDiff;
        await Product.updateProduct(productId, { stock: newStock });
        cartItems[itemIndex].quantity = newQuantity;
        console.log(`Updated product ${productId} quantity to ${newQuantity}, stock now ${newStock}`);
      }
    }
    
    // Save updated cart
    await saveCartToDB(userId, cartItems);
    
    // Update session
    req.session.cart = cartItems;
    
    res.redirect('/cart');
  } catch (error) {
    console.error('Error updating cart item:', error);
    res.redirect('/cart');
  }
};

// Remove from cart
exports.removeFromCart = async (req, res) => {
  const userId = getUserId(req);
  const productId = parseInt(req.params.id);
  
  try {
    // Get current cart
    let cartItems = await getCartFromDB(userId);
    
    // Find the item to remove
    const itemToRemove = cartItems.find(item => item.productId === productId);
    
    if (itemToRemove) {
      // Restore stock
      const product = await Product.getProductById(productId);
      if (product) {
        const newStock = product.stock + itemToRemove.quantity;
        await Product.updateProduct(productId, { stock: newStock });
        console.log(`Removed product ${productId} from cart, restored stock to ${newStock}`);
      }
    }
    
    // Remove item from cart
    cartItems = cartItems.filter(item => item.productId !== productId);
    
    // Save updated cart
    await saveCartToDB(userId, cartItems);
    
    // Update session
    req.session.cart = cartItems;
    
    res.redirect('/cart');
  } catch (error) {
    console.error('Error removing from cart:', error);
    res.redirect('/cart');
  }
};

// Clear cart
exports.clearCart = async (req, res) => {
  const userId = getUserId(req);
  
  try {
    // Get current cart to restore stock
    const cartItems = await getCartFromDB(userId);
    
    // Restore stock for all items
    for (const item of cartItems) {
      const product = await Product.getProductById(item.productId);
      if (product) {
        const newStock = product.stock + item.quantity;
        await Product.updateProduct(item.productId, { stock: newStock });
        console.log(`Cleared cart: restored ${item.quantity} units of product ${item.productId}`);
      }
    }
    
    // Save empty cart
    await saveCartToDB(userId, []);
    
    // Update session
    req.session.cart = [];
    
    res.redirect('/cart');
  } catch (error) {
    console.error('Error clearing cart:', error);
    res.redirect('/cart');
  }
};