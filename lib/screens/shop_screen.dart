import 'dart:async';

import 'package:flutter/material.dart';

import '../models/item.dart';
import '../services/analytics_service.dart';
import '../services/player_service.dart';
import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';
import '../widgets/pixel_asset_image.dart';
import '../widgets/retro_arcade_button.dart';
import '../widgets/retro_stat_bar.dart';
import '../widgets/retro_window.dart';

/// Altın harcanarak eşya alınan retro piksel mağaza ekranı.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _gold = 0;
  int _playerLevel = 1;
  bool _loading = true;

  static const List<Item> _shopItems = [
    Item(
      id: 'rusty_sword',
      name: 'Paslı Kılıç',
      price: 50,
      bonusDamage: 10,
      itemType: ItemType.weapon,
      rarity: ItemRarity.common,
      requiredLevel: 1,
      criticalChance: 0.05,
      imagePath: 'assets/images/items/sword.png',
    ),
    Item(
      id: 'iron_armor',
      name: 'Demir Zırh',
      price: 100,
      bonusDefense: 5,
      itemType: ItemType.armor,
      rarity: ItemRarity.common,
      requiredLevel: 2,
      imagePath: 'assets/images/items/iron_armor.png',
    ),
    Item(
      id: 'health_potion',
      name: 'Can İksiri',
      price: 20,
      itemType: ItemType.potion,
      rarity: ItemRarity.common,
      requiredLevel: 1,
      imagePath: 'assets/images/items/health_potion.png',
    ),
    Item(
      id: 'steel_blade',
      name: 'Çelik Bıçak',
      price: 120,
      bonusDamage: 18,
      itemType: ItemType.weapon,
      rarity: ItemRarity.rare,
      requiredLevel: 3,
      criticalChance: 0.12,
      imagePath: 'assets/images/items/steel_blade.png',
    ),
    Item(
      id: 'moon_katana',
      name: 'Ay Katanası',
      price: 170,
      bonusDamage: 26,
      itemType: ItemType.weapon,
      rarity: ItemRarity.epic,
      requiredLevel: 5,
      criticalChance: 0.25,
      imagePath: 'assets/images/items/steel_blade.png',
    ),
    Item(
      id: 'titan_mail',
      name: 'Titan Zırhı',
      price: 200,
      bonusDefense: 14,
      itemType: ItemType.armor,
      rarity: ItemRarity.epic,
      requiredLevel: 6,
      imagePath: 'assets/images/items/iron_armor.png',
    ),
    Item(
      id: 'elixir',
      name: 'Büyük İksir',
      price: 75,
      itemType: ItemType.potion,
      rarity: ItemRarity.rare,
      requiredLevel: 4,
      imagePath: 'assets/images/items/health_potion.png',
    ),
    Item(
      id: 'storm_spear',
      name: 'Fırtına Mızrağı',
      price: 240,
      bonusDamage: 34,
      itemType: ItemType.weapon,
      rarity: ItemRarity.legendary,
      requiredLevel: 8,
      criticalChance: 0.25,
      imagePath: 'assets/images/items/sword.png',
    ),
    Item(
      id: 'shadow_cloak',
      name: 'Gölge Pelerini',
      price: 155,
      bonusDefense: 11,
      itemType: ItemType.armor,
      rarity: ItemRarity.rare,
      requiredLevel: 4,
      imagePath: 'assets/images/items/iron_armor.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadGold());
  }

  Future<void> _loadGold() async {
    final player = await PlayerService.instance.loadPlayer();
    if (!mounted) return;
    setState(() {
      _gold = player.gold;
      _playerLevel = player.level;
      _loading = false;
    });
  }

  Future<void> _buyItem(Item item) async {
    final result = await PlayerService.instance.purchaseItem(item);
    if (!result.success) {
      final msg = switch (result.failure) {
        PurchaseFailure.levelTooLow =>
          'Seviye yetersiz! (Gerekli: Lv ${item.requiredLevel})',
        PurchaseFailure.insufficientGold =>
          'Yetersiz altın! (${item.price} G gerekli)',
        _ => 'Satın alma başarısız',
      };
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          backgroundColor: QuestTheme.error,
        ),
      );
      return;
    }

    final player = await PlayerService.instance.loadPlayer();
    setState(() {
      _gold = player.gold;
      _playerLevel = player.level;
    });

    unawaited(
      AnalyticsService.instance.logItemBought(
        itemName: item.name,
        price: item.price,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${item.name} satın alındı!',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: QuestTheme.surfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: QuestTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: QuestTheme.primary),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('MAĞAZA')),
      backgroundColor: QuestTheme.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF060610), Color(0xFF0D0D18)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ShopHeader(gold: _gold),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _shopItems.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ShopItemCard(
                          item: _shopItems[index],
                          playerLevel: _playerLevel,
                          onBuy: () => _buyItem(_shopItems[index]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({required this.gold});

  final int gold;

  @override
  Widget build(BuildContext context) {
    return RetroWindow(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '🏪 PİKSEL MAĞAZA',
            textAlign: TextAlign.center,
            style: pixelTextStyle(
              fontSize: 16,
              color: QuestTheme.primary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          RetroGoldCounter(gold: gold),
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.playerLevel,
    required this.onBuy,
  });

  final Item item;
  final int playerLevel;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final levelLocked = playerLevel < item.requiredLevel;
    return RetroWindow(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PixelAssetImage(
            imagePath: item.imagePath,
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            placeholderSeed: item.id,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.name, style: pixelTextStyle(fontSize: 14)),
                    ),
                    _RarityBadge(rarity: item.rarity),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _itemSubtitle(item),
                  style: pixelTextStyle(
                    fontSize: 11,
                    color: QuestTheme.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gereken Seviye: Lv ${item.requiredLevel}',
                  style: pixelTextStyle(
                    fontSize: 10,
                    color: levelLocked
                        ? QuestTheme.error
                        : QuestTheme.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.price} G',
                  style: pixelTextStyle(
                    fontSize: 11,
                    color: QuestTheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 88,
            child: RetroArcadeButton(
              label: levelLocked ? 'KİLİTLİ' : 'AL',
              height: 40,
              fontSize: 12,
              backgroundColor:
                  levelLocked ? QuestTheme.surfaceVariant : QuestTheme.primary,
              foregroundColor:
                  levelLocked ? QuestTheme.onSurfaceMuted : QuestTheme.background,
              onPressed: onBuy,
            ),
          ),
        ],
      ),
    );
  }

  String _itemSubtitle(Item item) {
    return switch (item.itemType) {
      ItemType.weapon => 'Hasar +${item.bonusDamage}',
      ItemType.armor => 'Savunma +${item.bonusDefense}',
      ItemType.potion => 'Can yeniler',
    };
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({required this.rarity});

  final ItemRarity rarity;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (rarity) {
      ItemRarity.common => ('COMMON', const Color(0xFF9AA3B2)),
      ItemRarity.rare => ('RARE', const Color(0xFF4FB2FF)),
      ItemRarity.epic => ('EPIC', const Color(0xFFC46BFF)),
      ItemRarity.legendary => ('LEGEND', const Color(0xFFFFB347)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: pixelTextStyle(
          fontSize: 8,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
