import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
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
import 'shop_screen.dart';

/// Uygulamanın ana menüsü — JRPG tarzı üç panelli oyun arayüzü.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Player? _player;
  User? _currentUser;
  bool _loading = true;
  bool _isSigningIn = false;

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
      _currentUser = AuthService.instance.currentUser;
      _loading = false;
    });
  }

  Future<void> _signInForCloudBackup() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);
    try {
      final credential = await AuthService.instance.signInWithGoogle();
      if (credential?.user != null) {
        await PlayerService.instance.syncFromCloudIfSignedIn();
      }
      if (!mounted) return;
      await _loadPlayer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google giriş başarısız: $e',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          backgroundColor: QuestTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _openShop() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const ShopScreen()),
    );
    await _loadPlayer();
  }

  Future<void> _setCharacterClass(CharacterClass characterClass) async {
    final current = _player;
    if (current == null || current.characterClass == characterClass) return;
    await PlayerService.instance.setCharacterClass(characterClass);
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
                _ClassSelectPanel(
                  selectedClass: player.characterClass,
                  onChanged: _setCharacterClass,
                ),
                const SizedBox(height: 12),
                _CloudSyncPanel(
                  user: _currentUser,
                  isSigningIn: _isSigningIn,
                  onSignIn: _signInForCloudBackup,
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

class _CloudSyncPanel extends StatelessWidget {
  const _CloudSyncPanel({
    required this.user,
    required this.isSigningIn,
    required this.onSignIn,
  });

  final User? user;
  final bool isSigningIn;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return RetroWindow(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: user == null
          ? RetroArcadeButton(
              label: isSigningIn
                  ? 'GIRIS YAPILIYOR...'
                  : 'BULUTA YEDEKLE (Google ile Giris)',
              icon: '☁️',
              backgroundColor: const Color(0xFF2D3D5A),
              foregroundColor: QuestTheme.secondary,
              onPressed: onSignIn,
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('☁️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'Veriler Bulutla Senkronize',
                  style: pixelTextStyle(
                    fontSize: 12,
                    color: const Color(0xFF8BE9FD),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ClassSelectPanel extends StatelessWidget {
  const _ClassSelectPanel({
    required this.selectedClass,
    required this.onChanged,
  });

  final CharacterClass selectedClass;
  final ValueChanged<CharacterClass> onChanged;

  @override
  Widget build(BuildContext context) {
    return RetroWindow(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SINIF SECIMI',
            textAlign: TextAlign.center,
            style: pixelTextStyle(
              fontSize: 11,
              color: QuestTheme.onSurfaceMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ClassChoiceButton(
                  label: 'SAVASCI',
                  icon: '⚔️',
                  selected: selectedClass == CharacterClass.warrior,
                  onPressed: () => onChanged(CharacterClass.warrior),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ClassChoiceButton(
                  label: 'BUYUCU',
                  icon: '🪄',
                  selected: selectedClass == CharacterClass.mage,
                  onPressed: () => onChanged(CharacterClass.mage),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClassChoiceButton extends StatelessWidget {
  const _ClassChoiceButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return RetroArcadeButton(
      label: label,
      icon: icon,
      height: 42,
      fontSize: 11,
      backgroundColor: selected ? QuestTheme.primary : const Color(0xFF2D3D5A),
      foregroundColor: selected ? QuestTheme.background : QuestTheme.onBackground,
      onPressed: onPressed,
    );
  }
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
