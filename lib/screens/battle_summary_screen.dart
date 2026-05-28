import 'package:flutter/material.dart';

import '../models/battle_summary.dart';
import '../models/player.dart';
import '../services/battle_summary_service.dart';
import '../services/player_service.dart';
import '../widgets/mock_ad_banner.dart';
import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';
import '../widgets/retro_arcade_button.dart';
import '../widgets/retro_window.dart';

class BattleSummaryScreen extends StatefulWidget {
  const BattleSummaryScreen({super.key});

  @override
  State<BattleSummaryScreen> createState() => _BattleSummaryScreenState();
}

class _BattleSummaryScreenState extends State<BattleSummaryScreen> {
  BattleSummary? _summary;
  Player? _player;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final summary = await BattleSummaryService.instance.load();
    final player = await PlayerService.instance.loadPlayer();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _player = player;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: QuestTheme.background,
        body: Center(child: CircularProgressIndicator(color: QuestTheme.primary)),
      );
    }

    final summary = _summary;
    if (summary == null) {
      return Scaffold(
        backgroundColor: QuestTheme.background,
        appBar: AppBar(title: const Text('Savaş Özeti')),
        body: Center(
          child: Text(
            'Henüz savaş özeti yok.',
            style: pixelTextStyle(fontSize: 14),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: QuestTheme.background,
      appBar: AppBar(title: const Text('Savaş Özeti')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RetroWindow(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _title(summary.outcome),
                      style: pixelTextStyle(
                        fontSize: 18,
                        color: _titleColor(summary.outcome),
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Dusman: ${summary.monsterName}',
                      style: pixelTextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Seri: ${summary.streakBefore} -> ${summary.streakAfter}',
                      style: pixelTextStyle(
                        fontSize: 12,
                        color: const Color(0xFFFF944D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Odul: +${summary.gainedXp} XP / +${summary.gainedGold} Altin',
                      style: pixelTextStyle(
                        fontSize: 12,
                        color: const Color(0xFF78D4FF),
                      ),
                    ),
                    if (summary.reason != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Neden: ${summary.reason}',
                        style: pixelTextStyle(
                          fontSize: 11,
                          color: QuestTheme.onSurfaceMuted,
                        ),
                      ),
                    ],
                    if (summary.brokenItems.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Kirilan Esyalar: ${summary.brokenItems.join(', ')}',
                        style: pixelTextStyle(fontSize: 11, color: QuestTheme.error),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Zaman: ${summary.timestampIso.replaceFirst('T', ' ').split('.').first}',
                      style: pixelTextStyle(
                        fontSize: 10,
                        color: QuestTheme.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              MockAdBanner(isPro: _player?.isPro ?? false),
              const Spacer(),
              RetroArcadeButton(
                label: 'ANA MENÜYE DÖN',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _title(BattleOutcome outcome) {
    return switch (outcome) {
      BattleOutcome.victory => 'ZAFER RAPORU',
      BattleOutcome.defeat => 'YENILGI RAPORU',
      BattleOutcome.forfeit => 'KACIS RAPORU',
    };
  }

  Color _titleColor(BattleOutcome outcome) {
    return switch (outcome) {
      BattleOutcome.victory => QuestTheme.primary,
      BattleOutcome.defeat => QuestTheme.error,
      BattleOutcome.forfeit => QuestTheme.secondary,
    };
  }
}
