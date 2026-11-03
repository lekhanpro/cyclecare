# v2.2.0 implementation and verification

The production source is Flutter under `lib/`. Browser material under `redesign/`
is design/research evidence and is maintained separately. Historical status prose
inside that handoff describes its original inspection, not the current app.

## Four-batch implementation

| Batch | Production behavior and evidence |
| --- | --- |
| 1 — Reliability | Home control labels and compact layouts; reminder gateway/service/controller, permission/recovery UI, device timezone, scheduled/boot receivers and forecast-based reminders. Domain and widget tests exercise denial, failures, retry and accepted schedules. |
| 2 — Prediction | Non-destructive exclusion fields on CycleEvent; common CycleSamples rules; Home/Calendar/Insights explanations; historical replay of the live predictor; tests of no future leakage, retained boundaries, persisted/reversible exclusions and Calendar editing. |
| 3 — Actionable records | Offline report builder and preview/share UI; explicit medication/test opt-ins; missing-data coverage; existing diary inclusion; nullable pain activity-impact fields; symptom counts by day, relative to the next actual period and across observed cycles. Privacy and persistence tests accompany the implementation. |
| 4 — Supporting flows | Actual LH/test/cervical observations preserved; optional BBT context persists; disturbed/unknown readings remain visible and cannot establish an undisturbed rise; missing-day windows are rejected. Typed article blocks preserve all 26 original article bodies and sources, reading state and bookmarks. |

`DailyLog` remains schema 2 with additive optional fields: old schema-2 explicit
zero values remain observations. Missing impact/context stays unknown. Old schema-1
default-value migration remains unchanged. Cycle exclusions default to false for
older periods. New fields survive normal persistence and tracking backup export/restore.

The report is a selected plain-text document, not a complete backup. It excludes
general free-text notes and unselected sensitive information. Pain-diary rows are
labelled separately because they may overlap daily entries; no observations are
silently merged or removed. Report date boundaries and private defaults have tests.

## Verification commands

Local verification on 3 November 2026 passed 397 behavior/unit/widget tests;
65 opt-in screenshot tests were skipped in that ordinary run. The explicit final
release matrix passed all 54 cases. Static analysis reported no errors, with
13 existing warnings and deprecation/style notices retained. Actionlint accepted
all three GitHub workflows. See [capture provenance](screenshots/README.md).

Installed Android 14 emulator testing exposed a legacy timezone alias missing
from the compact database. Reminder scheduling now uses the complete IANA
database; regression coverage checks Asia/Calcutta and US/Pacific offsets and
daylight-saving changes. This is separate from the mocked scheduling tests.

Android 14 emulator smoke tests covered account-free onboarding with an unknown
last-period date, a retained period record across APK replacement, notification
denial and recovery through Android settings, approximate-schedule acceptance,
and a visible test notification. The report preview opened Android's share sheet
with `cyclecare-health-report.txt`; no destination was selected or sent to.
See [device evidence](screenshots/device/README.md).

Start-only records from Home and onboarding now retain an unknown period end.
Calendar editing can explicitly record or clear the end; exclusions preserve it.
The calendar no longer colors guessed following days as recorded bleeding.
Existing records remain unchanged. Reports flag future ends as unconfirmed and
explain that older app versions could have filled ends from usual duration.

```sh
flutter pub get --enforce-lockfile
flutter analyze lib test --no-pub --no-fatal-infos --no-fatal-warnings
flutter test --no-pub
flutter test --no-pub --dart-define=SHOTS=true test/shots/release_screens_shots_test.dart
flutter build apk --release --no-pub
```

The screenshot matrix covers compact 320dp/200% text in light and dark mode,
main screens at the normal reference width, and structured article reading.
PNG output uses real Flutter widgets/fonts and fictional records. Screenshot
tests also check rendering exceptions. Visual inspection remains necessary to
catch poor wrapping that produces no rendering exception.

CI stores those PNGs as artifacts. Release CI repeats behavioral and layout checks
before building, verifies signatures, produces SHA-256 checksums and publishes the
APK/AAB. The README embeds current Flutter captures, not browser prototype images.

## Information boundaries and sources

The wording for care prompts was checked against the
[NHS period pain guidance](https://www.nhs.uk/symptoms/period-pain/) and
[NHS heavy-period guidance](https://www.nhs.uk/conditions/heavy-periods/).
Fertility limits are informed by
[NHS fertility-awareness guidance](https://www.nhs.uk/contraception/methods-of-contraception/natural-family-planning/)
and the [FDA LH urine-test explanation](https://www.fda.gov/medical-devices/home-use-tests/ovulation-urine-test).
Sources were accessed on 2 November 2026; this is not a clinician review credential.

This release makes no clinically validated probability, diagnosis, hormone-measurement,
contraceptive safe-day or representative accuracy claim. The retrospective replay
uses current preferences/exclusion choices because historical edits were not timestamped.
See [the evaluation gate](prediction-evaluation.md) before changing the estimator.

Remaining platform limits: Android battery/permission settings may prevent or delay
notifications after acceptance; cycle notifications wait when the anchored notice
date is past. Real-device and assistive-technology coverage cannot be inferred from
widget screenshots. Native companion mesh/film integration, wearable integration,
remote AI and cloud sync are not part of this release.
