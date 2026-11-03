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
//  • One saturated block leads the page. The previous header was a pale
//    lavender wash carrying mid-grey text, which put the pet, its name and its
//    caption all within a few percent of the page's own lightness — the whole
//    screen read as one soft field and the caption was close to illegible. The
//    hero is now the app's own [PhaseHero], deep enough to carry white ink.
//  • Glass goes on the hero and nowhere else. The XP readout and the mood chip
//    float on saturated colour, which is the only place a backdrop blur has
//    anything to sample; every surface below the hero is an opaque card.
//  • The pet is the emotional point of the screen, so it gets a real avatar —
//    a light medallion with a ring and a mood badge, sized off the viewport.
//    An icon alone in a circle is a glyph; framed and lit, it reads as a
//    character.
//  • Numbers animate toward their new value. XP that snaps looks like a data
//    refresh; XP that travels looks like it was earned.
//  • Delight is rationed. A tap gets a crisp pop on the app's standard
//    ease-out; the overshoot curve is held back for the one event that is
//    genuinely a milestone, which is a level-up.
//  • Every looping or scroll-linked movement checks reduced motion first. A pet
//    that bounces forever is charming for a week and nauseating for anyone who
//    asked their OS to stop moving things — and the meters render at their real
//    value at rest rather than relying on an animation to fill them.
//  • Nothing is said in colour alone. Happiness carries a mood icon, a word and
//    a percentage; a badge is a filled disc when earned and an empty ring when
//    not, and names its state in text either way.
//
// Reading order: the hero answers "how is my pet and how close is the next
// level", the care card is the two things to *do*, the stat pair is reference,
// and the badge board is browsing.
//
// Layout is width- and text-scale-aware rather than a fixed grid: the stat
// tiles and the badge board resolve their own column count and collapse to one
// column at large text, because a row of numerals is the first thing to clip at
// 200%.
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
                        // AppIcons has no generic "pet" entry — only the four
                        // species — and the failure is not about a species.
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
        final gutter = AppLayout.pageGutterFor(constraints.maxWidth);
        final safe = MediaQuery.paddingOf(context);
        // Content stops growing at the shared ceiling and centres itself on a
        // tablet instead of stretching a 148dp avatar across 1000dp of colour.
        final overflowWidth =
            constraints.maxWidth - gutter * 2 - AppLayout.maxContentWidth;
        final side = gutter + (overflowWidth > 0 ? overflowWidth / 2 : 0);

        return CustomScrollView(
          slivers: [
            // Full bleed, under the status bar, no app bar above it. This is a
            // root tab, so there is no back affordance to host and the pet's
            // name belongs on the hero at headline size rather than shrunk
            // into a toolbar.
            SliverToBoxAdapter(
              child: _Hero(
                pet: pet,
                swatch: swatch,
                idle: _idleCtrl,
                react: _reactCtrl,
                motion: motion,
                celebrating: _celebrating,
                cuddleReady: cuddleReady,
                side: side,
                onTapPet: _pet,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                side,
                AppSpacing.lg,
                side,
                AppSpacing.huge + safe.bottom,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Care leads the body: feeding and cuddling are the only two
                  // things this screen asks the user to do, and the figures
                  // below them are reference for those actions.
                  Reveal(
                    offsetY: AppSpacing.md,
                    child: _CareCard(pet: pet, onFeed: _feed, onPet: _pet),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Reveal(
                    index: 1,
                    offsetY: AppSpacing.md,
                    child: _StatBand(pet: pet, unlocked: unlocked),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Reveal(
                    index: 2,
                    offsetY: AppSpacing.md,
                    child: SectionHeader(
                      title: 'Achievements',
                      subtitle: '$unlocked of ${kAchievements.length} unlocked',
                    ),
                  ),
                  Reveal(
                    index: 3,
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
              _BadgeMedallion(
                icon: achievement.icon,
                unlocked: unlocked,
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
              icon: _xpIcon,
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

/// XP's own mark. Not `AppIcons.energy`: that one means bodily energy in the
/// symptom log, and reusing it here would have one glyph meaning two things.
const IconData _xpIcon = Icons.bolt_rounded;

/// The clock that stands in for a control's cooldown.
const IconData _waitIcon = Icons.schedule_rounded;

/// The happiness hue, at full saturation. For *fills* only — a meter, a rim.
Color _happinessTone(int happiness) {
  if (happiness > 60) return AppColors.success;
  if (happiness > 30) return AppColors.warning;
  return AppColors.error;
}

/// The same hue, pulled into text contrast.
///
/// [_happinessTone] is picked to look right as a filled bar, and two of the
/// three stops cannot be read as type: raw amber on white is about 1.9:1, well
/// under the 4.5:1 floor, and the previous mood label used it directly. So the
/// hue is darkened toward the app's ink on light surfaces and lifted toward
/// white on dark ones — the recipe `PhaseColors` already uses for its own
/// `text` role.
///
/// [onDark] is passed explicitly rather than read from the context because one
/// call site sits on a surface whose brightness is fixed: the mood badge's disc
/// is white in both themes, so its icon must take the light-mode tone either
/// way.
Color _happinessInk(int happiness, {required bool onDark}) =>
    _statusInk(_happinessTone(happiness), onDark: onDark);

/// Pulls any of the flat status hues into contrast against the surface it is
/// drawn on, by the same recipe `PhaseColors` uses for its own `text` role.
Color _statusInk(Color base, {required bool onDark}) => onDark
    ? Color.lerp(base, Colors.white, 0.34)!
    : Color.lerp(base, AppColors.ink, 0.50)!;

String _moodLabel(PetMood mood) => switch (mood) {
      PetMood.happy => 'Thriving',
      PetMood.excited => 'Excited',
      PetMood.neutral => 'Content',
      PetMood.sleepy => 'Sleepy',
      PetMood.sad => 'Needs you',
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
/// technology hears the pet's state once instead of hearing an icon, a meter,
/// and three chips as separate unlabelled nodes.
String _petSummary(PetState pet) {
  final into = pet.xp % pet.xpForNextLevel;
  return 'Level ${pet.level}. '
      '$into of ${pet.xpForNextLevel} XP toward level ${pet.level + 1}. '
      'Happiness ${pet.happiness} percent, '
      '${_moodLabel(pet.mood).toLowerCase()}. '
      '${_streakPhrase(pet.streak)}.';
}

/// The phase tone resolved against a *fixed* light brightness.
///
/// Used for ink on the hero's white elements. `swatch.text` is lifted toward
/// white in dark mode — correct on a dark card, but it renders as pale lavender
/// on a white medallion and fails contrast there. Pinning the brightness keeps
/// those marks dark enough to read in both themes.
Color _onLightTone(BuildContext context) =>
    const PhaseColors.forBrightness(Brightness.light).ovulation.text;

// ─── Hero ────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({
    required this.pet,
    required this.swatch,
    required this.idle,
    required this.react,
    required this.motion,
    required this.celebrating,
    required this.cuddleReady,
    required this.side,
    required this.onTapPet,
  });

  final PetState pet;
  final PhaseSwatch swatch;
  final Animation<double> idle;
  final Animation<double> react;
  final Motion motion;
  final bool celebrating;
  final bool cuddleReady;

  /// Horizontal inset shared with the page body, so the glass panel lines up
  /// with the cards below it.
  final double side;

  final VoidCallback onTapPet;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = HeroInk.of(context);

    return PhaseHero(
      swatch: swatch,
      // Heavier top inset than the default: there is no app bar above this
      // surface, so the name would otherwise sit tight against the clock.
      padding: EdgeInsets.fromLTRB(
        side,
        AppSpacing.xl,
        side,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // The avatar is an illustration, so it scales with the viewport
              // and not with the type ramp — a medallion that grows with text
              // would push the glass panel off the fold at 200%.
              final size = constraints.maxWidth.isFinite
                  ? (constraints.maxWidth * 0.40).clamp(104.0, 152.0).toDouble()
                  : 132.0;

              return _PetAvatar(
                pet: pet,
                idle: idle,
                react: react,
                motion: motion,
                celebrating: celebrating,
                size: size,
                cuddleReady: cuddleReady,
                onTap: onTapPet,
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          // Excluded as a block: the avatar button already announces level, XP,
          // happiness and streak in one sentence, and the glass panel below
          // publishes the XP figures on its own node.
          ExcludeSemantics(
            child: Column(
              children: [
                Text(
                  pet.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: ink.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _MoodChip(pet: pet),
                const SizedBox(height: AppSpacing.sm),
                // The caption this replaces was mid-grey on a pale lavender
                // wash and barely legible. On the deep hero it is white at 90%,
                // which clears AA against every hero stop.
                Text(
                  cuddleReady
                      ? 'Tap ${pet.name} to cuddle'
                      : '${pet.name} is enjoying the last cuddle',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(color: ink.secondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _XpPanel(pet: pet),
        ],
      ),
    );
  }
}

/// Mood, as a glass pill on the saturated ground.
///
/// Glass belongs here and only here: there is deep colour behind it to refract,
/// which is the whole premise of the material. The same chip on the page below
/// would be a flat grey box.
class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.pet});

  final PetState pet;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = HeroInk.of(context);

    return GlassSurface(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(pet.moodIcon, size: AppSpacing.lg, color: ink.primary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              '${_moodLabel(pet.mood)} · ${pet.type.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: ink.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The pet, framed.
///
/// Three concentric layers do the work the old emoji-in-a-circle could not: a
/// radial glow that bleeds into the hero, a hairline ring that gives the
/// medallion an edge, and an opaque light disc the pet icon sits on at half the
/// medallion's width. A mood badge overlaps the rim so the pet's state is
/// legible without reading any text.
///
/// The disc is light in both themes, like the hero's buttons elsewhere in the
/// app, because a dark disc on a deep hero loses the figure-to-ground split
/// that makes the pet the focal point.
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
    final tone = _onLightTone(context);
    final ring = size + AppSpacing.md;

    Widget medallion = SizedBox.square(
      dimension: ring,
      child: DecoratedBox(
        // The ring: a translucent white band between the glow and the disc.
        // Without it the disc's edge lands straight on the gradient and the
        // medallion reads as a sticker rather than something lit from above.
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(context.isDark ? 0.14 : 0.22),
          border: Border.all(
            color: Colors.white.withOpacity(context.isDark ? 0.26 : 0.42),
            width: AppStrokes.selected,
          ),
        ),
        child: Center(
          child: SizedBox.square(
            dimension: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // A two-stop wash rather than flat white: the disc picks up a
                // hint of the phase hue toward its base, which is what stops a
                // white circle from looking like a hole punched in the hero.
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.white,
                    Color.lerp(AppColors.white, AppColors.ovulationLight, 0.9)!,
                  ],
                ),
                boxShadow: AppElevation.medium(context.isDark),
              ),
              child: Center(
                child: Icon(pet.type.icon, size: size * 0.5, color: tone),
              ),
            ),
          ),
        ),
      ),
    );

    medallion = Stack(
      alignment: Alignment.center,
      children: [
        medallion,
        // Mood badge, overlapping the rim. Carries the mood *face*, so the
        // signal survives greyscale; the tint only reinforces it.
        Positioned(
          right: 0,
          bottom: ring * 0.06,
          child: _MoodBadge(pet: pet),
        ),
      ],
    );

    // Two independent transforms: a slow float that never stops (unless the
    // user asked it to) and a one-shot pop on interaction. Composed rather than
    // combined into one curve so a tap mid-float still reads as a tap.
    medallion = AnimatedBuilder(
      animation: Listenable.merge([idle, react]),
      builder: (context, child) {
        // Both the drift and the pop are sized through Motion, so reduced
        // motion resolves them to a stationary avatar instead of a slower one.
        final float = -motion.offset(AppSpacing.md) *
            Curves.easeInOut.transform(idle.value);
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
      child: medallion,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow, bled into the hero so the medallion sits in a pool of light
        // rather than on a flat field.
        IgnorePointer(
          child: SizedBox.square(
            dimension: ring + AppSpacing.huge,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(context.isDark ? 0.16 : 0.24),
                    Colors.white.withOpacity(0),
                  ],
                  stops: const [0.55, 1],
                ),
              ),
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
          borderRadius: BorderRadius.circular(ring),
          child: medallion,
        ),
      ],
    );
  }
}

/// The mood face as a small disc on the medallion's rim.
///
/// A white disc with a tinted face, not a tinted disc with a white face: two of
/// the three happiness tones (amber, red) cannot carry white at this size.
class _MoodBadge extends StatelessWidget {
  const _MoodBadge({required this.pet});

  final PetState pet;

  @override
  Widget build(BuildContext context) {
    // The disc is white in both themes, so the face takes the light-mode ink
    // regardless of the ambient brightness.
    final ink = _happinessInk(pet.happiness, onDark: false);

    return SizedBox.square(
      dimension: AppSpacing.xxxl,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white,
          border: Border.all(
            color: _happinessTone(pet.happiness).withOpacity(0.5),
            width: AppStrokes.selected,
          ),
          boxShadow: AppElevation.low(context.isDark),
        ),
        child: Center(
          child: Icon(pet.moodIcon, size: AppSpacing.xl, color: ink),
        ),
      ),
    );
  }
}

/// The primary readout: level and progress to the next one, floating on the
/// hero as glass.
///
/// This used to be an opaque white card below the header, equal in weight to
/// the stat row and the happiness card beneath it — three cards at the same
/// depth are three equal priorities, which is the same as none. Lifting it onto
/// the saturated surface makes it unambiguously the headline, and it is one of
/// the three places in the app where a backdrop blur has colour to sample.
class _XpPanel extends StatelessWidget {
  const _XpPanel({required this.pet});

  final PetState pet;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = HeroInk.of(context);
    final into = pet.xp % pet.xpForNextLevel;
    final remaining = (pet.xpForNextLevel - into).clamp(0, pet.xpForNextLevel);
    final percent = (pet.xpProgress.clamp(0.0, 1.0) * 100).round();

    return GlassSurface(
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
                  Icon(_xpIcon, size: AppSpacing.lg, color: ink.secondary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'EXPERIENCE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        color: ink.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _LevelPill(level: pet.level),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Wrapped rather than a fixed baseline row: at 200% the figure
              // and its denominator need two lines, and a Row would clip.
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  AnimatedCount(
                    value: into,
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: ink.primary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                    child: Text(
                      ' / ${pet.xpForNextLevel} XP',
                      style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: ink.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _ProgressBar(
                value: pet.xpProgress,
                // White on a faint white track, the same treatment the hero
                // ring uses. A phase-coloured fill on a phase-coloured hero
                // has nothing to push against.
                fill: const [Colors.white, Colors.white],
                track: ink.faint,
                // The XP meter draws itself once per visit, so it is allowed
                // the longer reveal the cycle ring uses.
                duration: AppDurations.reveal,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                remaining == 0
                    ? 'Level up on the next reward'
                    : '$remaining XP to level ${pet.level + 1}',
                style: text.bodySmall?.copyWith(color: ink.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Level badge: a white pill on the hero, with the phase tone as its ink.
///
/// Inverted rather than tinted, for the reason the home screen's hero button is
/// — a lavender chip on a lavender block has nothing to push against, and white
/// is the only fill with real contrast against every hero stop. It names itself
/// in text next to the star, so the tint is decoration rather than the message.
class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tone = _onLightTone(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.star, size: AppSpacing.lg, color: tone),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'LV ',
            style: text.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: tone,
            ),
          ),
          AnimatedCount(
            value: level,
            style: text.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: tone,
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
    required this.fill,
    this.track,
    this.height = AppSpacing.md,
    this.duration = AppDurations.normal,
  });

  final double value;

  /// Two or more stops for the filled portion.
  final List<Color> fill;

  /// Unfilled remainder. Defaults to the page's hairline colour.
  final Color? track;

  final double height;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(AppRadii.pill);

    final bar = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        // Diagonal rather than horizontal: the fill picks up a hint of shading
        // along its height, which is what stops a flat bar from looking like a
        // placeholder.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: fill,
        ),
      ),
    );

    // heightFactor is required: DecoratedBox has no intrinsic size, so without
    // it the fill collapses to zero height and the meter renders empty at every
    // value.
    Widget filled = FractionallySizedBox(
      widthFactor: clamped,
      heightFactor: 1,
      child: bar,
    );

    // Under reduced motion the meter is drawn at its real value with no tween
    // at all. Collapsing the duration to a millisecond instead still leaves a
    // controller that has to tick at least once, and anything that samples the
    // first frame — a screenshot, a golden — catches the bar empty.
    if (!motion.reduced) {
      filled = TweenAnimationBuilder<double>(
        tween: Tween<double>(end: clamped),
        duration: motion(duration),
        curve: AppCurves.out,
        builder: (context, animated, _) => FractionallySizedBox(
          widthFactor: animated.clamp(0.0, 1.0),
          heightFactor: 1,
          child: bar,
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: height,
        color: track ??
            (context.isDark
                ? context.lineColor.withOpacity(0.6)
                : context.lineColor),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: filled,
        ),
      ),
    );
  }
}

// ─── Stats ───────────────────────────────────────────────────────────────────

/// Streak and badges earned — reference figures, deliberately the quietest
/// surfaces on the page.
///
/// Level moved onto the hero and happiness lives in the care card beside the
/// buttons that change it, so what is left here is the pair of counts that
/// nothing on this screen acts on. [StatTile] is already an outlined, shadowless
/// card, which is the right weight for that.
///
/// The column count is resolved from the available width *and* the text scale
/// instead of being fixed, because a row of 24pt numerals is the first thing to
/// clip at 200%.
class _StatBand extends StatelessWidget {
  const _StatBand({required this.pet, required this.unlocked});

  final PetState pet;
  final int unlocked;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _Stat(
        label: 'Streak',
        spoken: pet.streak == 0
            ? 'None yet'
            : '${pet.streak} ${pet.streak == 1 ? 'day' : 'days'}',
        tile: StatTile(
          label: 'Streak',
          value: '${pet.streak}',
          unit: pet.streak == 1 ? 'day' : 'days',
          icon: AppIcons.streak,
          // Darkened: a StatTile accent is a 15dp icon, and raw amber on a
          // white card is about 1.9:1 — under the 3:1 floor for a graphical
          // element, never mind text.
          accent: _statusInk(AppColors.warning, onDark: context.isDark),
        ),
      ),
      _Stat(
        label: 'Badges',
        spoken: '$unlocked of ${kAchievements.length} unlocked',
        tile: StatTile(
          label: 'Badges',
          value: '$unlocked',
          unit: 'of ${kAchievements.length}',
          icon: AppIcons.trophy,
          accent: PhaseColors.of(context).ovulation.fill,
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

/// Merges a [StatTile] into a single labelled node. Each tile otherwise reads
/// as two fragments — a word, then a number.
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

/// Happiness and the two controls that change it.
///
/// The leading surface below the hero, and the only raised card on the page:
/// everything else in the body is flat and hairline-bordered, which is what
/// makes this one read as the thing to act on.
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
    // The bar is a fill and the mood label is type, so they take the two
    // different renderings of the same hue.
    final tone = _happinessTone(pet.happiness);
    final ink = _happinessInk(pet.happiness, onDark: context.isDark);
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
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Happiness',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: context.inkColor,
                              ),
                            ),
                            // The figure, so nothing on this screen reports
                            // happiness in a bar alone.
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.end,
                              children: [
                                AnimatedCount(
                                  value: pet.happiness,
                                  suffix: '%',
                                  style: text.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.6,
                                    color: context.inkColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Icon plus word: mood is never carried by the tint of
                      // the bar alone.
                      Icon(pet.moodIcon, size: AppSpacing.lg, color: ink),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          _moodLabel(pet.mood),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ProgressBar(
                    value: pet.happiness / 100,
                    fill: [tone.withOpacity(0.75), tone],
                    height: AppSpacing.sm,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              // Two buttons across a phone is fine at default text and
              // unreadable at 200%, where the label would ellipsise to a single
              // letter. Past that point they stack.
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final stacked = scale > 1.25 || constraints.maxWidth < 320;
              final feed = _CareAction(
                label: 'Feed',
                icon: AppIcons.feed,
                ready: feedReady,
                wait: _waitFragment(pet.lastFed, _feedCooldown),
                readyHint: 'Gives ${pet.name} a meal, some XP, and a '
                    'happiness boost',
                waitHint: '${pet.name} is still full. Ready again '
                    '${_waitFragment(pet.lastFed, _feedCooldown)}',
                onPressed: onFeed,
              );
              final cuddle = _CareAction(
                label: 'Cuddle',
                icon: AppIcons.cuddle,
                ready: cuddleReady,
                wait: _waitFragment(pet.lastPetted, _cuddleCooldown),
                readyHint: 'Adds a little happiness and XP',
                waitHint: '${pet.name} is enjoying the last cuddle. Ready '
                    'again ${_waitFragment(pet.lastPetted, _cuddleCooldown)}',
                // Only one of the two is filled. Two solid buttons side by side
                // are two primary actions, which is no primary action.
                quiet: true,
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: feed),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: cuddle),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A care action.
///
/// Built here rather than reusing [PrimaryButton] because the cooldown is the
/// interesting half of this control's life and a stock button has nowhere to put
/// it. Ready, the surface is filled and carries a tinted glow, so it looks
/// pressable. Waiting, it drops to a flat hairline-bordered tile with a clock
/// and the remaining time on a second line — unmistakably inert, without going
/// grey-on-grey.
///
/// The label never turns into a countdown: a control whose name disappears
/// while it waits cannot be found again by anyone who is listening rather than
/// looking. And it stays tappable while waiting, so the pet can still explain
/// itself when tapped early.
class _CareAction extends StatelessWidget {
  const _CareAction({
    required this.label,
    required this.icon,
    required this.ready,
    required this.wait,
    required this.readyHint,
    required this.waitHint,
    required this.onPressed,
    this.quiet = false,
  });

  final String label;
  final IconData icon;
  final bool ready;

  /// Remaining-wait fragment, shown under the label while on cooldown.
  final String wait;

  final String readyHint;
  final String waitHint;
  final VoidCallback onPressed;

  /// Renders as a tinted secondary action rather than a filled primary one.
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadii.control);
    final dark = context.isDark;

    // Three states, three surfaces. The waiting state is the one that has to
    // read as unavailable at a glance, so it loses the fill *and* the shadow
    // and keeps only a hairline.
    final Color background;
    final Color foreground;
    final Color? borderColor;
    final List<BoxShadow> shadows;

    if (!ready) {
      background = dark
          ? context.cardColor.withOpacity(0.5)
          : context.lineColor.withOpacity(0.35);
      foreground = context.mutedColor;
      borderColor = context.lineColor;
      shadows = AppElevation.none;
    } else if (quiet) {
      background = scheme.primary.withOpacity(dark ? 0.18 : 0.10);
      foreground = scheme.primary;
      borderColor = scheme.primary.withOpacity(dark ? 0.46 : 0.32);
      shadows = AppElevation.none;
    } else {
      background = scheme.primary;
      foreground = scheme.onPrimary;
      borderColor = null;
      // A tinted glow, not a black shadow: under a saturated fill black turns
      // the bottom edge muddy exactly where it meets the card.
      shadows = AppElevation.glow(scheme.primary, dark);
    }

    final surface = AnimatedContainer(
      duration: motion(AppDurations.fast),
      curve: AppCurves.out,
      constraints: const BoxConstraints(
        minHeight: AppLayout.buttonHeight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor, width: AppStrokes.selected),
        boxShadow: shadows,
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ready ? icon : _waitIcon, size: 18, color: foreground),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: foreground,
                    ),
                  ),
                  if (!ready)
                    Text(
                      'Ready $wait',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.subtleColor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Pressable(
      onTap: onPressed,
      scale: 0.975,
      borderRadius: radius,
      semanticLabel: label,
      semanticValue: ready ? 'Ready' : 'Waiting',
      semanticHint: ready ? readyHint : waitHint,
      excludeChildSemantics: true,
      child: surface,
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
          limit: 3,
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
        // An earned badge sits on a tinted card; an unearned one is bare. Both
        // are flat — the raised surface on this page is the care card.
        emphasis: unlocked ? CardEmphasis.tinted : CardEmphasis.outlined,
        color: unlocked ? swatch.surface : null,
        borderColor: unlocked ? swatch.border : null,
        borderRadius: radius,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BadgeMedallion(
              icon: achievement.icon,
              unlocked: unlocked,
              size: AppSpacing.huge,
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

/// A badge, as a medallion.
///
/// Earned, it is a filled disc with the icon knocked out of it; unearned, it is
/// an empty ring with the icon drawn in the page's muted ink. The difference is
/// *shape* rather than opacity, so the state survives greyscale, a colour-vision
/// difference, and the dimming that used to be the only cue — and the icon stays
/// the achievement's own mark either way, so a locked tile still shows what is
/// on offer rather than a padlock.
class _BadgeMedallion extends StatelessWidget {
  const _BadgeMedallion({
    required this.icon,
    required this.unlocked,
    required this.size,
  });

  final IconData icon;
  final bool unlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final swatch = PhaseColors.of(context).ovulation;

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: unlocked ? swatch.fill : Colors.transparent,
          border: unlocked
              ? null
              : Border.all(
                  color: context.lineColor,
                  width: AppStrokes.selected,
                ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: size * 0.5,
            // onFill is tuned per brightness for exactly this: a near-black on
            // the lifted dark-mode lavender, white on the light-mode one.
            color: unlocked ? swatch.onFill : context.mutedColor,
          ),
        ),
      ),
    );
  }
}

/// Locked or unlocked, said in an icon and a word. The medallion's shape and the
/// card's tint are reinforcement, never the signal.
class _LockState extends StatelessWidget {
  const _LockState({required this.unlocked, this.compact = false});

  final bool unlocked;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Raw `AppColors.success` is a mid-green tuned as a fill; at label size on
// a white card it lands near 2.5:1, so it goes through the same ink recipe
    // the mood label uses.
    final tone = unlocked
        ? _statusInk(AppColors.success, onDark: context.isDark)
        : context.mutedColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          unlocked ? AppIcons.success : AppIcons.locked,
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
