import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/date_helpers.dart';
import '../tracking/application/cycle_tracker_controller.dart';
import 'pet_care.dart';
import 'pet_models.dart';

enum PetClaimResult { awarded, alreadyClaimed, notRecorded }

class PetNotifier extends AsyncNotifier<PetState> {
  static const _key = 'cc.pet.v1';
  Future<void> _queue = Future.value();

  @override
  Future<PetState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const PetState();
    try {
      return PetState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const PetState();
    }
  }

  Future<T> _mutate<T>(Future<T> Function(PetState current) operation) {
    final next = _queue.then((_) async => operation(await future));
    _queue = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  Future<void> _save(PetState next) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      if (!await prefs.setString(_key, jsonEncode(next.toJson()))) {
        throw StateError('Companion progress could not be saved');
      }
    } catch (_) {
      // SharedPreferences updates its cache before the platform write resolves.
      // Re-read durable storage so a failed claim cannot appear saved on reload.
      await prefs.reload();
      rethrow;
    }
    state = AsyncData(next);
  }

  PetState _withXP(PetState current, int amount, {String? achievementId}) {
    var xp = current.xp + amount;
    var level = current.level;
    while (xp >= level * 100) {
      xp -= level * 100;
      level++;
    }
    final achievements = {...current.achievements};
    if (achievementId != null) achievements.add(achievementId);
    if (level >= 5) achievements.add('level_5');
    if (level >= 10) achievements.add('level_10');
    return current.copyWith(
      xp: xp,
      level: level,
      happiness: (current.happiness + (amount ~/ 5)).clamp(0, 100),
      achievements: achievements.toList(),
    );
  }

  Future<void> addXP(int amount, {String? achievementId}) => _mutate(
    (current) => _save(_withXP(current, amount, achievementId: achievementId)),
  );

  Future<void> feed() => _mutate((current) async {
    final now = DateTime.now();
    if (current.lastFed != null && now.difference(current.lastFed!).inHours < 4)
      return;
    await _save(
      _withXP(
        current.copyWith(
          lastFed: now,
          happiness: (current.happiness + 15).clamp(0, 100),
        ),
        PetXP.feedPet,
      ),
    );
  });

  Future<void> pet() => _mutate((current) async {
    final now = DateTime.now();
    if (current.lastPetted != null &&
        now.difference(current.lastPetted!).inMinutes < 30)
      return;
    await _save(
      _withXP(
        current.copyWith(
          lastPetted: now,
          happiness: (current.happiness + 8).clamp(0, 100),
        ),
        PetXP.petPet,
      ),
    );
  });

  Future<void> setPetType(PetType type) =>
      _mutate((current) => _save(current.copyWith(type: type)));
  Future<void> setPetName(String name) => _mutate(
    (current) => _save(
      current.copyWith(name: name.trim().isEmpty ? 'Luna' : name.trim()),
    ),
  );

  Future<void> incrementStreak() => _mutate((current) async {
    final streak = current.streak + 1;
    var next = current.copyWith(streak: streak);
    if (streak % 7 == 0)
      next = _withXP(next, PetXP.streakMilestone, achievementId: 'streak_7');
    if (streak >= 30) next = _withXP(next, 0, achievementId: 'streak_30');
    await _save(next);
  });

  /// Re-check stored tracking data at claim time. The caller cannot choose XP
  /// or assert task completion, and concurrent requests share one write queue.
  Future<PetClaimResult> claimCareGoal(
    String goalId, {
    DateTime? now,
  }) => _mutate((current) async {
    final day = dateOnly(now ?? DateTime.now());
    final records = await ref.read(cycleTrackerControllerProvider.future);
    final goal = recordedCareGoals(
      records.logFor(day),
    ).where((g) => g.id == goalId).firstOrNull;
    if (goal == null) throw ArgumentError.value(goalId, 'goalId');
    final key = goalClaimKey(goal.id, day);
    if (current.careClaims.contains(key)) return PetClaimResult.alreadyClaimed;
    if (!goal.done) return PetClaimResult.notRecorded;
    final rewarded = _withXP(current, goal.xp);
    await _save(rewarded.copyWith(careClaims: [...current.careClaims, key]));
    return PetClaimResult.awarded;
  });
}

final petProvider = AsyncNotifierProvider<PetNotifier, PetState>(
  PetNotifier.new,
);
