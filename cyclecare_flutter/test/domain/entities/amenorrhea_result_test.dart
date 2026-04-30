import 'package:flutter_test/flutter_test.dart';
import 'package:cyclecare_flutter/domain/entities/amenorrhea_result.dart';

void main() {
  group('AmenorrheaResult', () {
    test('mild severity between 45 and 89 days', () {
      final result = AmenorrheaResult(
        severity: AmenorrheaSeverity.mild,
        daysSinceLastPeriod: 50,
        description: '50 days late',
      );
      expect(result.severity, AmenorrheaSeverity.mild);
      expect(result.daysSinceLastPeriod, 50);
    });

    test('moderate severity between 90 and 179 days', () {
      final result = AmenorrheaResult(
        severity: AmenorrheaSeverity.moderate,
        daysSinceLastPeriod: 120,
        description: '120 days late',
      );
      expect(result.severity, AmenorrheaSeverity.moderate);
    });

    test('severe severity at 180+ days', () {
      final result = AmenorrheaResult(
        severity: AmenorrheaSeverity.severe,
        daysSinceLastPeriod: 200,
        description: '200 days late',
      );
      expect(result.severity, AmenorrheaSeverity.severe);
    });

    test('toJson serializes correctly', () {
      final result = AmenorrheaResult(
        severity: AmenorrheaSeverity.moderate,
        daysSinceLastPeriod: 95,
        description: '95 days',
      );
      final json = result.toJson();
      expect(json['severity'], 'moderate');
      expect(json['daysSinceLastPeriod'], 95);
      expect(json['description'], '95 days');
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'severity': 'severe',
        'daysSinceLastPeriod': 190,
        'description': '190 days',
      };
      final result = AmenorrheaResult.fromJson(json);
      expect(result.severity, AmenorrheaSeverity.severe);
      expect(result.daysSinceLastPeriod, 190);
    });

    test('AmenorrheaSeverity label returns correct text', () {
      expect(AmenorrheaSeverity.mild.label, 'Mild');
      expect(AmenorrheaSeverity.moderate.label, 'Moderate');
      expect(AmenorrheaSeverity.severe.label, 'Severe');
    });
  });
}
