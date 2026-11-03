# Flutter release UI review

Captured November 3, 2026 from actual Flutter screens, real bundled fonts, and fictional local records. These are widget-test renders, not the browser redesign or installed-device captures.

The release matrix passed all 54 tests: 13 routes in light/dark at 390dp and at 320dp with 200% text, plus two complete article readers. The `accessibility/` folder also includes the enlarged Home hormone controls after scrolling. No Flutter layout exceptions occurred. Main navigation, date estimates, logging actions and hormone controls remain visible at enlarged text; navigation uses two columns on compact phones at this setting.

Regenerate with:

```powershell
flutter test --no-pub --dart-define=SHOTS=true test/shots/release_screens_shots_test.dart
```

The output is written to `build/shots/`. `release-validation.json` lists the reviewed routes and copies here. The README's primary screenshots use the current captures in this folder. `ai-chat.png` and `insights-charts.png` are older captures and are outside this release matrix.

Separate behavior tests cover the article/source preservation migration, offline bookmarks/opened progress, structured reader, navigation, hormone interaction and report preview/copy with explicit sensitive-field opt-ins. A PNG does not prove notification delivery, sharing, persistence or animation performance. This review does not replace installed-device or screen-reader checks.
