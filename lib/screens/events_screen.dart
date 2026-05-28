import 'dart:async';

import 'package:flutter/material.dart';

import '../models/event_progress.dart';
import '../models/game_event_definition.dart';
import '../services/event_progress_service.dart';
import '../services/game_content_service.dart';
import '../services/player_service.dart';
import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';
import '../widgets/retro_arcade_button.dart';
import '../widgets/retro_stat_bar.dart';
import '../widgets/retro_window.dart';
import 'pro_upgrade_screen.dart';

/// Canlı etkinlikler — `global_events` + oyuncu ilerlemesi.
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String? _claimingEventId;
  String? _enrollingEventId;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPlayer());
  }

  Future<void> _loadPlayer() async {
    final player = await PlayerService.instance.loadPlayer();
    if (!mounted) return;
    setState(() => _isPro = player.isPro);
  }

  Future<void> _enroll(GameEventDefinition event) async {
    if (_enrollingEventId != null) return;
    setState(() => _enrollingEventId = event.id);

    final result =
        await EventProgressService.instance.enrollInEvent(event.id);

    if (!mounted) return;
    setState(() => _enrollingEventId = null);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Katılım başarısız'),
          backgroundColor: QuestTheme.error,
          action: result.message != null &&
                  result.message!.contains('Pro')
              ? SnackBarAction(
                  label: 'PRO',
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ProUpgradeScreen(),
                      ),
                    );
                  },
                )
              : null,
        ),
      );
    }
  }

  Future<void> _claimReward(
    GameEventDefinition event,
    EventProgress progress,
  ) async {
    if (_claimingEventId != null) return;
    setState(() => _claimingEventId = event.id);

    final result = await EventProgressService.instance.claimReward(
      eventId: event.id,
      rewardGold: event.rewardGold,
      targetCount: event.targetCount,
    );

    if (!mounted) return;
    setState(() => _claimingEventId = null);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Ödül alınamadı'),
          backgroundColor: QuestTheme.error,
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuestTheme.surface,
        title: Text(
          'ÖDÜL ALINDI!',
          style: pixelTextStyle(fontSize: 14, color: QuestTheme.primary),
        ),
        content: Text(
          '+${result.goldAwarded} altın hesabına eklendi.',
          style: pixelTextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('TAMAM'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ETKİNLİKLER')),
      backgroundColor: QuestTheme.background,
      body: StreamBuilder<List<GameEventDefinition>>(
        stream: GameContentService.instance.watchEvents(),
        builder: (context, eventsSnap) {
          if (eventsSnap.hasError) {
            return Center(
              child: Text(
                'Etkinlikler yüklenemedi.\n${eventsSnap.error}',
                style: pixelTextStyle(fontSize: 12, color: QuestTheme.error),
                textAlign: TextAlign.center,
              ),
            );
          }
          if (!eventsSnap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: QuestTheme.primary),
            );
          }

          final events = eventsSnap.data!;
          if (events.isEmpty) {
            return Center(
              child: Text(
                'Şu an aktif etkinlik yok.',
                style: pixelTextStyle(
                  fontSize: 12,
                  color: QuestTheme.onSurfaceMuted,
                ),
              ),
            );
          }

          return StreamBuilder<Map<String, EventProgress>>(
            stream: EventProgressService.instance.watchAllProgress(),
            builder: (context, progressSnap) {
              final progressMap = progressSnap.data ?? {};
              final activeCount = EventProgressService.instance
                  .countActiveEnrollments(progressMap);

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: events.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return RetroWindow(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        _isPro
                            ? '👑 Pro: Tüm etkinliklere katılabilirsin.'
                            : 'Aktif etkinlik: $activeCount / '
                                '${EventProgressService.maxFreeActiveEvents} '
                                '(Pro ile sınırsız)',
                        textAlign: TextAlign.center,
                        style: pixelTextStyle(
                          fontSize: 10,
                          color: QuestTheme.onSurfaceMuted,
                        ),
                      ),
                    );
                  }

                  final event = events[index - 1];
                  final progress =
                      progressMap[event.id] ?? EventProgress.empty(event.id);
                  return _EventCard(
                    event: event,
                    progress: progress,
                    claiming: _claimingEventId == event.id,
                    enrolling: _enrollingEventId == event.id,
                    onClaim: () => _claimReward(event, progress),
                    onEnroll: () => _enroll(event),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.progress,
    required this.claiming,
    required this.enrolling,
    required this.onClaim,
    required this.onEnroll,
  });

  final GameEventDefinition event;
  final EventProgress progress;
  final bool claiming;
  final bool enrolling;
  final VoidCallback onClaim;
  final VoidCallback onEnroll;

  @override
  Widget build(BuildContext context) {
    final canClaim = progress.canClaimReward(event.targetCount);
    final claimed = progress.rewardClaimed;
    final enrolled = progress.enrolled;
    final current = progress.currentProgress.clamp(0, event.targetCount);

    return RetroWindow(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            event.name.toUpperCase(),
            style: pixelTextStyle(fontSize: 14, color: QuestTheme.primary),
          ),
          const SizedBox(height: 6),
          Text(
            event.description,
            style: pixelTextStyle(
              fontSize: 11,
              color: QuestTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 10),
          if (!enrolled && !claimed) ...[
            RetroArcadeButton(
              label: enrolling ? 'KATILINIYOR...' : 'ETKİNLİĞE KATIL',
              icon: '🎯',
              onPressed: enrolling ? () {} : onEnroll,
            ),
            const SizedBox(height: 10),
          ],
          if (enrolled || claimed) ...[
            RetroStatBar(
              icon: '🎯',
              label: 'İLERLEME',
              current: current,
              max: event.targetCount,
              fillColor: QuestTheme.secondary,
              compact: true,
            ),
            const SizedBox(height: 6),
            Text(
              'Ödül: ${event.rewardGold} altın',
              style: pixelTextStyle(fontSize: 11, color: QuestTheme.secondary),
            ),
            const SizedBox(height: 12),
          ],
          if (claimed)
            Text(
              '✓ Etkinlik tamamlandı',
              textAlign: TextAlign.center,
              style: pixelTextStyle(fontSize: 11, color: QuestTheme.primary),
            )
          else if (canClaim)
            RetroArcadeButton(
              label: claiming ? 'ALINIYOR...' : 'ÖDÜLÜ AL',
              icon: '🎁',
              onPressed: claiming ? () {} : onClaim,
            )
          else if (enrolled)
            Text(
              'Sabah zaferi kazanarak ilerle ($current/${event.targetCount})',
              textAlign: TextAlign.center,
              style: pixelTextStyle(
                fontSize: 10,
                color: QuestTheme.onSurfaceMuted,
              ),
            ),
        ],
      ),
    );
  }
}
