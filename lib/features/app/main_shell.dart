import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/haptics.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/glass.dart';
import '../../widgets/motion.dart';

const _destinations = <_Destination>[
  _Destination(icon: AppIcons.home, label: 'Today'),
  _Destination(icon: AppIcons.calendar, label: 'Calendar'),
  _Destination(icon: AppIcons.plus, label: 'Log', isLog: true),
  _Destination(icon: AppIcons.insights, label: 'Insights'),
  _Destination(icon: AppIcons.petBunny, label: 'Companion'),
];

@immutable
class _Destination {
  const _Destination({
    required this.icon,
    required this.label,
    this.isLog = false,
  });
  final IconData icon;
  final String label;
  final bool isLog;
}

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: context.canvasColor,
      // Resize once at the shell. Scaffold removes the consumed keyboard
      // inset from its body, keeping a nested form's save bar above the IME.
      resizeToAvoidBottomInset: true,
      // Keep the dock in layout: a branch's save bar must never sit behind it.
      extendBody: false,
      body: SizedBox.expand(
        key: const ValueKey('main-safe-content'),
        child: shell,
      ),
      bottomNavigationBar: keyboardVisible
          ? null
          : CycleNavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: (index) {
                if (shell.currentIndex != index) Haptics.selection();
                shell.goBranch(
                  index,
                  initialLocation: index == shell.currentIndex,
                );
              },
            ),
    );
  }
}

/// Floating navigation follows actual safe width and text size, not a device name.
/// Full labels remain available; enlarged text gets rows instead of smaller type.
class CycleNavigationBar extends StatelessWidget {
  const CycleNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: 'Main navigation',
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.accent.fill.withValues(alpha: 0.18),
                  PhaseColors.of(
                    context,
                  ).follicular.fill.withValues(alpha: 0.14),
                ],
              ),
            ),
            child: GlassSurface(
              key: const ValueKey('floating-navigation-surface'),
              tone: GlassTone.chrome,
              borderRadius: BorderRadius.circular(28),
              blur: 16,
              padding: const EdgeInsets.all(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scaler = MediaQuery.textScalerOf(context);
                  final widths = [
                    for (final d in _destinations)
                      _minimumItemWidth(context, d, scaler),
                  ];
                  final total = widths.reduce((a, b) => a + b);
                  final rowHeight = math.max(60.0, 38 + scaler.scale(11) * 1.3);
                  Widget item(int index) => _NavItem(
                    key: ValueKey('main-nav-$index'),
                    destination: _destinations[index],
                    selected: selectedIndex == index,
                    position: index,
                    onTap: () => onDestinationSelected(index),
                  );
                  if (total <= constraints.maxWidth) {
                    final extra = (constraints.maxWidth - total) / 5;
                    return SizedBox(
                      height: rowHeight,
                      child: Row(
                        children: [
                          for (var i = 0; i < _destinations.length; i++)
                            SizedBox(width: widths[i] + extra, child: item(i)),
                        ],
                      ),
                    );
                  }
                  final maxWidth = widths.reduce(math.max);
                  final columns = (constraints.maxWidth / maxWidth)
                      .floor()
                      .clamp(1, 5);
                  const gap = 4.0;
                  final width =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (var i = 0; i < _destinations.length; i++)
                        SizedBox(
                          width: width,
                          height: rowHeight,
                          child: item(i),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );

  double _minimumItemWidth(
    BuildContext context,
    _Destination d,
    TextScaler scaler,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: d.label,
        style: AppTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700),
      ),
      textScaler: scaler,
      textDirection: Directionality.of(context),
    )..layout();
    final result = math.max(
      AppLayout.minTouchTarget,
      painter.width.ceilToDouble() + 12,
    );
    painter.dispose();
    return result;
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.position,
    required this.onTap,
  });
  final _Destination destination;
  final bool selected;
  final int position;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final accent = context.accent;
    final color = selected ? accent.text : context.mutedColor;
    return Pressable(
      onTap: onTap,
      haptic: false,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      semanticLabel: destination.label,
      semanticValue: 'Tab ${position + 1} of ${_destinations.length}',
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(20),
      scale: 0.98,
      child: AnimatedContainer(
        duration: motion(AppDurations.fast),
        curve: AppCurves.out,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? accent.fill.withValues(alpha: context.isDark ? 0.25 : 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                destination.icon,
                size: 23,
                color: destination.isLog ? accent.text : color,
              ),
              const SizedBox(height: 4),
              Text(
                destination.label,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ).copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
