import 'dart:convert';

import 'package:cyclecare/features/health/application/health_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const key = 'cyclecare.pain_entries.v1';
  final oldEntry = PainEntry(
    id: 'old',
    date: DateTime(2026, 9, 1),
    severity: 4,
    locations: const ['Lower abdomen'],
    notes: 'Keep my record',
  );
  test(
    'legacy diary survives concurrent saves and activity impact round trips',
    () async {
      SharedPreferences.setMockInitialValues({
        key: [jsonEncode(oldEntry.toJson()..remove('painInterference'))],
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final diary = container.read(painEntriesProvider.notifier);
      final first = PainEntry(
        id: 'new',
        date: DateTime(2026, 9, 2),
        severity: 7,
        painInterference: 'Some activities harder',
      );
      final second = PainEntry(
        id: 'newer',
        date: DateTime(2026, 9, 3),
        severity: 2,
        painInterference: 'No interference',
      );
      await Future.wait([diary.add(first), diary.add(second)]);
      final entries = container.read(painEntriesProvider);
      expect(entries.map((e) => e.id), ['newer', 'new', 'old']);
      expect(entries.last.painInterference, isNull);
      expect(entries.last.notes, oldEntry.notes);
      final persisted = (await SharedPreferences.getInstance()).getStringList(
        key,
      )!;
      expect(
        persisted
            .map((e) => PainEntry.fromJson(jsonDecode(e)))
            .map((e) => e.painInterference),
        ['No interference', 'Some activities harder', null],
      );
      await expectLater(
        diary.add(PainEntry(id: 'invalid', date: DateTime(2026), severity: 0)),
        throwsArgumentError,
      );
      expect(container.read(painEntriesProvider), hasLength(3));
      expect(
        (await SharedPreferences.getInstance()).getStringList(key),
        persisted,
      );
    },
  );
}
