const Product = require('../models/product');
const { get, put, scan, deleteItem, ORDERS_TABLE, CARTS_TABLE } = require('../utils/dynamodb');
const uuid = require('uuid');

// Helper function to get user ID
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

// Helper function to get orders from DynamoDB
const getOrdersFromDB = async (userId) => {
  try {
    const params = {
      TableName: ORDERS_TABLE,
      FilterExpression: 'userId = :userId',
      ExpressionAttributeValues: {
        ':userId': userId
      }
    };
    
    const result = await scan(params);
    return result || [];
  } catch (error) {
    console.error('Error getting orders from DynamoDB:', error);
    return [];
  }
};

// Checkout
exports.checkout = async (req, res) => {
  const userId = getUserId(req);
  const cartItems = await getCartFromDB(userId);
  
  if (cartItems.length === 0) {
    return res.redirect('/cart');
  }
  
  res.render('layout', { 
    content: 'checkout',
    cartCount: cartItems.length
  });
};

// Place order
exports.placeOrder = async (req, res) => {
  const userId = getUserId(req);
  const cartItems = await getCartFromDB(userId);
  
  if (cartItems.length === 0) {
    return res.redirect('/cart');
  }
  
  const { name, email, address } = req.body;
  
  // Calculate order total
  let total = 0;
  const itemPromises = cartItems.map(async (item) => {
    const product = await Product.getProductById(item.productId);
    const itemTotal = product.price * item.quantity;
    total += itemTotal;
    
    return {
      product: {
        id: product.id,
        name: product.name,
        price: product.price
      },
      quantity: item.quantity,
      itemTotal
    };
  });
  
  const items = await Promise.all(itemPromises);
  
  // Create order
  const orderId = Date.now();
  const order = {
    id: orderId,
    userId: userId,
    date: new Date().toISOString(),
    customer: { name, email, address },
    items,
    total,
    status: 'Confirmed'
  };
  
  // Save order to DynamoDB
  try {
    await put(ORDERS_TABLE, order);
    
    // Clear cart
    await saveCartToDB(userId, []);
    req.session.cart = [];
    
    res.redirect('/orders/confirmation/' + orderId);
  } catch (error) {
    console.error('Error saving order:', error);
    res.status(500).render('layout', {
      content: 'error',
      message: 'Failed to place order. Please try again.',
      cartCount: cartItems.length
    });
  }
};

// Order confirmation
exports.orderConfirmation = async (req, res) => {
  const userId = getUserId(req);
  const orderId = parseInt(req.params.id);
  
  try {
    const order = await get(ORDERS_TABLE, { id: orderId });
    
    if (!order || order.userId !== userId) {
      return res.status(404).render('layout', { 
        content: 'error',
        message: 'Order not found',
        cartCount: req.session.cart ? req.session.cart.length : 0
      });
    }
    
    res.render('layout', { 
      content: 'order-confirmation',
      order,
      cartCount: req.session.cart ? req.session.cart.length : 0
    });
  } catch (error) {
    console.error('Error getting order:', error);
    res.status(500).render('layout', {
      content: 'error',
      message: 'Failed to retrieve order details.',
      cartCount: req.session.cart ? req.session.cart.length : 0
    });
  }
};

// View orders
exports.viewOrders = async (req, res) => {
  const userId = getUserId(req);
  
  try {
    const orders = await getOrdersFromDB(userId);
    
    res.render('layout', { 
      content: 'orders',
      orders,
      cartCount: req.session.cart ? req.session.cart.length : 0
    });
  } catch (error) {
    console.error('Error getting orders:', error);
    res.status(500).render('layout', {
      content: 'error',
      message: 'Failed to retrieve orders.',
      cartCount: req.session.cart ? req.session.cart.length : 0
    });
  }
};

// Clear orders (for demo purposes)
exports.clearOrders = async (req, res) => {
  const userId = getUserId(req);
  
  try {
    const orders = await getOrdersFromDB(userId);
    
    // Delete each order
    for (const order of orders) {
      await deleteItem(ORDERS_TABLE, { id: order.id });
    }
    
    res.redirect('/orders');
  } catch (error) {
    console.error('Error clearing orders:', error);
    res.status(500).render('layout', {
      content: 'error',
      message: 'Failed to clear orders.',
      cartCount: req.session.cart ? req.session.cart.length : 0
    });
  }
};