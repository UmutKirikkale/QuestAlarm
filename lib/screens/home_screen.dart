import 'dart:async';

import 'package:flutter/material.dart';

import '../models/player.dart';
import '../services/analytics_service.dart';
import '../services/alarm_service.dart';
import '../services/auth_service.dart';
import '../services/player_service.dart';
import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';
import '../widgets/character_profile_panel.dart';
import '../widgets/retro_arcade_button.dart';
import '../widgets/retro_stat_bar.dart';
import '../widgets/retro_window.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

/// Uygulamanın ana menüsü — JRPG tarzı üç panelli oyun arayüzü.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Player? _player;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadPlayer());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
                    onOpenShop: _openShop,
                  ),
                ),
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUEST ALARM',
                style: pixelTextStyle(
                  fontSize: 13,
                  color: QuestTheme.primary,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'LV ${player.level}',
                style: pixelTextStyle(
                  fontSize: 13,
                  color: QuestTheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            stageName,
            style: pixelTextStyle(
              fontSize: 10,
              color: const Color(0xFF8AB4FF),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _classLabel(player.characterClass),
                style: pixelTextStyle(fontSize: 11, color: QuestTheme.onSurfaceMuted),
              ),
              _StreakBadge(streak: player.streak),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RetroStatBar(
                  icon: '❤️',
                  label: 'CAN (HP)',
                  current: player.currentHP,
                  max: player.maxHP,
                  fillColor: const Color(0xFF39FF14),
                  fillColorLow: QuestTheme.error,
                  lowThreshold: 0.3,
                ),
                RetroStatBar(
                  icon: '⚡',
                  label: 'TECRÜBE (XP)',
                  current: player.currentXP,
                  max: player.nextLevelXP,
                  fillColor: const Color(0xFF4488FF),
                ),
                RetroGoldCounter(gold: player.gold),
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
  const _ActionPanel({
    required this.onScheduleAlarm,
    required this.onOpenShop,
  });

  final VoidCallback onScheduleAlarm;
  final VoidCallback onOpenShop;

  @override
  Widget build(BuildContext context) {
    return RetroWindow(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RetroArcadeButton(
            label: 'ALARM KUR',
            icon: '⏰',
            onPressed: onScheduleAlarm,
          ),
          const SizedBox(height: 14),
          RetroArcadeButton(
            label: 'MAĞAZA',
            icon: '🏪',
            backgroundColor: const Color(0xFF2A3550),
            foregroundColor: QuestTheme.secondary,
            onPressed: onOpenShop,
          ),
        ],
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
