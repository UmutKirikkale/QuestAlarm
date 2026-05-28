import 'dart:async';

import 'package:flutter/material.dart';

import '../models/player.dart';
import '../services/analytics_service.dart';
import '../services/alarm_service.dart';
import '../services/auth_service.dart';
import '../services/player_service.dart';
import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';
import '../services/user_document_sync_service.dart';
import '../widgets/character_profile_panel.dart';
import '../widgets/daily_quest_ticker.dart';
import '../widgets/retro_arcade_button.dart';
import '../widgets/retro_stat_bar.dart';
import '../widgets/retro_window.dart';
import 'settings_screen.dart';
import 'diamond_shop_screen.dart';
import 'events_screen.dart';
import 'leaderboard_screen.dart';
import 'map_selection_screen.dart';
import 'pro_upgrade_screen.dart';
import 'shop_screen.dart';
import '../widgets/mock_ad_banner.dart';

/// Uygulamanın ana menüsü — JRPG tarzı üç panelli oyun arayüzü.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Player? _player;
  bool _loading = true;
  StreamSubscription<UserDocumentSnapshot>? _cloudPlayerSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadPlayer());
    _cloudPlayerSub = UserDocumentSyncService.instance.stream.listen(
      (snap) => _onCloudPlayerUpdate(snap),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cloudPlayerSub?.cancel();
    super.dispose();
  }

  Future<void> _onCloudPlayerUpdate(UserDocumentSnapshot snap) async {
    if (snap.player == null) return;
    await PlayerService.instance.mergeFromCloudIfNewer(snap);
    if (!mounted) return;
    final player = await PlayerService.instance.loadPlayer();
    setState(() => _player = player);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadPlayer());
    }
  }

  Future<void> _loadPlayer() async {
    PlayerService.instance.invalidateCache();
    final player = await PlayerService.instance.loadPlayer();
    if (!mounted) return;
    setState(() {
      _player = player;
      _loading = false;
    });
  }

  Future<void> _openShop() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const ShopScreen()),
    );
    await _loadPlayer();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _player == null) {
      return const Scaffold(
        backgroundColor: QuestTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: QuestTheme.primary),
        ),
      );
    }

    final player = _player!;
    final stage = _stageForLevel(player.level);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DASHBOARD'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: QuestTheme.surface,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              ListTile(
                leading: const Text('🏪'),
                title: const Text('Mağaza'),
                onTap: () async {
                  Navigator.pop(context);
                  await _openShop();
                },
              ),
              ListTile(
                leading: Text(player.isPro ? '👑' : '⭐'),
                title: Text(player.isPro ? 'Pro Üyelik (Aktif)' : 'Pro Sürüme Geç'),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ProUpgradeScreen(),
                    ),
                  );
                  await _loadPlayer();
                },
              ),
              ListTile(
                leading: const Text('💎'),
                title: const Text('Elmas Mağazası'),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const DiamondShopScreen(),
                    ),
                  );
                  await _loadPlayer();
                },
              ),
              ListTile(
                leading: const Text('🏆'),
                title: const Text('Liderlik Tablosu'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const LeaderboardScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Text('🎯'),
                title: const Text('Etkinlikler'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const EventsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Text('🗺️'),
                title: const Text('Zindan Seç'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const MapSelectionScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Text('⚙️'),
                title: const Text('Ayarlar'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: QuestTheme.error),
                title: const Text('Çıkış Yap'),
                onTap: () async {
                  Navigator.pop(context);
                  await AuthService.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/auth',
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: QuestTheme.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: stage.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const DailyQuestTicker(),
                Expanded(
                  flex: 26,
                  child: _TopStatusPanel(player: player, stageName: stage.title),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 44,
                  child: CharacterProfilePanel(player: player),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 18,
                  child: _ActionPanel(
                    onScheduleAlarm: () => _scheduleAlarm(context),
                  ),
                ),
                MockAdBanner(isPro: player.isPro, compact: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _StageInfo _stageForLevel(int level) {
    if (level >= 10) {
      return const _StageInfo(
        title: 'BOLGE 3: Cati Alarmi Hisari',
        backgroundGradient: [Color(0xFF12060A), Color(0xFF220B12)],
      );
    }
    if (level >= 5) {
      return const _StageInfo(
        title: 'BOLGE 2: Oturma Odasi Labirenti',
        backgroundGradient: [Color(0xFF061014), Color(0xFF0A1B26)],
      );
    }
    return const _StageInfo(
      title: 'BOLGE 1: Yatak Odasi Zindani',
      backgroundGradient: [Color(0xFF060610), Color(0xFF0D0D18)],
    );
  }
}

/// Üst bilgi paneli — sınıf, seri, HP/XP/Altın.
class _TopStatusPanel extends StatelessWidget {
  const _TopStatusPanel({required this.player, required this.stageName});

  final Player player;
  final String stageName;

  @override
  Widget build(BuildContext context) {
    return RetroWindow(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'QUEST ALARM',
                  style: pixelTextStyle(
                    fontSize: 12,
                    color: QuestTheme.primary,
                    letterSpacing: 2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'LV ${player.level}',
                style: pixelTextStyle(
                  fontSize: 12,
                  color: QuestTheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            stageName,
            style: pixelTextStyle(
              fontSize: 9,
              color: const Color(0xFF8AB4FF),
              letterSpacing: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _classLabel(player.characterClass),
                style: pixelTextStyle(fontSize: 10, color: QuestTheme.onSurfaceMuted),
              ),
              _StreakBadge(streak: player.streak),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RetroStatBar(
                  icon: '❤️',
                  label: 'CAN (HP)',
                  current: player.currentHP,
                  max: player.maxHP,
                  fillColor: const Color(0xFF39FF14),
                  fillColorLow: QuestTheme.error,
                  lowThreshold: 0.3,
                  compact: true,
                ),
                const SizedBox(height: 4),
                RetroStatBar(
                  icon: '⚡',
                  label: 'TECRÜBE (XP)',
                  current: player.currentXP,
                  max: player.nextLevelXP,
                  fillColor: const Color(0xFF4488FF),
                  compact: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _classLabel(CharacterClass characterClass) {
    return switch (characterClass) {
      CharacterClass.warrior => '◆ Savaşçı',
      CharacterClass.mage => '◆ Büyücü',
      CharacterClass.rogue => '◆ Hırsız',
    };
  }
}

class _StageInfo {
  const _StageInfo({
    required this.title,
    required this.backgroundGradient,
  });

  final String title;
  final List<Color> backgroundGradient;
}

/// Alev ikonlu seri rozeti.
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1000),
        border: Border.all(color: const Color(0xFFFF6600), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            'SERİ: $streak',
            style: pixelTextStyle(
              fontSize: 10,
              color: const Color(0xFFFF8800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Alt aksiyon paneli — arcade butonları.
class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.onScheduleAlarm});

  final VoidCallback onScheduleAlarm;

  @override
  Widget build(BuildContext context) {
    return RetroWindow(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Center(
        child: RetroArcadeButton(
          label: 'ALARM KUR',
          icon: '⏰',
          onPressed: onScheduleAlarm,
        ),
      ),
    );
  }
}

/// Saat seçici ile alarm kurar ve retro Snackbar gösterir.
Future<void> _scheduleAlarm(BuildContext context) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: QuestTheme.primary,
            surface: QuestTheme.surface,
            onSurface: QuestTheme.onBackground,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked == null) return;

  try {
    final scheduled = await AlarmService.instance.scheduleAlarm(picked);
    if (!context.mounted) return;

    final timeLabel =
        '${scheduled.hour.toString().padLeft(2, '0')}:${scheduled.minute.toString().padLeft(2, '0')}';

    unawaited(AnalyticsService.instance.logAlarmSet(time: timeLabel));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Alarm $timeLabel için kuruldu',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: QuestTheme.onBackground,
          ),
        ),
        backgroundColor: QuestTheme.surfaceVariant,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: QuestTheme.border, width: 2),
        ),
      ),
    );
  } on AlarmScheduleException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.message,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: QuestTheme.onBackground,
          ),
        ),
        backgroundColor: QuestTheme.error,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Alarm kurulamadı: $e',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        backgroundColor: QuestTheme.error,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
