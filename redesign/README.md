# CycleCare Refined Redesign

Current pet revision: [natural clay motion and finger interaction](NATURAL_PET_MOTION.md). [Try the updated companion](http://127.0.0.1:4178/?screen=pet&motion=on&revision=natural-8): 36 local MP4 actions across four pets; live head stroke/hold, ear and paw responses. This supersedes the earlier cutout puppet motion described below. Browser design prototype only; Flutter migration remains pending.

Run `py -3 preview.py` and open http://127.0.0.1:4178/.

- Every page: http://127.0.0.1:4178/?board=all
- All logging choices: http://127.0.0.1:4178/?board=logging
- Installed My Calendar research: http://127.0.0.1:4178/?board=research

See [REDESIGN.md](REDESIGN.md), [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) and [CURRENT_COVERAGE.md](CURRENT_COVERAGE.md).

62 screen designs in light and dark mode. Four companion assets. 168 SVG icons. Home phases/windows. 12 logging groups with planned features explicitly documented.

This is the mandatory future UI/UX direction, not a completed Flutter migration. Implement planned data/storage support first, then connect the same UI consistently. No commits were made.

Latest polish: eight refined SVG icons, animated idle motion for all four pets, Home greeting and distinct care reactions. [Icon comparison](icon-refinement.html) · [Pet motion video](motion/pets-live-motion.webm) · [Motion checks](motion/pet-motion-checks.json). Reduced motion disables decorative movement.

Current Home: [interactive cycle circle and hormone graph](http://127.0.0.1:4178/?screen=home&motion=on). The pet is outside the circle. Drag/hover over the chart, tap a hormone to focus, zoom into a phase or expand the plot. The dial and day sliders stay synchronized. Use the separate companion section for pet motion. [Latest video](motion/home-precision-interactions.webm) · [Latest checks](motion/home-precision-checks.json). Hormone curves are educational illustrations, not measured personal data. Explicit Play overrides system reduced motion only after opt-in.


Current companion motion: [helpful articulated pets](http://127.0.0.1:4178/?screen=pet&motion=on&revision=pet-support-6) · [all four in the motion study](http://127.0.0.1:4178/?board=pet-motion&motion=on). See [animation workflow and state contract](PET_ANIMATION.md), [browser recording](motion/pets-helpful-articulated.webm), [checks](motion/pet-support-checks.json) and [native Rive assets](rive-companions/README.md). These supersede the earlier whole-image motion approximation.


**Current appearance correction:** retain the original soft 3D clay PNG look. The active browser uses original face textures, matching clay body/limb layers and the same helpful spring actions. Resting pose shows the untouched original image. The flat vector study is superseded. See [the current pet appearance contract](PET_ANIMATION.md#current-pet-appearance--preserve-the-original-clay-artwork), [live check-in scene](http://127.0.0.1:4178/?screen=pet&motion=on&activity=checkin&revision=original-clay-7) and [original-texture Rive assets](rive-companions/textured-exports/README.md).
