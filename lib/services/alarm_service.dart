import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_settings_service.dart';
import 'analytics_service.dart';
import '../models/battle_summary.dart';
import 'battle_summary_service.dart';
import 'player_service.dart';
import 'widget_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Alarm çaldığında ana isolate'e haber vermek için port adı.
const String alarmRingPortName = 'quest_alarm_ring_port';

/// [AndroidAlarmManager] alarm kimliği.
const int questAlarmId = 1;

/// SharedPreferences: savaş ekranı bekliyor mu?
const String prefsPendingBattle = 'pending_battle_screen';

/// SharedPreferences: kurulu alarm zamanı (ISO-8601).
const String prefsScheduledAlarm = 'scheduled_alarm_iso';

/// 8-bit alarm sesi (CC0 — assets/audio/ATTRIBUTION.txt).
const String alarmAssetPath = 'audio/alarm.m4a';

/// Android 12+ (API 31) alt sınırı.
const int _android12Sdk = 31;

/// İzin reddedildiğinde kullanıcıya gösterilen mesaj.
const String alarmPermissionsDeniedMessage =
    'Lütfen alarmın çalışması için ayarlardan izinleri verin';

const MethodChannel _deviceChannel = MethodChannel('com.questalarm/device');

/// Alarm kurulamadığında kullanıcıya gösterilen anlaşılır hata.
class AlarmScheduleException implements Exception {
  AlarmScheduleException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Arka plan alarmı: kurma, iptal, dinleme ve ses çalma.
class AlarmService {
  AlarmService._();

  static final AlarmService instance = AlarmService._();

  final StreamController<void> _ringController = StreamController<void>.broadcast();
  final AudioPlayer _audioPlayer = AudioPlayer();

  FlutterLocalNotificationsPlugin? _notifications;
  bool _initialized = false;
  bool _isPlaying = false;
  DateTime? _lastRingHandled;

  /// Alarm çaldığında yayınlanan stream (BattleScreen yönlendirmesi için).
  Stream<void> get onAlarmRing => _ringController.stream;

  bool get isInitialized => _initialized;

  /// Servisi başlatır: AlarmManager, bildirimler, timezone, dinleyici portu.
  Future<void> initialize() async {
    if (_initialized) return;

    if (!Platform.isAndroid) {
      debugPrint('AlarmService: yalnızca Android destekleniyor.');
      _initialized = true;
      return;
    }

    tz_data.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('AlarmService timezone fallback: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    final initialized = await AndroidAlarmManager.initialize();
    if (!initialized) {
      debugPrint('AlarmService: AndroidAlarmManager başlatılamadı.');
    }

    await _initNotifications();
    _registerAlarmPort();

    _initialized = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidNotifications =>
      _notifications?.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<int> _androidSdkInt() async {
    if (!Platform.isAndroid) return 0;
    try {
      final sdk = await _deviceChannel.invokeMethod<int>('getSdkInt');
      return sdk ?? 0;
    } catch (e) {
      debugPrint('AlarmService SDK okunamadı: $e');
      return _android12Sdk;
    }
  }

  Future<bool> _isAndroid12OrAbove() async {
    if (!Platform.isAndroid) return false;
    return await _androidSdkInt() >= _android12Sdk;
  }

  /// Android 12+ için alarm izinlerini ister; hepsi verilmezse false döner.
  Future<bool> _ensureAndroid12AlarmPermissions() async {
    const required = <Permission>[
      Permission.scheduleExactAlarm,
      Permission.notification,
      Permission.systemAlertWindow,
    ];

    for (final permission in required) {
      if (await permission.isGranted) continue;

      final status = await permission.request();
      if (!status.isGranted) {
        return false;
      }
    }

    for (final permission in required) {
      if (!await permission.isGranted) {
        return false;
      }
    }

    return true;
  }

  /// Android 11 ve altı: flutter_local_notifications ile bildirim / exact alarm.
  Future<void> _requestLegacyAndroidPermissions() async {
    final android = _androidNotifications;
    if (android == null) return;

    await android.requestNotificationsPermission();
    await android.requestExactAlarmsPermission();
  }

  Future<void> _initNotifications() async {
    _notifications = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('ic_notification');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    const channel = AndroidNotificationChannel(
      'quest_alarm_channel',
      'Quest Alarm',
      description: 'Sabah canavarı alarm bildirimleri',
      importance: Importance.max,
      playSound: false,
    );

    await _notifications!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _registerAlarmPort() {
    // Her yeni port kaydında önce eski portu kaldır.
    IsolateNameServer.removePortNameMapping(alarmRingPortName);

    final receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(
      receivePort.sendPort,
      alarmRingPortName,
    );

    receivePort.listen((_) async {
      await _onAlarmFired();
      _ringController.add(null);
    });
  }

  void _onNotificationTapped(NotificationResponse response) {
    unawaited(_handleNotificationTap());
  }

  Future<void> _handleNotificationTap() async {
    await _onAlarmFired();
    _ringController.add(null);
  }

  /// Alarm çaldığında: bayrak kaydet, bildirim göster, ses çal.
  Future<void> _onAlarmFired() async {
    final now = DateTime.now();
    if (_lastRingHandled != null &&
        now.difference(_lastRingHandled!) < const Duration(seconds: 3)) {
      return;
    }
    _lastRingHandled = now;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsPendingBattle, true);
    await _showRingingNotification();
    await playAlarmSound();
  }

  Future<void> _showRingingNotification() async {
    if (_notifications == null) return;

    const androidDetails = AndroidNotificationDetails(
      'quest_alarm_channel',
      'Quest Alarm',
      channelDescription: 'Sabah canavarı alarm bildirimleri',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      icon: 'ic_notification',
    );

    await _notifications!.show(
      questAlarmId,
      'QUEST ALARM',
      'Sabah Canavarı saldırıyor! Telefonu salla!',
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Seçilen saate alarm kurar (bugün veya yarın).
  Future<DateTime> scheduleAlarm(TimeOfDay time) async {
    if (!_initialized) {
      await initialize();
    }

    final scheduled = nextOccurrence(time);

    if (!Platform.isAndroid) {
      debugPrint('AlarmService mock schedule: $scheduled');
      return scheduled;
    }

    if (await _isAndroid12OrAbove()) {
      final permissionsGranted = await _ensureAndroid12AlarmPermissions();
      if (!permissionsGranted) {
        throw AlarmScheduleException(alarmPermissionsDeniedMessage);
      }
    } else {
      await _requestLegacyAndroidPermissions();
    }

    await cancelAlarm();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsScheduledAlarm, scheduled.toIso8601String());

    var alarmManagerOk = await AndroidAlarmManager.oneShotAt(
      scheduled,
      questAlarmId,
      alarmRingCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
      alarmClock: true,
    );

    if (!alarmManagerOk) {
      alarmManagerOk = await AndroidAlarmManager.oneShotAt(
        scheduled,
        questAlarmId,
        alarmRingCallback,
        exact: false,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
        alarmClock: true,
      );
    }

    var notificationOk = false;
    try {
      await _scheduleBackupNotification(scheduled, exact: true);
      notificationOk = true;
    } on PlatformException catch (e) {
      debugPrint('AlarmService exact bildirim hatası: $e');
      try {
        await _scheduleBackupNotification(scheduled, exact: false);
        notificationOk = true;
      } on PlatformException catch (e2) {
        debugPrint('AlarmService bildirim hatası: $e2');
      }
    } catch (e) {
      debugPrint('AlarmService bildirim hatası: $e');
    }

    if (!alarmManagerOk && !notificationOk) {
      throw AlarmScheduleException(
        'Alarm kurulamadı.\n'
        'Ayarlar → Uygulamalar → QuestAlarm → Bildirimler ve Alarmlar izinlerini açın.',
      );
    }

    if (!alarmManagerOk) {
      debugPrint('AlarmService: AlarmManager başarısız, yalnızca bildirim ile devam.');
    }

    return scheduled;
  }

  /// Alarmı ve yedek bildirimi iptal eder (ceza uygulanmaz).
  Future<void> cancelAlarm() async {
    if (Platform.isAndroid) {
      await AndroidAlarmManager.cancel(questAlarmId);
      await _notifications?.cancel(questAlarmId);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsScheduledAlarm);
    await stopAlarmSound();
  }

  /// Aktif alarm/savaş sırasında kaçış — ağır ceza uygular.
  Future<void> forfeitActiveAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(prefsPendingBattle) ?? false;
    if (pending) {
      final player = await PlayerService.instance.loadPlayer();
      await PlayerService.instance.applyDefeat();
      await BattleSummaryService.instance.save(
        BattleSummary(
          outcome: BattleOutcome.forfeit,
          monsterName: 'Sabah Baskini',
          streakBefore: player.streak,
          streakAfter: 0,
          reason: 'Alarm ertelendi veya savas terk edildi',
          timestampIso: DateTime.now().toIso8601String(),
        ),
      );
      await WidgetService.instance.updateLiveWidget(status: LiveWidgetStatus.sad);
    }
    await cancelAlarm();
    await clearPendingBattle();
  }

  /// Alarmı erteler; aktif savaş varsa ağır ceza uygular.
  Future<DateTime> snoozeAlarm({
    Duration delay = const Duration(minutes: 5),
  }) async {
    await forfeitActiveAlarm();
    final snoozeAt = DateTime.now().add(delay);
    final scheduled = await scheduleAlarm(
      TimeOfDay(hour: snoozeAt.hour, minute: snoozeAt.minute),
    );
    unawaited(AnalyticsService.instance.logAlarmSnoozed());
    return scheduled;
  }

  /// [TimeOfDay] için bir sonraki gerçekleşme zamanını hesaplar.
  DateTime nextOccurrence(TimeOfDay time) {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _scheduleBackupNotification(
    DateTime scheduled, {
    required bool exact,
  }) async {
    if (_notifications == null) return;

    final tzScheduled = tz.TZDateTime.from(scheduled, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'quest_alarm_channel',
      'Quest Alarm',
      channelDescription: 'Sabah canavarı alarm bildirimleri',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      icon: 'ic_notification',
    );

    await _notifications!.zonedSchedule(
      questAlarmId,
      'QUEST ALARM',
      'Sabah Canavarı saldırıyor!',
      tzScheduled,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  /// Uygulama bildirimden veya arka plandan açıldığında bekleyen savaşı kontrol eder.
  Future<void> handlePendingBattleLaunch(void Function() openBattle) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(prefsPendingBattle) ?? false;
    if (!pending) return;

    await playAlarmSound();
    openBattle();
    _ringController.add(null);
  }

  /// Savaş ekranı açıldıktan sonra bayrağı temizler.
  Future<void> clearPendingBattle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsPendingBattle, false);
    await _notifications?.cancel(questAlarmId);
    await stopAlarmSound();
  }

  /// 8-bit alarm sesini döngüde çalar (asset yoksa sistem sesi).
  Future<void> playAlarmSound() async {
    final settings = await AppSettingsService.instance.loadSettings();
    if (!settings.soundEnabled) return;
    if (_isPlaying) return;
    _isPlaying = true;

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(alarmAssetPath));
    } catch (e) {
      debugPrint('AlarmService ses yüklenemedi ($alarmAssetPath): $e');
      // Yer tutucu: asset eklenene kadar sistem uyarı sesi.
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> stopAlarmSound() async {
    _isPlaying = false;
    await _audioPlayer.stop();
  }

  void dispose() {
    _ringController.close();
    _audioPlayer.dispose();
  }
}

/// Arka plan isolate'inden ana isolate'e alarm sinyali gönderir.
@pragma('vm:entry-point')
void alarmRingCallback() {
  final sendPort = IsolateNameServer.lookupPortByName(alarmRingPortName);
  sendPort?.send(null);
}

/// Bildirime dokunulduğunda (arka plan) savaş bayrağını ayarlar.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  SharedPreferences.getInstance().then((prefs) {
    prefs.setBool(prefsPendingBattle, true);
  });
}
