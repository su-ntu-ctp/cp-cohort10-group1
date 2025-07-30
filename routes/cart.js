const express = require('express');
const router = express.Router();
const cartController = require('../controllers/cartController');

// View cart
router.get('/', cartController.viewCart);

// Add to cart
router.post('/add', cartController.addToCart);

// Update cart item
router.post('/update/:id', cartController.updateCartItem);

// Remove from cart
router.get('/remove/:id', cartController.removeFromCart);

// Clear cart
router.get('/clear', cartController.clearCart);

module.exports = router;