import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/soft_card.dart';
import '../app/main_shell.dart';
import '../tracking/application/cycle_tracker_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  DateTime _lastPeriod = DateTime.now().subtract(const Duration(days: 7));
  double _cycleLength = 28;
  double _periodLength = 5;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<CycleTrackerState>>(
      cycleTrackerControllerProvider,
      (_, next) {
        if (next.valueOrNull?.preferences.onboardingCompleted == true) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const MainShell()),
            (_) => false,
          );
        }
      },
    );
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
          children: [
            const Text(
              'CycleCare',
              style: TextStyle(
                color: CycleCareColors.ink,
                fontSize: 40,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set your basics once. Everything stays on this device.',
              style: TextStyle(
                color: CycleCareColors.muted,
                fontSize: 17,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last period start',
                    style: TextStyle(
                      color: CycleCareColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CycleCareColors.cream,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        '${_lastPeriod.month}/${_lastPeriod.day}/${_lastPeriod.year}',
                        style: const TextStyle(
                          color: CycleCareColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SliderCard(
              label: 'Typical cycle length',
              value: _cycleLength,
              min: 21,
              max: 45,
              onChanged: (value) => setState(() => _cycleLength = value),
            ),
            const SizedBox(height: 16),
            _SliderCard(
              label: 'Typical period length',
              value: _periodLength,
              min: 2,
              max: 10,
              onChanged: (value) => setState(() => _periodLength = value),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Start tracking',
              icon: CupertinoIcons.heart,
              onPressed: () {
                ref.read(cycleTrackerControllerProvider.notifier).completeOnboarding(
                      lastPeriodStart: _lastPeriod,
                      cycleLength: _cycleLength.round(),
                      periodLength: _periodLength.round(),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriod,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _lastPeriod = picked);
    }
  }
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: CycleCareColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${value.round()} days',
            style: const TextStyle(
              color: CycleCareColors.rose,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            label: '${value.round()}',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
