import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../tracking/domain/cycle_models.dart';

class TrackingModeDescription {
  const TrackingModeDescription(this.title, this.intro, this.focus, this.icon);
  final String title, intro;
  final List<String> focus;
  final IconData icon;
}

TrackingModeDescription describeTrackingMode(TrackingGoal goal) =>
    switch (goal) {
      TrackingGoal.trackPeriods => const TrackingModeDescription(
        'Your cycle',
        'Keep period dates, daily observations and estimates together.',
        [
          'Period dates and cycle calendar',
          'Daily check-ins and reminders',
          'Cycle history and reports',
        ],
        AppIcons.goalTrack,
      ),
      TrackingGoal.tryingToConceive => const TrackingModeDescription(
        'Your fertility journal',
        'Bring calendar estimates and recorded fertility signs into one view.',
        [
          'LH tests, temperatures and cervical observations',
          'Calendar estimates kept separate from observations',
          'History and a report for your care team',
        ],
        AppIcons.goalConceive,
      ),
      TrackingGoal.pregnancy => const TrackingModeDescription(
        'Your pregnancy space',
        'Follow your pregnancy after entering a due date or last-period date.',
        [
          'Your saved pregnancy week and due date',
          'Weekly guides and movement counts',
          'Appointments and daily observations',
        ],
        AppIcons.goalPregnancy,
      ),
      TrackingGoal.perimenopause => const TrackingModeDescription(
        'Your changing patterns',
        'Keep a clear record of cycle changes and how you feel.',
        [
          'Bleeding, sleep and mood observations',
          'Cycle variation and symptom patterns',
          'Pain diary, learning and selected reports',
        ],
        AppIcons.goalPerimenopause,
      ),
      TrackingGoal.symptomWellness => const TrackingModeDescription(
        'Your daily wellbeing',
        'Focus on symptoms, mood and daily care at your own pace.',
        [
          'Symptoms, mood, sleep and energy',
          'Coverage and patterns from recorded days',
          'Pain diary and care-team reports',
        ],
        AppIcons.goalWellness,
      ),
    };

String modeBoundary(TrackingGoal goal) => switch (goal) {
  TrackingGoal.tryingToConceive =>
    'Calendar estimates and LH results do not confirm ovulation or contraceptive safe days.',
  TrackingGoal.pregnancy =>
    'Choosing this mode does not establish pregnancy or set a due date. Follow your care team’s guidance.',
  TrackingGoal.perimenopause =>
    'Logged changes do not diagnose perimenopause. Estimates can be less useful when cycles vary.',
  _ =>
    'Patterns describe your records. Estimates are not diagnoses or contraception.',
};
