import 'package:cyclecare/features/tracking/domain/hormone_illustration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HormoneCurve interpolation', () {
    for (final kind in HormoneKind.values) {
      final curve = HormoneIllustration.curves[kind]!;

      test('${kind.label} stays within [0, 1] across the reference cycle', () {
        for (var d = 1.0; d <= 28.0; d += 0.05) {
          final v = curve.valueAt(d);
          expect(v, inInclusiveRange(0.0, 1.0), reason: 'day $d');
        }
      });

      test('${kind.label} passes through every control point', () {
        for (final (day, value) in curve.points) {
          expect(curve.valueAt(day), closeTo(value, 1e-9), reason: 'day $day');
        }
      });

      test('${kind.label} never overshoots its neighbouring control points', () {
        for (var i = 0; i < curve.points.length - 1; i++) {
          final (x0, y0) = curve.points[i];
          final (x1, y1) = curve.points[i + 1];
          final lo = y0 < y1 ? y0 : y1;
          final hi = y0 < y1 ? y1 : y0;
          for (var t = 0.0; t <= 1.0; t += 0.05) {
            final v = curve.valueAt(x0 + (x1 - x0) * t);
            expect(v, inInclusiveRange(lo - 1e-9, hi + 1e-9));
          }
        }
      });
    }
  });

  group('HormoneIllustration resampling', () {
    test('reference cycle maps days onto themselves', () {
      final ill = HormoneIllustration.reference();
      for (var d = 1; d <= 28; d++) {
        expect(ill.referenceDay(d.toDouble()), closeTo(d.toDouble(), 1e-9));
      }
    });

    test('a 35-day cycle pins the reference ovulation to its ovulation day', () {
      final ill = HormoneIllustration(cycleLength: 35, ovulationDay: 21);
      expect(ill.referenceDay(1), 1);
      expect(ill.referenceDay(21), closeTo(15, 1e-9));
      expect(ill.referenceDay(35), closeTo(28, 1e-9));
      for (var d = 1.0; d <= 35; d += 0.25) {
        for (final kind in HormoneKind.values) {
          expect(ill.valueAt(kind, d), inInclusiveRange(0.0, 1.0));
        }
      }
    });

    test('the LH surge lands around the ovulation day', () {
      final ill = HormoneIllustration(cycleLength: 32, ovulationDay: 18);
      var peakDay = 1;
      var peak = -1.0;
      for (var d = 1; d <= 32; d++) {
        final v = ill.valueAt(HormoneKind.lh, d.toDouble());
        if (v > peak) {
          peak = v;
          peakDay = d;
        }
      }
      expect(peakDay, inInclusiveRange(16, 18));
    });
  });

  group('trend wording', () {
    final ill = HormoneIllustration.reference();

    test('estrogen rises toward the pre-ovulation peak', () {
      final t = ill.trendAt(HormoneKind.estrogen, 10);
      expect(t.direction, HormoneDirection.rising);
      expect(t.direction.label, 'Rising');
    });

    test('progesterone is high in the mid luteal phase', () {
      final t = ill.trendAt(HormoneKind.progesterone, 22);
      expect(t.level, HormoneLevel.high);
      expect(t.levelText, 'High in the illustration');
    });

    test('progesterone falls before the next period', () {
      expect(ill.trendAt(HormoneKind.progesterone, 25).direction,
          HormoneDirection.falling);
    });

    test('progesterone is low and steady in the early follicular phase', () {
      final t = ill.trendAt(HormoneKind.progesterone, 5);
      expect(t.level, HormoneLevel.low);
      expect(t.direction, HormoneDirection.steady);
      expect(t.levelText, 'Low in the illustration');
    });

    test('level copy never contains a unit or a number', () {
      for (final kind in HormoneKind.values) {
        for (var d = 1; d <= 28; d++) {
          final text = '${ill.trendAt(kind, d).direction.label} '
              '${ill.trendAt(kind, d).levelText} ${kind.patternCopy}';
          expect(
            text,
            isNot(matches(RegExp(r'\d|\b(pg|ng|ml|iu|miu|nmol|pmol)\b',
                caseSensitive: false))),
          );
        }
      }
    });
  });
}
