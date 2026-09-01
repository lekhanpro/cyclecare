"""Renders a contact sheet so the logo can be eyeballed at every size.

Nested SVGs are embedded as base64 data URIs rather than file:// hrefs: Chrome
blocks local file reads from a set_content page, and data URIs also keep each
image's gradient ids in their own document scope.
"""

from __future__ import annotations

import base64
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import brand as B  # noqa: E402
from render import rasterize_many  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
BRAND_DIR = ROOT / "assets" / "brand"
OUT = Path(__file__).resolve().parent / "_preview.png"

W, H = 1500, 1180


def data_uri(path: Path) -> str:
    encoded = base64.b64encode(path.read_bytes()).decode("ascii")
    return f"data:image/svg+xml;base64,{encoded}"


def main() -> None:
    parts: list[str] = [f'<rect width="{W}" height="{H}" fill="{B.CREAM}"/>']

    def text(value: str, x: int, y: int, color: str = B.MUTED, size: int = 20) -> None:
        parts.append(
            f'<text x="{x}" y="{y}" font-family="Nunito, Segoe UI, sans-serif" '
            f'font-weight="700" font-size="{size}" fill="{color}">{value}</text>'
        )

    def img(name: str, x: float, y: float, w: float, h: float | None = None) -> None:
        uri = data_uri(BRAND_DIR / name)
        height = h if h is not None else w
        parts.append(
            f'<image href="{uri}" x="{x:g}" y="{y:g}" '
            f'width="{w:g}" height="{height:g}"/>'
        )

    # ── Row 1: primary mark, descending sizes, baseline-aligned ──────────────
    text("Primary mark on cream", 48, 52, B.INK, 26)
    x = 48
    row_bottom = 272
    for size in (192, 128, 96, 64, 48, 32, 24, 16):
        img("cyclecare-mark.svg", x, row_bottom - size, size)
        text(str(size), x, row_bottom + 28, B.SUBTLE, 16)
        x += size + 34

    # ── Row 2: variants ──────────────────────────────────────────────────────
    text("Variants", 48, 372, B.INK, 26)
    tiles = [
        ("cyclecare-mark.svg", B.WHITE, "on white"),
        ("cyclecare-mark-white.svg", B.DARK_BG, "on dark"),
        ("cyclecare-mark-phases.svg", B.WHITE, "four phases"),
        ("cyclecare-mark-mono.svg", B.WHITE, "monochrome"),
    ]
    tx = 48
    for name, bg, label in tiles:
        parts.append(
            f'<rect x="{tx}" y="396" width="200" height="200" rx="28" fill="{bg}"/>'
        )
        img(name, tx + 20, 416, 160)
        text(label, tx, 626, B.MUTED, 16)
        tx += 224

    # App icon at launcher sizes.
    img("cyclecare-icon.svg", 992, 396, 200)
    text("app icon", 992, 626, B.MUTED, 16)
    img("cyclecare-icon.svg", 1216, 396, 96)
    text("96", 1216, 626, B.MUTED, 16)
    img("cyclecare-icon.svg", 1216, 508, 48)
    text("48", 1330, 626, B.MUTED, 16)

    # ── Row 3: wordmarks ─────────────────────────────────────────────────────
    text("Wordmark", 48, 706, B.INK, 26)
    wm = BRAND_DIR / "cyclecare-wordmark.svg"
    # Preserve the wordmark's aspect ratio from its own declared size.
    import re

    head = wm.read_text(encoding="utf-8")[:400]
    vb = re.search(r'viewBox="0 0 ([\d.]+) ([\d.]+)"', head)
    ratio = (float(vb.group(1)) / float(vb.group(2))) if vb else 4.0

    wm_h = 76
    img("cyclecare-wordmark.svg", 48, 730, wm_h * ratio, wm_h)

    parts.append(
        f'<rect x="24" y="838" width="{wm_h * ratio + 48:.0f}" height="124" '
        f'rx="22" fill="{B.DARK_BG}"/>'
    )
    img("cyclecare-wordmark-dark.svg", 48, 862, wm_h * ratio, wm_h)

    # ── Row 4: favicon realism check ─────────────────────────────────────────
    text("Browser tab / launcher realism", 48, 1030, B.INK, 26)
    fx = 48
    for size in (16, 20, 24, 32, 40, 48):
        parts.append(
            f'<rect x="{fx - 6}" y="{1060 - 6}" width="{size + 12}" '
            f'height="{size + 12}" rx="8" fill="{B.WHITE}"/>'
        )
        img("cyclecare-icon.svg", fx, 1060, size)
        fx += size + 34

    svg = (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" '
        f'width="{W}" height="{H}">' + "".join(parts) + "</svg>"
    )

    rasterize_many(
        [
            {
                "svg": svg,
                "out": OUT,
                "width": W,
                "height": H,
                "scale": 1,
                "background": B.CREAM,
            }
        ],
        settle_ms=1200,
    )
    print(f"preview -> {OUT}")


if __name__ == "__main__":
    main()
