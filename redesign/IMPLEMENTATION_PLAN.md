# CycleCare redesign — implementation requirements

**Production update:** see [v2.2.0 implementation and verification](../docs/release-verification.md)
for the current Flutter state. Implementation-status statements below describe
the original handoff inspection. They do not override verified production work.

Current pet implementation target: [NATURAL_PET_MOTION.md](NATURAL_PET_MOTION.md). Preserve original clay artwork through restrained continuous-mesh movement, use the delivered MP4 actions and distinct head-stroke/hold/ear/paw touch responses, and retain pause/reduced-motion/lifecycle behavior. This supersedes cutout puppet motion in earlier handoff sections. Platform integration is still required; the browser reference does not implement Flutter behavior.

Status: design handoff and browser interaction prototype. The Flutter application has **not** been migrated to this interface. Screenshots are design examples, not proof that a feature stores data or works on a device. See [SCREEN_INVENTORY.md](SCREEN_INVENTORY.md) and [logging-catalog.json](logging-catalog.json) for coverage and implementation status.

## Required direction for all future UI work

**Migrate CycleCare to this UI/UX, including the complete screen inventory and all approved elements. Every subsequent screen, feature, dialog, dropdown, error state and project addition must continue the same design system.** Extend the existing components and tokens instead of introducing a separate visual language for a new feature.

The design prototype is the visual reference; the app's domain models, saved records and current functional behavior are the implementation source of truth. When they disagree, preserve the data and behavior, then adapt the design. Do not omit an existing feature simply because it was absent from an early screenshot.

Newly designed tracking features marked `planned` or `not yet implemented` must receive their domain, storage, validation and migration work **before their production UI is treated as functional**. A selectable chip in the browser prototype is not an implementation of the corresponding health record. Complete these foundations first, then wire the same approved UI to them. Existing features need a visual migration rather than a redundant rewrite.

## Visual contract

| Concern | Requirement |
| --- | --- |
| Typography | Fraunces for expressive page headings and major numeric moments; DM Sans for controls, body copy, values and navigation. Bundle fonts for offline use. Support user text scaling. |
| Surfaces | Warm paper canvas, quiet cards and compact grouped list rows. Keep the plum primary action, blush tracking surfaces, sage care surfaces and violet secondary emphasis. Resolve all colors through tokens in light and dark mode. |
| Spacing | Four-unit base, consistent page gutters and section rhythm. The 390 × 844 review frame is a reference, not a fixed production layout. Adapt to compact phones, landscape, tablets, keyboard insets and safe areas. |
| Shape | Reuse the defined small-control, button, card and hero radii. Preserve concentric nested shapes. Avoid different corner treatments on each new screen. |
| Icons | Use the delivered semantic SVG family. A new meaning gets an appropriate named icon in the same 24-unit, 1.7-stroke, rounded family. Supply accessible labels at controls. Do not replace them with platform-dependent emoji. |
| Phase semantics | Keep phase and fertile-window meaning stable across user palettes. Resolve the existing `PhaseColors` roles to accessible light/dark tokens; include text, icons or patterns so color is never the only signal. |
| Navigation | Keep the five main destinations and their retained scroll positions. Secondary screens push above the shell; sheets have a consistent dismissal and back behavior. Preserve unsaved-change protection. |
| Touch and text | Preserve the app's 48px minimum interactive targets and 52px primary-button convention where available. Small review labels must not dictate unreadable production captions. Verify contrast and 200% text scaling. |
| Content states | Every addition includes loading, empty, error, unavailable, success and recovery states where applicable. A disabled action explains why. Errors remain visible long enough to recover. |
| Pet artwork | Reuse the four approved characters and habitat treatment. The four delivered PNGs are static hero poses, not a full 60-state animation/growth set. Commission or generate remaining art consistently before claiming every mood/stage is illustrated. |

## Home requirements

The revised Home must include all of the following, with the primary prediction and logging actions readable before the user explores secondary content:

1. Greeting/date and access to the user's space.
2. Current cycle day, named phase, next-period estimate and explanation of the estimate's confidence/history.
3. A visible segmented bar for **Menstrual, Follicular, Ovulation and Luteal** phases, with a current-day marker. Segments must derive from the current cycle data, not the screenshot's example dates.
4. A phase/window section covering all four phases, plus the **fertile window** and **PMS window** as separate overlays. These windows are not two extra phases. Show estimated date ranges, where today falls and a useful detail/care explanation. Honor fertility/ovulation visibility preferences.
5. Recorded versus predicted distinctions, and an explicit insufficient-history state when prediction is not supported.
6. Relevant late-period/long-gap/irregularity alerts from the existing domain logic, with appropriate next actions.
7. A compact week strip, today's entry summary, quick log/edit access and a consistent check-in completion state.
8. Phase-aware care guidance and the companion check-in without guilt or a claim that a phase determines every person's mood or energy.
9. Access to Learn, Health, Reminders, Birth control, Pregnancy, Partner sharing and Settings. Optional/unavailable features retain honest availability copy.

Use `lib/features/tracking/domain/cycle_windows.dart`, `phase_guidance.dart` and the prediction service to calculate these displays. Keep all Home dates, calendar ranges and insight summaries consistent with one shared domain result. A single screenshot may use October 30, cycle day 23, last period October 8 and next estimate November 5 solely as fictional design data.

## Logging requirements and missing functionality

Use [logging-catalog.json](logging-catalog.json) as the explicit field/option catalogue, with each item marked as implemented in the current Flutter source or planned. Keep that file synchronized when the implementation changes.

The currently active options come from `lib/features/tracking/domain/tracking_options.dart` and the models in `cycle_models.dart`. The broader lists in `AppConstants` are not evidence that their extra options are implemented in the live logging flow.

Current `DailyLog` support includes flow, a single mood, symptoms/custom tags, pain, discharge, cervical mucus/position/firmness/opening, BBT, weight, sleep hours, hydration, medication status/name and notes. Preserve all values, option spellings and units during migration. If the redesigned UI offers multiple moods, that is a schema/behavior extension: implement and migrate it before presenting it as working support.

The expanded UI must provide clear, individually iconed accordion categories rather than one long undifferentiated page. Each group shows a selected-value summary when collapsed. Users can open relevant categories without being forced to fill every one. Keep a persistent save action, date context, optional-field labels, clear/remove actions and an unsaved-changes guard.

For designed additions such as intimacy/protection/libido, exercise, expanded appetite/digestion, ovulation/pregnancy tests or more detailed medication records, do the following before shipping their controls:

- Add typed, nullable fields or separate typed event records with explicit units and timestamps where needed.
- Distinguish not logged, none, unknown/not sure and an actual selected value. Do not silently convert missing records to zero, negative test results or no symptoms.
- Define whether each choice is single-select, multi-select, numeric, free text or repeatable. Avoid putting contradictory exclusive states into one list.
- Implement local persistence, reading, editing, deletion, serialization, backup/export and restore, including backwards-compatible migration.
- Add meaningful validation and tests for round-tripping, empty/null states, units, migrations, undo and data removal. Keep existing cycle prediction behavior unless a separately reviewed domain change is intended.
- Treat intimate and reproductive information as sensitive. Keep it local and excluded from sharing/AI context by default; require an explicit, accurately described opt-in before any transfer.

Mark each planned category as **not yet implemented in Flutter** in the design/engineering catalogue until all of the above is complete. UI screenshots should remain clean product concepts; do not place developer implementation-status warnings inside a future consumer flow.

## Phased delivery

### 1. Confirm the data and behavior inventory

Trace every designed field and screen to source. Resolve stale constants, supported options and unsupported additions without discarding old records. Capture baseline tests, backup formats and prediction behavior. Record which My Calendar screens were actually observed and which competitor states were inaccessible; do not infer unseen behavior from promotional screenshots.

### 2. Implement missing feature foundations first

Complete the planned logging data model, serialization, persistence, migrations, validation and export/restore coverage. Implement any other new feature that a design depends on before labeling its production control usable. Keep unsupported AI/provider states unavailable. A new screen must not imply a functioning backend, notification delivery, synchronization or clinical capability that does not exist.

### 3. Port the shared design system

Create or update the shared typography, color, phase roles, spacing, buttons, chips, list rows, headers, bottom navigation, form controls, accordions, cards, sheets, toasts and empty/error states. Map semantic icon names to the delivered assets. Build both appearances together, with contrast-safe text and backgrounds. Preserve existing theming preferences or provide an explicit migration.

### 4. Migrate complete flows

Implement Home and logging, then calendar/insights, companion flows, onboarding, reminders, health/learning, pregnancy, birth control, partner sharing and settings/data/security. Use the inventory as the completion checklist. Port all nested screens and forms, not just each feature's landing page. Retain real save/retry/undo/delete behavior and navigation state.

### 5. Add and verify fluid motion

Apply the shared motion contract below to every migrated surface. Review transitions on an Android emulator and a representative lower-end device, in a release build. Preserve gesture continuity, interruptibility, back navigation and reduced motion. Capture actual transitions as video; static PNGs do not demonstrate animation.

### 6. Verify the finished product

Run the project's appropriate analysis/build/tests. Check old records after migration, export/restore, offline startup, account-free use, notifications/permission denial, all birth-control methods, pregnancy setup/exit, partner payload preview, lock recovery, large text, reduced motion, dark mode and keyboard access. Compare all screens to the approved gallery and resolve visual drift before calling the migration complete.

## Fluid motion contract

Extend `lib/core/theme/app_motion.dart`, `core/router/app_transitions.dart` and the existing motion wrappers. Do not create separate timings in every feature.

| Interaction | Reference behavior |
| --- | --- |
| Press | 120ms tactile contact, subtle scale near 0.98; no scale movement under reduced motion. |
| Chip, toggle and selection | 160–190ms, immediate selected state and a quiet color/icon transition. No delayed tap response. |
| Accordion | About 220–240ms, clear disclosure rotation and content fade; keep the tapped header visually anchored. In Flutter use a bounded size transition with a cheap child; in the web prototype prefer transform/opacity and avoid per-frame layout measurement. |
| Detail navigation | About 220ms directional push tied to the back gesture; preserve gesture progress and reversal rather than starting a second canned animation. |
| Sheets/dialogs | About 280ms on entry, 180ms exit, restrained movement and correct origin/scrim behavior. Retain drag-to-dismiss where appropriate. |
| Phase selection | About 190–240ms indicator and detail crossfade; do not move the entire Home page or restart all graphs. |
| Ring/chart reveal | Up to 620ms only for an occasional explanatory entrance; changes should not replay a long reveal on every rebuild or tab visit. |
| Pet | Slow breathing around 3200ms, occasional blink, small interruptible cuddle hop. Gentle spring/overshoot is reserved for this playful feedback and rare achievement moments. |
| Stagger | About 40ms between a small number of siblings, capped so content becomes available promptly. No repeated stagger while ordinary scrolling. |

Use the existing strong ease-out `Cubic(0.23, 1, 0.32, 1)` for responsive entrances, `drawer` for sheets and `springy` only for playful confirmation. If a physical spring is used, tune one shared, slightly damped preset and verify it on-device rather than spreading unrelated constants throughout screens.

Respect the platform's reduce-motion setting and the app preference. Remove decorative translation, scaling, pet breathing/hops and entrance delays; keep immediate state, readable feedback and restrained opacity changes. Avoid flashing, constant ambient motion behind health information or animations that block logging. Keep web animations on transform/opacity where possible and Flutter painting/layout bounded; profile frame timing instead of assuming a smooth emulator recording proves performance.

## Privacy and product invariants

- Core tracking remains useful offline without a sign-in wall. Optional auth is not a route gate.
- Preserve the existing local-first repositories and secure PIN/biometric behavior. Do not introduce analytics or health-data uploads to make a design seem complete.
- Partner sharing remains a deliberately shared snapshot, with the actual payload matching the preview. Sensitive fields start off. A share code is not automatic live sync.
- AI remains explicitly unavailable while wired to `UnavailableAIClient`. Any future configured AI requires transparent field-level sharing consent, error recovery and honest availability.
- Forecasts remain estimates, never guarantees, diagnoses or a sole contraception method. Fertile and ovulation visibility controls continue to work.
- Reminders schedule locally; the UI must handle permissions, OS delivery restrictions, test notifications, disabled states and failed saves without claiming delivery.
- Existing data deletion, restore replacement, pregnancy exit and other destructive actions retain confirmations and recovery paths.

## Definition of done

### Phase-range consistency during the port

The current `CycleWindows` follicular helper represents an early window that ends before the fertile window. Do not mistake that shorter interval for the entire follicular segment of a four-phase bar. Use a reviewed, coherent phase model for the four sequential phases and preserve fertile/PMS windows as separate overlapping intervals. Test Home, Calendar, predictions and phase details against the same dates; the fictional example consistently includes October 17–23 as the fertile window, with estimated ovulation on October 22.

### Native reference coverage and proposed logging additions

The installed My Calendar research additionally records all nine expanded symptom-library categories and all 47 displayed mood labels. The redesigned catalogue maps these observations explicitly, keeping existing CycleCare values and documenting aliases such as Tense → Tension. These reference additions are planned product options until local model/storage/validation/migration work is complete. See `logging-catalog.json` and `NOT_IMPLEMENTED.md`; competitor controls are not proof of CycleCare implementation.

A feature is complete only when its data behavior works, every required nested view uses this design system, supported states are designed, motion works with and without reduced motion, and the corresponding build/tests and visual/device checks pass. Update the catalogue and inventory status as evidence changes. Keep the same visual contract for all future additions to the project.


### Refined icons and live pet motion

The eight revised Home, Calendar, Insights, Reminders, Period, Fertile window, Bunny and Cuddle icons are synchronized across the SVG exports, sprite and preview data. Keep the 24-unit grid, 1.7 rounded stroke and semantic names in future extensions. See `assets/icon-refinement.json` for before/after geometry.

The browser prototype now animates all four original companion artworks with species-specific breathing, sway or a curious tilt. Home's companion responds to a greeting; the care controls trigger distinct, interruptible treat, water and cuddle reactions. `pet-motion.css` and `pet-motion.js` animate transform only. Reduced motion removes idle and reaction movement, including when the preference changes during a reaction. These are animated static illustrations; separate facial/blink, limb and growth artwork is still required for full character animation in Flutter. Port this behavior through the app's shared motion system and verify it on-device.

### Interactive Home circle and hormone education

The revised Home in `home-precision.js` and `home-precision.css` (with base styles in `home-orbit.css`) adds a four-phase cycle circle with day dots, Today marker, pointer dragging, keyboard arrows/Home/End and a labeled native range control. Its selected day, phase, date and hormone-graph cursor stay synchronized; the next-period estimate remains anchored to the current date. Keep the existing four-phase bar, fertile/PMS overlay lanes and all seven phase/window rows. The circle complements those required elements.

The graph includes individually focusable Estrogen, Progesterone, LH and FSH curves, with an All hormones reset. These are hand-shaped, normalized educational illustrations based on [UCSF's explanation of the menstrual cycle](https://crh.ucsf.edu/about-fertility/normal-menstrual-cycle), not a scientific plot of measured concentrations. Show the educational disclosure beside the graph, with no fabricated lab units, personal levels, scores or individual hormone predictions. Users requested this pattern; the captured competitor archive does not establish a native hormone-graph implementation. Source review, educational content, preference/availability rules and accessibility must precede a production port. No hormone measurements or new health-record fields have been implemented.

Pet motion now has an explicit Play/Pause control on Home and the companion page, larger idle movements and distinct care reactions. System reduced motion remains the default. Explicit Play opts into movement and Pause cancels it; opening `?screen=home&motion=on` is an intentional design-review opt-in that makes the demonstration visible even when Windows requests reduced motion. Apply the preference across the shared components, rather than letting older page-specific rules override the pet motion. Keep the final application preference in its normal accessibility settings.

Browser evidence: `motion/home-precision-checks.json` and `motion/home-precision-interactions.webm`. These verify prototype interaction and visible motion, not Flutter implementation or device performance.


### Current Home: precise cycle dial and directly interactive chart

Keep the companion outside the cycle dial. The dial shows the next-period countdown for today and the selected cycle day when exploring. Preserve forecast dates while users inspect other days. Use a restrained paper surface, fine day ticks and phase arcs; the companion retains its own entry and motion controls.

The active prototype is `home-precision.js`, loaded in place of the earlier `home-orbit.js`. The hormone chart uses shape-preserving cubic interpolation through asymmetric illustrative control points. This creates readable curves without claiming physiological measurements or predicting individual hormone levels. Each curve is normalized independently; the relative Low/Mid/High axis cannot be used to compare concentrations between hormones. Control points are design examples, not a dataset or lab reference range. The [UCSF source](https://crh.ucsf.edu/about-fertility/normal-menstrual-cycle) supports the educational narrative, not the synthetic numeric values.

Required interaction states: mouse hover, touch/pen dragging and keyboard day selection; a date tooltip, crosshair and curve markers; four changing qualitative readouts; single-hormone focus with a shaded area and muted context curves; All hormones reset; Full cycle / This phase time-domain zoom; Expand / Compact plotting room; Today reset; linked cycle ring and native range alternatives. Keep direct scrubbing immediate instead of letting the crosshair lag behind the pointer. Retain keyboard focus when rebuilding the hormone readout controls.

The browser checks cover direct mobile touch events, pointer and keyboard input, curve focus/reset, phase-domain dates, expanded chart height and compact-width overflow. These remain design/prototype features pending the same Flutter implementation and source/content review requirements above. No hormone values have been added to local health records.


### Current companion motion: articulated helpful SVGs

Read [PET_ANIMATION.md](PET_ANIMATION.md) before implementing any companion feature. It supersedes the earlier whole-image breathing/bounce approximation. Four new shaded vector rigs retain the original character palettes and have individually addressable heads, ears, eyes, mouths, arms, hands, feet, scarves and tails. The original PNG artwork remains a separate static asset set.

The live prototype uses locally bundled Motion 14.9.0 springValue with real stiffness, damping, mass and velocity continuity. It supports useful breathing, hydration, check-in, comfort, stretch and rest scenes, alongside articulated treat and cuddle interactions. Props are gripped by the paws; active arms change layer order when needed. Keep contextual next-step buttons available after an animation finishes, and never pretend that a pet gesture itself saves a log or schedules a reminder. Connect the same approved UI to the real domain behavior first.

Four native Rive exports and editable RML are included under `rive-companions/`. Their currently verified states are idle, breathing, water and check-in. They use authored elastic timelines, not a mass-spring solver. The browser has more actions; finish and verify the remaining Rive states before claiming parity. Flutter runtime integration, device performance and automatic reminder/event triggering remain implementation work. Respect reduced motion, user control and data/privacy invariants throughout.

Current evidence: `motion/pet-support-checks.json`, `motion/pets-helpful-articulated.webm`, `screenshots/pet-support/`, plus the Rive build and native-render reports. The design-review board is `?board=pet-motion&motion=on`.


**Current appearance correction:** retain the original soft 3D clay PNG look. The active browser uses original face textures, matching clay body/limb layers and the same helpful spring actions. Resting pose shows the untouched original image. The flat vector study is superseded. See [the current pet appearance contract](PET_ANIMATION.md#current-pet-appearance--preserve-the-original-clay-artwork), [live check-in scene](http://127.0.0.1:4178/?screen=pet&motion=on&activity=checkin&revision=original-clay-7) and [original-texture Rive assets](rive-companions/textured-exports/README.md).
