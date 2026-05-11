import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/tracking/data/cycle_repository.dart';
import '../../features/tracking/domain/cycle_models.dart';

class FirebaseSyncService {
  FirebaseSyncService({
    FirebaseFirestore? firestore,
    CycleRepository? repository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _repository = repository;

  final FirebaseFirestore _firestore;
  final CycleRepository? _repository;

  Future<CycleRepository> _repo() async {
    if (_repository != null) return _repository!;
    final preferences = await SharedPreferences.getInstance();
    return CycleRepository(preferences);
  }

  Future<void> pushLocalData(User user) async {
    final uid = user.uid;
    final repository = await _repo();
    final periods = repository.loadPeriods();
    final logs = repository.loadLogs();
    final preferences = repository.loadPreferences();

    final batch = _firestore.batch();

    batch.set(_firestore.collection('user_cycles').doc(uid), {
      'periods': periods.map((p) => p.toJson()).toList(),
      'preferences': preferences.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(_firestore.collection('user_daily_logs').doc(uid), {
      'logs': logs.map((l) => l.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> pullRemoteData(User user) async {
    final uid = user.uid;
    final repository = await _repo();

    final cyclesDoc = await _firestore.collection('user_cycles').doc(uid).get();
    if (cyclesDoc.exists && cyclesDoc.data() != null) {
      final data = cyclesDoc.data()!;
      final remotePeriods = (data['periods'] as List<dynamic>? ?? [])
          .map((e) => CycleEvent.fromJson(Map<String, Object?>.from(e as Map)))
          .toList();
      final localPeriods = repository.loadPeriods();
      final localIds = localPeriods.map((p) => p.id).toSet();
      final mergedPeriods = [
        ...localPeriods,
        for (final period in remotePeriods)
          if (!localIds.contains(period.id)) period,
      ]..sort((a, b) => b.startDate.compareTo(a.startDate));
      await repository.savePeriods(mergedPeriods);

      final remotePreferences = data['preferences'];
      if (remotePreferences is Map &&
          !repository.loadPreferences().onboardingCompleted) {
        await repository.savePreferences(
          CyclePreferences.fromJson(Map<String, Object?>.from(remotePreferences)),
        );
      }
    }

    final logsDoc = await _firestore.collection('user_daily_logs').doc(uid).get();
    if (logsDoc.exists && logsDoc.data() != null) {
      final data = logsDoc.data()!;
      final remoteLogs = (data['logs'] as List<dynamic>? ?? [])
          .map((e) => DailyLog.fromJson(Map<String, Object?>.from(e as Map)))
          .toList();
      final localLogs = repository.loadLogs();
      final localDates = localLogs
          .map((log) => log.date.toIso8601String().split('T').first)
          .toSet();
      final mergedLogs = [
        ...localLogs,
        for (final log in remoteLogs)
          if (!localDates.contains(log.date.toIso8601String().split('T').first))
            log,
      ]..sort((a, b) => b.date.compareTo(a.date));
      await repository.saveLogs(mergedLogs);
    }
  }

  Future<void> sync(User user) async {
    await pushLocalData(user);
    await pullRemoteData(user);
  }

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
