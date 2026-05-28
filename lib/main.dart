import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'utils/firestore_resilience.dart';
import 'screens/maintenance_screen.dart';
import 'services/global_settings_service.dart';
import 'screens/battle_screen.dart';
import 'screens/battle_summary_screen.dart';
import 'screens/onboarding_class_screen.dart';
import 'screens/home_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/auth_screen.dart';
import 'services/auth_service.dart';
import 'services/alarm_service.dart';
import 'services/player_service.dart';
import 'services/storage_service.dart';
import 'theme/quest_theme.dart';
import 'navigation/app_navigator.dart';
import 'widgets/live_ops_guard_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await GlobalSettingsService.instance.ensureLoaded();
  GlobalSettingsService.instance.startListening();

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

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
  StreamSubscription<Uri?>? _widgetClickSubscription;
  bool _battleRouteOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAlarmSystem();
    _initWidgetDeepLinks();
  }

  Future<void> _initAlarmSystem() async {
    await AlarmService.instance.initialize();

    _alarmRingSubscription =
        AlarmService.instance.onAlarmRing.listen((_) => _openBattleScreen());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AlarmService.instance.handlePendingBattleLaunch(_openBattleScreen);
    });
  }

  Future<void> _initWidgetDeepLinks() async {
    _widgetClickSubscription = HomeWidget.widgetClicked.listen(
      _handleWidgetUri,
    );
    final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    _handleWidgetUri(initialUri);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AlarmService.instance.handlePendingBattleLaunch(_openBattleScreen);
    }
  }

  Future<void> _handleWidgetUri(Uri? uri) async {
    if (uri == null) return;
    if (uri.scheme != 'questalarm') return;

    switch (uri.host) {
      case 'home':
        await _openTargetFromWidget(showBattleSummary: false);
        return;
      case 'battle-summary':
        await _openTargetFromWidget(showBattleSummary: true);
        return;
      default:
        await _openTargetFromWidget(showBattleSummary: false);
        return;
    }
  }

  Future<void> _openTargetFromWidget({required bool showBattleSummary}) async {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const InitialRouteScreen()),
      (route) => false,
    );

    if (!showBattleSummary) return;
    if (AuthService.instance.currentUser == null) return;
    final isFirstTime = await StorageService.instance.isFirstTime();
    if (isFirstTime) return;
    final player = await PlayerService.instance.loadPlayer();
    if (!player.hasChosenClass) return;

    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!navigator.mounted) return;
    await navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const BattleSummaryScreen(),
      ),
    );
  }

  void _openBattleScreen() {
    if (_battleRouteOpen) return;

    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;

    _battleRouteOpen = true;

    navigator
        .push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => const BattleScreen(),
          ),
        )
        .then((_) async {
          _battleRouteOpen = false;
          await AlarmService.instance.clearPendingBattle();
        });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _alarmRingSubscription?.cancel();
    _widgetClickSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuestAlarm',
      debugShowCheckedModeBanner: false,
      theme: QuestTheme.dark,
      navigatorKey: rootNavigatorKey,
      builder: (context, child) => LiveOpsGuardHost(child: child),
      routes: {
        '/auth': (_) => const AuthScreen(),
        '/initial': (_) => const InitialRouteScreen(),
      },
      home: const InitialRouteScreen(),
    );
  }
}

/// İlk açılışta izin kurulumu, sonrasında ana menü.
class InitialRouteScreen extends StatefulWidget {
  const InitialRouteScreen({super.key});

  @override
  State<InitialRouteScreen> createState() => _InitialRouteState();
}

class _InitialRouteState extends State<InitialRouteScreen> {
  Widget? _screen;

  @override
  void initState() {
    super.initState();
    _resolveStartScreen();
  }

  Future<void> _resolveStartScreen() async {
    try {
      await _resolveStartScreenCore().timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          debugPrint('InitialRouteScreen: startup timeout — offline fallback');
          return _applyOfflineFallback();
        },
      );
    } catch (e, stack) {
      debugPrint('InitialRouteScreen startup error: $e\n$stack');
      await _applyOfflineFallback();
    }
  }

  Future<void> _resolveStartScreenCore() async {
    final authUser = AuthService.instance.currentUser;
    if (authUser == null) {
      if (!mounted) return;
      setState(() => _screen = const AuthScreen());
      return;
    }

    final settings = await GlobalSettingsService.instance.loadSettings();
    if (settings.maintenanceMode) {
      if (!mounted) return;
      setState(() => _screen = LiveOpsLockScreen.maintenance());
      return;
    }

    final isBanned = await withFirestoreTimeout<bool>(
      () async {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(authUser.uid)
            .get();
        return userDoc.data()?['isBanned'] == true;
      }(),
      debugLabel: 'isBanned',
      fallback: false,
    );

    if (isBanned) {
      if (!mounted) return;
      setState(() => _screen = LiveOpsLockScreen.banned());
      return;
    }

    await PlayerService.instance.syncFromCloudIfSignedIn();
    await _applyMainFlow();
  }

  Future<void> _applyOfflineFallback() async {
    if (!mounted) return;
    final authUser = AuthService.instance.currentUser;
    if (authUser == null) {
      setState(() => _screen = const AuthScreen());
      return;
    }
    PlayerService.instance.invalidateCache();
    await _applyMainFlow();
  }

  Future<void> _applyMainFlow() async {
    final player = await PlayerService.instance.loadPlayer();
    final isFirstTime = await StorageService.instance.isFirstTime();
    if (!mounted) return;

    setState(() {
      if (isFirstTime) {
        _screen = const PermissionsScreen();
      } else if (!player.hasChosenClass) {
        _screen = const OnboardingClassScreen();
      } else {
        _screen = const HomeScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = _screen;
    if (screen == null) {
      return const Scaffold(
        backgroundColor: QuestTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: QuestTheme.primary),
        ),
      );
    }
    return screen;
  }
}
