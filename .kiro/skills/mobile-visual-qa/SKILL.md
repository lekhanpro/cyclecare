---
name: mobile-visual-qa
description: Perform systematic visual and interaction QA for CycleCare Flutter UI. Use after design changes to find cross-screen inconsistencies, overflow, state gaps, theme defects, awkward motion, and device-size regressions.
---

# Mobile Visual QA

Review the app as a connected product, not a collection of screenshots. Prioritize defects that affect comprehension, trust, task completion, or accessibility.

## Build the test matrix

Cover the affected routes across:

- light and dark themes;
- the default palette plus highest- and lowest-contrast selectable palettes;
- 320, 360, 412, and tablet-width layouts where supported;
- 100%, 130%, and 200% text scaling;
- short and long localized-looking content;
- initial, loading, populated, empty, error, offline, disabled, and permission-denied states;
- reduced motion on and off.

## Inspect in this order

1. **Navigation:** route names, selected destination, back behavior, deep-link state, and keyboard/sheet interaction.
2. **Hierarchy:** first focal point, primary action, grouping, scan order, and information density.
3. **System consistency:** spacing, typography, radius, color roles, icons, buttons, inputs, cards, sheets, dialogs, and feedback.
4. **Layout resilience:** overflow, clipping, unsafe insets, keyboard obstruction, long text, scrollability, orientation, and tablet bounds.
5. **State quality:** useful skeleton/progress, empty-state action, actionable errors, disabled rationale, stale/offline indicators, and retry behavior.
6. **Interaction feel:** pressed/focus states, double-submit prevention, interruption, scroll preservation, animation purpose, easing, and reduced motion.
7. **Accessibility:** semantics, contrast, non-color cues, text scaling, tap targets, reading order, and textual equivalents for visuals.
8. **Health trust:** inclusive copy, privacy exposure, prediction uncertainty, and absence of diagnostic claims.

## Design-review output

Use one markdown table with `Before`, `After`, and `Why` columns for visual recommendations. For defects, include route, state, viewport/theme, reproduction steps, expected behavior, actual behavior, and evidence.

Do not mark a screen visually complete from source review alone. State whether each result was verified by widget test, static analysis, emulator/simulator, physical device, or screenshot comparison. Never claim a device check that was not performed.

## Completion gate

A UI change is ready only when affected screens have no overflow or unreachable action at supported widths/text scales, light and dark themes retain hierarchy and contrast, all important states are intentional, motion respects user preferences, and validation passes.
