import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/haptics.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/motion.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Primary navigation
//
// The design's `nav.nav`: an 84 px paper band (9 px top padding, 56 px items,
// 18 px bottom padding that becomes the gesture inset on devices that have
// one) under a 1 px hairline. Five evenly spaced destinations, 23 px glyphs
// and small labels. The active one takes the accent text, weight 700, and a
// 31x3 accent bar at the top of the item, so selection is shown by position
// and weight as well as colour. The centre Log item is a 45x33 accent tile,
// pulled up 3 px, with its label below.
//
// Hand-built rather than Material's NavigationBar, whose pill indicator and
// fixed geometry cannot express the centre tile or the top bar.
//
// The label row is never hidden: icon-only tabs are a recognition problem,
// and hiding labels changes the bar's height as you navigate.
// ─────────────────────────────────────────────────────────────────────────────

const _destinations = <_Destination>[
  _Destination(icon: AppIcons.home, label: 'Today'),
  _Destination(icon: AppIcons.calendar, label: 'Calendar'),
  _Destination(icon: AppIcons.plus, label: 'Log', isLog: true),
  _Destination(icon: AppIcons.insights, label: 'Insights'),
  _Destination(icon: AppIcons.petBunny, label: 'Companion'),
];

/// `nav{padding:9px 12px 18px}`.
const double _navTopPadding = 9;
const double _navSidePadding = 12;

/// `nav button{height:56px}` — the item box inside the padding.
const double _itemHeight = 56;

/// `.nav svg{width:23px}`.
const double _iconSize = 23;

/// Label: the board sets 10 px; 11 px is the production floor for real text.
const double _labelSize = 11;
const double _labelLineHeight = 1.2;

/// The active bar: 31x3, radius 4, at the top of the item.
const double _indicatorWidth = 31;
const double _indicatorHeight = 3;

/// `.nav-plus`: 45x33, radius 12, margin-top -3.
const Size _logTileSize = Size(45, 33);
const double _logTileRadius = 12;
const double _logTileLift = 3;

/// Labels scale with the user's text size, up to a cap that keeps five
/// destinations on one row. The bar grows by whatever the label grows, so a
/// large text setting never clips it.
const double _maxLabelScale = 1.6;

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
    return Scaffold(
      // The hero bleeds under the status bar, which is a *top* concern and is
      // handled by the page not wrapping itself in a SafeArea.
      //
      // extendBody stays false. Setting it true pushes every branch's body to
      // full height, and the Log branch has its own Scaffold with a docked save
      // bar — that bar then lands underneath this one. Content scrolling behind
      // the bar would require every scroll view in the app to reserve the
      // bar's height, and getting that wrong hides the last row of a form.
      body: shell,
      bottomNavigationBar: _NavBar(shell: shell),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    // The design's 18 px bottom padding is the gesture inset where the OS
    // reports one, and the fallback where it does not.
    final bottom = math.max(
      MediaQuery.paddingOf(context).bottom,
      AppLayout.navigationBarMinInset,
    );
    final requestedScaler = MediaQuery.textScalerOf(context);
    final enlarged =
        requestedScaler.scale(_labelSize) > _labelSize * 1.3 &&
        MediaQuery.sizeOf(context).width < 600;
    final scaler = enlarged
        ? requestedScaler
        : requestedScaler.clamp(maxScaleFactor: _maxLabelScale);
    final baseLabel = _labelSize * _labelLineHeight;
    final labelGrowth = math.max(
      0.0,
      scaler.scale(_labelSize) * _labelLineHeight - baseLabel,
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Main navigation',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.cardColor,
          border: Border(
            top: BorderSide(
              color: context.lineColor,
              width: AppStrokes.hairline,
            ),
          ),
        ),
        child: Padding(
          // The inset is honoured here rather than by a SafeArea so the bar's
          // own fill still reaches the bottom of the window.
          padding: EdgeInsets.fromLTRB(
            _navSidePadding,
            _navTopPadding,
            _navSidePadding,
            bottom,
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: scaler),
            child: LayoutBuilder(
              builder: (context, constraints) {
                Widget item(int index) => _NavItem(
                  destination: _destinations[index],
                  selected: shell.currentIndex == index,
                  position: index,
                  count: _destinations.length,
                  onTap: () {
                    if (shell.currentIndex != index) Haptics.selection();
                    shell.goBranch(
                      index,
                      initialLocation: index == shell.currentIndex,
                    );
                  },
                );
                if (enlarged) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var index = 0; index < _destinations.length; index++)
                        SizedBox(
                          width: (constraints.maxWidth - 8) / 2,
                          height: _itemHeight + labelGrowth,
                          child: item(index),
                        ),
                    ],
                  );
                }
                return SizedBox(
                  height: _itemHeight + labelGrowth,
                  child: Row(
                    children: [
                      for (var index = 0; index < _destinations.length; index++)
                        Expanded(child: item(index)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.position,
    required this.count,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final int position;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final accent = context.accent;
    final color = selected ? accent.text : context.mutedColor;

    final label = Text(
      destination.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: AppTextStyles.body(
        fontSize: _labelSize,
        height: _labelLineHeight,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
      ).copyWith(color: color),
    );

    final Widget glyph = destination.isLog
        ? Transform.translate(
            offset: const Offset(0, -_logTileLift),
            child: Container(
              width: _logTileSize.width,
              height: _logTileSize.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.fill,
                borderRadius: BorderRadius.circular(_logTileRadius),
              ),
              child: Icon(
                destination.icon,
                size: _iconSize,
                color: accent.onFill,
              ),
            ),
          )
        : Icon(destination.icon, size: _iconSize, color: color);

    // `.nav button{padding:1px 6px;gap:4px}`. The Log tile is 10 px taller than
    // a glyph and is pulled up 3, so its label sits 7 px lower, as measured.
    final glyphGap = destination.isLog ? 4.0 - _logTileLift : 4.0;

    return Pressable(
      onTap: onTap,
      haptic: false,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      semanticLabel: destination.label,
      semanticValue: 'Tab ${position + 1} of $count',
      excludeChildSemantics: true,
      scale: 0.94,
      // No borderRadius: Pressable clips to it, which would hide the active
      // bar drawn above the item in the nav's top padding.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 1, 6, 0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                glyph,
                SizedBox(height: glyphGap),
                label,
              ],
            ),
          ),
          // Active bar at the top of the item. Animated in width so the move
          // between tabs reads, and instant under reduced motion.
          PositionedDirectional(
            top: -_navTopPadding,
            start: 0,
            end: 0,
            child: Center(
              child: AnimatedContainer(
                duration: motion(AppDurations.fast),
                curve: AppCurves.out,
                width: selected ? _indicatorWidth : 0,
                height: _indicatorHeight,
                decoration: BoxDecoration(
                  color: accent.fill,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
