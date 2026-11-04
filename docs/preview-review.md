# Companion and layout preview — awaiting approval

This work follows v2.2.0. It is a local review build, not a published release.
The final release must wait for the owner's review of actual Android emulator
captures and explicit approval.

## Scope

- Use the four original clay companions on Home and the companion page.
- Bundle all 36 authored action films (nine per pet), with native playback,
  continuous-image touch responses, pause and reduced-motion/lifecycle handling.
- Keep care, growth, cooldowns, achievements, renaming and selection accessible.
- Reduce default reading on Home, Calendar, Insights and secondary pages through
  concise summaries and named disclosures. Preserve all tracking and controls.

## Reference boundaries

The earlier installed My Calendar research used `com.lbrc.PeriodCalendar` 13.4.1
on Android 14: 92 captured states across onboarding, calendar, daily logging,
symptom/mood libraries, statistics, settings, reminders and reachable mode setup.
The original captures remain on local `redesign-port` under
`redesign/references/my-calendar-emulator/`; they are research, not app assets.
Restricted and unvisited states are documented there. They do not establish that
every competitor page was inspected.

Flo's [official product tour](https://flo.health/product-tour) and
[store listing](https://apps.apple.com/us/app/flo-cycle-period-tracker/id1038369065)
are public product references, not a complete installed-app audit. The current
[My Calendar listing](https://play.google.com/store/apps/details?id=com.lbrc.PeriodCalendar)
was also checked on 3 November 2026. CycleCare retains its approved typography,
palette, icon family and offline behavior.

## Previous APK and pull requests

The published v2.2.0 APK was built from `fc907e8`. PR #12's app tree was already
present in that commit; it was closed as superseded, never merged. The following
`d69d706` changed only README wording. Dependabot PR #11 was not included.
The newer native pet films/touch renderer in this preview were absent from v2.2.0.

## Verification

Pending final tests, APK build and emulator captures. Capture evidence and known
limits will be recorded here after those checks finish. Screenshots establish
layout; a separate native recording is needed to show animation and touch.
