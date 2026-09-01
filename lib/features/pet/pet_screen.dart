import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/haptics.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';
import 'pet_models.dart';
import 'pet_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Virtual pet
//
// The reward surface for everything else in the app, so it is the one screen
// where a little theatre is the point rather than a distraction. It still plays
// by the same rules as the rest:
//
//  • The hero is glass over a phase gradient, not a flat coloured block, so the
//    pet reads as sitting *in* a space instead of on a swatch.
//  • Numbers animate toward their new value. XP that snaps looks like a data
//    refresh; XP that travels looks like it was earned.
//  • Delight is rationed. A tap gets a crisp pop on the app's standard
//    ease-out; the overshoot curve is held back for the one event that is
//    genuinely a milestone, which is a level-up.
//  • Every looping or scroll-linked movement checks reduced motion first. A pet
//    that bounces forever is charming for a week and nauseating for anyone who
//    asked their OS to stop moving things, and the parallax collapse goes with
//    it.
//  • Nothing is said in colour alone. Happiness carries a mood icon and a word,
//    and every badge states "Unlocked" or "Locked" in text next to a lock or
//    tick.
//
// Layout is width- and text-scale-aware rather than a fixed grid: the stat
// tiles and the badge board resolve their own column count and collapse to one
// column at large text, because a three-across row of numerals is the first
// thing to clip at 200%.
//
// None of the XP, level, or happiness maths lives here — this file only ever
// reads state and calls the notifier.
// ─────────────────────────────────────────────────────────────────────────────

/// Mirrors the notifier's own cooldowns so the UI can explain a no-op before
/// the user taps into it. The notifier remains the authority; these values only
/// drive copy.
const Duration _feedCooldown = Duration(hours: 4);
const Duration _cuddleCooldown = Duration(minutes: 30);

class PetScreen extends ConsumerWidget {
  const PetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(petProvider);

    return Scaffold(
      body: petAsync.when(
        loading: () => const _LoadingPet(),
        error: (error, _) => _PetLoadFailure(error: error),
        data: (pet) => _PetView(pet: pet),
      ),
    );
  }
}

/// Re-reads the pet for the retry action. The failure is swallowed here because
/// the provider already carries it into [PetScreen], which renders the error
/// surface; rethrowing would surface a second, unhandled copy of the same
/// problem.
Future<void> _reloadPet(WidgetRef ref) async {
  ref.invalidate(petProvider);
  try {
    await ref.read(petProvider.future);
  } catch (_) {
    // Reported by the error branch of the screen.
  }
}

/// Loading, kept calm rather than blank. A bare spinner reads as a stall;
/// naming what is happening costs one line and gives assistive technology
/// something to announce.
class _LoadingPet extends StatelessWidget {
  const _LoadingPet();

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
                  semanticsLabel: 'Waking your pet',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Getting your pet ready',
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

/// Load failure, kept actionable. The raw exception is never the headline — it
/// is unreadable to the person holding the phone and it buries the one thing
/// they can do about it.
class _PetLoadFailure extends ConsumerWidget {
  const _PetLoadFailure({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final detail = error.toString().trim();

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = AppLayout.pageGutterFor(constraints.maxWidth);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.maxContentWidth,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EmptyState(
                        icon: Icons.pets_rounded,
                        title: 'Could not wake your pet',
                        message: 'Nothing was lost — your level, XP, and '
                            'badges stay on this device. Try again in a '
                            'moment.',
                        actionLabel: 'Try again',
                        onAction: () => _reloadPet(ref),
                      ),
                      Text(
                        'Reference: ${error.runtimeType}',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall
                            ?.copyWith(color: context.subtleColor),
                      ),
                      if (detail.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          detail,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall
                              ?.copyWith(color: context.subtleColor),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PetView extends ConsumerStatefulWidget {
  const _PetView({required this.pet});

  final PetState pet;

  @override
  ConsumerState<_PetView> createState() => _PetViewState();
}

class _PetViewState extends ConsumerState<_PetView>
    with TickerProviderStateMixin {
  /// The ambient float. Deliberately outside the [AppDurations] scale: those
  /// tokens govern how quickly the interface answers a tap, and a background
  /// loop that fast would read as a response. It never runs under reduced
  /// motion.
  static const Duration _idleCycle = Duration(milliseconds: 2200);

  /// The idle float. Looped only when the platform allows motion.
  late final AnimationController _idleCtrl;

  /// One-shot squash-and-stretch fired when the pet is interacted with, so a
  /// tap has a visible consequence even when nothing else on screen changes.
  late final AnimationController _reactCtrl;

  bool _looping = false;

  /// True while the current reaction is a level-up rather than an ordinary tap.
  /// Only the milestone gets the overshoot curve.
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    _idleCtrl = AnimationController(vsync: this, duration: _idleCycle);
    _reactCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
    );
  }

  @override
  void didUpdateWidget(_PetView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Level-up is the only genuinely celebratory event the pet has, so it gets
    // the double-tap haptic and the springy pop. Detected by comparing the
    // rebuilt state rather than by listening to the notifier, so it fires
    // exactly once per level regardless of how the XP arrived.
    if (widget.pet.level > oldWidget.pet.level) {
      Haptics.celebrate();
      // Assigned rather than setState: didUpdateWidget runs immediately before
      // this element rebuilds, so the new curve is picked up by that build.
      _celebrating = true;
      _reactCtrl.forward(from: 0);
      final level = widget.pet.level;
      final name = widget.pet.name;
      // Deferred a frame: didUpdateWidget runs inside the build phase, and
      // asking the messenger to rebuild from there throws.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showAppToast(
          context,
          message: '$name reached level $level',
          // The celebration haptic already fired; a success toast would stack
          // a third impact on top of it.
          kind: ToastKind.info,
        );
      });
    }
  }

  @override
  void dispose() {
    _idleCtrl.dispose();
    _reactCtrl.dispose();
    super.dispose();
  }

  /// Starts or stops the idle loop to match the current accessibility setting.
  /// Called from build because `disableAnimations` can change at runtime.
  void _syncIdleLoop(bool reduced) {
    if (reduced && _looping) {
      _idleCtrl
        ..stop()
        ..value = 0;
      _looping = false;
    } else if (!reduced && !_looping) {
      _idleCtrl.repeat(reverse: true);
      _looping = true;
    }
  }

  /// Fires the interaction pop. A routine tap never interrupts a milestone
  /// celebration that is still playing.
  void _react({bool celebrate = false}) {
    if (!mounted) return;
    if (!celebrate && _celebrating && _reactCtrl.isAnimating) return;
    setState(() => _celebrating = celebrate);
    _reactCtrl.forward(from: 0);
  }

  Future<void> _feed() async {
    final before = widget.pet.lastFed;
    await ref.read(petProvider.notifier).feed();
    if (!mounted) return;
    // The notifier silently no-ops inside its cooldown. Saying so beats a
    // button that appears to do nothing.
    if (ref.read(petProvider).valueOrNull?.lastFed == before) {
      showAppToast(
        context,
        message: '${widget.pet.name} is still full',
        kind: ToastKind.info,
      );
      return;
    }
    _react();
  }

  Future<void> _pet() async {
    final before = widget.pet.lastPetted;
    await ref.read(petProvider.notifier).pet();
    if (!mounted) return;
    if (ref.read(petProvider).valueOrNull?.lastPetted == before) {
      showAppToast(
        context,
        message: '${widget.pet.name} is enjoying the last cuddle',
        kind: ToastKind.info,
      );
      return;
    }
    _react();
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final motion = Motion.of(context);
    final swatch = PhaseColors.of(context).ovulation;

    _syncIdleLoop(motion.reduced);
    // A milestone is allowed to travel a little further than a tap.
    _reactCtrl.duration = motion(
      _celebrating ? AppDurations.normal : AppDurations.fast,
    );

    final unlocked =
        kAchievements.where((a) => pet.achievements.contains(a.id)).length;
    final cuddleReady = _isReady(pet.lastPetted, _cuddleCooldown);

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _HeroMetrics.of(context, constraints.maxWidth);
        final gutter = AppLayout.pageGutterFor(constraints.maxWidth);
        // Content stops growing at the shared ceiling and centres itself on a
        // tablet instead of stretching a 132dp avatar across 1000dp of glass.
        final overflowWidth =
            constraints.maxWidth - gutter * 2 - AppLayout.maxContentWidth;
        final side = gutter + (overflowWidth > 0 ? overflowWidth / 2 : 0);

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: metrics.expandedHeight,
              pinned: true,
              backgroundColor: context.canvasColor,
              surfaceTintColor: Colors.transparent,
              // Kept in the bar rather than the hero so the pet's name survives
              // the collapse instead of leaving a blank strip behind.
              title: Text(
                '${pet.name} ${pet.moodEmoji}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              flexibleSpace: FlexibleSpaceBar(
                // Parallax is scroll-linked spatial movement, so it is the
                // first thing to go when the user asked for less of it.
                collapseMode:
                    motion.reduced ? CollapseMode.none : CollapseMode.parallax,
                background: _Hero(
                  pet: pet,
                  swatch: swatch,
                  idle: _idleCtrl,
                  react: _reactCtrl,
                  motion: motion,
                  celebrating: _celebrating,
                  avatarSize: metrics.avatar,
                  cuddleReady: cuddleReady,
                  onTapPet: _pet,
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                side,
                AppSpacing.lg,
                side,
                AppSpacing.huge,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Reveal(
                    offsetY: AppSpacing.md,
                    child: _XpCard(pet: pet, swatch: swatch),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Reveal(
                    index: 1,
                    offsetY: AppSpacing.md,
                    child: _StatBand(pet: pet, swatch: swatch),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Reveal(
                    index: 2,
                    offsetY: AppSpacing.md,
                    child: _CareCard(pet: pet, onFeed: _feed, onPet: _pet),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Reveal(
                    index: 3,
                    offsetY: AppSpacing.md,
                    child: SectionHeader(
                      title: 'Achievements',
                      subtitle: '$unlocked of ${kAchievements.length} unlocked',
                    ),
                  ),
                  Reveal(
                    index: 4,
                    offsetY: AppSpacing.md,
                    child: _AchievementBoard(
                      pet: pet,
                      onOpen: (achievement, isUnlocked) =>
                          _showAchievement(context, achievement, isUnlocked),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAchievement(
    BuildContext context,
    Achievement achievement,
    bool unlocked,
  ) {
    final text = Theme.of(context).textTheme;

    showAppSheet<void>(
      context: context,
      title: achievement.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EmojiTile(
                emoji: unlocked ? achievement.emoji : '🔒',
                size: AppSpacing.huge + AppSpacing.lg,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.description,
                      style:
                          text.bodySmall?.copyWith(color: context.mutedColor),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _LockState(unlocked: unlocked),
                  ],
                ),
              ),
            ],
          ),
          if (achievement.xpReward > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            MetricPill(
              icon: Icons.bolt_rounded,
              value: '+${achievement.xpReward} XP',
              label: unlocked ? 'Awarded' : 'On unlock',
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

Color _happinessTone(int happiness) {
  if (happiness > 60) return AppColors.success;
  if (happiness > 30) return AppColors.warning;
  return AppColors.error;
}

String _moodLabel(PetMood mood) => switch (mood) {
      PetMood.happy => 'Thriving',
      PetMood.excited => 'Excited',
      PetMood.neutral => 'Content',
      PetMood.sleepy => 'Sleepy',
      PetMood.sad => 'Needs you',
    };

/// Non-colour mood cue, paired with [_moodLabel] everywhere it is used.
IconData _moodIcon(PetMood mood) => switch (mood) {
      PetMood.happy => Icons.sentiment_very_satisfied_rounded,
      PetMood.excited => Icons.celebration_rounded,
      PetMood.neutral => Icons.sentiment_satisfied_rounded,
      PetMood.sleepy => Icons.bedtime_rounded,
      PetMood.sad => Icons.sentiment_dissatisfied_rounded,
    };

bool _isReady(DateTime? last, Duration cooldown) =>
    last == null || DateTime.now().difference(last) >= cooldown;

/// Remaining wait, phrased as a fragment so it can be dropped into a sentence
/// ("Feed again in about 3h"). Hedged, because the cooldown is measured from a
/// timestamp that may be minutes stale by the time it is read.
String _waitFragment(DateTime? last, Duration cooldown) {
  if (last == null) return 'now';
  final left = cooldown - DateTime.now().difference(last);
  if (left.isNegative) return 'now';
  if (left.inHours >= 1) return 'in about ${left.inHours}h';
  return 'in about ${left.inMinutes + 1}m';
}

String _streakPhrase(int streak) => switch (streak) {
      0 => 'No logging streak yet',
      1 => '1 day logging streak',
      _ => '$streak day logging streak',
    };

/// One sentence covering everything the hero says visually, so assistive
/// technology hears the pet's state once instead of hearing a glyph, a ring,
/// and three tiles as separate unlabelled nodes.
String _petSummary(PetState pet) {
  final into = pet.xp % pet.xpForNextLevel;
  return 'Level ${pet.level}. '
      '$into of ${pet.xpForNextLevel} XP toward level ${pet.level + 1}. '
      'Happiness ${pet.happiness} percent, '
      '${_moodLabel(pet.mood).toLowerCase()}. '
      '${_streakPhrase(pet.streak)}.';
}

// ─── Hero ────────────────────────────────────────────────────────────────────

/// Hero geometry, resolved from the available width and the current text scale
/// rather than pinned to one magic number.
///
/// The avatar is an illustration, so it scales with the screen and not with the
/// type; the caption underneath is text, so the header reserves room for two
/// scaled lines of it. Without that, 200% text pushes the caption straight
/// through the bottom of the flexible space.
@immutable
class _HeroMetrics {
  const _HeroMetrics({required this.avatar, required this.expandedHeight});

  factory _HeroMetrics.of(BuildContext context, double width) {
    final caption = Theme.of(context).textTheme.labelMedium;
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(caption?.fontSize ?? 12) *
            (caption?.height ?? 1.3);
    final avatar =
        width.isFinite ? (width * 0.34).clamp(96.0, 148.0).toDouble() : 132.0;

    return _HeroMetrics(
      avatar: avatar,
      expandedHeight: kToolbarHeight +
          // The halo ring extends past the avatar on every side.
          avatar +
          AppSpacing.xxxl +
          AppSpacing.md +
          lineHeight * 2 +
          AppSpacing.lg,
    );
  }

  final double avatar;
  final double expandedHeight;
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.pet,
    required this.swatch,
    required this.idle,
    required this.react,
    required this.motion,
    required this.celebrating,
    required this.avatarSize,
    required this.cuddleReady,
    required this.onTapPet,
  });

  final PetState pet;
  final PhaseSwatch swatch;
  final Animation<double> idle;
  final Animation<double> react;
  final Motion motion;
  final bool celebrating;
  final double avatarSize;
  final bool cuddleReady;
  final VoidCallback onTapPet;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;

    return PhaseBackdrop(
      colors: swatch.gradient,
      child: Padding(
        // Clears the toolbar so the avatar never slides under the name.
        padding: EdgeInsets.only(
          top: topInset + kToolbarHeight,
          bottom: AppSpacing.lg,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PetAvatar(
              pet: pet,
              idle: idle,
              react: react,
              motion: motion,
              celebrating: celebrating,
              size: avatarSize,
              cuddleReady: cuddleReady,
              onTap: onTapPet,
            ),
            const SizedBox(height: AppSpacing.md),
            // Excluded: the avatar button already announces level, XP,
            // happiness, and streak in one sentence, and the invitation to tap
            // is carried by that button's hint.
            ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Text(
                  'Level ${pet.level} · ${pet.type.name} · tap to cuddle',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(color: context.mutedColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({
    required this.pet,
    required this.idle,
    required this.react,
    required this.motion,
    required this.celebrating,
    required this.size,
    required this.cuddleReady,
    required this.onTap,
  });

  final PetState pet;
  final Animation<double> idle;
  final Animation<double> react;
  final Motion motion;
  final bool celebrating;
  final double size;
  final bool cuddleReady;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size);

    Widget avatar = GlassCard(
      borderRadius: radius,
      padding: EdgeInsets.zero,
      blur: 22,
      tint: context.cardColor,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: SizedBox.square(
            dimension: size * 0.52,
            // Bounded rather than text-scaled: the pet is an illustration, and
            // an emoji that grows with the type ramp bursts its own glass.
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(pet.type.emoji),
            ),
          ),
        ),
      ),
    );

    // Two independent transforms: a slow float that never stops (unless the
    // user asked it to) and a one-shot pop on interaction. Composed rather than
    // combined into one curve so a tap mid-float still reads as a tap.
    avatar = AnimatedBuilder(
      animation: Listenable.merge([idle, react]),
      builder: (context, child) {
        // Both the drift and the pop are sized through Motion, so reduced
        // motion resolves them to a stationary avatar instead of a slower one.
        final float = -motion.offset(AppSpacing.md) *
            Curves.easeInOut.transform(
              idle.value,
            );
        // Triangle wave: out to full pop at the halfway point, back to rest.
        // Guarantees the transform lands exactly on 1.0 whatever the duration.
        final t = react.value;
        final pop = t == 0 ? 0.0 : 1 - (2 * t - 1).abs();
        final peak = motion.scale(celebrating ? 1.16 : 1.08);
        final curve = celebrating ? AppCurves.springy : AppCurves.out;
        final scale = 1 + (peak - 1) * curve.transform(pop);

        return Transform.translate(
          offset: Offset(0, float),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: avatar,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft halo so the glass has something to sit against even on a pale
        // backdrop.
        Container(
          width: size + AppSpacing.xxxl,
          height: size + AppSpacing.xxxl,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                context.accentColor.withOpacity(context.isDark ? 0.24 : 0.18),
                context.accentColor.withOpacity(0),
              ],
            ),
          ),
        ),
        Pressable(
          onTap: onTap,
          scale: 0.96,
          semanticLabel: 'Cuddle ${pet.name}',
          semanticValue: _petSummary(pet),
          semanticHint: cuddleReady
              ? 'Adds a little happiness and XP'
              : '${pet.name} is enjoying the last cuddle. Ready again '
                  '${_waitFragment(pet.lastPetted, _cuddleCooldown)}',
          excludeChildSemantics: true,
          borderRadius: radius,
          child: avatar,
        ),
      ],
    );
  }
}

// ─── XP ──────────────────────────────────────────────────────────────────────

class _XpCard extends StatelessWidget {
  const _XpCard({required this.pet, required this.swatch});

  final PetState pet;
  final PhaseSwatch swatch;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final into = pet.xp % pet.xpForNextLevel;
    final remaining = (pet.xpForNextLevel - into).clamp(0, pet.xpForNextLevel);
    final percent = (pet.xpProgress.clamp(0.0, 1.0) * 100).round();

    return AppCard(
      // One node: the eyebrow, the fraction, the pill, and the meter are four
      // views of a single number, and reading them separately is worse than
      // reading the sentence once.
      child: Semantics(
        container: true,
        label: 'Experience',
        value: '$into of ${pet.xpForNextLevel} XP, $percent percent toward '
            'level ${pet.level + 1}',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'EXPERIENCE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        color: context.subtleColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _LevelPill(level: pet.level, swatch: swatch),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // Wrapped rather than a fixed baseline row: at 200% the figure
              // and its denominator need two lines, and a Row would clip.
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  AnimatedCount(
                    value: into,
                    style: text.headlineMedium?.copyWith(
                      letterSpacing: -1,
                      color: context.inkColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                    child: Text(
                      ' / ${pet.xpForNextLevel} XP',
                      style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.mutedColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _ProgressBar(
                value: pet.xpProgress,
                gradient: swatch.gradient,
                // The XP meter draws itself once per visit, so it is allowed
                // the longer reveal the cycle ring uses.
                duration: AppDurations.reveal,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                remaining == 0
                    ? 'Level up on the next reward'
                    : '$remaining XP to level ${pet.level + 1}',
                style: text.bodySmall?.copyWith(color: context.mutedColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Level badge. Names itself in text next to the star, so the tint is
/// decoration rather than the message.
class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level, required this.swatch});

  final int level;
  final PhaseSwatch swatch;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: swatch.surface,
        borderRadius: BorderRadius.circular(AppRadii.compact),
        border: Border.all(
          color: swatch.border,
          width: AppStrokes.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: AppSpacing.lg, color: swatch.text),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'LV ',
            style: text.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: swatch.text,
            ),
          ),
          AnimatedCount(
            value: level,
            style: text.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: swatch.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded, gradient-filled meter.
///
/// Built rather than themed because [LinearProgressIndicator] cannot carry a
/// gradient, and a flat single-colour bar is the fastest way to make a reward
/// screen look like a form. Decorative on purpose — every call site wraps it in
/// a labelled semantics node, so the bar itself stays out of the tree.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.gradient,
    this.height = AppSpacing.md,
    this.duration = AppDurations.normal,
  });

  final double value;
  final List<Color> gradient;
  final double height;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(AppRadii.pill);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: height,
        color: context.isDark
            ? context.lineColor.withOpacity(0.6)
            : context.lineColor,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: clamped),
            duration: motion(duration),
            curve: AppCurves.out,
            builder: (context, animated, _) => FractionallySizedBox(
              widthFactor: animated.clamp(0.0, 1.0),
              // heightFactor is required: DecoratedBox has no intrinsic size,
              // so without it the fill collapses to zero height and the meter
              // renders empty at every value.
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  // Diagonal rather than horizontal: the fill picks up a hint
                  // of shading along its height, which is what stops a flat
                  // bar from looking like a placeholder.
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stats ───────────────────────────────────────────────────────────────────

/// Level, streak, and happiness.
///
/// The column count is resolved from the available width *and* the text scale
/// instead of being fixed at three. A three-across row of 24pt numerals is the
/// first thing to clip at 200%, so the band collapses to one column long before
/// it gets there.
class _StatBand extends StatelessWidget {
  const _StatBand({required this.pet, required this.swatch});

  final PetState pet;
  final PhaseSwatch swatch;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _Stat(
        label: 'Level',
        spoken: '${pet.level}',
        tile: StatTile(
          label: 'Level',
          value: '${pet.level}',
          icon: Icons.auto_awesome_rounded,
          accent: swatch.fill,
        ),
      ),
      _Stat(
        label: 'Streak',
        spoken: pet.streak == 0
            ? 'None yet'
            : '${pet.streak} ${pet.streak == 1 ? 'day' : 'days'}',
        tile: StatTile(
          label: 'Streak',
          value: '${pet.streak}',
          unit: pet.streak == 1 ? 'day' : 'days',
          icon: Icons.local_fire_department_rounded,
          accent: AppColors.warning,
        ),
      ),
      _Stat(
        label: 'Happiness',
        spoken: '${pet.happiness} percent, '
            '${_moodLabel(pet.mood).toLowerCase()}',
        tile: StatTile(
          label: 'Happiness',
          value: '${pet.happiness}',
          unit: '%',
          icon: _moodIcon(pet.mood),
          accent: _happinessTone(pet.happiness),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(
          context,
          width: constraints.maxWidth,
          limit: tiles.length,
          base: 96,
        );
        final width =
            (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

/// Merges a [StatTile] into a single labelled node. Three tiles otherwise read
/// as six fragments — a word, then a number, three times over.
class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.spoken,
    required this.tile,
  });

  final String label;
  final String spoken;
  final Widget tile;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      value: spoken,
      child: ExcludeSemantics(child: tile),
    );
  }
}

/// How many columns fit, given the width and how large the user's text is.
///
/// [base] is the narrowest a tile may be at default text size; each step up the
/// scale widens that floor, which is what forces the collapse to one column
/// before anything has to ellipsise.
int _columnsFor(
  BuildContext context, {
  required double width,
  required int limit,
  required double base,
}) {
  final scale = MediaQuery.textScalerOf(context).scale(1);
  final minimum = scale >= 1.6
      ? base * 2.6
      : scale >= 1.3
          ? base * 1.85
          : scale >= 1.15
              ? base * 1.4
              : base;
  if (!width.isFinite || width <= 0) return 1;
  return (width / minimum).floor().clamp(1, limit).toInt();
}

// ─── Care ────────────────────────────────────────────────────────────────────

class _CareCard extends StatelessWidget {
  const _CareCard({
    required this.pet,
    required this.onFeed,
    required this.onPet,
  });

  final PetState pet;
  final VoidCallback onFeed;
  final VoidCallback onPet;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tone = _happinessTone(pet.happiness);
    final feedReady = _isReady(pet.lastFed, _feedCooldown);
    final cuddleReady = _isReady(pet.lastPetted, _cuddleCooldown);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label: 'Happiness',
            value: '${pet.happiness} percent, '
                '${_moodLabel(pet.mood).toLowerCase()}',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Happiness',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: context.inkColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Icon plus word: mood is never carried by the tint of
                      // the bar alone.
                      Icon(
                        _moodIcon(pet.mood),
                        size: AppSpacing.lg,
                        color: tone,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          _moodLabel(pet.mood),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: tone,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ProgressBar(
                    value: pet.happiness / 100,
                    gradient: [tone.withOpacity(0.75), tone],
                    height: AppSpacing.sm,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              // Two 52dp buttons across a phone is fine at default text and
              // unreadable at 200%, where the label would ellipsise to a
              // single letter. Past that point they stack.
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final stacked = scale > 1.25 || constraints.maxWidth < 300;
              final feed = _CareAction(
                label: 'Feed',
                icon: Icons.restaurant_rounded,
                ready: feedReady,
                readyHint: 'Gives ${pet.name} a meal, some XP, and a '
                    'happiness boost',
                waitHint: '${pet.name} is still full. Ready again '
                    '${_waitFragment(pet.lastFed, _feedCooldown)}',
                onPressed: onFeed,
              );
              final cuddle = _CareAction(
                label: 'Cuddle',
                icon: Icons.favorite_rounded,
                ready: cuddleReady,
                readyHint: 'Adds a little happiness and XP',
                waitHint: '${pet.name} is enjoying the last cuddle. Ready '
                    'again ${_waitFragment(pet.lastPetted, _cuddleCooldown)}',
                outlined: true,
                onPressed: onPet,
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    feed,
                    const SizedBox(height: AppSpacing.sm),
                    cuddle,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: feed),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: cuddle),
                ],
              );
            },
          ),
          if (!feedReady || !cuddleReady) ...[
            const SizedBox(height: AppSpacing.md),
            // Visible twin of the hints above. Excluded from semantics because
            // each button already states its own wait.
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!feedReady)
                    _CooldownNote(
                      label: 'Feed again '
                          '${_waitFragment(pet.lastFed, _feedCooldown)}',
                    ),
                  if (!cuddleReady)
                    _CooldownNote(
                      label: 'Cuddle again '
                          '${_waitFragment(pet.lastPetted, _cuddleCooldown)}',
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A care action, wearing the app's primary button.
///
/// The label never changes into a countdown: a control whose name disappears
/// while it waits cannot be found again by anyone who is listening rather than
/// looking. The wait moves into the icon, the spoken value, the hint, and the
/// note underneath, and the button stays tappable so the pet can still explain
/// itself when tapped early.
class _CareAction extends StatelessWidget {
  const _CareAction({
    required this.label,
    required this.icon,
    required this.ready,
    required this.readyHint,
    required this.waitHint,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final bool ready;
  final String readyHint;
  final String waitHint;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: label,
      value: ready ? 'Ready' : 'Waiting',
      hint: ready ? readyHint : waitHint,
      onTap: onPressed,
      // The button underneath publishes its own bare label; this node carries
      // the state and the reason, so it replaces it rather than doubling it.
      excludeSemantics: true,
      child: PrimaryButton(
        label: label,
        icon: ready ? icon : Icons.schedule_rounded,
        outlined: outlined,
        onPressed: onPressed,
      ),
    );
  }
}

class _CooldownNote extends StatelessWidget {
  const _CooldownNote({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: AppSpacing.lg,
            color: context.subtleColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: context.mutedColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Achievements ────────────────────────────────────────────────────────────

/// The badge board.
///
/// Rows are laid out by hand rather than by [GridView]: a fixed aspect ratio is
/// exactly what clips a two-line title at 200% text, while an intrinsic-height
/// row lets each band grow to fit its tallest tile and keeps the grid tidy.
class _AchievementBoard extends StatelessWidget {
  const _AchievementBoard({required this.pet, required this.onOpen});

  final PetState pet;
  final void Function(Achievement achievement, bool unlocked) onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(
          context,
          width: constraints.maxWidth,
          limit: 4,
          base: 108,
        );
        final bands = <Widget>[];

        for (var start = 0; start < kAchievements.length; start += columns) {
          bands.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var slot = 0; slot < columns; slot++) ...[
                    if (slot > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: start + slot < kAchievements.length
                          ? _tileFor(kAchievements[start + slot])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < bands.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              bands[i],
            ],
          ],
        );
      },
    );
  }

  Widget _tileFor(Achievement achievement) {
    final unlocked = pet.achievements.contains(achievement.id);
    return _AchievementTile(
      achievement: achievement,
      unlocked: unlocked,
      onTap: () => onOpen(achievement, unlocked),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.unlocked,
    required this.onTap,
  });

  final Achievement achievement;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final swatch = PhaseColors.of(context).ovulation;
    final radius = BorderRadius.circular(AppRadii.card);

    return Pressable(
      onTap: onTap,
      scale: 0.985,
      semanticLabel: achievement.title,
      semanticValue: unlocked ? 'Unlocked' : 'Locked',
      semanticHint: achievement.description,
      excludeChildSemantics: true,
      borderRadius: radius,
      child: AppCard(
        emphasis: unlocked ? CardEmphasis.raised : CardEmphasis.outlined,
        color: unlocked ? swatch.surface : null,
        borderColor: unlocked ? swatch.border : null,
        borderRadius: radius,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: AppSpacing.xxxl,
              child: FittedBox(
                fit: BoxFit.contain,
                // A locked badge is dimmed rather than hidden: seeing what is
                // still available is most of why an achievement grid works.
                child: Opacity(
                  opacity: unlocked ? 1 : 0.55,
                  child: Text(unlocked ? achievement.emoji : '🔒'),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: unlocked ? context.inkColor : context.mutedColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _LockState(unlocked: unlocked, compact: true),
          ],
        ),
      ),
    );
  }
}

/// Locked or unlocked, said in an icon and a word. The tint and the dimmed
/// glyph are reinforcement, never the signal.
class _LockState extends StatelessWidget {
  const _LockState({required this.unlocked, this.compact = false});

  final bool unlocked;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tone = unlocked ? AppColors.success : context.mutedColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
          size: AppSpacing.lg,
          color: tone,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            unlocked ? 'Unlocked' : 'Locked',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (compact ? text.labelSmall : text.labelMedium)?.copyWith(
              fontWeight: FontWeight.w800,
              color: tone,
            ),
          ),
        ),
      ],
    );
  }
}

/// Emoji on a tinted tile, bounded so the glyph cannot outgrow its container.
class _EmojiTile extends StatelessWidget {
  const _EmojiTile({required this.emoji, required this.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.accentColor.withOpacity(context.isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: SizedBox.square(
        dimension: size * 0.52,
        child: FittedBox(fit: BoxFit.contain, child: Text(emoji)),
      ),
    );
  }
}
