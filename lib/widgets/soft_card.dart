import 'package:flutter/material.dart';

import 'app_card.dart';

/// The app's original card, now a thin delegate over [AppCard].
///
/// Kept as its own name because a dozen screens import it. Routing it through
/// [AppCard] means those screens pick up the shared shadow, radius, press
/// response, and dark-mode fill without each one needing to be touched.
///
/// New code should prefer [AppCard] directly — it exposes emphasis levels and
/// border control that this signature cannot express.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.margin,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      color: color,
      onTap: onTap,
      margin: margin,
      borderRadius: borderRadius,
      child: child,
    );
  }
}
