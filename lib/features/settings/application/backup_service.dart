import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../tracking/domain/cycle_models.dart';
import '../../tracking/domain/daily_log_validator.dart';

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
    required this.formatVersion,
  });

  final List<CycleEvent> periods;
  final List<DailyLog> logs;

  /// Null only when a legacy export genuinely omitted its settings block.
  /// A present but malformed block is rejected during inspection.
  final CyclePreferences? preferences;

  /// Null when the export carried no timestamp, or an unparseable one.
  final DateTime? exportedAt;

  /// Null for accepted legacy exports that predate the versioned envelope.
  final int? formatVersion;

  bool get isCurrentFormat =>
      formatVersion == CycleBackupFormat.currentVersion;

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

    final hasFormat = decoded.containsKey('format');
    final hasVersion = decoded.containsKey('version');
    int? formatVersion;
    if (hasFormat || hasVersion) {
      final format = decoded['format'];
      final version = decoded['version'];
      if (format != CycleBackupFormat.identifier || version is! int) {
        return const BackupRejected(
          'This is not a supported CycleCare backup. Export a new copy and '
          'paste the whole JSON object.',
        );
      }
      if (version > CycleBackupFormat.currentVersion) {
        return const BackupRejected(
          'This backup was made by a newer version of CycleCare. Update the '
          'app before restoring it.',
        );
      }
      if (version != CycleBackupFormat.currentVersion) {
        return const BackupRejected(
          'This CycleCare backup version is not supported by this app.',
        );
      }
      formatVersion = version;
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
      final schema = entry['schema'];
      if (schema is int && schema > DailyLog.schemaVersion) {
        return const BackupRejected(
          'A daily log in this backup was made by a newer version of '
          'CycleCare. Update the app before restoring it.',
        );
      }
      // Old exports carry no schema version; fromJson migrates them, so the
      // defaults the old log screen saved are not restored as observations.
      final log = _tryParse(() => DailyLog.fromJson(entry));
      if (log == null) {
        return const BackupRejected(
          'One of the daily logs is missing fields CycleCare needs.',
        );
      }
      final issues = DailyLogValidator.validate(log);
      if (issues.isNotEmpty) {
        final day = log.date.toIso8601String().split('T').first;
        return BackupRejected(
          'The daily log for $day has a value CycleCare cannot accept '
          '(${issues.first}). Nothing was restored.',
        );
      }
      logs.add(log);
    }

    // Only the versioned format can prove that an empty export came from
    // CycleCare. The same two empty lists in legacy JSON are too ambiguous to
    // use for a destructive replacement.
    if (periods.isEmpty && logs.isEmpty && formatVersion == null) {
      return const BackupRejected(
        'This backup has no periods or logs in it — restoring it would only '
        'clear your data.',
      );
    }

    CyclePreferences? preferences;
    if (decoded.containsKey('preferences')) {
      final rawPreferences = decoded['preferences'];
      if (rawPreferences is! Map<String, Object?>) {
        return const BackupRejected(
          'The cycle settings in this backup are unreadable. Nothing was '
          'restored.',
        );
      }
      preferences =
          _tryParse(() => CyclePreferences.fromJson(rawPreferences));
      if (preferences == null) {
        return const BackupRejected(
          'The cycle settings in this backup are unreadable. Nothing was '
          'restored.',
        );
      }
    }

    final rawExportedAt = decoded['exportedAt'];
    return BackupReady(
      BackupPreview(
        periods: periods,
        logs: logs,
        preferences: preferences,
        exportedAt:
            rawExportedAt is String ? DateTime.tryParse(rawExportedAt) : null,
        formatVersion: formatVersion,
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
    final replacements = <String, String>{
      BackupKeys.periods:
          jsonEncode([for (final period in backup.periods) period.toJson()]),
      BackupKeys.dailyLogs:
          jsonEncode([for (final log in backup.logs) log.toJson()]),
      if (backup.preferences case final restored?)
        BackupKeys.preferences: jsonEncode(
          // Onboarding is forced complete. Anyone holding a backup has
          // already been through it, and writing `false` here would bounce
          // them back to the setup flow.
          restored.copyWith(onboardingCompleted: true).toJson(),
        ),
    };
    final previous = <String, String?>{
      for (final key in replacements.keys) key: prefs.getString(key),
    };
    final attempted = <String>[];

    try {
      for (final entry in replacements.entries) {
        // SharedPreferences updates its memory cache before the platform write
        // completes, so even a false result must be rolled back.
        attempted.add(entry.key);
        final saved = await prefs.setString(entry.key, entry.value);
        if (!saved) {
          throw StateError('CycleCare could not write the backup.');
        }
      }
    } catch (error, stackTrace) {
      final rolledBack = await _restorePreviousValues(
        prefs,
        previous,
        attempted.reversed,
      );
      if (!rolledBack) {
        Error.throwWithStackTrace(
          StateError(
            'CycleCare could not restore the previous data after a failed '
            'backup write.',
          ),
          stackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<bool> _restorePreviousValues(
    SharedPreferences prefs,
    Map<String, String?> previous,
    Iterable<String> keys,
  ) async {
    var restoredEverything = true;
    for (final key in keys) {
      try {
        final oldValue = previous[key];
        final restored = oldValue == null
            ? await prefs.remove(key)
            : await prefs.setString(key, oldValue);
        if (!restored) restoredEverything = false;
      } catch (_) {
        // Keep trying the remaining slots so one rollback failure does not
        // leave every earlier write in its replacement state.
        restoredEverything = false;
      }
    }
    return restoredEverything;
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
