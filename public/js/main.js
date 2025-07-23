// Client-side JavaScript for ShopMate

document.addEventListener('DOMContentLoaded', function() {
  // Quantity input validation
  const quantityInputs = document.querySelectorAll('input[type="number"]');
  quantityInputs.forEach(input => {
    input.addEventListener('change', function() {
      const min = parseInt(this.getAttribute('min'));
      const max = parseInt(this.getAttribute('max'));
      const value = parseInt(this.value);
      
      if (value < min) {
        this.value = min;
      } else if (value > max) {
        this.value = max;
      }
    });
  });
  
  // Handle quantity control buttons
  const decreaseButtons = document.querySelectorAll('.quantity-btn.decrease');
  const increaseButtons = document.querySelectorAll('.quantity-btn.increase');
  
  decreaseButtons.forEach(button => {
    button.addEventListener('click', function() {
      const input = this.parentNode.querySelector('input[type="number"]');
      const min = parseInt(input.getAttribute('min'));
      const currentValue = parseInt(input.value);
      
      if (currentValue > min) {
        input.value = currentValue - 1;
        input.dispatchEvent(new Event('change'));
      }
    });
  });
  
  increaseButtons.forEach(button => {
    button.addEventListener('click', function() {
      const input = this.parentNode.querySelector('input[type="number"]');
      const max = parseInt(input.getAttribute('max'));
      const currentValue = parseInt(input.value);
      
      if (currentValue < max) {
        input.value = currentValue + 1;
        input.dispatchEvent(new Event('change'));
      }
    });
  });
  
  // Auto-submit quantity update forms
  const quantityForms = document.querySelectorAll('.quantity-form');
  quantityForms.forEach(form => {
    const input = form.querySelector('input[type="number"]');
    const originalValue = input.value;
    
    input.addEventListener('change', function() {
      if (this.value !== originalValue) {
        // Add a small delay to allow user to make multiple adjustments
        clearTimeout(this.timeout);
        this.timeout = setTimeout(() => {
          form.submit();
        }, 500);
      }
    });
  });
});