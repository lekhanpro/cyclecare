"""Shared brand geometry and palette for CycleCare's generated assets.

Every colour here is lifted directly from lib/core/theme/app_colors.dart so the
logo can never drift from the running app's palette.
"""

from __future__ import annotations

import base64
import math
from pathlib import Path

# ── Palette (mirrors lib/core/theme/app_colors.dart) ─────────────────────────
ROSE = "#E86F91"          # AppColors.period / AppPalette.pinkRose.seed
ROSE_LIGHT = "#FF8FAB"    # menstrualGradient end stop
ROSE_DARK = "#D9577D"     # AppColors.roseDark
ROSE_TINT = "#FCE4EC"     # AppColors.periodLight

FOLLICULAR = "#4AABDB"    # AppColors.info / follicularGradient start
FERTILE = "#3DBFA0"       # AppColors.fertile
OVULATION = "#9B7FE8"     # AppColors.ovulation
LUTEAL = "#FFB199"        # AppColors.luteal

INK = "#2D2530"           # AppColors.ink
MUTED = "#81747F"         # AppColors.muted
SUBTLE = "#B0A4AE"        # AppColors.subtle
LINE = "#F0DEE5"          # AppColors.line
CREAM = "#FFF8F6"         # AppColors.cream - scaffold background
WHITE = "#FFFFFF"

DARK_BG = "#1A1520"       # AppColors.darkBg
DARK_CARD = "#2E2736"     # AppColors.darkCard
DARK_TEXT = "#F5F0F8"     # AppColors.darkText

PHASE_COLORS = [ROSE, FOLLICULAR, OVULATION, LUTEAL]

# ── Mark geometry ─────────────────────────────────────────────────────────────
# The mark is an open ring - the cycle - broken at the east point by a single
# round marker: today's position on that cycle. A heart sits in the counter, so
# the silhouette also reads as a "C". Drawn in a 512 box with the artwork
# occupying 59..453 on both axes (symmetric 59px of breathing room).
SIZE = 512
CX = CY = 256.0
RING_R = 170.0
RING_W = 54.0
RING_GAP_DEG = 64.0          # opening centred on the east point
DOT_R = 27.0                 # == RING_W / 2, so the marker sits flush
ART_MIN = CX - RING_R - RING_W / 2   # 59.0
ART_MAX = CX + RING_R + RING_W / 2   # 453.0
ART_SPAN = ART_MAX - ART_MIN         # 394.0

# Heart, tuned by hand to sit inside the ring counter with even optical spacing.
HEART_PATH = (
    "M 256 324 "
    "C 214 292, 176 262, 176 226 "
    "C 176 200, 196 184, 218 184 "
    "C 236 184, 250 196, 256 210 "
    "C 262 196, 276 184, 294 184 "
    "C 316 184, 336 200, 336 226 "
    "C 336 262, 298 292, 256 324 Z"
)

# The base path leaves the ring's counter looking hollow. Scaling it up about
# its own optical centre fills the space and keeps the heart legible once the
# mark is rendered at favicon sizes. 1.18 is the largest factor that still
# clears the ring's inner edge (143px) by a visible margin.
HEART_SCALE = 1.18
HEART_ORIGIN = (256.0, 254.0)


def heart_transform() -> str:
    """Scales the heart about its optical centre."""
    ox, oy = HEART_ORIGIN
    return (
        f"translate({ox:g} {oy:g}) scale({HEART_SCALE:g}) translate({-ox:g} {-oy:g})"
    )


def _rgb(hex_color: str) -> tuple[int, int, int]:
    h = hex_color.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def mix(a: str, b: str, t: float) -> str:
    """Linear blend between two hex colours, t=0 -> a, t=1 -> b."""
    ra, ga, ba = _rgb(a)
    rb, gb, bb = _rgb(b)
    return "#{:02X}{:02X}{:02X}".format(
        round(ra + (rb - ra) * t),
        round(ga + (gb - ga) * t),
        round(ba + (bb - ba) * t),
    )


def on_light(color: str) -> str:
    """Darkens a phase colour enough to read as body text on a light surface.

    Mirrors PhaseColors._build in lib/core/theme/phase_colors.dart, which pulls
    each phase colour toward ink for exactly this reason - the luteal coral is
    unreadable at full saturation on cream.
    """
    return mix(color, INK, 0.42)


def polar(angle_deg: float, radius: float = RING_R) -> tuple[float, float]:
    """Point on the ring centreline at *angle_deg*, measured from east."""
    rad = math.radians(angle_deg)
    return (
        round(CX + radius * math.cos(rad), 3),
        round(CY + radius * math.sin(rad), 3),
    )


def arc_path(start_deg: float, end_deg: float, radius: float = RING_R) -> str:
    """Stroked circular arc sweeping clockwise from *start_deg* to *end_deg*."""
    x1, y1 = polar(start_deg, radius)
    x2, y2 = polar(end_deg, radius)
    large = 1 if (end_deg - start_deg) % 360 > 180 else 0
    return f"M {x1} {y1} A {radius} {radius} 0 {large} 1 {x2} {y2}"


def ring_path() -> str:
    """The single open arc used by the primary mark."""
    return arc_path(RING_GAP_DEG / 2, 360 - RING_GAP_DEG / 2)


def phase_arcs(gap_deg: float = 6.0) -> list[str]:
    """The ring split into four phase arcs with hairline gaps between them."""
    start = RING_GAP_DEG / 2
    total = 360 - RING_GAP_DEG
    span = (total - gap_deg * 3) / 4
    arcs = []
    for i in range(4):
        a0 = start + i * (span + gap_deg)
        arcs.append(arc_path(a0, a0 + span))
    return arcs


def dot_center() -> tuple[float, float]:
    """The today-marker: dead centre of the ring's opening."""
    return polar(0.0)


def scale_to(target_span: float, canvas: float) -> str:
    """SVG transform that centres the mark at *target_span* px on a canvas."""
    scale = target_span / ART_SPAN
    offset = canvas / 2 - CX * scale
    return f"translate({offset:.3f} {offset:.3f}) scale({scale:.5f})"


# ── Font embedding ───────────────────────────────────────────────────────────
FONT_DIR = Path(__file__).resolve().parent.parent / "fonts"
_FONT_FILES = {800: "nunito-800.woff2", 700: "nunito-700.woff2", 600: "nunito-600.woff2"}


def font_face_css() -> str:
    """@font-face blocks with Nunito inlined as base64.

    Embedding keeps the wordmark SVGs self-contained: they rasterise to
    pixel-identical PNGs whether or not Nunito is installed locally.
    """
    blocks = []
    for weight, filename in _FONT_FILES.items():
        path = FONT_DIR / filename
        if not path.exists():
            continue
        encoded = base64.b64encode(path.read_bytes()).decode("ascii")
        blocks.append(
            "@font-face{font-family:'Nunito';font-style:normal;"
            f"font-weight:{weight};font-display:block;"
            f"src:url(data:font/woff2;base64,{encoded}) format('woff2');}}"
        )
    return "".join(blocks)


def has_fonts() -> bool:
    return all((FONT_DIR / name).exists() for name in _FONT_FILES.values())
