const { PRODUCTS_TABLE, scan, get, batchWrite } = require('../utils/dynamodb');
const uuid = require('uuid');

// Sample product data - will be used to initialize the DynamoDB table
const sampleProducts = [
  {
    id: 1,
    name: 'Smartphone',
    price: 699.99,
    description: 'Latest model with high-resolution camera and long battery life.',
    image: '/images/smartphone.jpg',
    stock: 50
  },
  {
    id: 2,
    name: 'Laptop',
    price: 1299.99,
    description: 'Powerful laptop with fast processor and ample storage.',
    image: '/images/laptop.jpg',
    stock: 30
  },
  {
    id: 3,
    name: 'Headphones',
    price: 199.99,
    description: 'Noise-cancelling wireless headphones with premium sound quality.',
    image: '/images/headphones.jpg',
    stock: 100
  },
  {
    id: 4,
    name: 'Smartwatch',
    price: 249.99,
    description: 'Fitness tracker with heart rate monitor and sleep analysis.',
    image: '/images/smartwatch.jpg',
    stock: 45
  },
  {
    id: 5,
    name: 'Tablet',
    price: 499.99,
    description: 'Lightweight tablet with high-resolution display and long battery life.',
    image: '/images/tablet.jpg',
    stock: 25
  }
];

// Initialize products in DynamoDB if they don't exist
const initializeProducts = async () => {
  try {
    // Check if products already exist
    const products = await scan(PRODUCTS_TABLE);
    
    // If no products exist, add sample products
    if (products.length === 0) {
      console.log('Initializing products in DynamoDB...');
      
      await batchWrite(PRODUCTS_TABLE, sampleProducts);
      
      console.log('Products initialized successfully');
    }
  } catch (error) {
    console.error('Error initializing products:', error);
  }
};

// Call initialization (will run when the app starts)
initializeProducts();

// Get all products
exports.getAllProducts = async () => {
  try {
    const products = await scan(PRODUCTS_TABLE);
    return products.length > 0 ? products : sampleProducts;
  } catch (error) {
    console.error('Error getting products:', error);
    return sampleProducts; // Fallback to sample data if DynamoDB fails
  }
};

// Get product by ID
exports.getProductById = async (id) => {
  try {
    const product = await get(PRODUCTS_TABLE, { id: parseInt(id) });
    return product || sampleProducts.find(p => p.id === parseInt(id));
  } catch (error) {
    console.error(`Error getting product ${id}:`, error);
    return sampleProducts.find(product => product.id === parseInt(id)); // Fallback
  }
};