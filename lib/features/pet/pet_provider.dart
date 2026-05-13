import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pet_models.dart';

class PetNotifier extends AsyncNotifier<PetState> {
  static const _key = 'cc.pet.v1';

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

  Future<void> _save(PetState s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(s.toJson()));
    state = AsyncData(s);
  }

  Future<void> addXP(int amount, {String? achievementId}) async {
    final current = state.valueOrNull ?? const PetState();
    var newXp = current.xp + amount;
    var newLevel = current.level;
    var newHappiness = (current.happiness + (amount ~/ 5)).clamp(0, 100);

    // Level up
    while (newXp >= newLevel * 100) {
      newXp -= newLevel * 100;
      newLevel++;
    }

    final achievements = List<String>.from(current.achievements);
    if (achievementId != null && !achievements.contains(achievementId)) {
      achievements.add(achievementId);
    }

    // Level achievements
    if (newLevel >= 5 && !achievements.contains('level_5')) {
      achievements.add('level_5');
    }
    if (newLevel >= 10 && !achievements.contains('level_10')) {
      achievements.add('level_10');
    }

    await _save(current.copyWith(
      xp: newXp,
      level: newLevel,
      happiness: newHappiness,
      achievements: achievements,
    ));
  }

  Future<void> feed() async {
    final current = state.valueOrNull ?? const PetState();
    final now = DateTime.now();
    final lastFed = current.lastFed;
    if (lastFed != null &&
        now.difference(lastFed).inHours < 4) {
      return; // cooldown
    }
    await _save(current.copyWith(
      lastFed: now,
      happiness: (current.happiness + 15).clamp(0, 100),
    ));
    await addXP(PetXP.feedPet);
  }

  Future<void> pet() async {
    final current = state.valueOrNull ?? const PetState();
    final now = DateTime.now();
    final lastPetted = current.lastPetted;
    if (lastPetted != null &&
        now.difference(lastPetted).inMinutes < 30) {
      return; // cooldown
    }
    await _save(current.copyWith(
      lastPetted: now,
      happiness: (current.happiness + 8).clamp(0, 100),
    ));
    await addXP(PetXP.petPet);
  }

  Future<void> setPetType(PetType type) async {
    final current = state.valueOrNull ?? const PetState();
    await _save(current.copyWith(type: type));
  }

  Future<void> setPetName(String name) async {
    final current = state.valueOrNull ?? const PetState();
    await _save(current.copyWith(name: name.trim().isEmpty ? 'Luna' : name.trim()));
  }

  Future<void> incrementStreak() async {
    final current = state.valueOrNull ?? const PetState();
    final newStreak = current.streak + 1;
    await _save(current.copyWith(streak: newStreak));
    if (newStreak % 7 == 0) {
      await addXP(PetXP.streakMilestone, achievementId: 'streak_7');
    }
    if (newStreak >= 30) {
      await addXP(0, achievementId: 'streak_30');
    }
  }
}

final petProvider = AsyncNotifierProvider<PetNotifier, PetState>(
  PetNotifier.new,
);
