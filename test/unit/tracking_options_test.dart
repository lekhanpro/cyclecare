import 'package:cyclecare/features/tracking/domain/tracking_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('existing exported lists keep their meaning', () {
    expect(symptomOptions, hasLength(16));
    expect(moodOptions, hasLength(10));
    expect(dischargeOptions,
        ['None', 'Light', 'Creamy', 'Watery', 'Sticky', 'Unusual']);
    expect(cervicalMucusOptions,
        ['Dry', 'Sticky', 'Creamy', 'Watery', 'Egg-white']);
  });

  test('the four symptom groups hold every existing symptom', () {
    expect(bodySymptomOptions, hasLength(21));
    expect(digestionSymptomOptions, hasLength(11));
    expect(skinSymptomOptions, hasLength(9));
    expect(restSymptomOptions, hasLength(12));
    expect(catalogueSymptomOptions, hasLength(53));
    expect(catalogueSymptomOptions.toSet(), hasLength(53));
    for (final symptom in symptomOptions) {
      expect(catalogueSymptomOptions, contains(symptom), reason: symptom);
    }
  });

  test('54 moods in catalogue order, including every existing mood', () {
    expect(catalogueMoodOptions, hasLength(54));
    expect(catalogueMoodOptions.toSet(), hasLength(54));
    expect(catalogueMoodOptions.take(10).toSet(), moodOptions.toSet());
    expect(catalogueMoodOptions[14], 'Tension');
    expect(catalogueMoodOptions.last, 'Ill');
  });

  test('discharge adds Egg-white, With blood and Green', () {
    expect(catalogueDischargeOptions, [
      ...dischargeOptions,
      'Egg-white',
      'With blood',
      'Green',
    ]);
  });

  test('planned field option lists', () {
    expect(painLocationOptions, hasLength(6));
    expect(sleepQualityOptions, hasLength(4));
    expect(energyOptions, ['Low', 'Steady', 'High']);
    expect(exerciseTypeOptions, hasLength(10));
    expect(appetiteOptions, hasLength(4));
    expect(intimacyOptions, contains('Prefer not to say'));
    expect(protectionOptions, contains('Not sure'));
    expect(libidoOptions, contains('Not sure'));
    expect(testResultOptions, ['Positive', 'Negative', 'Unclear', 'Not taken']);
    expect(careActionOptions, hasLength(6));
    expect(medicineTakenOptions, ['Taken', 'Not taken']);
  });

  test('aliases resolve to real catalogue options without rewriting', () {
    expect(canonicalOption('mood', 'Tense'), 'Tension');
    expect(canonicalOption('symptoms', 'Backache'), 'Back pain');
    expect(canonicalOption('discharge', 'Egg white'), 'Egg-white');
    expect(canonicalOption('symptoms', 'My own tag'), 'My own tag');
    expect(canonicalOption('unknownField', 'Tense'), 'Tense');

    final targets = <String, List<String>>{
      'flow': ['None', 'Spotting', 'Light', 'Medium', 'Heavy', 'Very heavy'],
      'mood': catalogueMoodOptions,
      'symptoms': catalogueSymptomOptions,
      'appetite': appetiteOptions,
      'libido': libidoOptions,
      'discharge': catalogueDischargeOptions,
    };
    catalogueAliases.forEach((field, aliases) {
      aliases.forEach((alias, target) {
        expect(targets[field], contains(target), reason: '$alias -> $target');
        expect(targets[field], isNot(contains(alias)), reason: alias);
      });
    });
  });
}
