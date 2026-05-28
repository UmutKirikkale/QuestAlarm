import 'package:flutter/material.dart';

import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';
import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';
import '../widgets/retro_window.dart';

/// Küresel liderlik tablosu — seri ve seviye sekmeleri.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  LeaderboardSort get _currentSort =>
      _tabController.index == 0 ? LeaderboardSort.streak : LeaderboardSort.level;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuestTheme.background,
      appBar: AppBar(
        title: const Text('LİDERLİK TABLOSU'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: QuestTheme.primary,
          labelStyle: pixelTextStyle(fontSize: 11, color: QuestTheme.primary),
          unselectedLabelStyle: pixelTextStyle(
            fontSize: 11,
            color: QuestTheme.onSurfaceMuted,
          ),
          tabs: const [
            Tab(text: 'EN YÜKSEK SERİ'),
            Tab(text: 'EN YÜKSEK SEVİYE'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _LeaderboardTab(
                  sort: LeaderboardSort.streak,
                  stream: LeaderboardService.instance.watchTopByStreak(),
                  valueLabel: (e) => 'Seri: ${e.streak}',
                ),
                _LeaderboardTab(
                  sort: LeaderboardSort.level,
                  stream: LeaderboardService.instance.watchTopByLevel(),
                  valueLabel: (e) => 'Lv ${e.level} · ${e.xp} XP',
                ),
              ],
            ),
          ),
          _SelfRankFooter(sort: _currentSort),
        ],
      ),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab({
    required this.sort,
    required this.stream,
    required this.valueLabel,
  });

  final LeaderboardSort sort;
  final Stream<List<LeaderboardEntry>> stream;
  final String Function(LeaderboardEntry e) valueLabel;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LeaderboardEntry>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Liderlik yüklenemedi.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: pixelTextStyle(fontSize: 12, color: QuestTheme.error),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: QuestTheme.primary),
          );
        }

        final entries = snapshot.data!;
        if (entries.isEmpty) {
          return Center(
            child: Text(
              'Henüz sıralama yok.',
              style: pixelTextStyle(
                fontSize: 12,
                color: QuestTheme.onSurfaceMuted,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final rank = index + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LeaderboardRow(
                rank: rank,
                entry: entry,
                valueText: valueLabel(entry),
                highlight: rank <= 3,
              ),
            );
          },
        );
      },
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.valueText,
    required this.highlight,
  });

  final int rank;
  final LeaderboardEntry entry;
  final String valueText;
  final bool highlight;

  String? get _medal {
    return switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final medal = _medal;
    final podiumColor = switch (rank) {
      1 => const Color(0xFFFFD54F),
      2 => const Color(0xFFB0BEC5),
      3 => const Color(0xFFCD7F32),
      _ => QuestTheme.surfaceVariant,
    };

    return RetroWindow(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              medal ?? '#$rank',
              style: pixelTextStyle(
                fontSize: medal != null ? 20 : 12,
                color: highlight ? podiumColor : QuestTheme.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.displayName,
                        style: pixelTextStyle(
                          fontSize: 12,
                          color: highlight
                              ? podiumColor
                              : QuestTheme.onSurfaceMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.isPro) ...[
                      const SizedBox(width: 4),
                      Text('👑', style: pixelTextStyle(fontSize: 10)),
                    ],
                  ],
                ),
                Text(
                  valueText,
                  style: pixelTextStyle(
                    fontSize: 10,
                    color: QuestTheme.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelfRankFooter extends StatelessWidget {
  const _SelfRankFooter({required this.sort});

  final LeaderboardSort sort;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LeaderboardSelfRank?>(
      key: ValueKey(sort),
      future: LeaderboardService.instance.fetchSelfRank(sort),
      builder: (context, snapshot) {
        final self = snapshot.data;
        final loading = snapshot.connectionState == ConnectionState.waiting;

        String text;
        if (loading) {
          text = 'Sıralaman hesaplanıyor...';
        } else if (self == null) {
          text = 'Giriş yaparak sıralamanı gör.';
        } else if (!self.visibleOnLeaderboard) {
          text = sort == LeaderboardSort.streak
              ? 'Tabloda gizlisin. Seri: ${self.streak}'
              : 'Tabloda gizlisin. Lv ${self.level} · ${self.xp} XP';
        } else if (self.rank <= 0) {
          text = sort == LeaderboardSort.streak
              ? 'Seri: ${self.streak}'
              : 'Lv ${self.level} · ${self.xp} XP';
        } else {
          text = sort == LeaderboardSort.streak
              ? 'Senin Sıralaman: #${self.rank}. Seri: ${self.streak}'
              : 'Senin Sıralaman: #${self.rank}. Lv ${self.level} · ${self.xp} XP';
        }

        return Material(
          color: const Color(0xFF141820),
          elevation: 8,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text('⚔', style: pixelTextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: pixelTextStyle(
                        fontSize: 11,
                        color: QuestTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
