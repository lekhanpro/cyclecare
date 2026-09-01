# CycleCare brand kit

Everything here is generated. Edit the geometry or palette in
[`tool/brand/brand.py`](../../tool/brand/brand.py) and regenerate — never hand-edit
the SVGs or PNGs.

```bash
python tool/brand/generate_svg.py     # vector sources
python tool/brand/measure_wordmark.py # tighten the wordmark viewBox
python tool/brand/rasterize.py        # every PNG, all platforms
python tool/brand/preview.py          # contact sheet for eyeballing
```

## The mark

An open ring — the cycle — broken at its east point by a single round marker:
today's position on that cycle. A heart sits in the counter, so the silhouette
also reads as a **C**. The ring is 54 units wide on a 512 grid with round caps,
and the heart clears the ring's inner edge by a visible margin so it survives
being scaled to a favicon.

## Files

| File | Use |
| --- | --- |
| `cyclecare-mark.svg` | Primary mark, rose gradient. Default choice. |
| `cyclecare-mark-white.svg` | Knockout for dark or coloured backgrounds. |
| `cyclecare-mark-mono.svg` | Single-colour ink, for print or one-colour contexts. |
| `cyclecare-mark-phases.svg` | Ring split into the four cycle phases. Docs and illustrations only, not the app identity. |
| `cyclecare-icon.svg` | Rose tile with a squircle radius — launcher and favicon source. |
| `cyclecare-icon-foreground.svg` | Android adaptive foreground, transparent. |
| `cyclecare-wordmark.svg` | Mark plus name, for light backgrounds. |
| `cyclecare-wordmark-dark.svg` | Same, for dark backgrounds. |
| `cyclecare-social-preview.png` | 1280×640 GitHub social preview. |
| `cyclecare-mark-{64…1024}.png` | Raster mark on transparency. |

The wordmark SVGs embed Nunito as base64, so they rasterise identically whether
or not the font is installed. That is why they are ~65 KB — use the PNGs on the
web.

## Palette

Lifted from [`lib/core/theme/app_colors.dart`](../../lib/core/theme/app_colors.dart).
If those change, change `brand.py` to match.

| Role | Hex |
| --- | --- |
| Rose (primary) | `#E86F91` |
| Rose light (gradient end) | `#FF8FAB` |
| Rose deep (heart) | `#D9577D` |
| Ink (text) | `#2D2530` |
| Cream (canvas) | `#FFF8F6` |
| Fertile | `#3DBFA0` |
| Follicular | `#4AABDB` |
| Ovulation | `#9B7FE8` |
| Luteal | `#FFB199` |

Typeface is **Nunito**, ExtraBold (800) for the wordmark.

## Rules

- Keep clear space around the mark equal to the ring's stroke width.
- Never recolour the mark outside the variants above, and never add effects.
- Never stretch it — the ring must stay circular.
- Below 32 px use `cyclecare-icon.svg` rather than the bare mark; the tile holds
  the shape together at small sizes.
- On rose or other saturated backgrounds use the white knockout, not the
  gradient mark.
