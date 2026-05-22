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
import 'package:shared_preferences/shared_preferences.dart';
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

/// Yer tutucu 8-bit alarm sesi (assets/audio/alarm.mp3 ekleyin).
const String alarmAssetPath = 'audio/alarm.mp3';

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
    await _requestAndroidPermissions(silent: true);

    _initialized = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidNotifications =>
      _notifications?.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Bildirim ve tam zamanlı alarm izinlerini ister (Android 12+).
  Future<void> _requestAndroidPermissions({bool silent = false}) async {
    final android = _androidNotifications;
    if (android == null) return;

    await android.requestNotificationsPermission();
    final exactGranted = await android.requestExactAlarmsPermission();

    if (!silent && exactGranted == false) {
      throw AlarmScheduleException(
        'Tam zamanlı alarm izni kapalı.\n'
        'Ayarlar → Uygulamalar → QuestAlarm → Alarmlar ve hatırlatıcılar → İzin ver',
      );
    }
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

    await _requestAndroidPermissions();

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

  /// Alarmı ve yedek bildirimi iptal eder.
  Future<void> cancelAlarm() async {
    if (Platform.isAndroid) {
      await AndroidAlarmManager.cancel(questAlarmId);
      await _notifications?.cancel(questAlarmId);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsScheduledAlarm);
    await stopAlarmSound();
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
