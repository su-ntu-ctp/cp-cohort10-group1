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
  
  // Auto-submit quantity update forms
  const quantityForms = document.querySelectorAll('.quantity-form');
  quantityForms.forEach(form => {
    const input = form.querySelector('input[type="number"]');
    const originalValue = input.value;
    
    input.addEventListener('change', function() {
      if (this.value !== originalValue) {
        form.submit();
      }
    });
  });
});