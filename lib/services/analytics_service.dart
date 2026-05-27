import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics özel olayları (singleton).
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Alarm başarıyla kurulduğunda.
  Future<void> logAlarmSet({required String time}) async {
    try {
      await _analytics.logEvent(
        name: 'alarm_set',
        parameters: {'time': time},
      );
    } catch (e, stack) {
      debugPrint('AnalyticsService.logAlarmSet: $e\n$stack');
    }
  }

  /// Canavar yenildiğinde.
  Future<void> logMonsterDefeated({
    required int gainedXp,
    required int gainedGold,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'monster_defeated',
        parameters: {
          'gained_xp': gainedXp,
          'gained_gold': gainedGold,
        },
      );
    } catch (e, stack) {
      debugPrint('AnalyticsService.logMonsterDefeated: $e\n$stack');
    }
  }

  /// Mağazadan eşya satın alındığında.
  Future<void> logItemBought({
    required String itemName,
    required int price,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'item_bought',
        parameters: {
          'item_name': itemName,
          'price': price,
        },
      );
    } catch (e, stack) {
      debugPrint('AnalyticsService.logItemBought: $e\n$stack');
    }
  }

  /// Alarm ertelendiğinde (snooze).
  Future<void> logAlarmSnoozed() async {
    try {
      await _analytics.logEvent(name: 'alarm_snoozed');
    } catch (e, stack) {
      debugPrint('AnalyticsService.logAlarmSnoozed: $e\n$stack');
    }
  }
}
