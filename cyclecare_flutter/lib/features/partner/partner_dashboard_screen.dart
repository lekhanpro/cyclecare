import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/services/partner_service.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/soft_card.dart';

class PartnerDashboardScreen extends ConsumerWidget {
  const PartnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnerLink = ref.watch(partnerLinkForMeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Partner View')),
      body: partnerLink.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (_, __) => const Center(
          child: Text('Unable to load partner data'),
        ),
        data: (link) {
          if (link == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.person_2,
                        size: 64, color: CycleCareColors.muted),
                    SizedBox(height: 16),
                    Text(
                      'No partner connected',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: CycleCareColors.ink,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ask your partner to share their invite code with you from their Partner Sharing settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CycleCareColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return _PartnerData(link: link);
        },
      ),
    );
  }
}

class _PartnerData extends ConsumerWidget {
  const _PartnerData({required this.link});

  final PartnerLink link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedData = ref.watch(partnerSharedDataProvider(link.ownerUid));

    return sharedData.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (_, __) => const Center(child: Text('Unable to load data')),
      data: (data) {
        if (data == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Your partner has not shared any data yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: CycleCareColors.muted),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            SoftCard(
              color: const Color(0xFFFFFCFB),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: CycleCareColors.predicted,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(CupertinoIcons.heart_fill,
                        color: CycleCareColors.rose),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          link.ownerDisplayName ?? 'Your partner',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: CycleCareColors.ink,
                          ),
                        ),
                        if (data.updatedAt != null)
                          Text(
                            'Updated ${_timeAgo(data.updatedAt!)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: CycleCareColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (link.shareCyclePhase && data.currentPhase != null)
              _DataCard(
                icon: CupertinoIcons.circle_grid_hex,
                title: 'Cycle Phase',
                value: data.currentPhase!,
                subtitle: data.cycleDay != null
                    ? 'Day ${data.cycleDay}'
                    : null,
                color: CycleCareColors.lavender,
              ),
            if (link.sharePeriodPrediction && data.daysUntilPeriod != null)
              _DataCard(
                icon: CupertinoIcons.calendar,
                title: 'Next Period',
                value: '${data.daysUntilPeriod} days away',
                subtitle: data.nextPeriodDate,
                color: CycleCareColors.predicted,
              ),
            if (link.shareMoodSummary && data.mood != null)
              _DataCard(
                icon: CupertinoIcons.smiley,
                title: 'Mood',
                value: data.mood!,
                color: CycleCareColors.fertile,
              ),
            if (link.shareSymptoms &&
                data.symptoms != null &&
                data.symptoms!.isNotEmpty)
              _DataCard(
                icon: CupertinoIcons.bandage,
                title: 'Symptoms',
                value: data.symptoms!.join(', '),
                color: const Color(0xFFFFECB3),
              ),
            if (link.shareFlow && data.flow != null)
              _DataCard(
                icon: CupertinoIcons.drop,
                title: 'Flow',
                value: data.flow!,
                color: CycleCareColors.predicted,
              ),
            if (data.confidence != null)
              _DataCard(
                icon: CupertinoIcons.chart_bar,
                title: 'Prediction Confidence',
                value: '${(data.confidence! * 100).round()}%',
                color: CycleCareColors.ovulation,
              ),
            const SizedBox(height: 18),
            const SoftCard(
              child: Row(
                children: [
                  Icon(CupertinoIcons.lock_shield,
                      color: CycleCareColors.muted, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This is a read-only view. Your partner controls what data is shared.',
                      style: TextStyle(
                        color: CycleCareColors.muted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: CycleCareColors.ink, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CycleCareColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: CycleCareColors.ink,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CycleCareColors.muted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
