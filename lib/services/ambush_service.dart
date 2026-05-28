import 'dart:async';
import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../models/battle_summary.dart';
import 'analytics_service.dart';
import 'awake_verification_service.dart';
import 'battle_summary_service.dart';
import 'player_service.dart';
import 'widget_service.dart';

/// Pusu kontrolü alarm kimliği (quest alarm = 1).
const int ambushCheckAlarmId = 2;

/// Test: 30 sn — prod için 5 dakikaya çıkar.
const Duration ambushCheckDelay = Duration(seconds: 30);

const String prefsAmbushScheduled = 'ambush_check_scheduled';

class AmbushService {
  AmbushService._();

  static final AmbushService instance = AmbushService._();

  Future<void> scheduleAmbushCheck() async {
    if (!Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsAmbushScheduled, true);

    final ok = await AndroidAlarmManager.oneShot(
      ambushCheckDelay,
      ambushCheckAlarmId,
      ambushCheckCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: false,
    );
    if (!ok) {
      debugPrint('AmbushService: pusu zamanlayıcısı kurulamadı.');
    }
  }

  Future<void> cancelAmbushCheck() async {
    if (!Platform.isAndroid) return;
    await AndroidAlarmManager.cancel(ambushCheckAlarmId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsAmbushScheduled, false);
  }
}

/// Arka planda: uyanma doğrulanmadıysa ağır pusu cezası uygular.
@pragma('vm:entry-point')
void ambushCheckCallback() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(_executeAmbushCheck());
}

Future<void> _executeAmbushCheck() async {

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Zaten başlatılmış olabilir.
  }

  final prefs = await SharedPreferences.getInstance();
  final scheduled = prefs.getBool(prefsAmbushScheduled) ?? false;
  if (!scheduled) return;

  final verified = await AwakeVerificationService.instance.isAwakeVerified();
  await prefs.setBool(prefsAmbushScheduled, false);

  if (verified) return;

  final streakBefore = (await PlayerService.instance.loadPlayer()).streak;
  final penalty = await PlayerService.instance.applyAmbushPenalty();

  await BattleSummaryService.instance.save(
    BattleSummary(
      outcome: BattleOutcome.defeat,
      monsterName: 'Gece Pususu',
      streakBefore: streakBefore,
      streakAfter: 0,
      reason: 'Alarm kapandı ama uyanıp savaşmadın — köy yağmalandı!',
      brokenItems: penalty.brokenItemNames,
      timestampIso: DateTime.now().toIso8601String(),
    ),
  );

  try {
    await WidgetService.instance.updateLiveWidget(status: LiveWidgetStatus.sad);
  } catch (e) {
    debugPrint('AmbushService widget güncellenemedi: $e');
  }

  await AnalyticsService.instance.logPlayerAmbushedWhileSleeping();
}
