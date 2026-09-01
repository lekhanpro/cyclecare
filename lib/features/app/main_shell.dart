import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/cyclecare_theme.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < AppLayout.narrowWidth;

    return Scaffold(
      body: shell,
      bottomNavigationBar: Semantics(
        container: true,
        label: 'Primary navigation',
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: context.lineColor.withOpacity(context.isDark ? 0.82 : 0.72),
                width: AppStrokes.hairline,
              ),
            ),
          ),
          child: NavigationBar(
            height: compact
                ? AppLayout.compactNavigationBarHeight
                : AppLayout.navigationBarHeight,
            selectedIndex: shell.currentIndex,
            labelBehavior: compact
                ? NavigationDestinationLabelBehavior.onlyShowSelected
                : NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) => shell.goBranch(
              index,
              initialLocation: index == shell.currentIndex,
            ),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.favorite_border_rounded),
                selectedIcon: Icon(Icons.favorite_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Calendar',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline_rounded),
                selectedIcon: Icon(Icons.add_circle_rounded),
                label: 'Log',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights_rounded),
                label: 'Insights',
              ),
              NavigationDestination(
                icon: Icon(Icons.pets_outlined),
                selectedIcon: Icon(Icons.pets_rounded),
                label: 'Pet',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
