# Changelog

All notable changes to CycleCare are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versioning
follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- New brand identity: an open-ring mark with a "today" position marker and a
  heart in the counter, generated from one set of geometry constants in
  `tool/brand/`. Ships as launcher icons, favicons, PWA icons and a social
  preview for every platform target.
- 19 real app screenshots (light and dark) captured from a running build and
  used throughout the README.
- Repository essentials: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`,
  `SECURITY.md`, issue templates, a pull request template, and Dependabot
  configuration for both pub and GitHub Actions.

### Changed
- Updated all GitHub Actions to their current major versions
  (`actions/checkout@v5`, `actions/setup-java@v6`, `actions/upload-artifact@v6`,
  `actions/configure-pages@v6`, `actions/upload-pages-artifact@v5`,
  `actions/deploy-pages@v5`, `softprops/action-gh-release@v3`), clearing the
  Node 20 deprecation warnings on every workflow run.
- Enabled secret scanning with push protection and Dependabot security updates
  on the repository.

## [2.1.0] — 2026-09-01

### Fixed
- The pet screen's XP and happiness meters rendered empty at every value: the
  fill used `FractionallySizedBox(widthFactor: ...)` with no `heightFactor`
  inside an `Align`, and `DecoratedBox` has no intrinsic size, so the fill
  collapsed to zero height.
- The health screen's pain-diary summary crashed during layout: a `Row` with
  `CrossAxisAlignment.stretch` inside a scrollable view has no bounded height,
  so `stretch` forced infinite constraints. Wrapped in `IntrinsicHeight`.
- Dropped a stale `index` field on a Health section header left behind by an
  automated fix that removed the constructor parameter but not the field.

### Changed
- **Toolchain**: raised the minimum SDK to Dart 3.10 / Flutter 3.38 and moved
  CI to Flutter 3.41.6, so the project resolves and builds on current stable
  Flutter rather than the previously pinned 3.24.5.
- Applied the Flutter 3.27+ Material renames required for the new SDK floor:
  `CardTheme` → `CardThemeData`, `DialogTheme` → `DialogThemeData`,
  `TabBarTheme` → `TabBarThemeData`.
- Raised `google_fonts` to `^8.1` (6.3.0 fails constant evaluation on Dart 3.11).
- Dropped 10 dependencies nothing in the codebase imports: `custom_lint`,
  `riverpod_lint`, `riverpod_generator`, `riverpod_annotation`, `build_runner`
  (no `@riverpod` annotations or generated sources exist in this codebase),
  `table_calendar`, `lottie`, `flutter_svg`, `cached_network_image`,
  `cupertino_icons`.
- Regenerated `GeneratedPluginRegistrant` for the reduced plugin set.

### Documentation
- Rewrote the README with accurate, verified claims: corrected the test count
  (43, not 12), clarified that the AI assistant and cloud sync are not wired to
  a live backend, and removed a partner-dashboard/invite-code claim that had
  already been removed from the app.

## [2.0.1] — 2026-05-14

Full rebuild of the Android app from the original Kotlin codebase to Flutter.

### Added
- Material 3 design system with 8 selectable colour palettes.
- Cycle tracking with a weighted moving-average prediction engine.
- Daily health log: flow, mood, symptoms, BBT, sleep, water, weight.
- Virtual pet companion with XP and achievements.
- Firebase Auth and FCM push notifications.
- Offline-first local storage with optional Supabase cloud sync path.
- Birth control tracker, pregnancy mode, and partner sharing.
- AI chat via a Groq-backed Supabase Edge Function, keeping the API key
  server-side.

## [1.0.3] and earlier — Kotlin era

Native Android (Kotlin) releases prior to the Flutter rebuild. See
[flutter-v1.0.3](https://github.com/lekhanpro/cyclecare/releases/tag/flutter-v1.0.3),
[flutter-v1.0.2](https://github.com/lekhanpro/cyclecare/releases/tag/flutter-v1.0.2),
and [flutter-v1.0.0](https://github.com/lekhanpro/cyclecare/releases/tag/flutter-v1.0.0)
for details.

[Unreleased]: https://github.com/lekhanpro/cyclecare/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/lekhanpro/cyclecare/compare/v2.0.1...v2.1.0
[2.0.1]: https://github.com/lekhanpro/cyclecare/compare/flutter-v1.0.3...v2.0.1
