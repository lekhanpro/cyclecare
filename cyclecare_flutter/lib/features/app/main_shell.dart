import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../settings/settings_screen.dart';
import '../tracking/presentation/calendar_screen.dart';
import '../tracking/presentation/home_screen.dart';
import '../tracking/presentation/log_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: CycleCareColors.rose,
        inactiveColor: CycleCareColors.muted,
        backgroundColor: Colors.white.withOpacity(0.96),
        border: const Border(top: BorderSide(color: CycleCareColors.line)),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.heart_circle),
            activeIcon: Icon(CupertinoIcons.heart_circle_fill),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.calendar),
            activeIcon: Icon(CupertinoIcons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.add_circled),
            activeIcon: Icon(CupertinoIcons.add_circled_solid),
            label: 'Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.gear),
            activeIcon: Icon(CupertinoIcons.gear_solid),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        final screen = switch (index) {
          0 => const HomeScreen(),
          1 => const CalendarScreen(),
          2 => const LogScreen(),
          _ => const SettingsScreen(),
        };
        return CupertinoTabView(
          builder: (_) => screen,
        );
      },
    );
  }
}
