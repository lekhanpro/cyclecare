"""Measures the rendered wordmark text in Chrome so the SVG viewBox is tight.

Guessing glyph advances by hand leaves the wordmark either clipped or padded
with dead space. Chrome already has the embedded font, so it can report the
exact bounding box via getBBox().
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import brand as B  # noqa: E402
import generate_svg as G  # noqa: E402
from render import launch_browser  # noqa: E402

OUT = Path(__file__).resolve().parent / "_wordmark_width.txt"
RIGHT_PADDING = 6.0


def main() -> None:
    # Render at a deliberately oversized width so nothing clips while measuring.
    probe = G.wordmark_light(2000)
    html = (
        "<!doctype html><html><body style='margin:0'>"
        + probe.replace('width="2000"', 'width="2000" id="wm"')
        + "</body></html>"
    )

    with launch_browser() as (browser, context):
        page = context.new_page()
        page.set_content(html)
        page.wait_for_timeout(600)  # let the embedded woff2 decode
        box = page.evaluate(
            "() => { const t = document.querySelector('text');"
            " const b = t.getBBox();"
            " return { x: b.x, width: b.width }; }"
        )
        browser.close()

    total = box["x"] + box["width"] + RIGHT_PADDING
    OUT.write_text(f"{total:.2f}\n", encoding="utf-8")
    print(f"text x={box['x']:.2f} width={box['width']:.2f} -> canvas {total:.2f}")


if __name__ == "__main__":
    main()
