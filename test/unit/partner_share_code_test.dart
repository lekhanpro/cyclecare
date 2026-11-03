import 'package:cyclecare/features/partner/domain/partner_share_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final created = DateTime(2026, 10, 29, 9);
  final expires = created.add(const Duration(days: 7));

  PartnerSnapshot full() => PartnerSnapshot(
        createdAt: created,
        expiresAt: expires,
        ownerName: 'Ava',
        phase: 'Luteal',
        cycleDay: 19,
        nextPeriod: DateTime(2026, 11, 8),
        fertileStart: DateTime(2026, 10, 20),
        fertileEnd: DateTime(2026, 10, 26),
        ovulation: DateTime(2026, 10, 25),
        pmsStart: DateTime(2026, 11, 3),
        pmsEnd: DateTime(2026, 11, 7),
        mood: 'Calm',
        symptoms: const ['Cramps', 'Bloating'],
        painLevel: 3,
        supportTip: 'An early night helps.',
        note: 'Pizza tonight?',
      );

  test('round-trips every field', () {
    final back = decodeShareCode(encodeShareCode(full()), now: created);
    expect(back.ownerName, 'Ava');
    expect(back.phase, 'Luteal');
    expect(back.cycleDay, 19);
    expect(back.nextPeriod, DateTime(2026, 11, 8));
    expect(back.fertileStart, DateTime(2026, 10, 20));
    expect(back.fertileEnd, DateTime(2026, 10, 26));
    expect(back.ovulation, DateTime(2026, 10, 25));
    expect(back.pmsStart, DateTime(2026, 11, 3));
    expect(back.pmsEnd, DateTime(2026, 11, 7));
    expect(back.mood, 'Calm');
    expect(back.symptoms, ['Cramps', 'Bloating']);
    expect(back.painLevel, 3);
    expect(back.supportTip, 'An early night helps.');
    expect(back.note, 'Pizza tonight?');
    expect(back.expiresAt, expires);
  });

  test('omitted fields stay absent, not empty', () {
    final code = encodeShareCode(
      PartnerSnapshot(createdAt: created, expiresAt: expires, phase: 'Menstrual'),
    );
    final back = decodeShareCode(code, now: created);
    expect(back.phase, 'Menstrual');
    expect(back.mood, isNull);
    expect(back.symptoms, isNull);
    expect(back.fertileStart, isNull);
    expect(back.note, isNull);
  });

  test('an empty selection still encodes and decodes', () {
    final code = encodeShareCode(
      PartnerSnapshot(createdAt: created, expiresAt: expires),
    );
    expect(decodeShareCode(code, now: created).phase, isNull);
  });

  test('ignores whitespace and line breaks from messaging apps', () {
    final code = encodeShareCode(full());
    final wrapped = '  ${code.substring(0, 20)}\n${code.substring(20)} ';
    expect(decodeShareCode(wrapped, now: created).cycleDay, 19);
  });

  test('a single changed character fails the checksum', () {
    final code = encodeShareCode(full());
    final parts = code.split('-');
    final p = parts[1];
    final i = p.length ~/ 2;
    final flipped = p.replaceRange(i, i + 1, p[i] == 'A' ? 'B' : 'A');
    expect(
      () => decodeShareCode('${parts[0]}-$flipped-${parts[2]}', now: created),
      throwsA(isA<ShareCodeException>()
          .having((e) => e.error, 'error', ShareCodeError.checksum)),
    );
  });

  test('an expired code is rejected as expired', () {
    expect(
      () => decodeShareCode(encodeShareCode(full()),
          now: expires.add(const Duration(minutes: 1))),
      throwsA(isA<ShareCodeException>()
          .having((e) => e.error, 'error', ShareCodeError.expired)),
    );
  });

  test('garbage is malformed', () {
    for (final input in ['', 'hello', 'CC1--abc', 'XX1-abc-12345678', 'CC1-abc']) {
      expect(
        () => decodeShareCode(input, now: created),
        throwsA(isA<ShareCodeException>()
            .having((e) => e.error, 'error', ShareCodeError.malformed)),
        reason: input,
      );
    }
  });

  test('every error has a distinct, non-empty message', () {
    final messages = ShareCodeError.values
        .map((e) => ShareCodeException(e).message)
        .toSet();
    expect(messages.length, ShareCodeError.values.length);
    expect(messages.every((m) => m.isNotEmpty), isTrue);
  });
}
