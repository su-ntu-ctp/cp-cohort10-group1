const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');

// Checkout
router.get('/checkout', orderController.checkout);

// Place order
router.post('/place', orderController.placeOrder);

// Order confirmation
router.get('/confirmation/:id', orderController.orderConfirmation);

// View orders
router.get('/', orderController.viewOrders);

module.exports = router;