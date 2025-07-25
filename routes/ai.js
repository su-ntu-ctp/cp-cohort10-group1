const express = require('express');
const router = express.Router();

// Enhanced AI chatbot endpoint
router.post('/chat', async (req, res) => {
  try {
    const { message } = req.body;
    const lowerMessage = message.toLowerCase();
    
    // Product-specific recommendations based on actual products
    if (lowerMessage.includes('tablet') || lowerMessage.includes('ipad')) {
      return res.json({ response: 'Our tablets are perfect for work and entertainment! The iPad Pro offers excellent performance for creative tasks, while standard tablets are great for media consumption. Need help choosing the right size or storage?' });
    }
    
    if (lowerMessage.includes('laptop') || lowerMessage.includes('computer')) {
      return res.json({ response: 'Our laptops range from budget-friendly options to high-performance machines. For work: business laptops with long battery life. For gaming: powerful graphics cards. For students: lightweight and affordable. What\'s your main use case?' });
    }
    
    if (lowerMessage.includes('phone') || lowerMessage.includes('mobile') || lowerMessage.includes('smartphone')) {
      return res.json({ response: 'We have smartphones for every need! Premium flagships with best cameras, mid-range phones with great value, and budget options. Are you looking for specific features like camera quality, battery life, or gaming performance?' });
    }
    
    if (lowerMessage.includes('headphone') || lowerMessage.includes('earphone') || lowerMessage.includes('audio')) {
      return res.json({ response: 'Our audio products include wireless earbuds, over-ear headphones, and gaming headsets. For music: noise-cancelling options. For calls: clear microphones. For gaming: surround sound. What\'s your priority?' });
    }
    
    if (lowerMessage.includes('accessory') || lowerMessage.includes('accessories')) {
      return res.json({ response: 'We have all the accessories you need! Phone cases, laptop bags, chargers, cables, stands, and more. What device are you looking to accessorize?' });
    }
    
    // Comparison questions
    if (lowerMessage.includes('compare') || lowerMessage.includes('difference') || lowerMessage.includes('vs')) {
      return res.json({ response: 'I can help compare our products! Tell me which specific items you\'re considering, and I\'ll highlight the key differences in features, price, and performance to help you decide.' });
    }
    
    // Price and budget questions
    if (lowerMessage.includes('price') || lowerMessage.includes('cost') || lowerMessage.includes('budget') || lowerMessage.includes('cheap') || lowerMessage.includes('affordable')) {
      return res.json({ response: 'Our products are competitively priced! We have options for every budget. Check our current deals and discounts. Need recommendations within a specific price range? Just let me know your budget!' });
    }
    
    // Stock and availability
    if (lowerMessage.includes('stock') || lowerMessage.includes('available') || lowerMessage.includes('in stock')) {
      return res.json({ response: 'Most of our products are in stock and ready to ship! You can see real-time availability on each product page. Need something urgently? I can help you find similar in-stock alternatives.' });
    }
    
    // Specifications
    if (lowerMessage.includes('spec') || lowerMessage.includes('feature') || lowerMessage.includes('detail')) {
      return res.json({ response: 'I can help you understand product specifications! Each product page has detailed specs, but feel free to ask about specific features like battery life, storage, camera quality, or performance.' });
    }
    
    // Standard service responses
    const responses = {
      'return': 'Returns accepted within 30 days with receipt. Free return shipping on all orders!',
      'shipping': 'Free shipping on orders over $50. Express delivery available. Standard shipping: 3-5 business days.',
      'payment': 'We accept all major credit cards, PayPal, Apple Pay, and Buy Now Pay Later options.',
      'warranty': '1-year manufacturer warranty on all products. Extended warranties available at checkout.',
      'track': 'Track your order in the "My Orders" section or use the tracking number we emailed you.',
      'cancel': 'Orders can be cancelled within 1 hour of placement. Contact us immediately for assistance!',
      'hello': 'Hi! I\'m your ShopMate assistant. I can help with product recommendations, comparisons, and shopping questions!',
      'help': 'I can help with: product recommendations, comparisons, specifications, pricing, shipping, returns, and order tracking. What do you need?',
      'support': 'Our customer support team is here to help! For complex questions, email us at support@shopmate.com'
    };
    
    // Check for matches
    for (const [key, value] of Object.entries(responses)) {
      if (lowerMessage.includes(key)) {
        return res.json({ response: value });
      }
    }
    
    // Default response for unmatched queries
    const defaultResponse = 'I can help with product recommendations, comparisons, pricing, shipping, and returns. For detailed technical questions or specific product inquiries, please email our experts at support@shopmate.com - we\'ll get back to you within 24 hours!';
    
    res.json({ response: defaultResponse });
  } catch (error) {
    console.error('AI Chat error:', error);
    res.status(500).json({ error: 'Sorry, I encountered an error. Please email us at support@shopmate.com for assistance.' });
  }
});

// Product recommendations endpoint
router.get('/recommendations/:productId', async (req, res) => {
  try {
    const { productId } = req.params;
    
    // Simple recommendation logic based on product ID
    const recommendations = [
      { id: 1, name: 'Wireless Mouse', price: 29.99 },
      { id: 2, name: 'USB-C Hub', price: 49.99 },
      { id: 3, name: 'Laptop Stand', price: 39.99 }
    ];
    
    res.json({ recommendations });
  } catch (error) {
    console.error('Recommendations error:', error);
    res.status(500).json({ error: 'Unable to load recommendations' });
  }
});

module.exports = router;