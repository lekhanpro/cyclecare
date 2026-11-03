import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/services/haptics.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';
import 'pet_care.dart';
import 'pet_companion.dart';
import 'pet_models.dart';
import 'pet_provider.dart';

class PetScreen extends ConsumerWidget {
  const PetScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: ref
        .watch(petProvider)
        .when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Loading companion',
            ),
          ),
          error: (_, __) => SafeArea(
            child: Center(
              child: EmptyState(
                icon: AppIcons.petBunny,
                title: 'Could not load your companion',
                message: 'Try again to see your saved progress.',
                actionLabel: 'Try again',
                onAction: () => ref.invalidate(petProvider),
              ),
            ),
          ),
          data: (pet) => _PetView(pet: pet),
        ),
  );
}

class _PetView extends ConsumerStatefulWidget {
  const _PetView({required this.pet});
  final PetState pet;
  @override
  ConsumerState<_PetView> createState() => _PetViewState();
}

class _PetViewState extends ConsumerState<_PetView> {
  final _animation = PetAnimationController();
  PetAction? _selected;
  bool _saving = false;
  String? _failure;
  static const _feedCooldown = Duration(hours: 4);
  static const _cuddleCooldown = Duration(minutes: 30);

  @override
  void didUpdateWidget(_PetView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pet.level > oldWidget.pet.level) {
      Haptics.celebrate();
      _animation.play(PetAction.celebrate);
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  bool _ready(DateTime? last, Duration wait) =>
      last == null || DateTime.now().difference(last) >= wait;
  String _wait(DateTime? last, Duration duration) {
    if (last == null) return '';
    final minutes = (duration - DateTime.now().difference(last)).inMinutes + 1;
    return minutes >= 60
        ? '${(minutes / 60).ceil()}h'
        : '${minutes.clamp(1, 59)}m';
  }

  Future<void> _save(Future<void> Function() operation) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failure = null;
    });
    try {
      await operation();
    } catch (_) {
      if (mounted) {
        setState(() => _failure = 'Could not save. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _moment(PetAction action) {
    setState(() => _selected = action);
    _animation.play(action);
  }

  Future<void> _feed() async {
    _moment(PetAction.feed);
    if (!_ready(widget.pet.lastFed, _feedCooldown)) {
      showAppToast(
        context,
        message:
            'Next treat reward in ${_wait(widget.pet.lastFed, _feedCooldown)}',
        kind: ToastKind.info,
      );
      return;
    }
    await _save(() => ref.read(petProvider.notifier).feed());
  }

  Future<void> _cuddle() async {
    _moment(PetAction.cuddle);
    if (_ready(widget.pet.lastPetted, _cuddleCooldown)) {
      await _save(() => ref.read(petProvider.notifier).pet());
    } else {
      showAppToast(
        context,
        message:
            'Next cuddle reward in ${_wait(widget.pet.lastPetted, _cuddleCooldown)}',
        kind: ToastKind.info,
      );
    }
  }

  Future<void> _rename() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameCompanion(initialName: widget.pet.name),
    );
    if (name != null && mounted) {
      await _save(() => ref.read(petProvider.notifier).setPetName(name));
    }
  }

  Future<void> _choose() async {
    final type = await showModalBottomSheet<PetType>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Your companion',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              for (final type in PetType.values)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  leading: Image.asset(
                    type.artworkAsset,
                    width: 58,
                    height: 64,
                  ),
                  title: Text(
                    '${switch (type) {
                      PetType.bunny => 'Luna',
                      PetType.cat => 'Miso',
                      PetType.bear => 'Maple',
                      PetType.fox => 'Pip',
                    }} · ${type.name}',
                  ),
                  trailing: type == widget.pet.type
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.pop(context, type),
                ),
            ],
          ),
        ),
      ),
    );
    if (type != null && mounted) {
      await _save(() => ref.read(petProvider.notifier).setPetType(type));
    }
  }

  void _badge(Achievement badge) {
    final earned = widget.pet.achievements.contains(badge.id);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(badge.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              badge.icon,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(badge.description),
            const SizedBox(height: 12),
            Text(earned ? 'Unlocked' : 'Not yet unlocked'),
            if (badge.xpReward > 0)
              Text('${earned ? 'Awarded' : 'On unlock'}: ${badge.xpReward} XP'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final text = Theme.of(context).textTheme;
    final unlocked = kAchievements
        .where((a) => pet.achievements.contains(a.id))
        .length;
    final cuddleReady = _ready(pet.lastPetted, _cuddleCooldown);
    final stage = stageForLevel(pet.level);
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Companion'),
          floating: true,
          actions: [
            IconButton(
              onPressed: _saving ? null : _rename,
              tooltip: 'Rename companion',
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: _saving ? null : _choose,
              tooltip: 'Choose companion',
              icon: const Icon(AppIcons.petBunny),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text(pet.name, style: text.headlineMedium),
                        Chip(
                          label: Text('Level ${pet.level} · ${stage.label}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xffedf1e9),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
                      child: PetCompanion(
                        type: pet.type,
                        name: pet.name,
                        width: 268,
                        controller: _animation,
                        showHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _saving ? null : _cuddle,
                          icon: const Icon(AppIcons.cuddle),
                          label: const Text('Cuddle'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _saving ? null : _feed,
                          icon: const Icon(AppIcons.feed),
                          label: const Text('Treat'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _moment(PetAction.breathe),
                          icon: const Icon(Icons.air_rounded),
                          label: const Text('Breathe'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_failure != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _failure!,
                          style: text.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (_saving)
                      const LinearProgressIndicator(
                        semanticsLabel: 'Saving companion',
                      ),
                    _PetProgress(pet: pet),
                    const SizedBox(height: 12),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('More moments'),
                      subtitle: Text(
                        _selected?.label ?? 'Water, rest, stretch & more',
                      ),
                      childrenPadding: const EdgeInsets.only(bottom: 16),
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final action in PetAction.values.where(
                              (a) => ![
                                PetAction.feed,
                                PetAction.cuddle,
                                PetAction.breathe,
                              ].contains(a),
                            ))
                              ActionChip(
                                label: Text(action.label),
                                onPressed: () => _moment(action),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Moments play an animation. Record your own water, sleep or check-in in your log.',
                        ),
                        TextButton.icon(
                          onPressed: () => context.go(AppRoutes.log),
                          icon: const Icon(AppIcons.notes),
                          label: const Text('Open today’s log'),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Achievements'),
                      subtitle: Text(
                        '$unlocked of ${kAchievements.length} unlocked',
                      ),
                      children: [
                        for (final badge in kAchievements)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              badge.icon,
                              color: pet.achievements.contains(badge.id)
                                  ? Theme.of(context).colorScheme.primary
                                  : context.mutedColor,
                            ),
                            title: Text(badge.title),
                            trailing: Icon(
                              pet.achievements.contains(badge.id)
                                  ? Icons.check_circle_outline
                                  : Icons.lock_outline,
                            ),
                            onTap: () => _badge(badge),
                          ),
                      ],
                    ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Care & growth'),
                      childrenPadding: const EdgeInsets.only(bottom: 16),
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Cuddles'),
                          subtitle: Text(
                            cuddleReady
                                ? 'Happiness and XP ready'
                                : 'Next reward in ${_wait(pet.lastPetted, _cuddleCooldown)}',
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Treats'),
                          subtitle: Text(
                            _ready(pet.lastFed, _feedCooldown)
                                ? 'Happiness and 10 XP ready'
                                : 'Next reward in ${_wait(pet.lastFed, _feedCooldown)} · animations stay available',
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            stage.nextAt == null
                                ? 'Fully grown'
                                : 'Next stage at level ${stage.nextAt}',
                          ),
                          subtitle: const Text(
                            'Baby → Young → Grown. The original clay pose stays the same as your progress grows.',
                          ),
                        ),
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Touch & motion'),
                          subtitle: Text(
                            'Stroke or hold the head, touch an ear, or tap a paw. Touch interrupts a movie. Pause keeps every care action available.',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PetProgress extends StatelessWidget {
  const _PetProgress({required this.pet});
  final PetState pet;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 16,
          runSpacing: 8,
          children: [
            Text('${pet.xp} / ${pet.xpForNextLevel} XP'),
            Text('${pet.happiness}% · ${pet.mood.name}'),
            Text('${pet.streak} ${pet.streak == 1 ? 'day' : 'days'} streak'),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: pet.xpProgress,
          semanticsLabel:
              'Progress to level ${pet.level + 1}. '
              '${pet.xp} of ${pet.xpForNextLevel} XP',
          semanticsValue: '${(pet.xpProgress * 100).round()}',
        ),
      ],
    ),
  );
}

class _RenameCompanion extends StatefulWidget {
  const _RenameCompanion({required this.initialName});
  final String initialName;
  @override
  State<_RenameCompanion> createState() => _RenameCompanionState();
}

class _RenameCompanionState extends State<_RenameCompanion> {
  late final _input = TextEditingController(text: widget.initialName);
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Companion name'),
    content: TextField(
      controller: _input,
      autofocus: true,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(labelText: 'Name'),
      onSubmitted: (value) => Navigator.pop(context, value),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _input.text),
        child: const Text('Save'),
      ),
    ],
  );
}
