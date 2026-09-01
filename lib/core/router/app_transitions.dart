import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_motion.dart';

// Material-forward transitions for routes outside the stable navigation shell.
// Frequent branch changes remain unanimated inside StatefulNavigationShell.

/// A crisp Material depth transition for detail routes.
CustomTransitionPage<T> pushPage<T>({
  required Widget child,
  String? name,
}) {
  return CustomTransitionPage<T>(
    name: name,
    child: child,
    transitionDuration: AppDurations.navigation,
    reverseTransitionDuration: AppDurations.exit,
    transitionsBuilder: (context, animation, secondary, child) {
      final motion = Motion.of(context);
      final eased = CurvedAnimation(
        parent: animation,
        curve: AppCurves.out,
        reverseCurve: AppCurves.out,
      );

      if (motion.reduced) {
        return FadeTransition(opacity: eased, child: child);
      }

      return FadeTransition(
        opacity: Tween<double>(begin: 0.18, end: 1).animate(eased),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: motion.scale(0.985),
            end: 1,
          ).animate(eased),
          child: child,
        ),
      );
    },
  );
}

/// An interrupting task rises slightly from the bottom in Material fashion.
CustomTransitionPage<T> modalPage<T>({
  required Widget child,
  String? name,
}) {
  return CustomTransitionPage<T>(
    name: name,
    child: child,
    transitionDuration: AppDurations.modal,
    reverseTransitionDuration: AppDurations.exit,
    transitionsBuilder: (context, animation, secondary, child) {
      final motion = Motion.of(context);
      final eased = CurvedAnimation(
        parent: animation,
        curve: AppCurves.out,
        reverseCurve: AppCurves.out,
      );

      if (motion.reduced) {
        return FadeTransition(opacity: eased, child: child);
      }

      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, motion.offset(0.045)),
          end: Offset.zero,
        ).animate(eased),
        child: FadeTransition(opacity: eased, child: child),
      );
    },
  );
}

/// Root-level swap with no spatial relationship to imply.
CustomTransitionPage<T> fadePage<T>({
  required Widget child,
  String? name,
}) {
  return CustomTransitionPage<T>(
    name: name,
    child: child,
    transitionDuration: AppDurations.normal,
    reverseTransitionDuration: AppDurations.exit,
    transitionsBuilder: (context, animation, secondary, child) {
      final eased = CurvedAnimation(parent: animation, curve: AppCurves.out);
      return FadeTransition(opacity: eased, child: child);
    },
  );
}
