---
name: flutter-design-engineering
description: Design, implement, and review polished Flutter mobile interfaces for CycleCare. Use for themes, widgets, screens, navigation, responsive layouts, interaction polish, and app-wide visual consistency.
---

# Flutter Design Engineering

Build interfaces that feel calm, trustworthy, responsive, and intentional. For CycleCare, visual polish must support comprehension and privacy rather than decoration.

## Start with the existing system

Before changing UI:

1. Inspect `lib/core/theme/`, `lib/widgets/widgets.dart`, and the target screen.
2. Trace every state the screen can show: initial, loading, populated, empty, error, disabled, offline, and permission-denied.
3. Reuse existing theme tokens, semantic phase colors, motion primitives, and shared widgets.
4. Check both light and dark themes and every selectable app palette.
5. Do not add a package, icon set, font, or parallel component abstraction unless the existing system cannot solve a verified requirement.

## CycleCare design character

- Warm, reassuring, and health-literate without looking clinical or childish.
- Information-first: make dates, cycle phase, uncertainty, symptoms, and primary actions easy to scan.
- Private by design: avoid exposing sensitive details in unnecessary labels, previews, notifications, or decorative content.
- Inclusive: do not assume gender identity, fertility goals, cycle regularity, sexual activity, or pregnancy intent.
- Honest: predictions are estimates. Use ranges and confidence language where appropriate; never imply diagnosis.
- Cohesive: one visual hierarchy, spacing rhythm, radius system, icon language, and interaction vocabulary throughout the app.

## Composition rules

- Establish one clear primary action per view.
- Keep content aligned to a consistent horizontal gutter and spacing rhythm.
- Use whitespace and typography before borders, shadows, gradients, or extra containers.
- Avoid nested cards unless the inner surface represents a distinct interactive or semantic unit.
- Prefer semantic theme colors over hard-coded values. Never communicate cycle phase, severity, or status by color alone.
- Use concise labels and progressive disclosure. Put advanced or infrequent controls behind details, sheets, or secondary actions.
- Make empty states useful with a reason, next action, and no blame-oriented language.
- Keep bottom navigation destinations stable; do not move core actions between screens without a navigation-level reason.

## Flutter implementation rules

- Use Material 3 and the project `ThemeData`; prefer `colorScheme`, text theme, and `BuildContext` theme extensions.
- Import shared UI through `lib/widgets/widgets.dart` when possible.
- Use `SafeArea`, bounded content widths, and responsive constraints instead of device-specific pixel layouts.
- Support 320 logical-pixel widths, common phones, tablets, landscape where relevant, and text scaling up to 200% without clipping.
- Keep tap targets at least 48x48 logical pixels and preserve spacing between destructive and primary actions.
- Add `Semantics`, meaningful labels, values, hints, selected states, and sort order where visual context is insufficient.
- Exclude decorative images and icons from semantics.
- Respect `MediaQuery.disableAnimations`, the project `Motion` resolver, and platform reduced-motion preferences.
- Animate only when it clarifies state, spatial origin, or feedback. Prefer transform and opacity, short ease-out entrances, interruptible transitions, and immediate press feedback.
- Do not animate frequent navigation or keyboard-triggered actions. Never delay interaction to finish decorative motion.
- Preserve scroll position, focus, keyboard behavior, and state during responsive or animated changes.
- Use const constructors and isolate custom painting or expensive visuals when practical.

## Interaction polish

- Every pressable control needs visible enabled, pressed, focused, disabled, loading, success, and error behavior as applicable.
- Prevent double submission while work is pending, but keep a clear progress label.
- Make dismissals reversible when possible; confirm only destructive or high-impact actions.
- Sheets and dialogs must have a clear title, sensible focus order, keyboard-safe layout, and an obvious escape path.
- Give charts, calendars, rings, and phase colors equivalent textual summaries for assistive technology and low-vision users.
- Keep routine interactions crisp. Reserve delight for onboarding, milestones, and rare success moments.

## Review workflow

1. Compare the screen against nearby screens and shared components.
2. Identify hierarchy, consistency, accessibility, responsiveness, state coverage, and motion issues.
3. Present review findings as a single table with `Before`, `After`, and `Why` columns.
4. Make the smallest coherent app-wide change rather than patching one screen with isolated styles.
5. Format affected Dart files and run targeted analysis/tests after implementation.
6. Report what was validated on device or emulator and what remains unverified.

## Definition of done

A design change is complete only when it:

- works in light and dark themes;
- remains legible across supported palettes and text scales;
- exposes meaningful semantics and non-color status cues;
- handles loading, empty, error, disabled, and long-content states;
- uses existing design-system primitives or deliberately improves them for all consumers;
- introduces no unnecessary dependency;
- passes formatting, static analysis, and relevant tests.
