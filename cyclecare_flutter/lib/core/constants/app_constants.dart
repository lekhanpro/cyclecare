class AppConstants {
  AppConstants._();

  static const String appName = 'CycleCare';
  static const String appVersion = '1.0.0';

  // Default cycle settings
  static const int defaultCycleLength = 28;
  static const int defaultPeriodLength = 5;
  static const int defaultLutealPhase = 14;
  static const int minCycleLength = 21;
  static const int maxCycleLength = 45;
  static const int minPeriodLength = 2;
  static const int maxPeriodLength = 10;

  // Notification channels
  static const String periodReminderChannel = 'period_reminders';
  static const String pillReminderChannel = 'pill_reminders';
  static const String healthReminderChannel = 'health_reminders';
  static const String appointmentChannel = 'appointment_reminders';

  // Pregnancy
  static const int pregnancyWeeks = 40;
  static const int pregnancyDays = 280;

  // Water intake
  static const double defaultWaterGoalMl = 2000;
  static const double glassSize = 250;

  // Amenorrhea thresholds (days)
  static const int amenorrheaMild = 45;
  static const int amenorrheaModerate = 90;
  static const int amenorrheaSevere = 180;

  // Cycle phases
  static const String phaseFollicular = 'Follicular';
  static const String phaseOvulation = 'Ovulation';
  static const String phaseLuteal = 'Luteal';
  static const String phaseMenstrual = 'Menstrual';

  // Cervical mucus types
  static const List<String> cervicalMucusTypes = [
    'Dry',
    'Sticky',
    'Creamy',
    'Watery',
    'Egg-white',
  ];

  // Cervical position
  static const List<String> cervicalPositions = ['Low', 'Medium', 'High'];
  static const List<String> cervicalFirmness = ['Firm', 'Medium', 'Soft'];
  static const List<String> cervicalOpening = [
    'Closed',
    'Partially open',
    'Open',
  ];

  // Moods
  static const List<String> moods = [
    'Happy',
    'Calm',
    'Energetic',
    'Tired',
    'Anxious',
    'Irritable',
    'Sad',
    'Mood swings',
    'Sensitive',
    'Confident',
    'Stressed',
    'Focused',
  ];

  // Symptoms
  static const List<String> symptoms = [
    'Cramps',
    'Headache',
    'Backache',
    'Bloating',
    'Breast tenderness',
    'Acne',
    'Nausea',
    'Fatigue',
    'Insomnia',
    'Hot flashes',
    'Night sweats',
    'Dizziness',
    'Constipation',
    'Diarrhea',
    'Appetite changes',
    'Cravings',
    'Joint pain',
    'Muscle pain',
    'Migraine',
    'Spotting',
  ];

  // Flow levels
  static const List<String> flowLevels = [
    'Spotting',
    'Light',
    'Medium',
    'Heavy',
    'Very Heavy',
  ];

  // Exercise types
  static const List<String> exerciseTypes = [
    'Walking',
    'Running',
    'Yoga',
    'Swimming',
    'Cycling',
    'Strength',
    'Pilates',
    'Dancing',
    'HIIT',
    'Other',
  ];

  // Health conditions
  static const List<String> healthConditions = [
    'PCOS',
    'Endometriosis',
    'PMDD',
  ];

  // Birth control types
  static const List<String> birthControlTypes = [
    'Combination pill',
    'Progestin-only pill',
    'Extended cycle pill',
    'IUD (Hormonal)',
    'IUD (Copper)',
    'Injection',
    'Implant',
    'Patch',
    'Ring',
  ];

  // User modes
  static const String modeTrackPeriods = 'track_periods';
  static const String modeTryingToConceive = 'trying_to_conceive';
  static const String modePregnancy = 'pregnancy';
  static const String modePerimenopause = 'perimenopause';
  static const String modeAbstinence = 'abstinence';

  // Theme palettes
  static const Map<String, int> themePalettes = {
    'Rose': 0xFFE91E63,
    'Lavender': 0xFF9C27B0,
    'Ocean': 0xFF2196F3,
    'Mint': 0xFF4CAF50,
    'Sunset': 0xFFFF9800,
    'Berry': 0xFF880E4F,
    'Teal': 0xFF009688,
    'Coral': 0xFFFF5722,
    'Plum': 0xFF6A1B9A,
    'Sky': 0xFF03A9F4,
  };

  // Supported languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Spanish',
    'hi': 'Hindi',
    'fr': 'French',
    'pt': 'Portuguese',
    'ar': 'Arabic',
  };
}
