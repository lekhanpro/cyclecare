"""Chrome-backed SVG rasteriser.

Chrome is used instead of cairosvg because it needs no native libraries on
Windows and it already resolves the base64 @font-face payloads embedded in the
wordmark SVGs, so the PNGs match the vector source exactly.
"""

from __future__ import annotations

import contextlib
from collections import defaultdict
from pathlib import Path

from playwright.sync_api import sync_playwright

# Prefer an installed Chrome/Edge so a run never depends on Playwright's
# bundled browser revision being present.
_BROWSER_CANDIDATES = [
    Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe"),
    Path(r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"),
    Path(r"C:\Program Files\Microsoft\Edge\Application\msedge.exe"),
    Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"),
]

_LAUNCH_ARGS = ["--force-color-profile=srgb", "--font-render-hinting=none"]


def _executable() -> str | None:
    for candidate in _BROWSER_CANDIDATES:
        if candidate.exists():
            return str(candidate)
    return None


@contextlib.contextmanager
def launch_browser(device_scale_factor: float = 1.0, viewport: dict | None = None):
    """Yields (browser, context) using the system browser when available."""
    with sync_playwright() as p:
        kwargs: dict = {"args": _LAUNCH_ARGS}
        executable = _executable()
        if executable:
            kwargs["executable_path"] = executable
        browser = p.chromium.launch(**kwargs)
        context = browser.new_context(
            viewport=viewport or {"width": 1280, "height": 720},
            device_scale_factor=device_scale_factor,
        )
        try:
            yield browser, context
        finally:
            with contextlib.suppress(Exception):
                context.close()
            with contextlib.suppress(Exception):
                browser.close()


def _read(svg_source) -> str:
    if isinstance(svg_source, Path):
        return svg_source.read_text(encoding="utf-8")
    text = str(svg_source)
    if text.lstrip().startswith("<"):
        return text
    return Path(text).read_text(encoding="utf-8")


def _page_html(svg: str, width: float, height: float, background: str | None) -> str:
    bg = background or "transparent"
    return (
        "<!doctype html><html><head><meta charset='utf-8'><style>"
        f"html,body{{margin:0;padding:0;background:{bg};}}"
        f"svg{{display:block;width:{width}px;height:{height}px;}}"
        "</style></head><body>" + svg + "</body></html>"
    )


def rasterize_many(jobs: list[dict], settle_ms: int = 420) -> None:
    """Renders many PNGs, opening one browser context per device scale factor.

    Each job: {svg, out, width, height, scale?, background?}
    """
    if not jobs:
        return

    by_scale: dict[float, list[dict]] = defaultdict(list)
    for job in jobs:
        by_scale[float(job.get("scale", 1.0))].append(job)

    with sync_playwright() as p:
        kwargs: dict = {"args": _LAUNCH_ARGS}
        executable = _executable()
        if executable:
            kwargs["executable_path"] = executable
        browser = p.chromium.launch(**kwargs)

        try:
            for scale, scale_jobs in sorted(by_scale.items()):
                context = browser.new_context(
                    viewport={"width": 800, "height": 600},
                    device_scale_factor=scale,
                )
                page = context.new_page()
                for job in scale_jobs:
                    width = float(job["width"])
                    height = float(job["height"])
                    background = job.get("background")
                    out = Path(job["out"])
                    out.parent.mkdir(parents=True, exist_ok=True)

                    page.set_viewport_size(
                        {"width": max(1, round(width)), "height": max(1, round(height))}
                    )
                    page.set_content(
                        _page_html(_read(job["svg"]), width, height, background)
                    )
                    page.wait_for_timeout(settle_ms)
                    page.screenshot(
                        path=str(out), omit_background=background is None
                    )
                    print(
                        f"  {out.name} "
                        f"{round(width * scale)}x{round(height * scale)}"
                    )
                context.close()
        finally:
            with contextlib.suppress(Exception):
                browser.close()


def rasterize(
    svg_source,
    out_path,
    width: float,
    height: float,
    scale: float = 1.0,
    background: str | None = None,
) -> Path:
    """Single-file convenience wrapper around rasterize_many."""
    rasterize_many(
        [
            {
                "svg": svg_source,
                "out": out_path,
                "width": width,
                "height": height,
                "scale": scale,
                "background": background,
            }
        ]
    )
    return Path(out_path)
