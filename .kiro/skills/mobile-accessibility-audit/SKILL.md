---
name: mobile-accessibility-audit
description: Audit and improve accessibility in CycleCare Flutter screens and widgets. Use for semantics, contrast, text scaling, touch targets, focus order, reduced motion, forms, calendars, charts, and assistive-technology behavior.
---

# Mobile Accessibility Audit

Treat accessibility as product quality, not a final checklist. Inspect source and behavior before proposing changes.

## Audit order

1. Understand the task, user journey, and sensitive health context.
2. Inspect the target widget plus its theme, shared components, state providers, and navigation entry.
3. Test or reason through light/dark themes, every palette, 200% text scaling, narrow width, landscape, and reduced motion.
4. Evaluate TalkBack/VoiceOver output, traversal order, keyboard focus where applicable, and switch-control reachability.
5. Check all loading, empty, error, permission, offline, and destructive states.

## Required checks

### Structure and semantics

- Every screen exposes one useful route/screen name and a logical reading order.
- Headings, groups, selected states, values, toggles, validation errors, progress, and live updates are announced accurately.
- Icon-only actions have specific labels; decorative visuals are excluded.
- Composite visuals such as cycle rings, charts, calendars, and severity controls expose concise textual equivalents instead of dozens of noisy nodes.
- Dates include full semantic context, including selected/current state and relevant cycle meaning.

### Visual access

- Text and meaningful UI indicators maintain appropriate contrast in light/dark themes and all palettes.
- Status is never encoded by color alone; pair it with text, iconography, shape, or pattern.
- Content survives 200% text scaling without clipping, overlap, ellipsis that removes meaning, or unreachable controls.
- Focus indicators remain visible and are not obscured by overlays or the keyboard.

### Motor and cognitive access

- Interactive targets are at least 48x48 logical pixels with adequate separation.
- Gestures have discoverable tap alternatives; no feature depends only on swipe, drag, long press, or precise timing.
- Error messages explain what happened and how to recover without blame.
- Labels use plain, inclusive language and avoid medical certainty when presenting estimates.
- Timeouts pause when the app is backgrounded and do not remove essential information prematurely.

### Motion and media

- Respect platform and project reduced-motion settings.
- Remove nonessential parallax, large movement, repeated motion, and animated navigation.
- Keep useful opacity/color feedback when it aids comprehension.
- Never flash rapidly or use motion as the only signal of state change.

## Finding format

Report findings in a compact table with columns: `Severity`, `Location`, `Evidence`, `Impact`, and `Remediation`. Use severity levels `Blocker`, `High`, `Medium`, and `Low`; do not inflate severity. Include exact file paths and line references when available.

When implementing fixes, prefer shared primitives so all screens benefit. Format changed Dart files and run targeted static analysis/tests. Clearly separate verified behavior from emulator/device checks that remain outstanding.
