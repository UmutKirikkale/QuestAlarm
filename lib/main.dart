import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/battle_screen.dart';
import 'screens/home_screen.dart';
import 'services/alarm_service.dart';
import 'theme/quest_theme.dart';

/// Alarm tetiklendiğinde [BattleScreen] açmak için global navigator.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: QuestTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const QuestAlarmApp());
}

class QuestAlarmApp extends StatefulWidget {
  const QuestAlarmApp({super.key});

  @override
  State<QuestAlarmApp> createState() => _QuestAlarmAppState();
}

class _QuestAlarmAppState extends State<QuestAlarmApp>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _alarmRingSubscription;
  bool _battleRouteOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAlarmSystem();
  }

  Future<void> _initAlarmSystem() async {
    await AlarmService.instance.initialize();

    _alarmRingSubscription =
        AlarmService.instance.onAlarmRing.listen((_) => _openBattleScreen());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AlarmService.instance.handlePendingBattleLaunch(_openBattleScreen);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AlarmService.instance.handlePendingBattleLaunch(_openBattleScreen);
    }
  }

  void _openBattleScreen() {
    if (_battleRouteOpen) return;

    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;

    _battleRouteOpen = true;

    navigator
        .push(
          MaterialPageRoute<void>(
            builder: (_) => const BattleScreen(
              playerCurrentHP: 80,
              playerMaxHP: 100,
            ),
          ),
        )
        .whenComplete(() {
          _battleRouteOpen = false;
          unawaited(AlarmService.instance.clearPendingBattle());
        });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _alarmRingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuestAlarm',
      debugShowCheckedModeBanner: false,
      theme: QuestTheme.dark,
      navigatorKey: rootNavigatorKey,
      home: const HomeScreen(),
    );
  }
}
