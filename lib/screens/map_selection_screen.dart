import 'package:flutter/material.dart';

import '../models/game_map_definition.dart';
import '../models/player.dart';
import '../models/shop_currency.dart';
import '../services/game_content_service.dart';
import '../services/player_service.dart';
import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';
import '../widgets/pixel_asset_image.dart';
import '../widgets/retro_arcade_button.dart';
import '../widgets/retro_window.dart';

/// Sabah zindanı seçimi — `global_maps` koleksiyonunu dinler.
class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  Player? _player;

  @override
  void initState() {
    super.initState();
    _loadPlayer();
  }

  Future<void> _loadPlayer() async {
    final player = await PlayerService.instance.loadPlayer();
    if (!mounted) return;
    setState(() => _player = player);
  }

  Future<void> _onMapTap(GameMapDefinition map) async {
    final player = _player;
    if (player == null) return;

    if (map.isProOnly && !player.isPro) {
      _showSnack('Bu zindan sadece Pro üyelere açık! 🔒', isError: true);
      return;
    }

    if (player.level < map.requiredLevel) {
      _showSnack(
        'Seviye yetersiz! (Gerekli: Lv ${map.requiredLevel})',
        isError: true,
      );
      return;
    }

    final needsPurchase =
        map.requiresPurchase && !player.hasUnlockedMap(map.id);

    if (needsPurchase) {
      final result = await PlayerService.instance.purchaseMapUnlock(map);
      if (!result.success) {
        final msg = switch (result.failure) {
          PurchaseFailure.insufficientGold =>
            'Yetersiz altın! (${map.shopCurrency.formatPrice(map.unlockPrice)} gerekli)',
          PurchaseFailure.insufficientDiamonds =>
            'Yetersiz elmas! (${map.shopCurrency.formatPrice(map.unlockPrice)} gerekli)',
          PurchaseFailure.levelTooLow =>
            'Seviye yetersiz! (Gerekli: Lv ${map.requiredLevel})',
          _ => 'Satın alma başarısız',
        };
        _showSnack(msg, isError: true);
        return;
      }
      await _loadPlayer();
      _showSnack('${map.name} açıldı!');
    }

    if (!mounted) return;
    Navigator.of(context).pop(map);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        backgroundColor: isError ? QuestTheme.error : QuestTheme.surfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;

    return Scaffold(
      appBar: AppBar(title: const Text('ZİNDAN SEÇ')),
      backgroundColor: QuestTheme.background,
      body: player == null
          ? const Center(
              child: CircularProgressIndicator(color: QuestTheme.primary),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RetroWindow(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Sabah maceran için bir zindan seç. '
                        '(Seviye: ${player.level} · '
                        '🪙 ${player.gold} · 💎 ${player.diamonds})',
                        textAlign: TextAlign.center,
                        style: pixelTextStyle(
                          fontSize: 12,
                          color: QuestTheme.onSurfaceMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: StreamBuilder<List<GameMapDefinition>>(
                        stream: GameContentService.instance.watchMaps(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Haritalar yüklenemedi.\n${snapshot.error}',
                                style: pixelTextStyle(
                                  fontSize: 12,
                                  color: QuestTheme.error,
                                ),
                              ),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: QuestTheme.primary,
                              ),
                            );
                          }
                          final maps = snapshot.data!;
                          return ListView.separated(
                            itemCount: maps.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final map = maps[index];
                              final levelLocked =
                                  player.level < map.requiredLevel;
                              final needsPurchase = map.requiresPurchase &&
                                  !player.hasUnlockedMap(map.id);
                              final proLocked =
                                  map.isProOnly && !player.isPro;
                              return _MapCard(
                                map: map,
                                levelLocked: levelLocked,
                                needsPurchase: needsPurchase,
                                proLocked: proLocked,
                                onSelect: () => _onMapTap(map),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.map,
    required this.levelLocked,
    required this.needsPurchase,
    required this.proLocked,
    required this.onSelect,
  });

  final GameMapDefinition map;
  final bool levelLocked;
  final bool needsPurchase;
  final bool proLocked;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final locked = levelLocked || proLocked;
    final buttonLabel = proLocked
        ? 'PRO 🔒'
        : levelLocked
            ? 'KİLİTLİ'
            : needsPurchase
                ? 'SATIN AL'
                : 'SEÇ';

    return RetroWindow(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: PixelAssetImage(
                  imagePath: map.backgroundImagePath,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  placeholderSeed: map.id,
                ),
              ),
              if (proLocked)
                Container(
                  width: 72,
                  height: 72,
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: Text(
                    '🔒',
                    style: pixelTextStyle(fontSize: 28),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(map.name, style: pixelTextStyle(fontSize: 14)),
                if (map.isProOnly) ...[
                  const SizedBox(height: 2),
                  Text(
                    '👑 PRO ZİNDAN',
                    style: pixelTextStyle(
                      fontSize: 9,
                      color: const Color(0xFFFFD54F),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Min Lv ${map.requiredLevel} · ${map.monsterCount} canavar',
                  style: pixelTextStyle(
                    fontSize: 11,
                    color: QuestTheme.onSurfaceMuted,
                  ),
                ),
                if (map.requiresPurchase) ...[
                  const SizedBox(height: 4),
                  Text(
                    needsPurchase
                        ? 'Ücret: ${map.shopCurrency.formatPrice(map.unlockPrice)}'
                        : '✓ Açıldı',
                    style: pixelTextStyle(
                      fontSize: 10,
                      color: needsPurchase
                          ? (map.shopCurrency == ShopCurrency.diamond
                              ? const Color(0xFF88DDFF)
                              : QuestTheme.secondary)
                          : QuestTheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: RetroArcadeButton(
              label: buttonLabel,
              height: 40,
              fontSize: 11,
              backgroundColor: locked
                  ? QuestTheme.surfaceVariant
                  : needsPurchase
                      ? const Color(0xFF2A2840)
                      : QuestTheme.primary,
              foregroundColor: locked
                  ? QuestTheme.onSurfaceMuted
                  : QuestTheme.background,
              onPressed: onSelect,
            ),
          ),
        ],
      ),
    );
  }
}
