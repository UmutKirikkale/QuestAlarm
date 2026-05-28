import 'dart:async';

import 'package:flutter/material.dart';

import '../models/equipped_item.dart';
import '../models/item.dart';
import '../models/shop_currency.dart';
import '../services/analytics_service.dart';
import '../services/global_settings_service.dart';
import '../services/live_log_service.dart';
import '../services/game_content_service.dart';
import '../services/player_service.dart';
import 'diamond_shop_screen.dart';
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
  int _diamonds = 0;
  int _playerLevel = 1;
  EquippedItem? _weapon;
  EquippedItem? _armor;
  bool _isPro = false;
  bool _loading = true;

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
      _diamonds = player.diamonds;
      _playerLevel = player.level;
      _weapon = player.equippedWeapon;
      _armor = player.equippedArmor;
      _isPro = player.isPro;
      _loading = false;
    });
  }

  Future<void> _repairEquipment({required bool weapon}) async {
    final result =
        await PlayerService.instance.repairEquipment(repairWeapon: weapon);
    if (!result.success) {
      final msg = switch (result.failure) {
        PurchaseFailure.insufficientGold => 'Tamir için yetersiz altın!',
        PurchaseFailure.nothingToRepair => 'Tamir gerekmiyor.',
        _ => 'Tamir başarısız',
      };
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontFamily: 'monospace')),
          backgroundColor: QuestTheme.error,
        ),
      );
      return;
    }
    await _loadGold();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ekipman tamir edildi!')),
    );
  }

  Future<void> _buyItem(Item item) async {
    final result = await PlayerService.instance.purchaseItem(item);
    if (!result.success) {
      final msg = switch (result.failure) {
        PurchaseFailure.levelTooLow =>
          'Seviye yetersiz! (Gerekli: Lv ${item.requiredLevel})',
        PurchaseFailure.insufficientGold =>
          'Yetersiz altın! (${item.shopCurrency.formatPrice(item.price)} gerekli)',
        PurchaseFailure.insufficientDiamonds =>
          'Yetersiz elmas! (${item.shopCurrency.formatPrice(item.price)} gerekli)',
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
      _diamonds = player.diamonds;
      _playerLevel = player.level;
    });

    unawaited(
      AnalyticsService.instance.logItemBought(
        itemName: item.name,
        price: item.price,
      ),
    );
    unawaited(LiveLogService.instance.logItemPurchased(itemName: item.name));

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
                const SizedBox(height: 8),
                _DiamondBanner(
                  diamonds: _diamonds,
                  onTap: () async {
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const DiamondShopScreen(),
                      ),
                    );
                    await _loadGold();
                  },
                ),
                const SizedBox(height: 12),
                StreamBuilder(
                  stream: GlobalSettingsService.instance.watchSettings(),
                  builder: (context, _) {
                    return _RepairPanel(
                      weapon: _weapon,
                      armor: _armor,
                      gold: _gold,
                      isPro: _isPro,
                      onRepairWeapon: () => _repairEquipment(weapon: true),
                      onRepairArmor: () => _repairEquipment(weapon: false),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<List<Item>>(
                    stream: GameContentService.instance.watchShopItems(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Mağaza yüklenemedi.\n${snapshot.error}',
                            style: pixelTextStyle(
                              fontSize: 12,
                              color: QuestTheme.error,
                            ),
                            textAlign: TextAlign.center,
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
                      final items = snapshot.data!;
                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ShopItemCard(
                              item: item,
                              playerLevel: _playerLevel,
                              onBuy: () => _buyItem(item),
                            ),
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
      ),
    );
  }
}

class _RepairPanel extends StatelessWidget {
  const _RepairPanel({
    required this.weapon,
    required this.armor,
    required this.gold,
    required this.isPro,
    required this.onRepairWeapon,
    required this.onRepairArmor,
  });

  final EquippedItem? weapon;
  final EquippedItem? armor;
  final int gold;
  final bool isPro;
  final VoidCallback onRepairWeapon;
  final VoidCallback onRepairArmor;

  @override
  Widget build(BuildContext context) {
    final ps = PlayerService.instance;
    final weaponCost = ps.repairCostForEquipped(weapon, isPro: isPro);
    final armorCost = ps.repairCostForEquipped(armor, isPro: isPro);

    if (weapon == null && armor == null) return const SizedBox.shrink();
    if (weaponCost <= 0 && armorCost <= 0) return const SizedBox.shrink();

    return RetroWindow(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '🔧 TAMİRHANE',
            style: pixelTextStyle(fontSize: 12, color: QuestTheme.primary),
          ),
          const SizedBox(height: 8),
          if (weapon != null && weaponCost > 0)
            _RepairRow(
              label: '⚔ ${weapon!.item.name} (%${weapon!.durability})',
              cost: weaponCost,
              canAfford: gold >= weaponCost,
              onRepair: onRepairWeapon,
            ),
          if (armor != null && armorCost > 0) ...[
            if (weapon != null && weaponCost > 0) const SizedBox(height: 8),
            _RepairRow(
              label: '🛡 Zırh (%${armor!.durability})',
              cost: armorCost,
              canAfford: gold >= armorCost,
              onRepair: onRepairArmor,
            ),
          ],
        ],
      ),
    );
  }
}

class _RepairRow extends StatelessWidget {
  const _RepairRow({
    required this.label,
    required this.cost,
    required this.canAfford,
    required this.onRepair,
  });

  final String label;
  final int cost;
  final bool canAfford;
  final VoidCallback onRepair;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: pixelTextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$cost G',
          style: pixelTextStyle(
            fontSize: 11,
            color: canAfford ? QuestTheme.secondary : QuestTheme.error,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          height: 36,
          child: RetroArcadeButton(
            label: 'TAMİR',
            height: 36,
            fontSize: 10,
            onPressed: canAfford ? onRepair : () {},
            backgroundColor:
                canAfford ? QuestTheme.primary : QuestTheme.surfaceVariant,
            foregroundColor:
                canAfford ? QuestTheme.background : QuestTheme.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}

class _DiamondBanner extends StatelessWidget {
  const _DiamondBanner({
    required this.diamonds,
    required this.onTap,
  });

  final int diamonds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0D1A33),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Text('💎', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ELMAS: $diamonds',
                  style: pixelTextStyle(
                    fontSize: 13,
                    color: const Color(0xFF4FB2FF),
                  ),
                ),
              ),
              Text(
                'ELMAS MAĞAZASI →',
                style: pixelTextStyle(
                  fontSize: 10,
                  color: QuestTheme.onSurfaceMuted,
                ),
              ),
            ],
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
                  item.shopCurrency.formatPrice(item.price),
                  style: pixelTextStyle(
                    fontSize: 11,
                    color: item.shopCurrency == ShopCurrency.diamond
                        ? const Color(0xFF88DDFF)
                        : QuestTheme.secondary,
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
