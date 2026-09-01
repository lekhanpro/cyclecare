import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../tracking/domain/cycle_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Backup & restore
//
// Export has always worked — it hands the user a JSON string and gets out of
// the way. Restore is the half that was missing, which made the export a
// souvenir rather than a backup.
//
// There is no file picker in this project, so the transport is the clipboard:
// the user pastes a previously exported backup and CycleCare reads it. Crude,
// but it needs no permissions, works between devices, and the user can see
// exactly what they are handing over.
//
// The important part is that a restore *overwrites*. So nothing is written
// until the backup has been fully parsed into real models. Validating the
// shape and then writing the raw text would still let a subtly wrong file
// through, and the failure would surface later as a crash on load with the
// original data already gone.
// ─────────────────────────────────────────────────────────────────────────────

/// The storage slots a restore writes.
///
/// These must stay identical to the keys `CycleRepository` reads from — a
/// restore is only useful if the repository picks up exactly what was written.
class BackupKeys {
  BackupKeys._();

  static const String periods = 'cyclecare.periods.v1';
  static const String dailyLogs = 'cyclecare.daily_logs.v1';
  static const String preferences = 'cyclecare.preferences.v1';
}

/// A backup that parsed cleanly, alongside the counts the confirmation copy
/// needs so the user can recognise their own data before replacing it.
@immutable
class BackupPreview {
  const BackupPreview({
    required this.periods,
    required this.logs,
    required this.preferences,
    required this.exportedAt,
  });

  final List<CycleEvent> periods;
  final List<DailyLog> logs;

  /// Null when the backup carried no readable settings block. The cycle data
  /// still restores; only the preferences are left alone.
  final CyclePreferences? preferences;

  /// Null when the export carried no timestamp, or an unparseable one.
  final DateTime? exportedAt;

  int get periodCount => periods.length;
  int get logCount => logs.length;
}

/// Result of inspecting pasted text. Either a backup ready to be confirmed, or
/// a reason the user can act on.
@immutable
sealed class BackupCheck {
  const BackupCheck();
}

final class BackupReady extends BackupCheck {
  const BackupReady(this.preview);

  final BackupPreview preview;
}

final class BackupRejected extends BackupCheck {
  const BackupRejected(this.reason);

  /// Written for the person holding the paste buffer, not for a log file.
  final String reason;
}

class BackupService {
  const BackupService();

  /// Parses [source] without touching storage.
  ///
  /// Never throws: every malformed input comes back as a [BackupRejected] with
  /// copy the UI can show verbatim.
  BackupCheck inspect(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      return const BackupRejected('Paste your backup first.');
    }

    final decoded = _tryDecode(trimmed);
    if (decoded == null) {
      return const BackupRejected(
        'That is not valid JSON. Paste the whole export, including the outer '
        'curly braces.',
      );
    }
    if (decoded is! Map<String, Object?>) {
      return const BackupRejected(
        'A CycleCare backup is a single JSON object. This looks like something '
        'else.',
      );
    }

    final rawPeriods = decoded['periods'];
    final rawLogs = decoded['dailyLogs'];
    if (rawPeriods is! List || rawLogs is! List) {
      return const BackupRejected(
        'No "periods" and "dailyLogs" lists in here, so this is not a '
        'CycleCare export.',
      );
    }

    final periods = <CycleEvent>[];
    for (final entry in rawPeriods) {
      if (entry is! Map<String, Object?>) {
        return const BackupRejected('One of the period entries is unreadable.');
      }
      final period = _tryParse(() => CycleEvent.fromJson(entry));
      if (period == null) {
        return const BackupRejected(
          'One of the period entries is missing fields CycleCare needs.',
        );
      }
      periods.add(period);
    }

    final logs = <DailyLog>[];
    for (final entry in rawLogs) {
      if (entry is! Map<String, Object?>) {
        return const BackupRejected('One of the daily logs is unreadable.');
      }
      final log = _tryParse(() => DailyLog.fromJson(entry));
      if (log == null) {
        return const BackupRejected(
          'One of the daily logs is missing fields CycleCare needs.',
        );
      }
      logs.add(log);
    }

    // A backup with nothing in it is almost certainly the wrong text, and
    // restoring it would quietly wipe whatever is on the device.
    if (periods.isEmpty && logs.isEmpty) {
      return const BackupRejected(
        'This backup has no periods or logs in it — restoring it would only '
        'clear your data.',
      );
    }

    final rawPreferences = decoded['preferences'];
    final preferences = rawPreferences is Map<String, Object?>
        ? _tryParse(() => CyclePreferences.fromJson(rawPreferences))
        : null;

    final rawExportedAt = decoded['exportedAt'];
    return BackupReady(
      BackupPreview(
        periods: periods,
        logs: logs,
        preferences: preferences,
        exportedAt:
            rawExportedAt is String ? DateTime.tryParse(rawExportedAt) : null,
      ),
    );
  }

  /// Overwrites the stored cycle data with [backup].
  ///
  /// Re-encoded from the parsed models rather than passed through as text, so
  /// anything the current schema does not understand is dropped instead of
  /// being written back into storage.
  Future<void> restore(BackupPreview backup) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      BackupKeys.periods,
      jsonEncode([for (final period in backup.periods) period.toJson()]),
    );
    await prefs.setString(
      BackupKeys.dailyLogs,
      jsonEncode([for (final log in backup.logs) log.toJson()]),
    );

    final restored = backup.preferences;
    if (restored != null) {
      // Onboarding is forced complete. Anyone holding a backup has already
      // been through it, and writing `false` here would bounce them out of the
      // app and straight back to the setup flow.
      await prefs.setString(
        BackupKeys.preferences,
        jsonEncode(restored.copyWith(onboardingCompleted: true).toJson()),
      );
    }
  }

  Object? _tryDecode(String source) {
    try {
      return jsonDecode(source);
    } catch (_) {
      // Malformed JSON is the expected case here, not an exceptional one.
      return null;
    }
  }

  T? _tryParse<T>(T Function() parse) {
    try {
      return parse();
    } catch (_) {
      return null;
    }
  }
}

final Provider<BackupService> backupServiceProvider =
    Provider<BackupService>((ref) => const BackupService());
