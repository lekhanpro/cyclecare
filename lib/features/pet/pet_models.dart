// ─────────────────────────────────────────────────────────────────────────────
// Pet System Models
// ─────────────────────────────────────────────────────────────────────────────

enum PetType {
  bunny,
  cat,
  bear,
  fox;

  String get emoji => switch (this) {
        PetType.bunny => '🐰',
        PetType.cat => '🐱',
        PetType.bear => '🐻',
        PetType.fox => '🦊',
      };

  String get name => switch (this) {
        PetType.bunny => 'Bunny',
        PetType.cat => 'Kitty',
        PetType.bear => 'Bear',
        PetType.fox => 'Foxy',
      };
}

enum PetMood { happy, neutral, sad, excited, sleepy }

class PetState {
  const PetState({
    this.type = PetType.bunny,
    this.name = 'Luna',
    this.xp = 0,
    this.level = 1,
    this.happiness = 80,
    this.streak = 0,
    this.lastFed,
    this.lastPetted,
    this.achievements = const [],
  });

  final PetType type;
  final String name;
  final int xp;
  final int level;
  final int happiness; // 0–100
  final int streak;
  final DateTime? lastFed;
  final DateTime? lastPetted;
  final List<String> achievements;

  int get xpForNextLevel => level * 100;
  double get xpProgress => (xp % xpForNextLevel) / xpForNextLevel;

  PetMood get mood {
    if (happiness >= 80) return PetMood.happy;
    if (happiness >= 60) return PetMood.neutral;
    if (happiness >= 40) return PetMood.sleepy;
    return PetMood.sad;
  }

  String get moodEmoji => switch (mood) {
        PetMood.happy => '😊',
        PetMood.excited => '🤩',
        PetMood.neutral => '😐',
        PetMood.sleepy => '😴',
        PetMood.sad => '😢',
      };

  PetState copyWith({
    PetType? type,
    String? name,
    int? xp,
    int? level,
    int? happiness,
    int? streak,
    DateTime? lastFed,
    DateTime? lastPetted,
    List<String>? achievements,
  }) =>
      PetState(
        type: type ?? this.type,
        name: name ?? this.name,
        xp: xp ?? this.xp,
        level: level ?? this.level,
        happiness: happiness ?? this.happiness,
        streak: streak ?? this.streak,
        lastFed: lastFed ?? this.lastFed,
        lastPetted: lastPetted ?? this.lastPetted,
        achievements: achievements ?? this.achievements,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'name': name,
        'xp': xp,
        'level': level,
        'happiness': happiness,
        'streak': streak,
        'lastFed': lastFed?.toIso8601String(),
        'lastPetted': lastPetted?.toIso8601String(),
        'achievements': achievements,
      };

  factory PetState.fromJson(Map<String, dynamic> json) => PetState(
        type: PetType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => PetType.bunny,
        ),
        name: json['name'] as String? ?? 'Luna',
        xp: json['xp'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        happiness: json['happiness'] as int? ?? 80,
        streak: json['streak'] as int? ?? 0,
        lastFed: json['lastFed'] != null
            ? DateTime.tryParse(json['lastFed'] as String)
            : null,
        lastPetted: json['lastPetted'] != null
            ? DateTime.tryParse(json['lastPetted'] as String)
            : null,
        achievements:
            (json['achievements'] as List<dynamic>?)?.cast<String>() ??
                const [],
      );
}

// ─── XP rewards ──────────────────────────────────────────────────────────────
class PetXP {
  static const int dailyLogComplete = 20;
  static const int periodStart = 30;
  static const int streakMilestone = 50;
  static const int firstBBT = 25;
  static const int aiChatSession = 15;
  static const int partnerInviteAccepted = 40;
  static const int achievementUnlocked = 60;
  static const int feedPet = 10;
  static const int petPet = 5;
}

// ─── Achievements ─────────────────────────────────────────────────────────────
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.xpReward,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;
  final int xpReward;
}

const kAchievements = [
  Achievement(
    id: 'first_log',
    title: 'First Log',
    description: 'Logged your first daily entry',
    emoji: '📝',
    xpReward: 60,
  ),
  Achievement(
    id: 'streak_7',
    title: '7-Day Streak',
    description: 'Logged 7 days in a row',
    emoji: '🔥',
    xpReward: 100,
  ),
  Achievement(
    id: 'streak_30',
    title: 'Monthly Champion',
    description: 'Logged 30 days in a row',
    emoji: '🏆',
    xpReward: 300,
  ),
  Achievement(
    id: 'first_period',
    title: 'Cycle Starter',
    description: 'Logged your first period',
    emoji: '💧',
    xpReward: 60,
  ),
  Achievement(
    id: 'first_bbt',
    title: 'Temp Tracker',
    description: 'Logged your first BBT reading',
    emoji: '🌡️',
    xpReward: 60,
  ),
  Achievement(
    id: 'ai_chat',
    title: 'AI Explorer',
    description: 'Had your first AI chat session',
    emoji: '✨',
    xpReward: 60,
  ),
  Achievement(
    id: 'partner_invite',
    title: 'Together',
    description: 'Invited a partner',
    emoji: '💑',
    xpReward: 60,
  ),
  Achievement(
    id: 'level_5',
    title: 'Level 5',
    description: 'Reached level 5',
    emoji: '⭐',
    xpReward: 0,
  ),
  Achievement(
    id: 'level_10',
    title: 'Level 10',
    description: 'Reached level 10',
    emoji: '🌟',
    xpReward: 0,
  ),
];
