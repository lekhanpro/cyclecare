import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';

class FeatureTourStep {
  const FeatureTourStep(this.title, this.route, this.overview);
  final String title, route, overview;
}

const featureTourSteps = [
  FeatureTourStep(
    'Your cycle at a glance',
    '/home?cycle=1',
    'See your cycle dial, all four phases and estimated windows. Tap a day to explore; your estimates remain separate from recorded dates.',
  ),
  FeatureTourStep(
    'Your calendar',
    '/calendar',
    'Browse recorded periods and calendar estimates. Select a date to log or edit it; the year view helps you look further back.',
  ),
  FeatureTourStep(
    'Your daily log',
    '/log',
    'Open only the categories you need. Save observations, leave unknown details blank, and return later to edit them.',
  ),
  FeatureTourStep(
    'Patterns & reports',
    '/insights',
    'Explore cycle history and observed symptoms. Coverage shows missing days; the cycle-health report lets you choose records and preview before sharing.',
  ),
  FeatureTourStep(
    'Your companion',
    '/pet',
    'Choose a pet, try a cuddle or a quiet moment, and play or pause motion. Pet moments never create health records for you.',
  ),
  FeatureTourStep(
    'Local reminders',
    '/reminders',
    'Choose schedules, check permission status and send a test. Android controls final delivery; no permission request happens just by visiting.',
  ),
  FeatureTourStep(
    'Your learning library',
    '/education',
    'Search the offline articles, save bookmarks and follow the cited sources when online.',
  ),
  FeatureTourStep(
    'Health & pain diary',
    '/health',
    'Read condition information or record pain and activity impact. Questionnaires are conversation starters, not diagnoses.',
  ),
  FeatureTourStep(
    'Sharing on your terms',
    '/partner',
    'Preview a snapshot before Share or Copy. A live connection requires explicit pairing and field approval; review or revoke what you share.',
  ),
  FeatureTourStep(
    'Make it yours',
    '/settings',
    'Change tracking mode, appearance, motion, privacy and backup choices. Birth-control and pregnancy tools stay available here, and you can replay this tour anytime.',
  ),
];

enum FeatureTourStatus { notStarted, active, paused, completed }

class FeatureTourState {
  const FeatureTourState({
    this.status = FeatureTourStatus.notStarted,
    this.step = 0,
  });
  final FeatureTourStatus status;
  final int step;
  FeatureTourStep get current => featureTourSteps[step];
  Map<String, Object> toJson() => {
    'version': 1,
    'status': status.name,
    'step': step,
  };
  factory FeatureTourState.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) return const FeatureTourState();
    final step = json['step'];
    if (step is! int || step < 0 || step >= featureTourSteps.length)
      return const FeatureTourState();
    final status = FeatureTourStatus.values
        .where((s) => s.name == json['status'])
        .firstOrNull;
    if (status == null) return const FeatureTourState();
    // Resuming is an explicit choice after a process restart.
    return FeatureTourState(
      status: status == FeatureTourStatus.active
          ? FeatureTourStatus.paused
          : status,
      step: step,
    );
  }
}

class FeatureTourController extends AsyncNotifier<FeatureTourState> {
  static const storageKey = 'cc.feature-tour.v1';
  Future<void> _queue = Future.value();

  @override
  Future<FeatureTourState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return const FeatureTourState();
    try {
      return FeatureTourState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const FeatureTourState();
    }
  }

  Future<void> _change(FeatureTourState Function(FeatureTourState) change) {
    final next = _queue.then((_) async {
      final previous = await future;
      final target = change(previous);
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(
        storageKey,
        jsonEncode(target.toJson()),
      );
      if (!saved) throw StateError('Tour progress could not be saved');
      state = AsyncData(target);
    });
    _queue = next.catchError((Object _) {});
    return next;
  }

  Future<void> start({bool replay = false}) => _change(
    (old) => FeatureTourState(
      status: FeatureTourStatus.active,
      step: replay || old.status == FeatureTourStatus.completed ? 0 : old.step,
    ),
  );
  Future<void> pause() => _change(
    (old) => FeatureTourState(status: FeatureTourStatus.paused, step: old.step),
  );
  Future<void> back() => _change(
    (old) => FeatureTourState(
      status: FeatureTourStatus.active,
      step: (old.step - 1).clamp(0, featureTourSteps.length - 1),
    ),
  );
  Future<void> next() => _change(
    (old) => old.step == featureTourSteps.length - 1
        ? FeatureTourState(status: FeatureTourStatus.completed, step: old.step)
        : FeatureTourState(
            status: FeatureTourStatus.active,
            step: old.step + 1,
          ),
  );
}

final featureTourProvider =
    AsyncNotifierProvider<FeatureTourController, FeatureTourState>(
      FeatureTourController.new,
    );

class FeatureTourScreen extends ConsumerStatefulWidget {
  const FeatureTourScreen({super.key});
  @override
  ConsumerState<FeatureTourScreen> createState() => _FeatureTourScreenState();
}

class _FeatureTourScreenState extends ConsumerState<FeatureTourScreen> {
  bool _busy = false;
  String? _error;
  Future<void> _begin({bool replay = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(featureTourProvider.notifier).start(replay: replay);
      final state = ref.read(featureTourProvider).requireValue;
      if (mounted) context.go(state.current.route);
    } catch (_) {
      if (mounted)
        setState(
          () => _error = 'Could not save tour progress. Please try again.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Explore CycleCare')),
    body: ref
        .watch(featureTourProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(featureTourProvider),
              child: const Text('Try again'),
            ),
          ),
          data: (tour) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'A quick look around',
                style: AppTextStyles.heading(fontSize: 30),
              ),
              const SizedBox(height: 12),
              const Text(
                'Visit 10 features, with a short guide on each page. Explore at your pace, skip or resume anytime.',
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < featureTourSteps.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text('${i + 1}'),
                  title: Text(featureTourSteps[i].title),
                  trailing:
                      i < tour.step ||
                          tour.status == FeatureTourStatus.completed
                      ? const Icon(Icons.check_rounded)
                      : null,
                ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              PrimaryButton(
                label: tour.status == FeatureTourStatus.completed
                    ? 'Replay tour'
                    : tour.step > 0
                    ? 'Resume at step ${tour.step + 1}'
                    : 'Start tour',
                loading: _busy,
                onPressed: _busy ? null : () => _begin(),
              ),
              if (tour.step > 0 && tour.status != FeatureTourStatus.completed)
                TextButton(
                  onPressed: _busy ? null : () => _begin(replay: true),
                  child: const Text('Start from the beginning'),
                ),
              TextButton(
                onPressed: _busy ? null : () => context.go('/mode'),
                child: const Text('Maybe later · open my dashboard'),
              ),
            ],
          ),
        ),
  );
}

/// Mount inside the app-lock boundary. It never writes health records or asks
/// for permissions; a tour progresses only after an explicit user action.
class FeatureTourHost extends ConsumerStatefulWidget {
  const FeatureTourHost({super.key, required this.router, required this.child});
  final GoRouter router;
  final Widget child;
  @override
  ConsumerState<FeatureTourHost> createState() => _FeatureTourHostState();
}

class _FeatureTourHostState extends ConsumerState<FeatureTourHost> {
  String? _shown;
  bool _busy = false;
  bool _dialogOpen = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    widget.router.routeInformationProvider.addListener(_routeChanged);
  }

  @override
  void didUpdateWidget(FeatureTourHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      oldWidget.router.routeInformationProvider.removeListener(_routeChanged);
      widget.router.routeInformationProvider.addListener(_routeChanged);
    }
  }

  @override
  void dispose() {
    widget.router.routeInformationProvider.removeListener(_routeChanged);
    super.dispose();
  }

  void _routeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _move({bool back = false, bool pause = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final control = ref.read(featureTourProvider.notifier);
      if (pause) {
        await control.pause();
      } else if (back) {
        await control.back();
      } else {
        await control.next();
      }
      if (!mounted) return;
      final next = ref.read(featureTourProvider).requireValue;
      if (!pause) {
        _shown = null;
        widget.router.go(
          next.status == FeatureTourStatus.completed
              ? '/mode'
              : next.current.route,
        );
      }
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Tour progress was not saved. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _overview(FeatureTourState tour) {
    final key = '${tour.step}:${tour.current.route}';
    if (_shown == key || _dialogOpen) return;
    _shown = key;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final current = ref.read(featureTourProvider).valueOrNull;
      final context = widget.router.routerDelegate.navigatorKey.currentContext;
      if (current?.status != FeatureTourStatus.active ||
          current?.step != tour.step ||
          context == null)
        return;
      _dialogOpen = true;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text('${tour.step + 1}/10 · ${tour.current.title}'),
          content: Text(tour.current.overview),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Explore this page'),
            ),
          ],
        ),
      );
      _dialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tour = ref.watch(featureTourProvider).valueOrNull;
    final location = widget.router.routeInformationProvider.value.uri;
    final path = location.path;
    final active = tour?.status == FeatureTourStatus.active;
    final allowed = ![
      '/',
      '/landing',
      '/sign-in',
      '/onboarding',
      '/mode-introduction',
      '/tour',
    ].contains(path);
    final expected = Uri.parse(tour?.current.route ?? '/');
    final onStep =
        path == expected.path &&
        expected.queryParameters.entries.every(
          (entry) => location.queryParameters[entry.key] == entry.value,
        );
    if (active && allowed && onStep) _overview(tour!);
    return Column(
      children: [
        Expanded(child: widget.child),
        if (active && allowed && MediaQuery.viewInsetsOf(context).bottom == 0)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .35,
            ),
            child: SingleChildScrollView(
              child: SafeArea(
                top: false,
                child: Material(
                  elevation: 4,
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Tour ${tour!.step + 1}/10',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        if (_error != null) Text(_error!),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: _busy || tour.step == 0
                                  ? null
                                  : () => _move(back: true),
                              child: const Text('Back'),
                            ),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _move(pause: true),
                              child: const Text('Pause tour'),
                            ),
                            FilledButton(
                              onPressed: _busy ? null : () => _move(),
                              child: Text(tour.step == 9 ? 'Finish' : 'Next'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
