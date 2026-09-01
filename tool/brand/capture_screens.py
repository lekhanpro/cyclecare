"""Captures real CycleCare screens from the Flutter web build.

These are genuine renders of the app's widgets driven by the demo history seeded
in main_shots.dart - not mockups. Two builds are served (light and dark theme)
and each route is deep-linked via the hash router.
"""

from __future__ import annotations

import functools
import http.server
import socketserver
import sys
import threading
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from render import _LAUNCH_ARGS, _executable  # noqa: E402
from playwright.sync_api import sync_playwright  # noqa: E402

SCRATCH = Path(r"D:\_cyclecare_shots")
OUT_DIR = Path(__file__).resolve().parents[2] / "docs" / "screenshots"

# Logical phone viewport; 2x gives crisp README images without huge files.
VIEWPORT = {"width": 390, "height": 844}
SCALE = 2

# (route, filename, scroll_px, extra_wait_ms)
#   scroll     - nudges long screens to their most representative frame
#   extra_wait - time for progress bars to animate in and for the auto-save
#                confirmation toast to clear before the shutter fires
SCREENS = [
    ("/home", "home", 0, 1600),
    ("/calendar", "calendar", 0, 1600),
    # Left unscrolled: the date, flow and mood sections read best together, and
    # the pinned save footer is translucent so it overlaps content at every
    # scroll position anyway.
    ("/log", "log", 0, 2200),
    ("/insights", "insights", 0, 1600),
    ("/insights", "insights-charts", 900, 1600),
    ("/pet", "pet", 0, 3200),
    ("/health", "health", 0, 1600),
    ("/education", "education", 0, 1600),
    ("/pregnancy", "pregnancy", 0, 1600),
    ("/birth-control", "birth-control", 0, 1600),
    ("/reminders", "reminders", 0, 1600),
    ("/partner", "partner", 0, 1600),
    ("/settings", "settings", 0, 1600),
    ("/ai-chat", "ai-chat", 0, 1600),
]

DARK_SCREENS = {"home", "calendar", "insights", "pet", "log"}


class _QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):  # noqa: D102
        pass


def serve(directory: Path, port: int) -> socketserver.TCPServer:
    handler = functools.partial(_QuietHandler, directory=str(directory))
    httpd = socketserver.ThreadingTCPServer(("127.0.0.1", port), handler)
    httpd.daemon_threads = True
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    return httpd


def wait_until_stable(page, settle_ms: int = 700, attempts: int = 14) -> bool:
    """Flutter paints into a canvas, so DOM readiness says nothing.

    Instead poll the rendered pixels and stop once two consecutive frames are
    byte-identical - that covers CanvasKit boot, the Google Fonts fetch and the
    entry animations in one check.
    """
    previous = None
    for _ in range(attempts):
        page.wait_for_timeout(settle_ms)
        current = page.screenshot()
        if previous is not None and current == previous:
            return True
        previous = current
    return False


def capture(theme: str, port: int, out_dir: Path) -> list[str]:
    base = f"http://127.0.0.1:{port}"
    captured: list[str] = []

    with sync_playwright() as p:
        kwargs: dict = {"args": _LAUNCH_ARGS}
        executable = _executable()
        if executable:
            kwargs["executable_path"] = executable
        browser = p.chromium.launch(**kwargs)
        context = browser.new_context(
            viewport=VIEWPORT,
            device_scale_factor=SCALE,
            is_mobile=True,
            has_touch=True,
            # Animations are left enabled on purpose: the app honours
            # reduced-motion by holding progress bars at their initial value,
            # which renders the pet's XP and happiness meters empty.
            color_scheme="dark" if theme == "dark" else "light",
        )
        page = context.new_page()

        for route, name, scroll, extra_wait in SCREENS:
            if theme == "dark" and name not in DARK_SCREENS:
                continue

            page.goto(f"{base}/#{route}", wait_until="domcontentloaded")
            stable = wait_until_stable(page)

            if scroll:
                page.mouse.move(VIEWPORT["width"] / 2, VIEWPORT["height"] / 2)
                # Stepped rather than one big delta: Flutter treats a single
                # oversized wheel event as a fling and settles back at the top.
                remaining = scroll
                while remaining > 0:
                    step = min(240, remaining)
                    page.mouse.wheel(0, step)
                    remaining -= step
                    page.wait_for_timeout(90)
                page.wait_for_timeout(1000)

            page.wait_for_timeout(extra_wait)

            suffix = "-dark" if theme == "dark" else ""
            out = out_dir / f"{name}{suffix}.png"
            page.screenshot(path=str(out))
            captured.append(out.name)
            print(f"  {out.name}{'' if stable else '  (did not fully settle)'}")

        context.close()
        browser.close()

    return captured


def main() -> None:
    # Optional filter so a single screen can be re-shot without a full pass:
    #   python tool/brand/capture_screens.py log insights
    only = {arg.lstrip("-") for arg in sys.argv[1:]}
    if only:
        global SCREENS
        SCREENS = [s for s in SCREENS if s[1] in only]
        if not SCREENS:
            raise SystemExit(f"no screens matched {sorted(only)}")

    light_dir = SCRATCH / "build" / "web-light"
    dark_dir = SCRATCH / "build" / "web-dark"
    for directory in (light_dir, dark_dir):
        if not (directory / "index.html").exists():
            raise SystemExit(f"missing web build: {directory}")

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    light_server = serve(light_dir, 8801)
    dark_server = serve(dark_dir, 8802)
    try:
        print("light theme:")
        capture("light", 8801, OUT_DIR)
        print("dark theme:")
        capture("dark", 8802, OUT_DIR)
    finally:
        light_server.shutdown()
        dark_server.shutdown()

    print(f"\nscreenshots -> {OUT_DIR}")


if __name__ == "__main__":
    main()
