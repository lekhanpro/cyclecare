import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import 'pet_care.dart';
import 'pet_models.dart';
import 'pet_painter.dart';

/// The pet, alive: breathing, blinking now and then, and hopping when tapped.
///
/// Under reduced motion it holds a resting pose with its eyes open. Its mood
/// and stage still show, so nothing is lost but the movement.
class PetCharacter extends StatefulWidget {
  const PetCharacter({
    super.key,
    required this.type,
    required this.mood,
    required this.stage,
    required this.size,
    this.onTap,
    this.semanticLabel,
  });

  final PetType type;
  final PetMood mood;
  final PetStage stage;
  final double size;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<PetCharacter> createState() => _PetCharacterState();
}

class _PetCharacterState extends State<PetCharacter>
    with TickerProviderStateMixin {
  late final _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  late final _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );
  late final _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  Timer? _blinkTimer;
  final _random = math.Random();
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = Motion.of(context).reduced;
    if (_reduced) {
      _blinkTimer?.cancel();
      _breath
        ..stop()
        ..value = 0.5;
      _blink.value = 0;
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
      _scheduleBlink();
    }
  }

  /// Every few seconds, at an uneven interval, so it never looks mechanical.
  void _scheduleBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer(
      Duration(milliseconds: 2500 + _random.nextInt(3500)),
      () async {
        if (!mounted || _reduced) return;
        await _blink.forward();
        if (mounted) await _blink.reverse();
        if (mounted) _scheduleBlink();
      },
    );
  }

  void _tap() {
    if (!_reduced) _bounce.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _breath.dispose();
    _blink.dispose();
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breath, _blink, _bounce]),
        builder: (context, _) => CustomPaint(
          painter: PetPainter(
            type: widget.type,
            mood: widget.mood,
            stage: widget.stage,
            breath: Curves.easeInOut.transform(_breath.value),
            blink: _blink.value,
            bounce: Curves.easeOut.transform(_bounce.value),
          ),
        ),
      ),
    );

    return Semantics(
      label: widget.semanticLabel,
      button: widget.onTap != null,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: widget.onTap == null ? null : _tap,
          behavior: HitTestBehavior.opaque,
          child: body,
        ),
      ),
    );
  }
}
