# tool/

Asset generation. Nothing here ships in the app.

```
tool/
├── brand/
│   ├── brand.py              # palette + mark geometry (single source of truth)
│   ├── generate_svg.py       # emits every SVG into assets/brand/
│   ├── measure_wordmark.py   # measures the wordmark in Chrome for a tight viewBox
│   ├── rasterize.py          # emits every PNG: brand kit, Android, iOS, web
│   ├── preview.py            # contact sheet for eyeballing the mark at all sizes
│   ├── capture_screens.py    # real app screenshots from a Flutter web build
│   └── render.py             # Chrome-backed SVG -> PNG
└── fonts/                    # Nunito woff2, embedded into the wordmark SVGs
```

## Requirements

```bash
pip install playwright pillow
```

Chrome or Edge is used for rendering when installed; otherwise Playwright's
bundled Chromium is used.

## Regenerating brand assets

```bash
python tool/brand/generate_svg.py
python tool/brand/measure_wordmark.py   # optional, only if the wordmark changes
python tool/brand/rasterize.py
```

`rasterize.py` writes to `assets/brand/`, `assets/images/`, `web/`,
`android/app/src/main/res/` and `ios/Runner/Assets.xcassets/`, matching the
existing filenames and pixel sizes exactly. It is a drop-in replacement, so
`flutter_launcher_icons` is not required — though running it will produce the
same result from `assets/images/app_icon.png`.

To change the logo, edit the geometry constants in `brand.py` and regenerate.
Never hand-edit the output.

## Regenerating screenshots

`capture_screens.py` shoots the real app, not mockups: it serves a Flutter web
build and deep-links each route through the hash router.

It expects two builds produced from a screenshot entrypoint that seeds a demo
history through the app's own `CycleRepository` before `runApp`, so the stored
data is guaranteed to match what the running app reads back:

```
D:\_cyclecare_shots\build\web-light
D:\_cyclecare_shots\build\web-dark
```

Built with:

```bash
flutter build web --release -t lib/main_shots.dart \
  --dart-define=SHOT_THEME=light --output build/web-light
flutter build web --release -t lib/main_shots.dart \
  --dart-define=SHOT_THEME=dark  --output build/web-dark
```

Then:

```bash
python tool/brand/capture_screens.py            # every screen
python tool/brand/capture_screens.py log home   # just these
```

Output lands in `docs/screenshots/` at 390×844 logical, 2× scale.

Readiness is detected by polling rendered pixels until two consecutive frames
are identical — Flutter paints into a canvas, so DOM readiness tells you nothing
about whether CanvasKit has booted and the fonts have arrived.

> The screenshot entrypoint is not committed. On a Flutter SDK newer than 3.24
> the web build additionally needs the `CardTheme`/`DialogTheme`/`TabBarTheme`
> renames and `google_fonts ^8.x` described in the README's compatibility note.
