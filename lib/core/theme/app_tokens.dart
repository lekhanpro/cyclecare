import 'package:flutter/material.dart';

/// Shared spacing values. Prefer the semantic inset roles below when a
/// component has a well-known layout responsibility.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
}

/// One radius vocabulary keeps controls related without making every surface
/// the same shape.
class AppRadii {
  AppRadii._();

  static const double connected = 4;
  static const double compact = 10;
  static const double control = 14;
  static const double calendarDay = 15;
  static const double card = 22;
  static const double sheet = 28;
  static const double pill = 999;
}

/// Layout roles shared by themes and custom widgets.
class AppLayout {
  AppLayout._();

  static const double minTouchTarget = 48;
  static const double buttonHeight = 52;
  static const double navigationBarHeight = 76;
  static const double compactNavigationBarHeight = 72;
  static const double narrowWidth = 360;
  static const double maxContentWidth = 720;

  static double pageGutterFor(double width) =>
      width < narrowWidth ? AppSpacing.lg : AppSpacing.xl;
}

/// Reusable component insets. Screen-specific composition can still combine
/// spacing tokens without inventing a parallel scale.
class AppInsets {
  AppInsets._();

  static const EdgeInsets card = EdgeInsets.all(18);
  static const EdgeInsets compactCard = EdgeInsets.all(14);
  static const EdgeInsets control = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  );
  static const EdgeInsets sheet = EdgeInsets.fromLTRB(
    AppSpacing.xl,
    AppSpacing.md,
    AppSpacing.xl,
    AppSpacing.xxl,
  );
}

class AppStrokes {
  AppStrokes._();

  static const double hairline = 1;
  static const double selected = 1.5;
  static const double focus = 2;
}
