import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/soft_card.dart';

// ─── Simple state ─────────────────────────────────────────────────────────────
enum BirthControlMethod {
  pill,
  patch,
  ring,
  iud,
  implant,
  injection,
  condom,
  none;

  String get label => switch (this) {
        BirthControlMethod.pill => 'Daily Pill',
        BirthControlMethod.patch => 'Patch',
        BirthControlMethod.ring => 'Ring',
        BirthControlMethod.iud => 'IUD',
        BirthControlMethod.implant => 'Implant',
        BirthControlMethod.injection => 'Injection',
        BirthControlMethod.condom => 'Condom',
        BirthControlMethod.none => 'None',
      };

  String get emoji => switch (this) {
        BirthControlMethod.pill => '💊',
        BirthControlMethod.patch => '🩹',
        BirthControlMethod.ring => '💍',
        BirthControlMethod.iud => '🔩',
        BirthControlMethod.implant => '💉',
        BirthControlMethod.injection => '💉',
        BirthControlMethod.condom => '🛡️',
        BirthControlMethod.none => '❌',
      };
}

class BirthControlState {
  const BirthControlState({
    this.method = BirthControlMethod.none,
    this.streak = 0,
    this.takenToday = false,
    this.lastTaken,
  });

  final BirthControlMethod method;
  final int streak;
  final bool takenToday;
  final DateTime? lastTaken;
}

class BirthControlNotifier extends AsyncNotifier<BirthControlState> {
  static const _methodKey = 'cc.bc.method';
  static const _streakKey = 'cc.bc.streak';
  static const _lastTakenKey = 'cc.bc.lastTaken';

  @override
  Future<BirthControlState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final methodName = prefs.getString(_methodKey) ?? 'none';
    final streak = prefs.getInt(_streakKey) ?? 0;
    final lastTakenStr = prefs.getString(_lastTakenKey);
    final lastTaken =
        lastTakenStr != null ? DateTime.tryParse(lastTakenStr) : null;
    final takenToday =
        lastTaken != null && _isSameDay(lastTaken, DateTime.now());

    return BirthControlState(
      method: BirthControlMethod.values.firstWhere(
        (m) => m.name == methodName,
        orElse: () => BirthControlMethod.none,
      ),
      streak: streak,
      takenToday: takenToday,
      lastTaken: lastTaken,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> setMethod(BirthControlMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_methodKey, method.name);
    final current = state.valueOrNull ?? const BirthControlState();
    state = AsyncData(BirthControlState(
      method: method,
      streak: current.streak,
      takenToday: current.takenToday,
      lastTaken: current.lastTaken,
    ));
  }

  Future<void> checkIn() async {
    final prefs = await SharedPreferences.getInstance();
    final current = state.valueOrNull ?? const BirthControlState();
    if (current.takenToday) return;

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final newStreak =
        current.lastTaken != null && _isSameDay(current.lastTaken!, yesterday)
            ? current.streak + 1
            : 1;

    await prefs.setInt(_streakKey, newStreak);
    await prefs.setString(_lastTakenKey, now.toIso8601String());

    state = AsyncData(BirthControlState(
      method: current.method,
      streak: newStreak,
      takenToday: true,
      lastTaken: now,
    ));
  }
}

final birthControlProvider =
    AsyncNotifierProvider<BirthControlNotifier, BirthControlState>(
  BirthControlNotifier.new,
);

// ─── Screen ───────────────────────────────────────────────────────────────────
class BirthControlScreen extends ConsumerWidget {
  const BirthControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bcAsync = ref.watch(birthControlProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Birth Control')),
      body: bcAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (bc) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Method selector
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your method',
                      style: AppTextStyles.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: BirthControlMethod.values.map((m) {
                      final selected = bc.method == m;
                      return ChoiceChip(
                        label: Text('${m.emoji} ${m.label}'),
                        selected: selected,
                        onSelected: (_) => ref
                            .read(birthControlProvider.notifier)
                            .setMethod(m),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (bc.method == BirthControlMethod.pill) ...[
              // Daily check-in card
              SoftCard(
                color: bc.takenToday
                    ? AppColors.fertileLight
                    : AppColors.periodLight,
                child: Column(
                  children: [
                    Text(
                      bc.takenToday ? '✅ Taken today!' : '💊 Take your pill',
                      style: AppTextStyles.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Streak: ${bc.streak} day${bc.streak == 1 ? '' : 's'} 🔥',
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!bc.takenToday)
                      FilledButton(
                        onPressed: () =>
                            ref.read(birthControlProvider.notifier).checkIn(),
                        child: const Text('Mark as taken'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Info card
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About ${bc.method.label}',
                      style: AppTextStyles.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 8),
                  Text(
                    _methodInfo(bc.method),
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _Disclaimer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _methodInfo(BirthControlMethod m) => switch (m) {
        BirthControlMethod.pill =>
          'Combined or progestin-only pills are taken daily. Effectiveness is highest when taken at the same time each day.',
        BirthControlMethod.patch =>
          'A hormonal patch worn on the skin, changed weekly for 3 weeks with a patch-free week.',
        BirthControlMethod.ring =>
          'A flexible ring inserted vaginally for 3 weeks, removed for 1 week.',
        BirthControlMethod.iud =>
          'A small device placed in the uterus by a healthcare provider. Can be hormonal or copper.',
        BirthControlMethod.implant =>
          'A small rod inserted under the skin of the upper arm, effective for up to 3 years.',
        BirthControlMethod.injection =>
          'A hormonal injection given every 3 months by a healthcare provider.',
        BirthControlMethod.condom =>
          'A barrier method that also protects against STIs. Most effective when used correctly every time.',
        BirthControlMethod.none =>
          'No birth control method selected. Consult a healthcare provider to discuss your options.',
      };
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '⚕️ This is educational information only. Consult a healthcare provider for medical advice about contraception.',
        style: AppTextStyles.textTheme.bodySmall?.copyWith(
          color: AppColors.muted,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
