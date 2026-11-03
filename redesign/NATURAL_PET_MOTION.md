# Current companion motion: original artwork, films and live touch

This November 1, 2026 revision supersedes the cutout texture-puppet motion in `PET_ANIMATION.md`. It changes the **browser redesign prototype**, not the Flutter app. The four original clay PNGs remain unchanged. Previous SVG and Rive studies are retained as historical assets; they do not define the current movement.

Open [the companion](http://127.0.0.1:4178/?screen=pet&motion=on&revision=natural-8) or [all four companions](http://127.0.0.1:4178/?board=pet-motion&motion=on&revision=natural-8).

## What changed

The visible pet uses one continuous 56 × 56 subdivided image mesh with broad anatomical weights. Head movement stays around two degrees, paws move a few artwork pixels, the feet stay planted, and breathing expands the chest locally. This retains the original shading and silhouette without rotating separate cutout arms or replacing the face. It is **2.5D image animation**, not a reconstructed volumetric animal or a photorealistic simulation.

Nine authored actions for each of four pets are delivered as **36 local H.264 MP4 clips**, 480 × 510, 24 fps, muted and inline. Each clip starts and settles near the original pose. Water, check-in, comfort, rest and treat have small accompanying rendered care objects. These gestures acknowledge a care action; they do not show a fully articulated pet handing over or eating an object. Breathing continues live after the first ten-second clip, completing the optional thirty-second pause. No video generation service or upload is used.

The MP4s are in `assets/pets/films/{luna,miso,maple,pip}/`. `manifest.json` contains dimensions, durations, sizes and hashes. The first set totals roughly 4 MB. Each action loads only when requested. Playback stops on pause, tab hiding, leaving the viewport or navigation. If a clip cannot load or autoplay, the same movement renders live. If WebGL is unavailable, the original artwork and care controls remain available. WebGL contexts and media are disposed when leaving the screen.

## Finger interaction

Touch interrupts the movie immediately and hands control to the live mesh. It preserves the selected care action and its logging/reminder link.

| Contact | Response |
| --- | --- |
| Head tap | Small acknowledging nod. |
| Head stroke | Restrained lean toward the finger's direction, with damped release. |
| Head hold | A quiet lean after half a second. |
| Ear touch | Local flick on the touched side, then settle. |
| Paw tap | Small paw lift and tap back. |
| Enter / Space with pet focused | Accessible greeting and nod. |

Contact does not pull the head or drag the whole character. Horizontal stroking is supported while `touch-action: pan-y` preserves vertical page scrolling and cancellation. Text feedback is announced politely. System reduced motion is respected by default; explicit Play remains available. Reduced motion keeps text and actions usable without playing clips or moving the mesh.

## Source and skill

Installed and read [CloudAI-X's threejs-animation skill](https://github.com/CloudAI-X/threejs-skills/tree/main/skills/threejs-animation), at `D:/DevData/.codex/skills/threejs-animation/SKILL.md`. Applied its procedural blending, time-based damping, visible-only updates and disposal guidance. The preview pins Three.js r183 under `vendor/`; `three-source.json` records source, hashes and the local import-path adjustment, and `three-LICENSE` carries MIT attribution. The skill describes r186; this implementation uses only the stable mesh, texture, material and renderer APIs available in the pinned r183 release.

`pet-natural.js` owns the continuous mesh, local care-object rendering, video handoff and touch input. `pet-natural.css` fits them to the approved habitat. `pet-support.js` retains action captions and honest routes. `pet-film-studio.html` is a local deterministic render fixture. Rebuild with `py -3 redesign/render_pet_films.py` from the repo root while `preview.py` runs; it requires Python Playwright/Edge and imageio-ffmpeg. Existing films are skipped; render revised clips into a fresh destination or intentionally replace specific outputs before regenerating. Never overwrite original PNGs.

## Verification and production work still required

`verify_natural_pets.py` decodes all clips, verifies hashes, tests actual MP4 playback, pause/resume, distinct touch/mouse/keyboard input, film interruption, reduced motion, navigation, resource cleanup, four-pet playback and compact layouts. Results: `motion/natural-pet-checks.json`. The recorded browser review is `motion/natural-pet-interactions.webm`; screenshots are in `screenshots/pet-support/natural-*.png`. The concise user walkthrough is `motion/natural-pet-demo.mp4`; `show_natural_pets.py` also checks visible action buttons, habitat reveal and the head-hold gesture.

Flutter video playback, live touch deformation, platform lifecycle behavior, caching, accessibility and real-device performance remain **not implemented**. These browser checks do not establish Flutter behavior. Preserve the approved art and this interaction contract through implementation; do not revert to large cutout rotations or call prototype logging/reminders saved data.
