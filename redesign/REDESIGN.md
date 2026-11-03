# CycleCare — Refined redesign

Updated November 1, 2026. This is the approved design direction and a browser interaction prototype. The Flutter application has not yet been migrated. All health values, names and dates shown are fictional examples.

Latest companion revision: [natural pet motion and live finger interaction](NATURAL_PET_MOTION.md). It replaces the cutout movement with continuous original-art meshes and 36 local MP4 clips. [Open the current demo](http://127.0.0.1:4178/?screen=pet&motion=on&revision=natural-8) or [watch the short walkthrough](motion/natural-pet-demo.mp4). Platform implementation remains pending.

## Required implementation direction

**Change CycleCare to this UI/UX with all of its elements and the complete screen inventory. All later features, pages, dialogs, dropdowns, states and project additions must maintain the same design system and fluid motion.** Reuse these typography, colour, spacing, shape, icon and component tokens rather than introducing another visual style.

**Some newly designed features are not yet implemented. Implement their domain models, local persistence, validation, migrations and export/restore support first, then connect them to this same UI/UX.** An interactive mockup does not prove the production feature exists. Preserve existing data and working behaviour.

Mandatory handoff documents:

- [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md): visual contract, required Home elements, missing-feature implementation order, fluid motion, reduced motion and production acceptance criteria.
- [SCREEN_INVENTORY.md](SCREEN_INVENTORY.md): source-backed route/state audit.
- [CURRENT_COVERAGE.md](CURRENT_COVERAGE.md): the actual current screenshot index and logging status.
- [NOT_IMPLEMENTED.md](NOT_IMPLEMENTED.md): human-readable field status and every planned logging addition.
- [logging-catalog.json](logging-catalog.json): every proposed logging field and choice with implemented/planned status and source evidence.
- [../DESIGN.md](../DESIGN.md) and [../AGENTS.md](../AGENTS.md): persistent project instructions for consistent future UI work.

## Open the designs

Run `py -3 preview.py` from this folder, then open http://127.0.0.1:4178/. Python's standard library is enough for the preview. Fonts and artwork are bundled locally.

- Everyday screens: `?board=core`
- Every designed page: `?board=all`
- All logging groups and choices: `?board=logging`
- Installed My Calendar screenshots and motion recordings: `?board=research`
- Original store-reference artwork: `?board=references`
- Individual screen: `?screen=home` or `?screen=reminderEdit`
- Dark variant: add `&theme=dark`
- Open one full logging group: `?screen=log&group=fertility`

## What was refined

The companion now has articulated SVG artwork and useful action scenes, with Motion spring physics, facial movement, held objects and direct links into care flows. This replaces the earlier whole-image bob. See [PET_ANIMATION.md](PET_ANIMATION.md), [the four-character motion board](http://127.0.0.1:4178/?board=pet-motion&motion=on), [the actual recording](motion/pets-helpful-articulated.webm) and [four verified native Rive exports](rive-companions/README.md).


The latest Home has a precise cycle dial with the companion removed from the circle. Its educational four-curve hormone chart supports direct hover/touch scrubbing, date/crosshair feedback, changing readouts, hormone focus, phase zoom and chart expansion, all linked to cycle-day exploration. The required phase bar and all windows remain below. Visible Play/Pause controls resolve reduced-motion suppression and give every pet larger, distinct motion. Open `?screen=home&motion=on` for the requested animation demonstration. See [latest recording](motion/home-precision-interactions.webm), [interaction checks](motion/home-precision-checks.json) and the [implementation requirements](IMPLEMENTATION_PLAN.md#interactive-home-circle-and-hormone-education).

Home has a precise countdown dial with a separate companion section, separate log-today/log-period actions, average cycle/period context, confidence explanation, current cycle-day marker, and a visible four-phase bar. Fertile and PMS windows are separate overlapping lanes. A complete dated phase/window section, today's check-in, week strip, phase guidance, upcoming estimates and existing feature shortcuts follow on scroll.

The logging interface has 12 expandable sections, 36 fields including date and 204 selectable choices. Every choice has an appropriate icon. All 10 currently wired moods and 16 currently wired symptoms are preserved. The proposal also includes additional symptoms, exercise/nourishment, intimacy/protection, tests and structured observations. The source distinguishes 64 existing choices from 140 proposed choices. These counts describe choices, not independent production features.

The live source of truth for choices is `lib/features/tracking/domain/tracking_options.dart`, not the broader legacy lists in `AppConstants`. `DailyLog` currently persists 17 fields including date. In particular, planned fields and nullable absence/none/unknown handling require actual storage work before release. The prototype uses separate “not logged”, explicit “none” and “not sure” states where appropriate.

The expanded collection covers 62 named screen designs, including reminder editing/permission recovery, calendar year/period editing, history/trends, all companion and health detail patterns, reading/saved articles, pregnancy setup/movement/appointments, method/pack/adherence, sharing, optional sign-in, settings/data management and recovery states. Each has light and dark PNG exports. Reusable condition/article/error patterns cover variants; the collection does not claim every backend integration is functioning.

## Screenshots and assets

| Location | Contents |
| --- | --- |
| `screenshots/01-everyday-light.png` | Refined main screens |
| `screenshots/02-dark.png` | Main dark screens |
| `screenshots/home-complete-light.png` | Complete scrolling Home, including all phase/window rows |
| `screenshots/10-every-page.png` | Full design index |
| `screenshots/detail-board-*.png` | Secondary pages in groups of four |
| `screenshots/*-light.png`, `*-dark.png` | 124 individual exports: 62 designs × two appearances |
| `screenshots/log-group-*.png` | All 12 expandable logging groups |
| `screenshots/11-logging-library.png` | All logging choices expanded |
| `motion/redesign-walkthrough.webm` | Selected prototype interactions with motion enabled |
| `assets/pets/` | Four original transparent 1280 × 1280 companion hero assets |
| `assets/icons/` | 168 named SVGs, sprite and mapping for all 190 existing app glyph references |
| `assets/design-tokens.json` | Shared colour/type/layout/icon tokens |
| `references/my-calendar-emulator/` | Actual installed-app PNG/XML captures, MP4 recordings, capture manifest and coverage notes |
| `references/sources.json` | Official store-reference image sources |
| `fonts/` | DM Sans and Fraunces with OFL licences |

## Original companion and icon artwork

Luna the bunny, Miso the cat, Maple the bear and Pip the fox share warm, soft clay forms, consistent facial features and distinct silhouettes. The built-in image generation tool produced these four static hero poses; exact prompts are in `assets/pets/generation-prompts.json`. Real alpha transparency was verified. A complete 60-state mood/species/growth animation art set is not included and must not be claimed as delivered.

The original SVG family uses a 24-unit grid, rounded caps/joins and a 1.7-unit stroke with `currentColor`. Semantic aliases may intentionally share a recognisable shape. New meanings must extend this family consistently, with accessible control labels.

## Motion and UX requirements

Use fluid, interruptible entrances, selection feedback, dropdown/accordion disclosures and bottom-sheet transitions, plus restrained breathing/cuddle feedback for companions. Keep ordinary logging fast and responsive. Prefer transform and opacity in the web prototype; profile the Flutter port rather than assuming a recording proves performance. The implementation plan defines timing/easing and reduced-motion requirements. Reduced motion removes decorative translation, scaling and delay, while retaining immediate, readable feedback.

The production implementation must preserve 48px touch targets, readable captions, text scaling, safe areas, keyboard handling, offline-first tracking, optional accounts, honest estimates, explicit sharing and all existing save/error/recovery behaviour. The fixed 390 × 844 review frame is not a production layout constraint or an accessibility certification.

## Research provenance

Official My Calendar listing, now titled Period Tracker and Calendar, by SimpleInnovation:

https://play.google.com/store/apps/details?id=com.lbrc.PeriodCalendar&hl=en_US

The corresponding iOS listing was reviewed:

https://apps.apple.com/us/app/period-tracker-and-calendar/id1032267351

Eight original Google Play promotional images remain in `references/my-calendar-simpleinnovation-*`. Supplementary Simple Design store artwork is kept separately under `references/period-calendar-simple-design-*`. These store images are not installed-app captures.

The later installed-app research uses an isolated Android 14 emulator and My Period Calendar version 13.4.1, package `com.lbrc.PeriodCalendar`. The unmodified split APK was obtained through APKPure because direct Play Store installation was not configured. Its signer SHA-1 matches the published distribution fingerprint `77c28483f243b695b39a8bf90b55bada95c1f61c`; Android's package verifier accepted it and the package carries a Google source stamp. Download provenance and exact device/capture coverage are recorded with the research. APK files and emulator disks are outside this repository.

No personal account or real user health history was used. Research captures use a fictional test profile. Paid, account-gated and data-dependent pages are documented as limitations rather than invented captures. PNGs show states; MP4 recordings show transitions. Competitor artwork is research-only and must not be bundled as original CycleCare production art.

## Verification and scope

All 62 screen designs rendered in both appearances with no JavaScript errors, missing images or horizontal page overflow at the reference viewport. Still exports use reduced motion so they do not capture a partially transparent entrance frame. Motion recordings keep motion enabled. See `screenshots/render-checks.json` and the interaction checks for evidence.

The Flutter source and build configuration were not changed for this refinement. No commit or remote push was made. Implementation status remains separate from design coverage.


**Current appearance correction:** retain the original soft 3D clay PNG look. The active browser uses original face textures, matching clay body/limb layers and the same helpful spring actions. Resting pose shows the untouched original image. The flat vector study is superseded. See [the current pet appearance contract](PET_ANIMATION.md#current-pet-appearance--preserve-the-original-clay-artwork), [live check-in scene](http://127.0.0.1:4178/?screen=pet&motion=on&activity=checkin&revision=original-clay-7) and [original-texture Rive assets](rive-companions/textured-exports/README.md).
