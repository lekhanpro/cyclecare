import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';
import '../tracking/application/cycle_tracker_controller.dart';
import '../tracking/domain/cycle_models.dart';
import 'application/partner_sharing_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Partner sharing
//
// This screen used to generate a random invite code, display it, and do nothing
// with it. There was no backend behind it and no partner ever received
// anything — the code was decoration. An affordance that fabricates a result is
// worse than a missing feature, because the user acts on it.
//
// The honest version does what the app can actually deliver today: it builds a
// summary from real cycle data on this device, lets the user choose exactly what
// goes in, shows them the finished text, and hands it to the OS share sheet. It
// is a manual snapshot rather than a live feed, and every piece of copy on the
// screen says so rather than implying sync.
//
// Three principles govern what may be shared:
//  • Nothing leaves the device without an explicit tap on Share or Copy. There
//    is no automatic or background path, and none may be added.
//  • Every field is a switch, and the sensitive ones start off. Cycle data is
//    used to coerce and control people, so over-sharing is never the path of
//    least resistance.
//  • The preview is the payload. The string on screen is the identical string
//    that gets shared, so consent is given to words rather than to a promise.
// ─────────────────────────────────────────────────────────────────────────────

/// Font size used to probe the current text scale. Dense rows swap to a stacked
/// variant instead of clipping a label or pushing an action off screen.
const double _textScaleProbe = 14;

double _textScaleOf(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(_textScaleProbe) / _textScaleProbe;

class PartnerScreen extends ConsumerWidget {
  const PartnerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cycleTrackerControllerProvider);
    final options = ref.watch(partnerSharingProvider);

    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(title: const Text('Share with partner')),
      body: state.when(
        loading: () => const _LoadingPartner(),
        error: (error, _) => _LoadFailure(error: error),
        data: (data) {
          if (data.prediction == null) {
            return const _PageShell(
              fillViewport: true,
              child: EmptyState(
                emoji: '💑',
                title: 'Nothing to share yet',
                message: 'Log a period first. Once CycleCare can estimate your '
                    'cycle, you can build a summary and share it with someone '
                    'you trust.',
              ),
            );
          }

          return _PartnerBody(
            summary: buildPartnerSummary(data: data, options: options),
            options: options,
          );
        },
      ),
    );
  }
}

/// Page scaffolding shared by every state: safe area, a width-aware gutter, and
/// a content column that stops growing at [AppLayout.maxContentWidth] and
/// centres itself on tablets.
class _PageShell extends StatelessWidget {
  const _PageShell({required this.child, this.fillViewport = false});

  final Widget child;

  /// Stretches the content to at least one viewport height, so a short
  /// placeholder sits centred rather than pinned under the app bar.
  final bool fillViewport;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = AppLayout.pageGutterFor(constraints.maxWidth);

          Widget content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.maxContentWidth,
              ),
              child: child,
            ),
          );

          if (fillViewport) {
            content = ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: content,
            );
          }

          return SingleChildScrollView(
            padding: fillViewport
                ? EdgeInsets.symmetric(horizontal: gutter)
                : EdgeInsets.fromLTRB(
                    gutter,
                    AppSpacing.md,
                    gutter,
                    AppSpacing.xxxl,
                  ),
            child: content,
          );
        },
      ),
    );
  }
}

class _LoadingPartner extends StatelessWidget {
  const _LoadingPartner();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: AppSpacing.xxl,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  semanticsLabel: 'Loading your cycle',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Reading your cycle from this device',
                textAlign: TextAlign.center,
                style: text.labelLarge?.copyWith(color: context.mutedColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadFailure extends ConsumerWidget {
  const _LoadFailure({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final detail = error.toString().trim();

    return _PageShell(
      fillViewport: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'We could not load your cycle',
            message: 'Nothing was lost, and nothing was shared — your entries '
                'stay on this device. Try again.',
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(cycleTrackerControllerProvider),
          ),
          Text(
            'Reference: ${error.runtimeType}',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.labelSmall?.copyWith(color: context.subtleColor),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              detail,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(color: context.subtleColor),
            ),
          ],
        ],
      ),
    );
  }
}

class _PartnerBody extends StatelessWidget {
  const _PartnerBody({required this.summary, required this.options});

  final String summary;
  final PartnerSharingOptions options;

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Reveal(offsetY: AppSpacing.md, child: _Intro()),
          const SizedBox(height: AppSpacing.xl),
          const Reveal(
            index: 1,
            offsetY: AppSpacing.md,
            child: _SectionTitle(
              title: 'What to include',
              subtitle: 'Nothing is included unless its switch is on',
            ),
          ),
          Reveal(
            index: 2,
            offsetY: AppSpacing.md,
            child: _OptionsCard(options: options),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Reveal(
            index: 3,
            offsetY: AppSpacing.md,
            child: _SectionTitle(
              title: 'Preview',
              subtitle: 'Word for word, this is all your partner receives',
            ),
          ),
          Reveal(
            index: 4,
            offsetY: AppSpacing.md,
            child: _PreviewCard(summary: summary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Reveal(
            index: 5,
            offsetY: AppSpacing.md,
            child: _ShareActions(summary: summary),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Reveal(
            index: 6,
            offsetY: AppSpacing.md,
            child: InfoBanner(
              icon: Icons.lock_rounded,
              tone: AppColors.info,
              title: 'A snapshot, not a live link',
              message: 'This is a one-off copy of the text above, made on this '
                  'device when you tap Share or Copy. Your partner gets no '
                  'account, no link, and no access to your history, and the '
                  'text never updates on its own. Nothing is sent in the '
                  'background — share again whenever you want to.',
            ),
          ),
        ],
      ),
    );
  }
}

/// What this screen is, before the user turns anything on.
class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return MergeSemantics(
      child: AppCard(
        emphasis: CardEmphasis.tinted,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Container(
                width: AppLayout.minTouchTarget,
                height: AppLayout.minTouchTarget,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.accentColor
                      .withOpacity(context.isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('💑', style: text.headlineSmall),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You choose every word',
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: context.inkColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'CycleCare builds a short summary here on your phone. '
                    'Nothing leaves the device until you tap Share or Copy.',
                    style: text.bodySmall?.copyWith(
                      color: context.isDark
                          ? context.inkColor.withOpacity(0.86)
                          : context.mutedColor,
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

/// Section label, announced as a heading so a screen reader can jump between
/// groups instead of reading the page end to end.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        header: true,
        child: SectionHeader(
          title: title,
          subtitle: subtitle,
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            right: AppSpacing.xs,
            bottom: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}

class _OptionsCard extends ConsumerWidget {
  const _OptionsCard({required this.options});

  final PartnerSharingOptions options;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(partnerSharingProvider.notifier);

    final rows = <Widget>[
      _OptionRow(
        icon: Icons.donut_large_rounded,
        title: 'Cycle phase',
        subtitle: 'Which phase you are in right now',
        value: options.sharePhase,
        onChanged: controller.setSharePhase,
      ),
      _OptionRow(
        icon: Icons.event_rounded,
        title: 'Next period',
        subtitle: 'How many days until it is expected',
        value: options.shareNextPeriod,
        onChanged: controller.setShareNextPeriod,
      ),
      _OptionRow(
        icon: Icons.mood_rounded,
        title: "Today's mood",
        subtitle: 'Only if you logged one today',
        value: options.shareMood,
        onChanged: controller.setShareMood,
        sensitive: true,
      ),
      _OptionRow(
        icon: Icons.healing_rounded,
        title: "Today's symptoms",
        subtitle: 'What you logged feeling today',
        value: options.shareSymptoms,
        onChanged: controller.setShareSymptoms,
        sensitive: true,
      ),
      _OptionRow(
        icon: Icons.spa_rounded,
        title: 'Fertile window',
        subtitle: 'The dates CycleCare estimates as fertile',
        value: options.shareFertileWindow,
        onChanged: controller.setShareFertileWindow,
        sensitive: true,
      ),
      _OptionRow(
        icon: Icons.favorite_rounded,
        title: 'A note on support',
        subtitle: 'A line on what tends to help in this phase',
        value: options.shareSupportTip,
        onChanged: controller.setShareSupportTip,
      ),
    ];

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  height: AppStrokes.hairline,
                  color: context.lineColor.withOpacity(0.75),
                ),
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// One switch, one field of the summary.
///
/// The sensitive fields carry the word "Sensitive" rather than a warning tint,
/// because a colour cue is invisible to a screen reader and meaningless to
/// anyone who has not learned the palette.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.sensitive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool sensitive;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final stacked = _textScaleOf(context) > 1.3;

    final marker = Icon(
      icon,
      size: AppSpacing.xl,
      color: value ? context.accentColor : context.subtleColor,
    );

    final labels = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            Text(
              title,
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.inkColor,
              ),
            ),
            if (sensitive) const _SensitiveTag(),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          subtitle,
          style: text.bodySmall?.copyWith(color: context.mutedColor),
        ),
      ],
    );

    final toggle = Switch.adaptive(value: value, onChanged: onChanged);

    // Merged so the switch is announced with its field name, its description and
    // its sensitivity, instead of as a bare "on/off" control.
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(child: marker),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: labels),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      toggle,
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          value ? 'Included' : 'Not included',
                          style: text.labelLarge?.copyWith(
                            color: context.inkColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(child: marker),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: labels),
                  const SizedBox(width: AppSpacing.sm),
                  toggle,
                ],
              ),
      ),
    );
  }
}

class _SensitiveTag extends StatelessWidget {
  const _SensitiveTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: context.lineColor,
          width: AppStrokes.hairline,
        ),
      ),
      child: Text(
        'Sensitive',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.mutedColor,
            ),
      ),
    );
  }
}

/// Shows the exact string that will be shared.
///
/// A preview matters more here than anywhere else in the app: the user is about
/// to send health information to another person, and they should read the words
/// before they leave the device rather than trusting a description of them.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    if (summary.isEmpty) {
      return MergeSemantics(
        child: AppCard(
          emphasis: CardEmphasis.outlined,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.visibility_off_rounded,
                  size: AppSpacing.xl,
                  color: context.subtleColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Nothing is selected, so there is nothing to share. Switch '
                  'an item on above and the exact text appears here.',
                  style: text.bodySmall?.copyWith(color: context.mutedColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: 'Preview of the summary that will be shared',
      child: AppCard(
        emphasis: CardEmphasis.outlined,
        child: Text(
          summary,
          style: text.bodyMedium?.copyWith(
            height: 1.6,
            color: context.inkColor,
          ),
        ),
      ),
    );
  }
}

/// Share and Copy, plus the reason they are off when they are off.
///
/// A dimmed button that says nothing invites taps that do nothing. The sentence
/// underneath names the condition and how to clear it.
class _ShareActions extends StatelessWidget {
  const _ShareActions({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final empty = summary.isEmpty;
    final stacked = _textScaleOf(context) > 1.2;

    final share = PrimaryButton(
      label: 'Share',
      icon: Icons.ios_share_rounded,
      onPressed: empty ? null : () => _share(summary),
    );

    final copy = PrimaryButton(
      label: 'Copy',
      icon: Icons.copy_rounded,
      outlined: true,
      onPressed: empty ? null : () => _copy(context, summary),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (stacked || constraints.maxWidth < 320) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  share,
                  const SizedBox(height: AppSpacing.sm),
                  copy,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: share),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: copy),
              ],
            );
          },
        ),
        if (empty) ...[
          const SizedBox(height: AppSpacing.sm),
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: AppSpacing.lg,
                    color: context.mutedColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Share and Copy stay off until at least one item above is '
                    'switched on — there is no empty message to send.',
                    style: text.bodySmall?.copyWith(color: context.mutedColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Actions ─────────────────────────────────────────────────────────────────

Future<void> _share(String summary) async {
  await Share.share(summary, subject: 'My cycle summary');
}

Future<void> _copy(BuildContext context, String summary) async {
  await Clipboard.setData(ClipboardData(text: summary));
  if (!context.mounted) return;
  showAppToast(context, message: 'Summary copied');
}

// ─── Summary ─────────────────────────────────────────────────────────────────

/// Builds the shareable text from real tracker data.
///
/// Pure and synchronous so the preview and the share action can never disagree
/// — the string the user reads is the identical string that gets sent.
String buildPartnerSummary({
  required CycleTrackerState data,
  required PartnerSharingOptions options,
}) {
  final prediction = data.prediction;
  if (prediction == null) return '';

  final name = data.preferences.profileName;
  final today = data.logFor(DateTime.now());
  final lines = <String>[];

  if (options.sharePhase) {
    lines.add(
      'Cycle day ${prediction.cycleDay} — '
      '${prediction.currentPhase.label.toLowerCase()} phase.',
    );
  }

  if (options.shareNextPeriod) {
    if (prediction.isLate) {
      lines.add(
        'Period is ${prediction.daysLate} '
        '${prediction.daysLate == 1 ? 'day' : 'days'} later than expected.',
      );
    } else if (prediction.daysUntilPeriod == 0) {
      lines.add('Period expected today.');
    } else {
      lines.add(
        'Next period expected in ${prediction.daysUntilPeriod} '
        '${prediction.daysUntilPeriod == 1 ? 'day' : 'days'}, around '
        '${DateFormat('MMM d').format(prediction.nextPeriodStart)}.',
      );
    }
  }

  if (options.shareFertileWindow) {
    lines.add(
      'Fertile window: '
      '${DateFormat('MMM d').format(prediction.fertileWindowStart)} to '
      '${DateFormat('MMM d').format(prediction.fertileWindowEnd)}.',
    );
  }

  if (options.shareMood && today?.mood != null && today!.mood!.isNotEmpty) {
    lines.add('Feeling ${today.mood!.toLowerCase()} today.');
  }

  if (options.shareSymptoms && (today?.symptoms.isNotEmpty ?? false)) {
    lines.add('Today: ${today!.symptoms.join(', ').toLowerCase()}.');
  }

  if (options.shareSupportTip) {
    lines.add('');
    lines.add(_supportTipFor(prediction.currentPhase));
  }

  if (lines.isEmpty) return '';

  final header = name.isEmpty ? 'Cycle update' : "$name's cycle update";
  return '$header\n\n${lines.join('\n')}';
}

/// A single line of practical, non-clinical guidance for a partner.
///
/// Framed as what tends to help rather than instructions, and deliberately
/// mild — nobody wants an app telling their partner how to manage them.
String _supportTipFor(CyclePhase phase) => switch (phase) {
      CyclePhase.menstrual =>
        'Energy is usually lowest now. Warmth, food, and a lighter schedule '
            'tend to help more than anything else.',
      CyclePhase.follicular =>
        'Energy is usually climbing in this stretch — a good window for plans '
            'and bigger things.',
      CyclePhase.ovulation =>
        'Energy and mood are often at their highest around now.',
      CyclePhase.luteal =>
        'The days before a period can bring lower energy and a shorter fuse. '
            'Patience and an early night both go a long way.',
    };
