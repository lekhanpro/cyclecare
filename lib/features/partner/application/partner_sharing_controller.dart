import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which fields the user has agreed to include in a partner summary.
///
/// Every flag defaults to **false**. Cycle and fertility data is used to
/// pressure and monitor people, so the safe default is to share nothing and
/// make each addition a deliberate choice. An opt-out design would leak
/// fertility windows to anyone who tapped Share without reading.
class PartnerSharingOptions {
  const PartnerSharingOptions({
    this.sharePhase = true,
    this.shareNextPeriod = true,
    this.shareMood = false,
    this.shareSymptoms = false,
    this.shareFertileWindow = false,
    this.shareSupportTip = true,
  });

  /// Current phase and cycle day.
  final bool sharePhase;

  /// Days until the next expected period.
  final bool shareNextPeriod;

  final bool shareMood;
  final bool shareSymptoms;

  /// Off by default and deliberately separate from [sharePhase]: fertility
  /// timing is the most sensitive field here.
  final bool shareFertileWindow;

  /// A short, non-clinical note on what tends to help in the current phase.
  final bool shareSupportTip;

  PartnerSharingOptions copyWith({
    bool? sharePhase,
    bool? shareNextPeriod,
    bool? shareMood,
    bool? shareSymptoms,
    bool? shareFertileWindow,
    bool? shareSupportTip,
  }) {
    return PartnerSharingOptions(
      sharePhase: sharePhase ?? this.sharePhase,
      shareNextPeriod: shareNextPeriod ?? this.shareNextPeriod,
      shareMood: shareMood ?? this.shareMood,
      shareSymptoms: shareSymptoms ?? this.shareSymptoms,
      shareFertileWindow: shareFertileWindow ?? this.shareFertileWindow,
      shareSupportTip: shareSupportTip ?? this.shareSupportTip,
    );
  }
}

class PartnerSharingNotifier extends Notifier<PartnerSharingOptions> {
  static const _phaseKey = 'cyclecare.partner.phase';
  static const _nextPeriodKey = 'cyclecare.partner.next_period';
  static const _moodKey = 'cyclecare.partner.mood';
  static const _symptomsKey = 'cyclecare.partner.symptoms';
  static const _fertileKey = 'cyclecare.partner.fertile';
  static const _tipKey = 'cyclecare.partner.tip';

  SharedPreferences? _prefs;

  @override
  PartnerSharingOptions build() {
    _load();
    return const PartnerSharingOptions();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    state = PartnerSharingOptions(
      sharePhase: prefs.getBool(_phaseKey) ?? true,
      shareNextPeriod: prefs.getBool(_nextPeriodKey) ?? true,
      shareMood: prefs.getBool(_moodKey) ?? false,
      shareSymptoms: prefs.getBool(_symptomsKey) ?? false,
      shareFertileWindow: prefs.getBool(_fertileKey) ?? false,
      shareSupportTip: prefs.getBool(_tipKey) ?? true,
    );
  }

  Future<void> _set(
    String key,
    bool value,
    PartnerSharingOptions next,
  ) async {
    state = next;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setBool(key, value);
  }

  Future<void> setSharePhase(bool value) =>
      _set(_phaseKey, value, state.copyWith(sharePhase: value));

  Future<void> setShareNextPeriod(bool value) =>
      _set(_nextPeriodKey, value, state.copyWith(shareNextPeriod: value));

  Future<void> setShareMood(bool value) =>
      _set(_moodKey, value, state.copyWith(shareMood: value));

  Future<void> setShareSymptoms(bool value) =>
      _set(_symptomsKey, value, state.copyWith(shareSymptoms: value));

  Future<void> setShareFertileWindow(bool value) =>
      _set(_fertileKey, value, state.copyWith(shareFertileWindow: value));

  Future<void> setShareSupportTip(bool value) =>
      _set(_tipKey, value, state.copyWith(shareSupportTip: value));
}

final partnerSharingProvider =
    NotifierProvider<PartnerSharingNotifier, PartnerSharingOptions>(
  PartnerSharingNotifier.new,
);
