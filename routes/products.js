const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');

// Get all products
router.get('/', productController.getAllProducts);

// Get product details
router.get('/:id', productController.getProductDetails);

module.exports = router;