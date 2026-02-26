# CycleCare Landing Page

A beautiful, modern landing page for the CycleCare menstrual cycle tracking app.

## 🎨 Features

- **Responsive Design** - Works perfectly on all devices
- **Modern UI** - Clean, professional design with smooth animations
- **Fast Loading** - Optimized for performance
- **SEO Friendly** - Proper meta tags and semantic HTML
- **Accessible** - WCAG compliant markup
- **Custom Fonts** - Google Fonts (Inter & Poppins)

## 🚀 Quick Start

### View Locally

Simply open `index.html` in your web browser:

```bash
cd landing-page
# Then open index.html in your browser
```

Or use a local server:

```bash
# Python
python -m http.server 8000

# Node.js
npx serve

# PHP
php -S localhost:8000
```

Then visit `http://localhost:8000`

## 📁 File Structure

```
landing-page/
├── index.html      # Main HTML file
├── styles.css      # All styles
├── script.js       # JavaScript functionality
└── README.md       # This file
```

## 🎨 Design System

### Colors

```css
--primary: #E91E63        /* Vibrant Pink */
--primary-dark: #C2185B   /* Deep Pink */
--secondary: #9C27B0      /* Purple */
--accent: #26A69A         /* Teal */
--period-red: #E53935     /* Period indicator */
--fertile-green: #66BB6A  /* Fertile window */
--ovulation-blue: #42A5F5 /* Ovulation day */
```

### Typography

- **Headings**: Poppins (Bold/SemiBold)
- **Body**: Inter (Regular/Medium)

### Spacing

- Container max-width: 1200px
- Section padding: 100px vertical
- Card padding: 32px
- Gap between elements: 16px, 24px, 32px

## 🌐 Deployment

### GitHub Pages

1. Push to GitHub repository
2. Go to Settings → Pages
3. Select source branch and folder
4. Your site will be live at `https://username.github.io/repo-name`

### Netlify

```bash
# Drag and drop the landing-page folder to Netlify
# Or use CLI:
npm install -g netlify-cli
netlify deploy --prod
```

### Vercel

```bash
npm install -g vercel
cd landing-page
vercel --prod
```

### Traditional Hosting

Upload all files to your web server:
- index.html
- styles.css
- script.js

## 🔧 Customization

### Update Colors

Edit the CSS variables in `styles.css`:

```css
:root {
    --primary: #YOUR_COLOR;
    --secondary: #YOUR_COLOR;
    /* ... */
}
```

### Update Content

Edit text directly in `index.html`:

```html
<h1 class="hero-title">
    Your Custom Title
</h1>
```

### Update Download Link

Find and update the download button href:

```html
<a href="YOUR_APK_URL" class="btn-download">
    Download APK
</a>
```

### Add Analytics

Add before closing `</body>` tag:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

## 📱 Responsive Breakpoints

- **Desktop**: > 968px
- **Tablet**: 768px - 968px
- **Mobile**: < 768px

## ✨ Features Included

### Navigation
- Fixed navbar with blur effect
- Smooth scroll to sections
- Mobile-responsive menu

### Hero Section
- Eye-catching gradient background
- Call-to-action buttons
- Stats display
- Phone mockup with app preview

### Features Section
- 6 feature cards with icons
- Hover animations
- Grid layout

### About Section
- Benefits list with checkmarks
- Feature showcase cards
- Two-column layout

### Download Section
- Prominent download button
- Version information
- Gradient background

### Footer
- Multi-column layout
- Links to resources
- Branding

## 🎭 Animations

- Smooth scroll
- Fade-in on scroll (Intersection Observer)
- Hover effects on cards and buttons
- Navbar background change on scroll

## 🌍 Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
- Mobile browsers (iOS Safari, Chrome Mobile)

## 📊 Performance

- No external dependencies (except Google Fonts)
- Optimized CSS
- Minimal JavaScript
- Fast loading time

## 🔒 Privacy

- No tracking scripts
- No cookies
- No external analytics (unless you add them)

## 📝 License

Free to use for personal and commercial projects.

## 🤝 Contributing

Feel free to customize and improve the landing page!

## 📧 Support

For issues or questions, please open an issue on GitHub.

---

Made with ❤️ for CycleCare
