// AI Chat functionality
class AIChat {
  constructor() {
    this.isOpen = false;
    this.init();
  }

  init() {
    this.createChatWidget();
    this.attachEventListeners();
  }

  createChatWidget() {
    const chatHTML = `
      <div id="ai-chat-widget" class="chat-widget">
        <div id="chat-toggle" class="chat-toggle">
          <span>💬</span>
        </div>
        <div id="chat-window" class="chat-window">
          <div class="chat-header">
            <h4>ShopMate Assistant</h4>
            <button id="chat-close">&times;</button>
          </div>
          <div id="chat-messages" class="chat-messages">
            <div class="bot-message">
              Hi! I'm your ShopMate assistant. Ask me about returns, shipping, or anything else!
            </div>
          </div>
          <div class="chat-input-container">
            <input type="text" id="chat-input" placeholder="Type your message..." />
            <button id="chat-send">Send</button>
          </div>
        </div>
      </div>
    `;
    
    document.body.insertAdjacentHTML('beforeend', chatHTML);
  }

  attachEventListeners() {
    document.getElementById('chat-toggle').addEventListener('click', () => this.toggleChat());
    document.getElementById('chat-close').addEventListener('click', () => this.closeChat());
    document.getElementById('chat-send').addEventListener('click', () => this.sendMessage());
    document.getElementById('chat-input').addEventListener('keypress', (e) => {
      if (e.key === 'Enter') this.sendMessage();
    });
  }

  toggleChat() {
    this.isOpen = !this.isOpen;
    const chatWindow = document.getElementById('chat-window');
    chatWindow.style.display = this.isOpen ? 'flex' : 'none';
  }

  closeChat() {
    this.isOpen = false;
    document.getElementById('chat-window').style.display = 'none';
  }

  async sendMessage() {
    const input = document.getElementById('chat-input');
    const message = input.value.trim();
    
    if (!message) return;

    this.addMessage(message, 'user');
    input.value = '';

    try {
      const response = await fetch('/api/ai/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message })
      });

      const data = await response.json();
      this.addMessage(data.response, 'bot');
    } catch (error) {
      this.addMessage('Sorry, I encountered an error. Please try again.', 'bot');
    }
  }

  addMessage(message, sender) {
    const messagesContainer = document.getElementById('chat-messages');
    const messageDiv = document.createElement('div');
    messageDiv.className = `${sender}-message`;
    messageDiv.textContent = message;
    messagesContainer.appendChild(messageDiv);
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
  }
}

// Initialize chat when page loads
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    new AIChat();
  });
} else {
  new AIChat();
}