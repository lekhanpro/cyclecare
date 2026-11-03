# CycleCare UI/UX direction

Current Flutter implementation status and test boundaries are documented in
[`docs/release-verification.md`](docs/release-verification.md). The browser
handoff below remains the visual contract; its original implementation-status
notes are historical snapshots. In particular, expanded logging and interactive
Home controls now have Flutter implementations, while natural-mesh/film companion
integration was absent from v2.2.0. Native companion work is now in the
[unreleased review build](docs/preview-review.md); its approval and verification
status are recorded separately.

The approved redesign lives in [`redesign/`](redesign/). Migrate the Flutter application to this UI/UX with **all existing elements and the complete redesigned screen inventory**. This includes the Home phase bar and phase/window details, grouped logging, all secondary pages, reminders, and fluid motion.

Home now also requires the interactive cycle circle and linked educational hormone-pattern graph in `redesign/home-precision.js`. Preserve the existing phase bar and every phase/window section alongside them. The graph must remain explicitly illustrative; never imply the app has measured a user's hormones. Keep the pet outside the cycle circle in its separate companion section. Provide visible pet play/pause controls, honor reduced motion by default, and allow an explicit motion preference. Support direct graph scrubbing, hormone focus, phase zoom and chart expansion.


The current companion motion reference is [`redesign/NATURAL_PET_MOTION.md`](redesign/NATURAL_PET_MOTION.md): restrained continuous-image mesh motion, local MP4 action clips and distinct live finger responses. This supersedes the cutout puppet movement in `PET_ANIMATION.md`. Preserve the separate companion section, visible motion controls, reduced-motion defaults and honest links to logging/reminders. The supplementary Rive files are earlier verified studies with a smaller state catalogue, not the current browser renderer.


**Pet appearance:** preserve the approved original soft 3D clay PNG look. Flat SVG redraws and visibly rotating image cutouts are superseded. The browser reference uses `redesign/pet-natural.js` and the local films in `redesign/assets/pets/films/`, retaining original character faces/material through a continuous mesh. Head strokes, holds, ear touches and paw taps must respond differently and interrupt playback. Do not reintroduce the rejected vector appearance or large cutout rotations in new features. Native review work uses `lib/features/pet/pet_companion.dart` and `assets/pets/films/`; see the review document before claiming production verification.

Every future feature, screen, dialog, dropdown, state and project addition must retain the same typography, colours, spacing, components, icon family and motion language. Extend this design system instead of creating a new visual style for each addition.

Before implementing UI, read:

1. [`redesign/IMPLEMENTATION_PLAN.md`](redesign/IMPLEMENTATION_PLAN.md) — mandatory visual, motion, accessibility and implementation-order requirements.
2. [`redesign/SCREEN_INVENTORY.md`](redesign/SCREEN_INVENTORY.md) — existing routes, nested pages and required states.
3. [`redesign/logging-catalog.json`](redesign/logging-catalog.json) — all logging fields/options and their implementation status.
4. [`redesign/REDESIGN.md`](redesign/REDESIGN.md) — preview, screenshots, assets and research evidence.

**Implement missing features first at the domain, local storage, validation and migration layers. Then connect them to this same UI/UX.** A planned control in the preview does not mean the Flutter feature is implemented. Preserve existing data and behaviour, make absence/none/unknown distinct, and never silently drop old records during migration.

Keep tracking offline-first, sign-in optional, sharing explicit, estimates honest and private data private. Support reduced motion, text scaling and accessible targets throughout. The current browser prototype and screenshot exports are design artifacts; they are not a completed Flutter migration.
