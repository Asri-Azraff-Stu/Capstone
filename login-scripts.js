document.addEventListener('DOMContentLoaded', () => {
    // Define the base URL for your backend API
    const API_BASE_URL = 'http://localhost:3000/api';

    const loginFormContainer = document.getElementById('login-form-container');
    const signupFormContainer = document.getElementById('signup-form-container');
    const showSignupLink = document.getElementById('show-signup');
    const showLoginLink = document.getElementById('show-login');
    
    // Form Toggling
    showSignupLink.addEventListener('click', (e) => {
        e.preventDefault();
        loginFormContainer.classList.add('hidden');
        signupFormContainer.classList.remove('hidden');
    });
    
    showLoginLink.addEventListener('click', (e) => {
        e.preventDefault();
        signupFormContainer.classList.add('hidden');
        loginFormContainer.classList.remove('hidden');
    });

    // Show/Hide Password
    document.querySelectorAll('.toggle-password').forEach(toggle => {
        toggle.addEventListener('click', () => {
            const targetId = toggle.dataset.target;
            const passwordInput = document.getElementById(targetId);
            if (passwordInput.type === 'password') {
                passwordInput.type = 'text';
                toggle.classList.remove('fa-eye');
                toggle.classList.add('fa-eye-slash');
            } else {
                passwordInput.type = 'password';
                toggle.classList.remove('fa-eye-slash');
                toggle.classList.add('fa-eye');
            }
        });
    });

    // Password Strength Indicator
    const signupPasswordInput = document.getElementById('signupPassword');
    const strengthText = document.getElementById('strength-text');
    const strengthBars = [
        document.getElementById('strength-bar-1'),
        document.getElementById('strength-bar-2'),
        document.getElementById('strength-bar-3'),
        document.getElementById('strength-bar-4')
    ];

    signupPasswordInput.addEventListener('input', () => {
        const password = signupPasswordInput.value;
        let score = 0;
        if (password.length >= 12) score++; // Increased length requirement
        if (/[A-Z]/.test(password)) score++;
        if (/[0-9]/.test(password)) score++;
        if (/[^A-Za-z0-9]/.test(password)) score++;

        strengthBars.forEach((bar, index) => {
            if (index < score) {
                if (score === 1) bar.style.backgroundColor = '#ef4444'; // red-500
                if (score === 2) bar.style.backgroundColor = '#f97316'; // orange-500
                if (score === 3) bar.style.backgroundColor = '#eab308'; // yellow-500
                if (score === 4) bar.style.backgroundColor = '#22c55e'; // green-500
            } else {
                bar.style.backgroundColor = '#e2e8f0'; // slate-200
            }
        });

        const strengthMessages = ['', 'Weak', 'Fair', 'Good', 'Strong'];
        strengthText.textContent = `Strength: ${strengthMessages[score]}`;
    });

    // Login Handler
    const loginForm = document.getElementById('loginForm');
    loginForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const email = loginForm.email.value;
        const password = loginForm.password.value;

        try {
            const response = await fetch(`${API_BASE_URL}/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ email, password }),
            });

            const data = await response.json();

            if (response.ok) {
                // Login successful
                alert(`Login successful! Welcome, ${data.user.fullName} (${data.user.role}).`);
                // Store the token for future authenticated requests
                localStorage.setItem('authToken', data.token);
                localStorage.setItem('currentUser', JSON.stringify(data.user));
                
                // Redirect to the main application page
                window.location.href = 'index.html'; // Assumes main app is named index.html
            } else {
                // Handle login errors (e.g., invalid credentials)
                alert(`Login Failed: ${data.message}`);
            }
        } catch (error) {
            console.error('Login Error:', error);
            alert('Could not connect to the server. Please make sure it is running.');
        }
    });

    // Sign Up Handler
    const signupForm = document.getElementById('signupForm');
    const confirmPasswordInput = document.getElementById('confirmPassword');
    const passwordMatchError = document.getElementById('password-match-error');

    signupForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const fullName = signupForm.fullName.value;
        const email = signupForm.email.value;
        const password = signupPasswordInput.value;
        const confirmPassword = confirmPasswordInput.value;

        // Client-side validation
        if (password !== confirmPassword) {
            passwordMatchError.classList.remove('hidden');
            return;
        }
        passwordMatchError.classList.add('hidden');

        try {
            const response = await fetch(`${API_BASE_URL}/register`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ fullName, email, password }),
            });

            const data = await response.json();

            if (response.status === 201) {
                // Account created successfully
                alert('Account created successfully!\nPlease sign in with your new credentials.');
                
                // Switch back to login form
                signupFormContainer.classList.add('hidden');
                loginFormContainer.classList.remove('hidden');
                signupForm.reset();
                strengthBars.forEach(bar => bar.style.backgroundColor = '#e2e8f0');
                strengthText.textContent = '';
            } else {
                // Handle registration errors (e.g., email already exists)
                alert(`Registration Failed: ${data.message}`);
            }
        } catch (error) {
            console.error('Registration Error:', error);
            alert('Could not connect to the server. Please make sure it is running.');
        }
    });
});
