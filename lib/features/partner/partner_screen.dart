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
import 'domain/partner_snapshot_builder.dart';
import 'partner_flows.dart';

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
//
// Layout follows from that last point. The screen leads with one surface that
// states the privacy model, because that is what the user has to believe before
// any switch below it means anything — and the explanation of what "share"
// actually does sits immediately under it rather than at the foot of the page.
// A privacy note positioned last is fine print, and fine print is read after
// the decision instead of before it.
// ─────────────────────────────────────────────────────────────────────────────

/// Font size used to probe the current text scale. Dense rows swap to a stacked
/// variant instead of clipping a label or pushing an action off screen.
const double _textScaleProbe = 14;

double _textScaleOf(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(_textScaleProbe) / _textScaleProbe;

/// Width of the leading icon column every row on this screen shares.
const double _markerSize = AppSpacing.huge;

/// Where a row's text starts, and therefore where its divider starts. Running
/// the rule under the icon column instead would hide the one alignment that
/// makes a list of rows read as a group.
const double _rowTextInset = AppSpacing.lg + _markerSize + AppSpacing.md;

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
                icon: AppIcons.partnerPair,
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

          // The three facts about what sharing does, directly below the lead
          // surface that claims it. Sitting where it does, this is read before
          // the first switch is touched rather than after the text has already
          // been sent.
          const SizedBox(height: AppSpacing.md),
          const ExpansionTile(
            tilePadding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            title: Text('How sharing works'),
            subtitle: Text('Manual snapshot · no live access'),
            children: [_PrivacyTerms()],
          ),

          const SizedBox(height: AppSpacing.xl),
          const Reveal(
            index: 2,
            offsetY: AppSpacing.md,
            child: _SectionTitle(
              title: 'What to include',
              subtitle: 'Nothing is included unless its switch is on',
            ),
          ),
          Reveal(
            index: 3,
            offsetY: AppSpacing.md,
            child: _OptionsCard(options: options),
          ),
          const SizedBox(height: AppSpacing.md),
          Reveal(
            index: 3,
            offsetY: AppSpacing.md,
            child: _NoteField(initial: options.note),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Reveal(
            index: 3,
            offsetY: AppSpacing.md,
            child: _FlowButtons(),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Reveal(
            index: 4,
            offsetY: AppSpacing.md,
            child: _SectionTitle(
              title: 'Preview',
              subtitle: 'Word for word, this is all your partner receives',
            ),
          ),
          Reveal(
            index: 5,
            offsetY: AppSpacing.md,
            child: _PreviewCard(summary: summary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Reveal(
            index: 6,
            offsetY: AppSpacing.md,
            child: _ShareActions(summary: summary),
          ),
        ],
      ),
    );
  }
}

/// What sharing does and does not do, as three separate claims.
///
/// This was one 50-word paragraph in an info banner at the foot of the page.
/// Nobody reads a paragraph of reassurance, and a privacy model stated as prose
/// cannot be checked against — so each guarantee is now its own line with its
/// own icon, which is scannable and makes a broken promise obvious.
///
/// Deliberately a plain outlined surface rather than a tinted notice: this is
/// the screen's standing terms, not an alert, and a warning tint on a permanent
/// condition is the fastest way to teach someone to ignore it.
class _PrivacyTerms extends StatelessWidget {
  const _PrivacyTerms();

  static const _terms = <({IconData icon, String title, String detail})>[
    (
      icon: AppIcons.privacy,
      title: 'Nothing is sent until you tap Share or Copy',
      detail: 'There is no background sync and no automatic path out of this '
          'device.',
    ),
    (
      icon: Icons.link_off_rounded,
      title: 'A snapshot, not a live link',
      detail: 'Your partner needs no account and gets no access to your '
          'history. A text or code never updates on its own; send a new one '
          'when things change.',
    ),
    (
      icon: AppIcons.notes,
      title: 'Only what you switch on',
      detail: 'The text and the share code carry exactly the items switched '
          'on below, and nothing else. Use Preview to see it as they will.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppRadii.card);

    return AppCard(
      emphasis: CardEmphasis.outlined,
      padding: EdgeInsets.zero,
      borderRadius: radius,
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _terms.length; i++) ...[
              if (i > 0)
                Divider(
                  height: AppStrokes.hairline,
                  thickness: AppStrokes.hairline,
                  indent: _rowTextInset,
                  endIndent: AppSpacing.lg,
                  color: context.lineColor,
                ),
              MergeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: SizedBox(
                          width: _markerSize,
                          child: Icon(
                            _terms[i].icon,
                            size: AppSpacing.xl,
                            color: context.accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _terms[i].title,
                              style: text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: context.inkColor,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              _terms[i].detail,
                              style: text.bodySmall?.copyWith(
                                color: context.mutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// What this screen is — the one surface that leads the page.
///
/// A saturated block rather than another pale tinted card. The screen is about
/// trusting the app with health information, and the claim that earns that
/// trust should not be rendered at the same weight as the six switches it
/// governs. One colour block at the top with every surface below it a quiet
/// near-white card is the same figure-to-ground split the home screen uses.
///
/// The ink is `onPrimary`, not [HeroInk]. HeroInk is white at three opacities,
/// which is correct over the phase gradients it was built for — those stops are
/// deep by construction. The palette accent is not: three of the eight seeds
/// are light enough that white text on them fails AA. `ColorScheme.fromSeed`
/// derives a contrast-safe primary/onPrimary pair for every palette and both
/// brightnesses, so taking both from the scheme is what keeps this legible
/// across all sixteen combinations instead of just the default one.
class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadii.card);

    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          // Tinted with the surface's own hue rather than black: a black
          // shadow under a saturated block muddies the bottom edge exactly
          // where it meets the page. See the note on [AppElevation.glow].
          boxShadow: AppElevation.glow(scheme.primary, context.isDark),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary,
                  // Deepened toward the container tone rather than toward
                  // black, so the block stays in the palette's family.
                  Color.lerp(scheme.primary, scheme.primaryContainer, 0.28)!,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ExcludeSemantics(
                        child: Container(
                          width: AppLayout.minTouchTarget,
                          height: AppLayout.minTouchTarget,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            // A wash of the surface's own light. A white card
                            // with a grey hairline looks pasted onto a
                            // saturated block; this reads as part of it.
                            color: scheme.onPrimary.withOpacity(0.18),
                            borderRadius:
                                BorderRadius.circular(AppRadii.control),
                            border: Border.all(
                              color: scheme.onPrimary.withOpacity(0.26),
                              width: AppStrokes.hairline,
                            ),
                          ),
                          child: Icon(
                            AppIcons.partnerPair,
                            size: AppSpacing.xxl,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'You choose every word',
                          style: text.titleLarge?.copyWith(
                            letterSpacing: -0.3,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Choose what to include, then preview. Nothing is sent '
                    'until you tap Share or Copy.',
                    style: text.bodyMedium?.copyWith(
                      // 0.88 rather than full strength: the headline above has
                      // to stay the brighter of the two, and the same hierarchy
                      // trick HeroInk uses applies here.
                      color: scheme.onPrimary.withOpacity(0.88),
                    ),
                  ),
                ],
              ),
            ),
          ),
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

    // Icons resolve through the shared registry so "cycle", "fertile" and
    // "symptoms" are drawn the same here as everywhere else in the app.
    final rows = <Widget>[
      _OptionRow(
        icon: AppIcons.cycle,
        title: 'Cycle phase',
        subtitle: 'Which phase you are in right now',
        value: options.sharePhase,
        onChanged: controller.setSharePhase,
      ),
      _OptionRow(
        icon: AppIcons.calendarRange,
        title: 'Next period',
        subtitle: 'How many days until it is expected',
        value: options.shareNextPeriod,
        onChanged: controller.setShareNextPeriod,
      ),
      _OptionRow(
        icon: AppIcons.moodNeutral,
        title: "Today's mood",
        subtitle: 'Only if you logged one today',
        value: options.shareMood,
        onChanged: controller.setShareMood,
        sensitive: true,
      ),
      _OptionRow(
        icon: AppIcons.symptoms,
        title: "Today's symptoms",
        subtitle: 'What you logged feeling today',
        value: options.shareSymptoms,
        onChanged: controller.setShareSymptoms,
        sensitive: true,
      ),
      _OptionRow(
        icon: AppIcons.fertile,
        title: 'Fertile window',
        subtitle: 'The dates CycleCare estimates as fertile',
        value: options.shareFertileWindow,
        onChanged: controller.setShareFertileWindow,
        sensitive: true,
      ),
      _OptionRow(
        icon: AppIcons.ovulation,
        title: 'Ovulation day',
        subtitle: 'The single day CycleCare estimates',
        value: options.shareOvulation,
        onChanged: controller.setShareOvulation,
        sensitive: true,
      ),
      _OptionRow(
        icon: AppIcons.pms,
        title: 'PMS window',
        subtitle: 'The days before your period starts',
        value: options.sharePms,
        onChanged: controller.setSharePms,
      ),
      _OptionRow(
        icon: AppIcons.pain,
        title: "Today's pain level",
        subtitle: 'Only if you logged one today',
        value: options.sharePain,
        onChanged: controller.setSharePain,
        sensitive: true,
      ),
      _OptionRow(
        icon: AppIcons.partner,
        title: 'A note on support',
        subtitle: 'A line on what tends to help in this phase',
        value: options.shareSupportTip,
        onChanged: controller.setShareSupportTip,
      ),
    ];

    final radius = BorderRadius.circular(AppRadii.card);

    // Outlined, matching the privacy terms above and the preview below. These
    // three lists are the same kind of object and the page reads as composed
    // only while they stay the same weight — the lead surface is the one thing
    // on this screen allowed to sit above the page.
    return AppCard(
      emphasis: CardEmphasis.outlined,
      padding: EdgeInsets.zero,
      borderRadius: radius,
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(
                  height: AppStrokes.hairline,
                  thickness: AppStrokes.hairline,
                  indent: _rowTextInset,
                  endIndent: AppSpacing.lg,
                  color: context.lineColor,
                ),
              rows[i],
            ],
          ],
        ),
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

    // Sized to the shared icon column so a switch row's title starts at the
    // same inset as a privacy term's, and the dividers line up with both.
    final marker = SizedBox(
      width: _markerSize,
      child: Icon(
        icon,
        size: AppSpacing.xl,
        color: value ? context.accentColor : context.subtleColor,
      ),
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
    //
    // The whole row toggles, not just the switch. Before, tapping the title — the
    // biggest thing in the row — did nothing, which a widget test caught. A tap
    // on the switch itself is claimed by the switch first, so it never toggles
    // twice.
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
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
  // Built from the same snapshot as the code and the preview, so the text, the
  // code and the dashboard always say the same things.
  final s = buildPartnerSnapshot(
    prediction: data.prediction,
    todayLog: data.logFor(DateTime.now()),
    options: options,
    ownerName: data.preferences.profileName,
    now: DateTime.now(),
  );
  final d = DateFormat('MMM d');
  final lines = <String>[
    if (s.phase != null) 'Cycle day ${s.cycleDay} — ${s.phase!.toLowerCase()} phase.',
    if (s.daysLate != null)
      'Period is ${s.daysLate} ${s.daysLate == 1 ? 'day' : 'days'} later than expected.'
    else if (s.nextPeriod != null)
      'Next period expected around ${d.format(s.nextPeriod!)}.',
    if (s.fertileStart != null)
      'Fertile window: ${d.format(s.fertileStart!)} to ${d.format(s.fertileEnd!)}.',
    if (s.ovulation != null) 'Estimated ovulation: ${d.format(s.ovulation!)}.',
    if (s.pmsStart != null)
      'PMS window: ${d.format(s.pmsStart!)} to ${d.format(s.pmsEnd!)}.',
    if (s.mood != null) 'Feeling ${s.mood!.toLowerCase()} today.',
    if (s.symptoms != null) 'Today: ${s.symptoms!.join(', ').toLowerCase()}.',
    if (s.painLevel != null) 'Pain today: ${s.painLevel} out of 10.',
    if (s.note != null) '"${s.note}"',
    if (s.supportTip != null) ...['', s.supportTip!],
  ];
  if (lines.isEmpty) return '';
  final header =
      s.ownerName == null ? 'Cycle update' : "${s.ownerName}'s cycle update";
  return '$header\n\n${lines.join('\n')}';
}


/// A line from the owner, sent as written. Saved as they type so it survives
/// leaving the screen.
class _NoteField extends ConsumerStatefulWidget {
  const _NoteField({required this.initial});

  final String initial;

  @override
  ConsumerState<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends ConsumerState<_NoteField> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void didUpdateWidget(_NoteField old) {
    super.didUpdateWidget(old);
    // The saved note loads after the first frame; pick it up once, without
    // overwriting anything the user has already typed.
    if (_controller.text.isEmpty && widget.initial.isNotEmpty) {
      _controller.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('partner-note-field'),
      controller: _controller,
      maxLength: 140,
      maxLines: 2,
      minLines: 1,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Add a note (optional)',
        hintText: 'e.g. Could use a quiet night in',
        prefixIcon: Icon(Icons.edit_note_rounded),
      ),
      onChanged: ref.read(partnerSharingProvider.notifier).setNote,
    );
  }
}

/// The three ways forward: see it as they will, send it as a code, or open
/// one you were sent.
class _FlowButtons extends StatelessWidget {
  const _FlowButtons();

  void _push(BuildContext context, Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          label: 'Preview as your partner',
          icon: Icons.visibility_rounded,
          onPressed: () => _push(context, const PartnerPreviewScreen()),
        ),
        const SizedBox(height: AppSpacing.sm),
        PrimaryButton(
          label: 'Create share code',
          icon: Icons.qr_code_2_rounded,
          outlined: true,
          onPressed: () => _push(context, const PartnerShareCodeScreen()),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton.icon(
          onPressed: () => _push(context, const PartnerOpenCodeScreen()),
          icon: const Icon(Icons.key_rounded),
          label: const Text('I have a code from my partner'),
        ),
      ],
    );
  }
}
