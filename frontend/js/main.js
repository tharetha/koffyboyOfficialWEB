// Splash Screen Logic
const greetings = [
    "Hello...",
    "How are you today?",
    "Vibes...",
    "Zaazuu...",
    "Muli bwanji",
    "Shani"
];

function initSplashScreen() {
    const splashScreen = document.getElementById('splash-screen');
    const greetingEl = document.getElementById('splash-greeting');

    if (splashScreen && greetingEl) {
        let count = 0;
        const interval = setInterval(() => {
            greetingEl.textContent = greetings[count % greetings.length];
            count++;
        }, 800);

        setTimeout(() => {
            clearInterval(interval);
            splashScreen.style.opacity = '0';
            setTimeout(() => {
                splashScreen.style.display = 'none';
            }, 500);
        }, 4000); // Hide after 4 seconds
    }
}

// User Auth State
function checkAuthState() {
    const user = JSON.parse(localStorage.getItem('koffy_user'));
    const authButtons = document.querySelector('.auth-buttons');
    const userProfile = document.querySelector('.user-profile');

    if (user && authButtons) {
        authButtons.classList.add('hidden');
        if (userProfile) {
            userProfile.classList.remove('hidden');
            userProfile.innerHTML = `
                <span style="color:var(--text-secondary); font-size:0.9rem;">Hi, ${user.first_name || 'User'}</span>
                <a href="account.html" style="margin-left:0.8rem; color:var(--text-primary); text-decoration:none; font-size:0.9rem; padding:0.3rem 0.8rem; border:1px solid var(--border-color); border-radius:20px; transition:all 0.2s;" onmouseover="this.style.borderColor='var(--primary-color)';this.style.color='var(--primary-color)'" onmouseout="this.style.borderColor='var(--border-color)';this.style.color='var(--text-primary)'">Account</a>
                <a href="#" onclick="logout()" style="margin-left:0.5rem; color:var(--primary-color); font-size:0.9rem;">Logout</a>
            `;
        }
    } else {
        // Guest user: Start 5-minute timer for login prompt
        startGuestTimer();
    }
}

let guestTimer;
function startGuestTimer() {
    if (localStorage.getItem('koffy_prompted')) return;
    
    guestTimer = setTimeout(() => {
        showLoginPrompt();
    }, 300000); // 5 minutes
}

function showLoginPrompt() {
    const modal = document.createElement('div');
    modal.id = 'guest-prompt-modal';
    // Use the custom modal CSS we already added in account.html but make it generic or add here
    modal.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.85);backdrop-filter:blur(8px);display:flex;justify-content:center;align-items:center;z-index:2000;';
    modal.innerHTML = `
        <div style="background:#1a1a1a; padding:2rem; border-radius:20px; width:100%; max-width:400px; border:1px solid #333; text-align:center;">
            <h3 style="margin-bottom:0.5rem;">Enjoying the vibe?</h3>
            <p style="color:#888; margin-bottom:1.5rem; font-size:0.9rem;">Register now to get full access to exclusive tracks and events!</p>
            <div style="display:flex; gap:1rem; justify-content:center;">
                <a href="signup.html" style="background:#ff3366; color:white; padding:0.8rem 1.5rem; border-radius:8px; text-decoration:none; font-weight:700;">Join the Fam</a>
                <button onclick="closePrompt()" style="background:transparent; border:1px solid #333; color:#888; padding:0.8rem 1.5rem; border-radius:8px; cursor:pointer;">Maybe Later</button>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
    localStorage.setItem('koffy_prompted', 'true');
}

function closePrompt() {
    const m = document.getElementById('guest-prompt-modal');
    if (m) m.remove();
}

async function fetchWithAuth(url, options = {}) {
    const token = localStorage.getItem('koffy_token');
    if (token) {
        options.headers = {
            ...options.headers,
            'Authorization': `Bearer ${token}`
        };
    }
    return fetch(url, options);
}

function logout() {
    localStorage.removeItem('koffy_user');
    localStorage.removeItem('koffy_token');
    window.location.href = 'index.html';
}

// Highlights Slider Logic
let currentSlide = 0;
let slideInterval;

function showSlide(index) {
    const slides = document.getElementById('slides');
    if (!slides) return;
    
    const totalSlides = slides.children.length;
    
    if (index >= totalSlides) {
        currentSlide = 0;
    } else if (index < 0) {
        currentSlide = totalSlides - 1;
    } else {
        currentSlide = index;
    }
    
    slides.style.transform = `translateX(-${currentSlide * 100}%)`;
}

function moveSlide(step) {
    showSlide(currentSlide + step);
    resetSlideInterval();
}

function startSlideInterval() {
    slideInterval = setInterval(() => {
        showSlide(currentSlide + 1);
    }, 5000);
}

function resetSlideInterval() {
    clearInterval(slideInterval);
    startSlideInterval();
}

async function startPaystackPayment(amount, type, metadata = {}) {
    try {
        const user = JSON.parse(localStorage.getItem('koffy_user'));
        const res = await fetchWithAuth('/api/payments/initialize', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                amount: amount,
                email: user.email,
                metadata: { ...metadata, type: type }
            })
        });

        const data = await res.json();
        if (res.ok && data.checkout_url) {
            // Redirect user to Paystack checkout
            window.location.href = data.checkout_url;
        } else {
            alert('Payment initialization failed: ' + (data.error || 'Unknown error'));
        }
    } catch (err) {
        console.error(err);
        alert('Server error during payment initialization.');
    }
}

document.addEventListener('DOMContentLoaded', () => {
    initSplashScreen();
    checkAuthState();
    
    // Mobile Menu Toggle
    console.log('Main.js loaded, checking for mobile menu...');
    const mobileMenu = document.getElementById('mobile-menu');
    const navContainer = document.getElementById('nav-container');
    
    if (mobileMenu && navContainer) {
        console.log('Mobile menu found, initializing listeners...');
        // Create overlay if it doesn't exist
        let overlay = document.querySelector('.nav-overlay');
        if (!overlay) {
            overlay = document.createElement('div');
            overlay.className = 'nav-overlay';
            document.body.appendChild(overlay);
        }

        const toggleMenu = (e) => {
            if (e) e.preventDefault();
            console.log('Toggle menu triggered');
            mobileMenu.classList.toggle('active');
            navContainer.classList.toggle('active');
            overlay.classList.toggle('active');
            document.body.classList.toggle('nav-active');
            document.body.style.overflow = navContainer.classList.contains('active') ? 'hidden' : '';
        };

        mobileMenu.addEventListener('click', toggleMenu);
        overlay.addEventListener('click', toggleMenu);

        // Prevent clicks inside the sidebar from bubbling up to the overlay/nav
        navContainer.addEventListener('click', (e) => {
            e.stopPropagation();
        });

        // Verify links are clickable and logged
        const navLinks = navContainer.querySelectorAll('a');
        navLinks.forEach(link => {
            link.addEventListener('click', (e) => {
                console.log('Navigating to:', link.getAttribute('href'));
                // Explicitly allow navigation and stop any further bubbling
                e.stopPropagation();
            });
        });
    }

    // Initialize Slider if it exists on the page
    if (document.getElementById('slides')) {
        showSlide(0);
        startSlideInterval();
    }
});
