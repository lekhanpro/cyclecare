import 'package:flutter/material.dart';

import '../core/services/haptics.dart';
import '../core/theme/cyclecare_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Toggles
//
// The design's `.toggle` is measured rather than Material's Switch: a 43×25
// track with 3px of inset and a 19px knob, the track hairline-grey when off
// and sage when on (`appearance`, `appLockSettings` and five other specs all
// agree on those values). Material's Switch is 52×32 with a 24px thumb and an
// outline, so matching the boards means drawing the control.
//
// Two places depart from the boards, both deliberately:
//
//  * The painted track is 25 tall; the *gesture* target is 48, because a 25pt
//    tap target fails the project's touch-target invariant. The extra height
//    is transparent, so the design's spacing is unchanged.
//  * Dark mode's ON track is the pale sage token (#acd1b9). A white knob on it
//    measures about 1.4:1 and disappears, so dark mode uses the same dark ink
//    the design puts on its pale `.dark .primary` fill. Light mode keeps the
//    design's white knob, where the soft shadow is what defines its edge.
// ─────────────────────────────────────────────────────────────────────────────

/// The design's `.toggle`. A switch, not a checkbox: the knob's position is
/// the signal, so it still reads with colour removed.
class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.semanticHint,
    this.includeSemantics = true,
  });

  /// `.toggle{width:43px;height:25px;padding:3px}`.
  static const double trackWidth = 43;
  static const double trackHeight = 25;
  static const double trackInset = 3;

  /// 19, from the track height less its inset on both edges.
  static const double knobSize = trackHeight - trackInset * 2;

  final bool value;

  /// Null renders the control as disabled rather than hiding it, so a switch
  /// that is off because a permission is missing still says what it is.
  final ValueChanged<bool>? onChanged;

  final String? semanticLabel;
  final String? semanticHint;

  /// False when a parent (such as [SwitchRow]) already exposes the switch
  /// semantics, so a screen reader does not announce the control twice.
  final bool includeSemantics;

  bool get enabled => onChanged != null;

  void _toggle() {
    Haptics.selection();
    onChanged!(!value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final motion = Motion.of(context);

    final trackColor = value
        ? (isDark ? AppColors.darkSage : AppColors.sage)
        : context.lineColor;
    final knobColor =
        value && isDark ? AppColors.darkOnAccent : AppColors.white;

    Widget control = AnimatedContainer(
      // The design's transition is 150ms; `micro` is the token nearest it and
      // a token is what the rest of the app animates on.
      duration: motion(AppDurations.micro),
      curve: AppCurves.out,
      width: trackWidth,
      height: trackHeight,
      padding: const EdgeInsets.all(trackInset),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: AnimatedAlign(
        duration: motion(AppDurations.micro),
        curve: AppCurves.out,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: knobSize,
          height: knobSize,
          decoration: BoxDecoration(
            color: knobColor,
            shape: BoxShape.circle,
            boxShadow: AppElevation.low(isDark),
          ),
        ),
      ),
    );

    if (!enabled) {
      control = Opacity(opacity: 0.45, child: control);
    }

    final target = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? _toggle : null,
      child: SizedBox(
        width: trackWidth,
        height: AppLayout.minTouchTarget,
        child: Center(child: control),
      ),
    );

    if (!includeSemantics) return ExcludeSemantics(child: target);

    return Semantics(
      container: true,
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      hint: semanticHint,
      // The action is restated here because the child's semantics are
      // excluded; without it the node would describe a switch nobody can
      // activate with assistive technology.
      onTap: enabled ? _toggle : null,
      excludeSemantics: true,
      child: target,
    );
  }
}

/// The design's `.sp-switch-row`: a title, a muted description and a trailing
/// [AppToggle], over a bottom hairline.
///
/// The whole row is the control. That is both what the boards imply and the
/// only way the description text is tappable, which matters more than it
/// sounds — the toggle itself is 43pt wide on a 342pt row.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
    this.showDivider = true,
    this.titleStyle,
    this.descriptionStyle,
  });

  /// `.sp-switch-row{padding:17px 0}`.
  static const double verticalPadding = 17;

  /// `gap:14px` between the copy and the toggle.
  static const double gap = 14;

  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showDivider;

  /// Set only where a dense page measures its own value; the defaults are the
  /// design's.
  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;

  bool get enabled => onChanged != null;

  void _toggle() {
    Haptics.selection();
    onChanged!(!value);
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.mutedColor;

    return Semantics(
      container: true,
      toggled: value,
      enabled: enabled,
      label: title,
      hint: description,
      onTap: enabled ? _toggle : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? _toggle : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: showDivider
                ? Border(
                    bottom: BorderSide(
                      color: context.lineColor,
                      width: AppStrokes.hairline,
                    ),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: verticalPadding),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: titleStyle ??
                            AppTextStyles.body(
                              fontSize: 14,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ).copyWith(
                              color: enabled
                                  ? context.inkColor
                                  : context.subtleColor,
                            ),
                      ),
                      if (description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            description!,
                            style: descriptionStyle ??
                                AppTextStyles.body(fontSize: 11, height: 1.6)
                                    .copyWith(color: muted),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: gap),
                AppToggle(
                  value: value,
                  onChanged: onChanged,
                  includeSemantics: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
