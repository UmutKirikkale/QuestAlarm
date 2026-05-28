import 'package:flutter/material.dart';

import '../../models/leaderboard_entry.dart';
import '../../services/leaderboard_service.dart';
import '../../services/player_moderation_service.dart';
import '../widgets/admin_buttons.dart';

/// Liderlik tablosu yansıması ve moderasyon.
class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  LeaderboardSort _sort = LeaderboardSort.streak;
  String? _busyUid;

  static const _neon = Color(0xFF00E5A0);

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _toggleVisibility(LeaderboardEntry entry) async {
    if (_busyUid != null) return;
    setState(() => _busyUid = entry.uid);
    try {
      final hide = entry.showOnLeaderboard;
      await PlayerModerationService.instance.setShowOnLeaderboard(
        entry.uid,
        !hide,
      );
      _snack(hide ? 'Oyuncu tablodan gizlendi.' : 'Oyuncu tabloya geri alındı.');
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _busyUid = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'LİDERLİK TABLOSU & MODERASYON',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _neon,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Canlı küresel sıralama. 🗑️ ile oyuncuyu mobil listeden gizleyin '
            '(showOnLeaderboard: false). Banlı oyuncular mobilde zaten görünmez.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SegmentedButton<LeaderboardSort>(
            segments: const [
              ButtonSegment(
                value: LeaderboardSort.streak,
                label: Text('En Yüksek Seri'),
                icon: Icon(Icons.local_fire_department_outlined, size: 18),
              ),
              ButtonSegment(
                value: LeaderboardSort.level,
                label: Text('En Yüksek Seviye'),
                icon: Icon(Icons.military_tech_outlined, size: 18),
              ),
            ],
            selected: {_sort},
            onSelectionChanged: (s) => setState(() => _sort = s.first),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: StreamBuilder<List<LeaderboardEntry>>(
                stream: LeaderboardService.instance.watchAllForModeration(
                  sort: _sort,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Hata: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final entries = snapshot.data!;
                  if (entries.isEmpty) {
                    return const Center(child: Text('Kayıtlı oyuncu yok.'));
                  }

                  return ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final e = entries[index];
                      final rank = index + 1;
                      final hidden = !e.showOnLeaderboard;
                      final banned = e.isBanned;

                      return ListTile(
                        leading: Text(
                          switch (rank) {
                            1 => '🥇',
                            2 => '🥈',
                            3 => '🥉',
                            _ => '#$rank',
                          },
                          style: TextStyle(
                            fontSize: rank <= 3 ? 22 : 14,
                          ),
                        ),
                        title: Text(
                          e.displayName,
                          style: TextStyle(
                            decoration: hidden || banned
                                ? TextDecoration.lineThrough
                                : null,
                            color: hidden
                                ? Colors.orangeAccent
                                : banned
                                    ? Colors.redAccent
                                    : null,
                          ),
                        ),
                        subtitle: Text(
                          '${e.shortUid} · Seri ${e.streak} · Lv ${e.level} · ${e.xp} XP'
                          '${hidden ? ' · GİZLİ' : ''}'
                          '${banned ? ' · BAN' : ''}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: AdminCompactButton(
                          label: hidden ? 'Geri Al' : '🗑️ Gizle',
                          destructive: !hidden,
                          onPressed: _busyUid == e.uid
                              ? null
                              : () => _toggleVisibility(e),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
