#!/usr/bin/env python3
"""
Generate CycleCare app icon as a simple SVG, then convert to PNG sizes.
Run: python scripts/generate_icon.py
Requires: pip install cairosvg pillow (optional - SVG output works without)
"""

import os

SVG = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <!-- Background -->
  <rect width="1024" height="1024" rx="230" fill="#E86F91"/>
  <!-- Heart -->
  <path d="M512 720 C512 720 280 560 280 400 C280 320 340 260 420 260 C460 260 496 278 512 300 C528 278 564 260 604 260 C684 260 744 320 744 400 C744 560 512 720 512 720Z" fill="white" opacity="0.95"/>
  <!-- Cycle dots -->
  <circle cx="512" cy="200" r="28" fill="white" opacity="0.7"/>
  <circle cx="680" cy="260" r="20" fill="white" opacity="0.5"/>
  <circle cx="344" cy="260" r="20" fill="white" opacity="0.5"/>
</svg>'''

os.makedirs("assets/images", exist_ok=True)
with open("assets/images/app_icon.svg", "w") as f:
    f.write(SVG)
print("SVG icon written to assets/images/app_icon.svg")

# Try to generate PNG if pillow/cairosvg available
try:
    import cairosvg
    sizes = [48, 72, 96, 144, 192, 512, 1024]
    for size in sizes:
        out = f"assets/images/icon_{size}.png"
        cairosvg.svg2png(bytestring=SVG.encode(), write_to=out, output_width=size, output_height=size)
        print(f"Generated {out}")
except ImportError:
    print("cairosvg not installed - SVG only. Install with: pip install cairosvg")
    print("You can convert the SVG manually at https://svgtopng.com")
