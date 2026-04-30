import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/database/app_database.dart';

class FirebaseSyncService {
  final FirebaseFirestore _firestore;
  final AppDatabase _db;

  FirebaseSyncService({
    FirebaseFirestore? firestore,
    AppDatabase? db,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _db = db ?? AppDatabase.instance;

  /// Push all local data to Firestore for the current user.
  Future<void> pushLocalData(User user) async {
    final uid = user.uid;
    final periods = await _db.getAllPeriods();
    final logs = await _db.getAllDailyLogs();

    final batch = _firestore.batch();

    final periodsRef = _firestore.collection('user_cycles').doc(uid);
    batch.set(periodsRef, {
      'periods': periods.map((p) => p.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final logsRef = _firestore.collection('user_daily_logs').doc(uid);
    batch.set(logsRef, {
      'logs': logs.map((l) => l.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Pull data from Firestore and merge into local database (local-first).
  /// Local data is preserved; remote data is added only if no local conflict.
  Future<void> pullRemoteData(User user) async {
    final uid = user.uid;

    final cyclesDoc = await _firestore.collection('user_cycles').doc(uid).get();
    if (cyclesDoc.exists) {
      final data = cyclesDoc.data();
      final remotePeriods = (data?['periods'] as List<dynamic>? ?? [])
          .map((e) => PeriodRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      final localPeriods = await _db.getAllPeriods();
      final localIds = localPeriods.map((p) => p.id).toSet();
      for (final rp in remotePeriods) {
        if (!localIds.contains(rp.id)) {
          // Add missing remote period to local storage
          await _db.insertPeriod(
            startDate: rp.startDate,
            endDate: rp.endDate,
            symptoms: rp.symptoms,
            notes: rp.notes,
          );
        }
      }
    }

    final logsDoc = await _firestore.collection('user_daily_logs').doc(uid).get();
    if (logsDoc.exists) {
      final data = logsDoc.data();
      final remoteLogs = (data?['logs'] as List<dynamic>? ?? [])
          .map((e) => DailyLogRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      final localLogs = await _db.getAllDailyLogs();
      final localDates = localLogs.map((l) => l.date.toIso8601String().split('T').first).toSet();
      for (final rl in remoteLogs) {
        final dateKey = rl.date.toIso8601String().split('T').first;
        if (!localDates.contains(dateKey)) {
          await _db.insertDailyLog(rl);
        }
      }
    }
  }

  /// Two-way sync: push local data then pull remote missing data.
  Future<void> sync(User user) async {
    await pushLocalData(user);
    await pullRemoteData(user);
  }

  /// Delete all user data from Firestore (GDPR / account deletion).
  Future<void> deleteRemoteData(User user) async {
    final uid = user.uid;
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('user_cycles').doc(uid));
    batch.delete(_firestore.collection('user_daily_logs').doc(uid));
    batch.delete(_firestore.collection('shared_cycle_data').doc(uid));
    final partnerLinks = await _firestore
        .collection('partner_links')
        .where('ownerUid', isEqualTo: uid)
        .get();
    for (final doc in partnerLinks.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
