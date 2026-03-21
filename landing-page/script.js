// ── Smooth scrolling ─────────────────────────────────────────────────
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
        // Close mobile menu on link click
        navLinks.classList.remove('active');
        menuToggle.classList.remove('active');
    });
});

// ── Mobile menu toggle ───────────────────────────────────────────────
const menuToggle = document.getElementById('menu-toggle');
const navLinks = document.getElementById('nav-links');

if (menuToggle) {
    menuToggle.addEventListener('click', () => {
        navLinks.classList.toggle('active');
        menuToggle.classList.toggle('active');
    });
}

// ── Navbar scroll effect ─────────────────────────────────────────────
const navbar = document.getElementById('navbar');
let lastScroll = 0;

window.addEventListener('scroll', () => {
    const scrollY = window.scrollY;
    if (scrollY > 60) {
        navbar.classList.add('scrolled');
    } else {
        navbar.classList.remove('scrolled');
    }
    lastScroll = scrollY;
});

// ── Scroll reveal (data-reveal) ──────────────────────────────────────
const revealObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('revealed');
            revealObserver.unobserve(entry.target);
        }
    });
}, {
    threshold: 0.1,
    rootMargin: '0px 0px -60px 0px'
});

document.querySelectorAll('[data-reveal]').forEach(el => {
    revealObserver.observe(el);
});

// ── Hero entrance animation ──────────────────────────────────────────
window.addEventListener('load', () => {
    const heroText = document.getElementById('hero-text');
    const heroVisual = document.getElementById('hero-visual');
    if (heroText) {
        setTimeout(() => heroText.classList.add('revealed'), 200);
    }
    if (heroVisual) {
        setTimeout(() => heroVisual.classList.add('revealed'), 500);
    }
});

// ── Parallax for floating cards ──────────────────────────────────────
const floatCards = document.querySelectorAll('.float-card');
document.addEventListener('mousemove', (e) => {
    const x = (e.clientX / window.innerWidth - 0.5) * 2;
    const y = (e.clientY / window.innerHeight - 0.5) * 2;
    floatCards.forEach((card, i) => {
        const factor = (i + 1) * 4;
        card.style.transform = `translate(${x * factor}px, ${y * factor}px)`;
    });
});
