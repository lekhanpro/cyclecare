import 'dart:async';

import 'package:flutter/material.dart';

import '../core/services/haptics.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Motion primitives
// ─────────────────────────────────────────────────────────────────────────────

/// Adds Material press, focus, keyboard, and semantic behavior to a custom
/// surface while keeping the surface's own layout and decoration intact.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.haptic = true,
    this.borderRadius,
    this.behavior = HitTestBehavior.opaque,
    this.enabled,
    this.selected,
    this.semanticLabel,
    this.semanticValue,
    this.semanticHint,
    this.semanticButton = true,
    this.excludeChildSemantics = false,
    this.liveRegion = false,
    this.inMutuallyExclusiveGroup = false,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
    this.minimumSize = const Size.square(AppLayout.minTouchTarget),
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Resting-to-pressed scale. Large surfaces generally use a subtler value.
  final double scale;

  final bool haptic;
  final BorderRadius? borderRadius;
  final HitTestBehavior behavior;

  /// Optional explicit state keeps intentionally disabled controls exposed as
  /// disabled buttons instead of turning them into unlabelled decoration.
  final bool? enabled;
  final bool? selected;
  final String? semanticLabel;
  final String? semanticValue;
  final String? semanticHint;
  final bool semanticButton;
  final bool excludeChildSemantics;
  final bool liveRegion;
  final bool inMutuallyExclusiveGroup;
  final FocusNode? focusNode;
  final bool autofocus;
  final MouseCursor? mouseCursor;
  final Size minimumSize;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  bool _focused = false;

  bool get _hasAction => widget.onTap != null || widget.onLongPress != null;
  bool get _enabled => (widget.enabled ?? true) && _hasAction;
  bool get _isControl =>
      widget.enabled != null || _hasAction || widget.selected != null;

  void _setDown(bool value) {
    if (!_enabled || _down == value) return;
    setState(() => _down = value);
  }

  void _setFocused(bool value) {
    if (_focused == value) return;
    setState(() => _focused = value);
  }

  void _handleTap() {
    if (!_enabled || widget.onTap == null) return;
    if (widget.haptic) Haptics.tap();
    widget.onTap!();
  }

  void _handleLongPress() {
    if (!_enabled || widget.onLongPress == null) return;
    if (widget.haptic) Haptics.longPress();
    widget.onLongPress!();
  }

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final scheme = Theme.of(context).colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.zero;

    final overlay = WidgetStateProperty.resolveWith<Color?>((states) {
      if (!_enabled) return Colors.transparent;
      if (states.contains(WidgetState.pressed)) {
        return scheme.primary.withOpacity(
          Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.11,
        );
      }
      if (states.contains(WidgetState.focused)) {
        return scheme.primary.withOpacity(
          Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.09,
        );
      }
      if (states.contains(WidgetState.hovered)) {
        return scheme.primary.withOpacity(
          Theme.of(context).brightness == Brightness.dark ? 0.11 : 0.06,
        );
      }
      return null;
    });

    final surface = Material(
      type: MaterialType.transparency,
      borderRadius: radius,
      clipBehavior:
          widget.borderRadius == null ? Clip.none : Clip.antiAlias,
      child: InkWell(
        onTap: _enabled && widget.onTap != null ? _handleTap : null,
        onLongPress:
            _enabled && widget.onLongPress != null ? _handleLongPress : null,
        onHighlightChanged: _setDown,
        onFocusChange: _setFocused,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        canRequestFocus: _enabled,
        mouseCursor: widget.mouseCursor,
        borderRadius: radius,
        overlayColor: overlay,
        splashFactory: Theme.of(context).splashFactory,
        excludeFromSemantics: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minimumSize.width,
            minHeight: widget.minimumSize.height,
          ),
          child: AnimatedScale(
            scale: _down ? motion.scale(widget.scale) : 1,
            duration: motion(AppDurations.press),
            curve: AppCurves.out,
            child: AnimatedContainer(
              duration: motion(AppDurations.press),
              curve: AppCurves.out,
              foregroundDecoration: _focused
                  ? BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                        color: scheme.primary,
                        width: AppStrokes.focus,
                      ),
                    )
                  : null,
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (!_isControl &&
        widget.semanticLabel == null &&
        widget.semanticValue == null &&
        widget.semanticHint == null) {
      return surface;
    }

    return Semantics(
      button: widget.semanticButton && _isControl,
      enabled: _isControl ? _enabled : null,
      selected: widget.selected,
      label: widget.semanticLabel,
      value: widget.semanticValue,
      hint: widget.semanticHint,
      liveRegion: widget.liveRegion,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup,
      excludeSemantics: widget.excludeChildSemantics,
      onTap: _enabled && widget.onTap != null ? _handleTap : null,
      onLongPress:
          _enabled && widget.onLongPress != null ? _handleLongPress : null,
      child: surface,
    );
  }
}

/// Fades and lifts a widget into place on first build.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.index = 0,
    this.duration,
    this.offsetY = 14,
    this.scaleFrom = 0.98,
    this.enabled = true,
  });

  final Widget child;

  /// Position in the cascade. Delay is [index] × [AppDurations.staggerStep],
  /// capped so long lists never leave the last item visibly waiting.
  final int index;

  final Duration? duration;
  final double offsetY;
  final double scaleFrom;

  /// Set false to render at rest immediately.
  final bool enabled;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delay;
  bool _scheduled = false;
  bool? _reduced;

  static const _maxStaggerSlots = 8;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? AppDurations.normal,
      value: widget.enabled ? 0 : 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configureMotion();
  }

  @override
  void didUpdateWidget(Reveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    final configurationChanged = oldWidget.enabled != widget.enabled ||
        oldWidget.index != widget.index ||
        oldWidget.duration != widget.duration;
    if (!configurationChanged) return;

    _delay?.cancel();
    _delay = null;
    _scheduled = false;
    _controller.value = widget.enabled ? 0 : 1;
    _configureMotion();
  }

  void _configureMotion() {
    final motion = Motion.of(context);
    _controller.duration = motion(widget.duration ?? AppDurations.normal);

    if (!widget.enabled) {
      _delay?.cancel();
      _controller.value = 1;
      _scheduled = true;
      _reduced = motion.reduced;
      return;
    }

    // If reduce-motion is enabled while a stagger is waiting, release it
    // immediately rather than preserving a decorative delay.
    if (_scheduled) {
      if (motion.reduced && _reduced != true && _delay?.isActive == true) {
        _delay?.cancel();
        _delay = null;
        _controller.forward();
      }
      _reduced = motion.reduced;
      return;
    }

    _scheduled = true;
    _reduced = motion.reduced;
    final slots = widget.index.clamp(0, _maxStaggerSlots);
    final delay = motion.delay(AppDurations.staggerStep * slots);
    if (delay == Duration.zero) {
      _controller.forward();
      return;
    }

    _delay = Timer(delay, () {
      _delay = null;
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);

    if (motion.reduced) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: AppCurves.fade),
        child: widget.child,
      );
    }

    final eased = CurvedAnimation(parent: _controller, curve: AppCurves.out);

    return AnimatedBuilder(
      animation: eased,
      builder: (context, child) {
        final t = eased.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, motion.offset(widget.offsetY) * (1 - t)),
            child: Transform.scale(
              scale: motion.scale(widget.scaleFrom) +
                  (1 - motion.scale(widget.scaleFrom)) * t,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Cross-fades between two children with a subtle scale handover.
class BlurSwap extends StatelessWidget {
  const BlurSwap({
    super.key,
    required this.child,
    this.duration,
  });

  final Widget child;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    return AnimatedSwitcher(
      duration: motion(duration ?? AppDurations.fast),
      switchInCurve: AppCurves.out,
      switchOutCurve: AppCurves.out,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.center,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: motion.reduced
            ? child
            : ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
                child: child,
              ),
      ),
      child: child,
    );
  }
}

/// Animates a number toward its new value instead of hard-cutting.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.duration,
    this.suffix,
  });

  final int value;
  final TextStyle? style;
  final Duration? duration;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: motion(duration ?? AppDurations.normal),
      curve: AppCurves.inOut,
      builder: (context, animated, _) => Text(
        '${animated.round()}${suffix ?? ''}',
        style: style,
      ),
    );
  }
}
