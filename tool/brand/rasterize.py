"""Renders every PNG the project needs from the generated brand SVGs.

Covers the brand kit, the Flutter launcher-icon sources, the web/PWA icons and
the platform icon sets for Android and iOS. Existing filenames and pixel sizes
are matched exactly so the output is a drop-in replacement.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from PIL import Image  # noqa: E402

import brand as B  # noqa: E402
import generate_svg as G  # noqa: E402
from render import rasterize_many  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
BRAND = ROOT / "assets" / "brand"
IMAGES = ROOT / "assets" / "images"
WEB = ROOT / "web"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
IOS_ICONS = (
    ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
)

# Android launcher densities -> px
MIPMAP = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
# Android adaptive foreground densities -> px
DRAWABLE = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
# iOS AppIcon set, mirroring Contents.json
IOS = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}

# Superseded by the cyclecare-* naming; removed so the kit has one source of truth.
STALE_BRAND_FILES = [
    "logomark.svg",
    "logomark-white.svg",
    "logomark-ink.svg",
    "logomark-512.png",
    "logomark-256.png",
    "logomark-128.png",
    "logomark-white-512.png",
    "logomark-ink-512.png",
    "app-icon.svg",
    "app-icon-foreground.svg",
    "app-icon-1024.png",
    "app-icon-512.png",
    "app-icon-foreground-1024.png",
]


def _wordmark_size(name: str) -> tuple[float, float]:
    head = (BRAND / name).read_text(encoding="utf-8")[:400]
    match = re.search(r'viewBox="0 0 ([\d.]+) ([\d.]+)"', head)
    if not match:
        return 660.0, 180.0
    return float(match.group(1)), float(match.group(2))


def jobs() -> list[dict]:
    out: list[dict] = []

    def add(svg, path: Path, size: float, height: float | None = None, scale=1.0):
        out.append(
            {
                "svg": svg,
                "out": path,
                "width": size,
                "height": height if height is not None else size,
                "scale": scale,
            }
        )

    # ── Brand kit ────────────────────────────────────────────────────────────
    for size in (1024, 512, 256, 128, 64):
        add(BRAND / "cyclecare-mark.svg", BRAND / f"cyclecare-mark-{size}.png", size)
    add(BRAND / "cyclecare-mark-white.svg", BRAND / "cyclecare-mark-white-512.png", 512)
    add(BRAND / "cyclecare-mark-mono.svg", BRAND / "cyclecare-mark-mono-512.png", 512)
    add(BRAND / "cyclecare-mark-phases.svg", BRAND / "cyclecare-mark-phases-512.png", 512)
    add(BRAND / "cyclecare-icon.svg", BRAND / "cyclecare-icon-1024.png", 1024)
    add(BRAND / "cyclecare-icon.svg", BRAND / "cyclecare-icon-512.png", 512)

    for name, png in (
        ("cyclecare-wordmark.svg", "cyclecare-wordmark.png"),
        ("cyclecare-wordmark-dark.svg", "cyclecare-wordmark-dark.png"),
    ):
        w, h = _wordmark_size(name)
        add(BRAND / name, BRAND / png, w, h, scale=2)

    add(
        BRAND / "cyclecare-social-preview.svg",
        BRAND / "cyclecare-social-preview.png",
        G.SOCIAL_W,
        G.SOCIAL_H,
    )

    # ── Flutter launcher-icon sources ────────────────────────────────────────
    add(G.app_icon_square(1024), IMAGES / "app_icon.png", 1024)
    add(G.app_icon_foreground(1024), IMAGES / "app_icon_foreground.png", 1024)

    # ── Web / PWA ────────────────────────────────────────────────────────────
    add(BRAND / "cyclecare-icon.svg", WEB / "favicon.png", 32)
    add(BRAND / "cyclecare-icon.svg", WEB / "icons" / "Icon-192.png", 192)
    add(BRAND / "cyclecare-icon.svg", WEB / "icons" / "Icon-512.png", 512)
    add(G.app_icon_maskable(192), WEB / "icons" / "Icon-maskable-192.png", 192)
    add(G.app_icon_maskable(512), WEB / "icons" / "Icon-maskable-512.png", 512)

    # ── Android ──────────────────────────────────────────────────────────────
    for density, px in MIPMAP.items():
        add(G.app_icon(1024), ANDROID_RES / f"mipmap-{density}" / "ic_launcher.png", px)
        add(
            G.app_icon_round(1024),
            ANDROID_RES / f"mipmap-{density}" / "ic_launcher_round.png",
            px,
        )
    for density, px in DRAWABLE.items():
        add(
            G.app_icon_foreground(1024),
            ANDROID_RES / f"drawable-{density}" / "ic_launcher_foreground.png",
            px,
        )

    # ── iOS (flattened to opaque RGB afterwards) ─────────────────────────────
    for filename, px in IOS.items():
        add(G.app_icon_square(1024), IOS_ICONS / filename, px)

    return out


def flatten_ios_icons() -> None:
    """iOS rejects icons with an alpha channel, so composite onto the brand rose."""
    background = tuple(int(B.ROSE[i : i + 2], 16) for i in (1, 3, 5))
    for filename in IOS:
        path = IOS_ICONS / filename
        if not path.exists():
            continue
        with Image.open(path) as im:
            rgba = im.convert("RGBA")
            flat = Image.new("RGB", rgba.size, background)
            flat.paste(rgba, mask=rgba.split()[3])
            flat.save(path, format="PNG", optimize=True)
    print(f"  flattened {len(IOS)} iOS icons to opaque RGB")


def sync_legacy_svg() -> None:
    """assets/images/app_icon.svg is referenced by docs/ - keep it on-brand."""
    target = IMAGES / "app_icon.svg"
    target.write_text(G.app_icon(1024), encoding="utf-8")
    print(f"  refreshed {target.relative_to(ROOT).as_posix()}")


def remove_stale() -> None:
    removed = 0
    for name in STALE_BRAND_FILES:
        path = BRAND / name
        if path.exists():
            path.unlink()
            removed += 1
    if removed:
        print(f"  removed {removed} superseded brand files")


def main() -> None:
    print("rasterising brand assets")
    rasterize_many(jobs())
    flatten_ios_icons()
    sync_legacy_svg()
    remove_stale()
    print("done")


if __name__ == "__main__":
    main()
