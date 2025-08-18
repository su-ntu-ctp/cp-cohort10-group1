const { PRODUCTS_TABLE, scan, get, batchWrite, put } = require('../utils/dynamodb');
const uuid = require('uuid');

// Sample product data - will be used to initialize the DynamoDB table
const sampleProducts = [
  {
    id: 1,
    name: 'Smartphone X12 Pro',
    price: 699.99,
    description: 'Experience the future with our flagship X12 Pro smartphone. Featuring a stunning 6.5-inch AMOLED display with 120Hz refresh rate for ultra-smooth scrolling. Capture professional-quality photos with the 108MP quad-camera system and 8K video recording. Powered by the latest octa-core processor and 8GB RAM for lightning-fast performance. Includes 256GB storage, all-day 5000mAh battery with fast charging, water resistance (IP68), and advanced facial recognition security.',
    image: '/images/smartphone.jpg',
    stock: 50
  },
  {
    id: 2,
    name: 'UltraBook Pro 16',
    price: 1299.99,
    description: 'Meet the UltraBook Pro 16 - the ultimate productivity powerhouse. Featuring a brilliant 16-inch 4K display with 100% Adobe RGB color accuracy for stunning visuals. Powered by the latest 12th Gen processor with 16-core architecture and dedicated graphics for seamless multitasking and content creation. Includes 32GB high-speed RAM, 1TB SSD storage, backlit keyboard with precision trackpad, all-day battery life (up to 12 hours), Thunderbolt 4 connectivity, and military-grade durability certification. Perfect for professionals, creators, and power users.',
    image: '/images/laptop.jpg',
    stock: 30
  },
  {
    id: 3,
    name: 'SoundWave Elite Headphones',
    price: 199.99,
    description: 'Immerse yourself in audio perfection with SoundWave Elite wireless headphones. Experience industry-leading active noise cancellation with three customizable modes to control your environment. Enjoy rich, detailed sound with custom-designed 40mm drivers tuned by award-winning audio engineers. Features include premium memory foam ear cushions for all-day comfort, touch controls, voice assistant integration, multipoint Bluetooth 5.2 connectivity, 30-hour battery life, fast charging (5 hours of playback from just 10 minutes of charging), and foldable design with premium travel case.',
    image: '/images/headphones.jpg',
    stock: 100
  },
  {
    id: 4,
    name: 'FitTech Pro Smartwatch',
    price: 249.99,
    description: 'Transform your fitness journey with the FitTech Pro Smartwatch. Track over 40 workout types with built-in GPS and advanced metrics for runners, swimmers, and cyclists. Monitor your health 24/7 with continuous heart rate tracking, blood oxygen monitoring, stress management tools, and comprehensive sleep analysis with personalized insights. Features include a vibrant 1.4-inch always-on display, 5ATM water resistance for swimming, ECG capability, fall detection, 7-day battery life, smartphone notifications, music control, contactless payments, and customizable watch faces. Compatible with iOS and Android.',
    image: '/images/smartwatch.jpg',
    stock: 45
  },
  {
    id: 5,
    name: 'SlimTab Ultra',
    price: 499.99,
    description: 'Unleash your creativity with the SlimTab Ultra. Featuring a stunning 10.9-inch Liquid Retina display with True Tone technology for vibrant, accurate colors in any lighting. Powered by the A14 Bionic chip for desktop-class performance in a portable device. Perfect for digital artists with the included precision stylus featuring pressure sensitivity and tilt recognition. Includes 128GB storage, all-day battery life (up to 10 hours), quad speakers with spatial audio, 12MP front and rear cameras, Face ID security, and optional keyboard attachment with trackpad. Weighing just 460g and 6.1mm thin for ultimate portability.',
    image: '/images/tablet.jpg',
    stock: 25
  }
];

// Track initialization status
let productsInitialized = false;
let initializationPromise = null;

// Initialize products in DynamoDB if they don't exist
const initializeProducts = async () => {
  try {
    // Check if products already exist
    const products = await scan(PRODUCTS_TABLE);
    
    // If no products exist, add sample products
    if (products.length === 0) {
      console.log('Initializing products in DynamoDB...');
      
      await batchWrite(PRODUCTS_TABLE, sampleProducts);
      
      // Wait a bit for eventual consistency
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      console.log('Products initialized successfully');
    }
    
    productsInitialized = true;
  } catch (error) {
    console.error('Error initializing products:', error);
    productsInitialized = true; // Set to true to prevent hanging
  }
};

// Call initialization and store promise
initializationPromise = initializeProducts();

// Get all products
exports.getAllProducts = async () => {
  try {
    // Wait for initialization to complete
    if (!productsInitialized && initializationPromise) {
      await initializationPromise;
    }
    
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
    // Wait for initialization to complete
    if (!productsInitialized && initializationPromise) {
      await initializationPromise;
    }
    
    const product = await get(PRODUCTS_TABLE, { id: parseInt(id) });
    return product || sampleProducts.find(p => p.id === parseInt(id));
  } catch (error) {
    console.error(`Error getting product ${id}:`, error);
    return sampleProducts.find(product => product.id === parseInt(id)); // Fallback
  }
};

// Update product
exports.updateProduct = async (id, updates) => {
  try {
    const product = await get(PRODUCTS_TABLE, { id: parseInt(id) });
    if (product) {
      const updatedProduct = { ...product, ...updates };
      await put(PRODUCTS_TABLE, updatedProduct);
      return updatedProduct;
    }
    return null;
  } catch (error) {
    console.error(`Error updating product ${id}:`, error);
    throw error;
  }
};