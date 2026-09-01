# Contributing to CycleCare

Thanks for considering a contribution. This project is a solo-maintained,
privacy-first health app, so contributions that keep it small, local-first and
honest in its README are especially welcome.

## Before you start

For anything beyond a small fix, open an issue first describing what you want
to change and why. That avoids spending time on a PR that doesn't fit the
project's direction — particularly for anything touching cloud sync, AI
providers, or analytics, where the answer may be "not for this app."

## Development setup

```bash
git clone https://github.com/lekhanpro/cyclecare.git
cd cyclecare
flutter pub get
flutter run
```

No `.env`, Firebase config or Supabase project is required — the app is fully
functional offline. See [README.md](README.md#getting-started) for details.

**Toolchain:** Flutter 3.41.6, Dart 3.11.4 (see [`.github/workflows/ci.yml`](.github/workflows/ci.yml)
for the exact pinned version CI uses).

## Making changes

1. Fork the repo and create a branch from `main`:
   `git checkout -b feature/short-description`
2. Match the existing code style. Run `flutter analyze` before committing —
   CI fails on analyzer errors and warnings (`--no-fatal-infos --no-fatal-warnings`
   still fails on warnings, not infos).
3. Add or update tests for any change to `lib/features/*/domain/` or
   `lib/features/*/application/` logic. UI-only changes don't need new tests,
   but shouldn't break existing ones.
4. Run the full suite locally:
   ```bash
   flutter analyze --no-fatal-infos --no-fatal-warnings
   flutter test
   ```
5. Keep commits focused. One logical change per commit, written in the
   imperative (`fix: correct luteal phase length clamp`, not `fixed bug`).

## Code style

- Follow `analysis_options.yaml` — it extends `flutter_lints`.
- Match the existing design system: use the widgets in `lib/widgets/` (`AppCard`,
  `AppChip`, `PrimaryButton`, etc.) rather than raw Material widgets, and pull
  colours from `lib/core/theme/app_colors.dart` rather than hardcoding hex values.
- Domain logic belongs in `domain/`, state management in `application/`, and
  widgets in `presentation/` — see any existing feature folder under
  `lib/features/` for the pattern.
- No emoji in UI code; use `Icons.*` (Material icons) for anything user-facing.

## Pull requests

- Open PRs against `main`.
- Fill in the PR template — it asks for a summary, what you tested, and any
  screenshots for UI changes.
- CI must pass (`flutter analyze` + `flutter test` + debug build) before merge.
- Keep the diff scoped to the stated purpose. Drive-by formatting or unrelated
  refactors in the same PR make review slower, not faster.

## Reporting bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md). Include:
- Steps to reproduce
- What you expected vs. what happened
- Flutter/Dart version (`flutter --version`) and platform (Android version,
  or browser if running on web)

## Suggesting features

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md).
Because this app is intentionally local-first and minimal, features that
require a backend, third-party SDK, or ongoing infrastructure cost are less
likely to be accepted than ones that work entirely on-device.

## Security issues

Do not open a public issue for a security vulnerability. See
[SECURITY.md](SECURITY.md) for how to report one privately.

## Medical and safety-sensitive content

This app displays health information (cycle phases, symptom patterns, health
condition explainers). Any change to that content should:
- Stay in plain, non-diagnostic language
- Not imply CycleCare can diagnose, treat, or replace a clinician
- Cite a source in the PR description if introducing new medical claims

## License

By contributing, you agree that your contributions will be licensed under the
project's [MIT License](LICENSE).
