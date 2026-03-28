// Flow intensity levels
enum FlowIntensity {
  spotting,
  light,
  medium,
  heavy;

  String get displayName {
    switch (this) {
      case FlowIntensity.spotting:
        return 'Spotting';
      case FlowIntensity.light:
        return 'Light';
      case FlowIntensity.medium:
        return 'Medium';
      case FlowIntensity.heavy:
        return 'Heavy';
    }
  }
}

// Mood states
enum Mood {
  happy,
  sad,
  anxious,
  irritable,
  calm,
  energetic,
  tired,
  stressed;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}

// Symptoms
enum Symptom {
  cramps,
  headache,
  moodSwings,
  fatigue,
  bloating,
  acne,
  backPain,
  nausea,
  breastTenderness,
  anxiety,
  irritability,
  foodCravings,
  lowerBackPain,
  insomnia,
  lowEnergy,
  appetiteChanges;

  String get displayName {
    switch (this) {
      case Symptom.moodSwings:
        return 'Mood Swings';
      case Symptom.backPain:
        return 'Back Pain';
      case Symptom.breastTenderness:
        return 'Breast Tenderness';
      case Symptom.foodCravings:
        return 'Food Cravings';
      case Symptom.lowerBackPain:
        return 'Lower Back Pain';
      case Symptom.lowEnergy:
        return 'Low Energy';
      case Symptom.appetiteChanges:
        return 'Appetite Changes';
      default:
        return name[0].toUpperCase() + name.substring(1);
    }
  }
}

// Discharge types
enum DischargeType {
  dry,
  sticky,
  creamy,
  watery,
  eggWhite,
  bloody,
  unusual;

  String get displayName {
    switch (this) {
      case DischargeType.eggWhite:
        return 'Egg White';
      default:
        return name[0].toUpperCase() + name.substring(1);
    }
  }
}

// Cervical mucus types
enum CervicalMucusType {
  dry,
  sticky,
  creamy,
  watery,
  eggWhite;

  String get displayName {
    switch (this) {
      case CervicalMucusType.eggWhite:
        return 'Egg White';
      default:
        return name[0].toUpperCase() + name.substring(1);
    }
  }
}

// Intimacy types
enum IntimacyType {
  none,
  protected,
  unprotected,
  other;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}

// Test results
enum TestResult {
  notTaken,
  negative,
  positive,
  inconclusive;

  String get displayName {
    switch (this) {
      case TestResult.notTaken:
        return 'Not Taken';
      default:
        return name[0].toUpperCase() + name.substring(1);
    }
  }
}

// Reminder types
enum ReminderType {
  period,
  ovulation,
  fertileWindow,
  dailyLog,
  pill,
  medication,
  hydration,
  weight,
  temperature,
  bodyMetrics,
  pregnancyTest,
  ovulationTest,
  custom;

  String get displayName {
    switch (this) {
      case ReminderType.fertileWindow:
        return 'Fertile Window';
      case ReminderType.dailyLog:
        return 'Daily Log';
      case ReminderType.bodyMetrics:
        return 'Body Metrics';
      case ReminderType.pregnancyTest:
        return 'Pregnancy Test';
      case ReminderType.ovulationTest:
        return 'Ovulation Test';
      default:
        return name[0].toUpperCase() + name.substring(1);
    }
  }
}

// Theme modes
enum ThemeMode {
  light,
  dark,
  system;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}

// Temperature units
enum TemperatureUnit {
  celsius,
  fahrenheit;

  String get displayName {
    switch (this) {
      case TemperatureUnit.celsius:
        return 'Celsius';
      case TemperatureUnit.fahrenheit:
        return 'Fahrenheit';
    }
  }
}

// Record source
enum RecordSource {
  manual,
  import,
  edit;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}

// Tracking goals
enum TrackingGoal {
  trackPeriods,
  tryingToConceive,
  pregnancy,
  perimenopause;

  String get displayName {
    switch (this) {
      case TrackingGoal.trackPeriods:
        return 'Track Periods';
      case TrackingGoal.tryingToConceive:
        return 'Trying to Conceive';
      case TrackingGoal.pregnancy:
        return 'Pregnancy';
      case TrackingGoal.perimenopause:
        return 'Perimenopause';
    }
  }

  String get description {
    switch (this) {
      case TrackingGoal.trackPeriods:
        return 'Monitor your menstrual cycle and symptoms';
      case TrackingGoal.tryingToConceive:
        return 'Track fertility windows and ovulation';
      case TrackingGoal.pregnancy:
        return 'Track pregnancy symptoms and milestones';
      case TrackingGoal.perimenopause:
        return 'Monitor irregular cycles and symptoms';
    }
  }
}
