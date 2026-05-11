import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/cyclecare_theme.dart';
import '../core/utils/date_helpers.dart';
import '../features/tracking/domain/cycle_models.dart';
import 'soft_card.dart';

class CycleSummaryCard extends StatelessWidget {
  const CycleSummaryCard({
    required this.prediction,
    required this.onLogPeriod,
    super.key,
  });

  final CyclePrediction? prediction;
  final VoidCallback onLogPeriod;

  @override
  Widget build(BuildContext context) {
    final forecast = prediction;
    return SoftCard(
      color: const Color(0xFFFFFCFB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CycleCareColors.predicted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  CupertinoIcons.heart_fill,
                  color: CycleCareColors.rose,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 13,
                        color: CycleCareColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      forecast == null
                          ? 'Start with your last period'
                          : forecast.isLate
                              ? '${forecast.daysLate} days late'
                              : 'Cycle day ${forecast.cycleDay}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: CycleCareColors.ink,
                          ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: CycleCareColors.rose,
                borderRadius: BorderRadius.circular(16),
                onPressed: onLogPeriod,
                child: const Text('Log'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            forecast == null
                ? 'Add a period date and CycleCare will estimate your next window.'
                : forecast.isLate
                    ? 'Your period was expected around ${shortDate(forecast.nextPeriodStart)}. This can happen for many reasons; seek support if you are concerned.'
                    : 'Next period is expected ${shortDate(forecast.nextPeriodStart)}-${shortDate(forecast.nextPeriodEnd)}.',
            style: const TextStyle(
              color: CycleCareColors.ink,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MetricPill(
                label: forecast?.isLate == true ? 'Late by' : 'In',
                value: forecast == null
                    ? '--'
                    : forecast.isLate
                        ? '${forecast.daysLate} days'
                        : '${forecast.daysUntilPeriod} days',
              ),
              const SizedBox(width: 10),
              _MetricPill(
                label: 'Phase',
                value: forecast == null ? '--' : forecast.phase,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: CycleCareColors.cream,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: CycleCareColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: CycleCareColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
