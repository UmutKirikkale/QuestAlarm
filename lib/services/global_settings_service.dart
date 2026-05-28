import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/global_settings.dart';
import '../utils/firestore_resilience.dart';

/// `global_settings/app` canlı ayarlar + mobil için önbellek.
class GlobalSettingsService {
  GlobalSettingsService._();

  static final GlobalSettingsService instance = GlobalSettingsService._();

  static const String collection = 'global_settings';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  GlobalSettings _cached = const GlobalSettings();
  StreamSubscription<GlobalSettings>? _subscription;

  /// Mobil ve servisler için güncel ekonomi / LiveOps ayarları.
  GlobalSettings get current => _cached;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection(collection).doc(GlobalSettings.documentId);

  /// Uygulama açılışında çağırın — Firestore değişimlerini önbelleğe alır.
  void startListening() {
    _subscription?.cancel();
    _subscription = watchSettings().listen(
      (settings) => _cached = settings,
      onError: (Object e) =>
          debugPrint('GlobalSettingsService listen: $e'),
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<GlobalSettings> ensureLoaded() async {
    final settings = await loadSettings();
    _cached = settings;
    return settings;
  }

  Stream<GlobalSettings> watchSettings() {
    return _doc.snapshots().map((snap) {
      final settings = GlobalSettings.fromMap(snap.data());
      _cached = settings;
      return settings;
    });
  }

  Future<GlobalSettings> loadSettings() async {
    return withFirestoreTimeout(
      () async {
        final snap = await _doc.get();
        final settings = GlobalSettings.fromMap(snap.data());
        _cached = settings;
        return settings;
      }(),
      debugLabel: 'global_settings',
      fallback: const GlobalSettings(),
    );
  }

  Future<void> saveSettings(GlobalSettings settings) async {
    await _doc.set(settings.toMap(), SetOptions(merge: true));
    _cached = settings;
  }

  Future<void> setMaintenanceMode(bool enabled) async {
    await _doc.set(
      {'maintenanceMode': enabled},
      SetOptions(merge: true),
    );
    _cached = _cached.copyWith(maintenanceMode: enabled);
  }

  Future<void> setDailyQuestText(String text) async {
    await _doc.set(
      {'dailyQuestText': text},
      SetOptions(merge: true),
    );
    _cached = _cached.copyWith(dailyQuestText: text);
  }

  Future<void> saveEconomySettings({
    required double levelXpExponent,
    required double streakBonusPerDay,
    required double maxStreakMultiplier,
    required double repairCostPerDurability,
    required double proXpMultiplier,
    required double proGoldMultiplier,
    required double proRepairCost,
  }) async {
    await _doc.set(
      {
        'levelXpExponent': levelXpExponent,
        'streakBonusPerDay': streakBonusPerDay,
        'maxStreakMultiplier': maxStreakMultiplier,
        'repairCostPerDurability': repairCostPerDurability,
        'proXpMultiplier': proXpMultiplier,
        'proGoldMultiplier': proGoldMultiplier,
        'proRepairCost': proRepairCost,
      },
      SetOptions(merge: true),
    );
    _cached = _cached.copyWith(
      levelXpExponent: levelXpExponent,
      streakBonusPerDay: streakBonusPerDay,
      maxStreakMultiplier: maxStreakMultiplier,
      repairCostPerDurability: repairCostPerDurability,
      proXpMultiplier: proXpMultiplier,
      proGoldMultiplier: proGoldMultiplier,
      proRepairCost: proRepairCost,
    );
  }
}
