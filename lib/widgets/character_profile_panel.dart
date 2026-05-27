import 'package:flutter/material.dart';

import '../models/equipped_item.dart';
import '../models/player.dart';
import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';
import 'retro_window.dart';

/// Orta panel — sınıfa göre avatar silüeti ve ekipman durumu.
class CharacterProfilePanel extends StatelessWidget {
  const CharacterProfilePanel({
    super.key,
    required this.player,
  });

  final Player player;

  @override
  Widget build(BuildContext context) {
    return RetroWindow(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Text(
            '── KAHRAMAN ──',
            style: pixelTextStyle(
              fontSize: 11,
              color: QuestTheme.onSurfaceMuted,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: _ClassAvatar(characterClass: player.characterClass),
            ),
          ),
          const SizedBox(height: 8),
          _EquipmentStatus(weapon: player.equippedWeapon),
        ],
      ),
    );
  }
}

class _ClassAvatar extends StatelessWidget {
  const _ClassAvatar({required this.characterClass});

  final CharacterClass characterClass;

  @override
  Widget build(BuildContext context) {
    final (primary, secondary, label) = switch (characterClass) {
      CharacterClass.warrior => ('🛡️', '⚔️', 'SAVAŞÇI'),
      CharacterClass.mage => ('🧙', '✨', 'BÜYÜCÜ'),
      CharacterClass.rogue => ('🗡️', '🌑', 'HIRSIZ'),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF080818),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 18,
                child: Text(primary, style: const TextStyle(fontSize: 44)),
              ),
              Positioned(
                bottom: 14,
                right: 22,
                child: Text(secondary, style: const TextStyle(fontSize: 28)),
              ),
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: Container(
                  height: 24,
                  color: const Color(0xFF1A2840),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: pixelTextStyle(
                      fontSize: 9,
                      color: QuestTheme.primary,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        CustomPaint(
          size: const Size(100, 8),
          painter: _PixelPlatformPainter(),
        ),
      ],
    );
  }
}

class _EquipmentStatus extends StatelessWidget {
  const _EquipmentStatus({this.weapon});

  final EquippedItem? weapon;

  @override
  Widget build(BuildContext context) {
    if (weapon == null) {
      return Text(
        'SİLAHSIZ',
        style: pixelTextStyle(fontSize: 12, color: QuestTheme.onSurfaceMuted),
      );
    }

    final durability = weapon!.durability;
    final status = _durabilityStatus(durability);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1020),
            border: Border.all(color: const Color(0xFF505060), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '⚔ ${weapon!.item.name}',
                  style: pixelTextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'DMG +${weapon!.item.bonusDamage}',
                style: pixelTextStyle(
                  fontSize: 10,
                  color: QuestTheme.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DAYANIK: %$durability',
              style: pixelTextStyle(
                fontSize: 10,
                color: status.color,
              ),
            ),
            Text(
              status.label,
              style: pixelTextStyle(
                fontSize: 10,
                color: status.color,
                shadows: [
                  Shadow(color: status.color.withValues(alpha: 0.4)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  ({String label, Color color}) _durabilityStatus(int durability) {
    if (durability > 50) {
      return (label: 'DURUM: SAĞLAM', color: QuestTheme.primary);
    }
    if (durability > 25) {
      return (label: 'DURUM: AŞINMIŞ', color: QuestTheme.secondary);
    }
    return (label: 'DURUM: KRİTİK', color: QuestTheme.error);
  }
}

/// Avatar altında piksel platform çizgisi.
class _PixelPlatformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF384860);
    const step = 8.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawRect(Rect.fromLTWH(x, 0, step - 1, size.height), paint);
      x += step;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
