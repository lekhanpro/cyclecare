// Kit gallery and the bottom navigation, light and dark.
//
// Run: tool/dev/flutterq.sh test --dart-define=SHOTS=true test/shots/kit_shots_test.dart
// Layout evidence only; behaviour lives in test/widget/kit_controls_test.dart.

import 'package:cyclecare/core/theme/app_icons.dart';
import 'package:cyclecare/core/theme/app_tokens.dart';
import 'package:cyclecare/widgets/widgets.dart';
import 'package:flutter/material.dart';

import 'shot_harness.dart';

class _Gallery extends StatelessWidget {
  const _Gallery();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          children: [
            const PageHeader(eyebrow: 'Kit', title: 'Controls'),
            Row(
              children: [
                Expanded(
                  child: FilledButton(onPressed: () {}, child: const Text('Save')),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(onPressed: () {}, child: const Text('Later')),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                TextButton(onPressed: () {}, child: const Text('See all')),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  tooltip: 'Search',
                  icon: const Icon(AppIcons.search),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(label: 'Log today', icon: AppIcons.plus, onPressed: () {}),
            const SizedBox(height: AppSpacing.md),
            const TextField(
              decoration: InputDecoration(hintText: 'Add a note'),
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedTabs<int>(
              segments: const [
                SegmentOption(value: 0, label: 'Month'),
                SegmentOption(value: 1, label: 'Week'),
                SegmentOption(value: 2, label: 'Year'),
              ],
              value: 0,
              onChanged: (_) {},
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                SelectableChip(label: 'Cramps', selected: true, onSelected: (_) {}),
                SelectableChip(label: 'Headache', selected: false, onSelected: (_) {}),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListRow(
                    title: 'Reminders',
                    subtitle: 'Period, pill and check-in',
                    icon: AppIcons.reminders,
                    value: '3 on',
                    showChevron: true,
                    onTap: () {},
                  ),
                  SwitchRow(
                    title: 'Show fertile window',
                    value: true,
                    onChanged: (_) {},
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const InfoBanner(
              title: 'Estimates',
              message: 'Predictions improve as you log more cycles.',
            ),
            const SizedBox(height: AppSpacing.md),
            const SkeletonListRows(count: 2, animate: false),
            const SizedBox(
              height: 360,
              child: EmptyStateView(
                title: 'Nothing logged yet',
                message: 'Your first check-in starts the picture.',
                icon: AppIcons.notes,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testShot('kit gallery $mode', (tester) async {
      await pumpShotScreen(tester, const _Gallery(), dark: dark, height: 1500);
      await captureShot(tester, 'kit-gallery-$mode');
    });
    testShot('home nav $mode', (tester) async {
      await pumpShotApp(tester, route: '/home', dark: dark);
      await captureShot(tester, 'kit-home-nav-$mode');
    });
  }
}
