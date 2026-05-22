import 'package:flutter/material.dart';

import '../models/item.dart';
import '../theme/quest_theme.dart';

/// Altın harcanarak eşya alınan retro piksel mağaza ekranı.
class ShopScreen extends StatelessWidget {
  const ShopScreen({
    super.key,
    this.gold = 150,
  });

  /// Oyuncunun mevcut altın miktarı (şimdilik mock).
  final int gold;

  /// Mağazada listelenecek sahte eşyalar.
  static const List<Item> _mockItems = [
    Item(
      id: 'rusty_sword',
      name: 'Paslı Kılıç',
      price: 50,
      bonusDamage: 10,
      itemType: ItemType.weapon,
    ),
    Item(
      id: 'iron_armor',
      name: 'Demir Zırh',
      price: 100,
      bonusDefense: 5,
      itemType: ItemType.armor,
    ),
    Item(
      id: 'health_potion',
      name: 'Can İksiri',
      price: 20,
      itemType: ItemType.potion,
    ),
    Item(
      id: 'steel_blade',
      name: 'Çelik Bıçak',
      price: 120,
      bonusDamage: 18,
      itemType: ItemType.weapon,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuestTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ShopHeader(gold: gold),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _mockItems.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShopItemCard(
                      item: _mockItems[index],
                      onBuy: () {
                        // Satın alma mantığı ileride eklenecek.
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Geri butonu, başlık ve altın göstergesini içeren üst bar.
class _ShopHeader extends StatelessWidget {
  const _ShopHeader({required this.gold});

  final int gold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _RetroBackButton(
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: QuestTheme.surface,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'PİKSEL MAĞAZA',
                    style: _pixelTextStyle(
                      fontSize: 18,
                      color: QuestTheme.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D3200),
                    border: Border.all(color: QuestTheme.secondary, width: 2),
                  ),
                  child: Text(
                    '$gold G',
                    style: _pixelTextStyle(
                      fontSize: 14,
                      color: QuestTheme.secondary,
                    ),
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

/// Tek bir eşyayı gösteren retro menü kutusu kartı.
class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.onBuy,
  });

  final Item item;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: QuestTheme.surface,
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: _pixelTextStyle(fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  _itemSubtitle(item),
                  style: _pixelTextStyle(
                    fontSize: 12,
                    color: QuestTheme.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fiyat: ${item.price} G',
                  style: _pixelTextStyle(
                    fontSize: 12,
                    color: QuestTheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _BuyButton(onPressed: onBuy),
        ],
      ),
    );
  }

  String _itemSubtitle(Item item) {
    return switch (item.itemType) {
      ItemType.weapon => 'Hasar: +${item.bonusDamage}',
      ItemType.armor => 'Savunma: +${item.bonusDefense}',
      ItemType.potion => 'Can yeniler',
    };
  }
}

/// "< GERİ" retro geri dönüş butonu.
class _RetroBackButton extends StatefulWidget {
  const _RetroBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_RetroBackButton> createState() => _RetroBackButtonState();
}

class _RetroBackButtonState extends State<_RetroBackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final offset = _isPressed ? 2.0 : 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Transform.translate(
        offset: Offset(offset, offset),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: QuestTheme.surfaceVariant,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Text(
            '< GERİ',
            style: _pixelTextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }
}

/// Eşya kartındaki "SATIN AL" piksel butonu.
class _BuyButton extends StatefulWidget {
  const _BuyButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_BuyButton> createState() => _BuyButtonState();
}

class _BuyButtonState extends State<_BuyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final offset = _isPressed ? 2.0 : 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Transform.translate(
        offset: Offset(offset, offset),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: QuestTheme.primary,
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: _isPressed
                ? null
                : const [
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(2, 2),
                    ),
                  ],
          ),
          child: Text(
            'SATIN\nAL',
            textAlign: TextAlign.center,
            style: _pixelTextStyle(
              fontSize: 11,
              color: QuestTheme.background,
            ),
          ),
        ),
      ),
    );
  }
}

/// Retro arayüz için ortak monospace metin stili.
TextStyle _pixelTextStyle({
  required double fontSize,
  Color color = QuestTheme.onBackground,
}) {
  return TextStyle(
    fontFamily: 'monospace',
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    color: color,
    letterSpacing: 1,
  );
}
