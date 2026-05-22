import 'package:flutter/material.dart';

import '../models/player.dart';
import '../theme/quest_theme.dart';
import '../services/alarm_service.dart';
import 'shop_screen.dart';

/// Uygulamanın ana menüsü — karakter durumu ve hızlı erişim butonları.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Arayüzü test etmek için kullanılan sahte oyuncu verisi.
  static final Player _mockPlayer = Player(
    level: 1,
    currentXP: 30,
    nextLevelXP: 100,
    currentHP: 80,
    maxHP: 100,
    gold: 150,
    characterClass: CharacterClass.warrior,
  );

  @override
  Widget build(BuildContext context) {
    final player = _mockPlayer;

    return Scaffold(
      backgroundColor: QuestTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CharacterHeader(player: player),
              const SizedBox(height: 32),
              _RetroProgressBar(
                label: 'CAN (HP)',
                current: player.currentHP,
                max: player.maxHP,
                fillColor: const Color(0xFF39FF14),
                fillColorLow: const Color(0xFFFF4444),
                lowThreshold: 0.3,
              ),
              const SizedBox(height: 20),
              _RetroProgressBar(
                label: 'TECRÜBE (XP)',
                current: player.currentXP,
                max: player.nextLevelXP,
                fillColor: const Color(0xFF4488FF),
              ),
              const SizedBox(height: 28),
              _GoldDisplay(gold: player.gold),
              const Spacer(),
              _RetroPixelButton(
                label: 'ALARM KUR',
                onPressed: () => _scheduleAlarm(context),
              ),
              const SizedBox(height: 12),
              _RetroPixelButton(
                label: 'MAĞAZA',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ShopScreen(gold: player.gold),
                    ),
                  );
                },
                backgroundColor: QuestTheme.surfaceVariant,
                foregroundColor: QuestTheme.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Karakter sınıfı ve seviye bilgisini gösteren üst başlık kutusu.
class _CharacterHeader extends StatelessWidget {
  const _CharacterHeader({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: QuestTheme.surface,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Sınıf: ${_classLabel(player.characterClass)}',
            style: _pixelTextStyle(fontSize: 14),
          ),
          Text(
            'Seviye: ${player.level}',
            style: _pixelTextStyle(fontSize: 14, color: QuestTheme.primary),
          ),
        ],
      ),
    );
  }

  String _classLabel(CharacterClass characterClass) {
    return switch (characterClass) {
      CharacterClass.warrior => 'Savaşçı',
      CharacterClass.mage => 'Büyücü',
      CharacterClass.rogue => 'Hırsız',
    };
  }
}

/// Kalın kenarlıklı retro ilerleme çubuğu (HP, XP vb.).
class _RetroProgressBar extends StatelessWidget {
  const _RetroProgressBar({
    required this.label,
    required this.current,
    required this.max,
    required this.fillColor,
    this.fillColorLow,
    this.lowThreshold = 0.0,
  });

  final String label;
  final int current;
  final int max;
  final Color fillColor;
  final Color? fillColorLow;
  final double lowThreshold;

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final isLow = fillColorLow != null && ratio <= lowThreshold;
    final activeFill = isLow ? fillColorLow! : fillColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _pixelTextStyle(fontSize: 12, color: QuestTheme.onSurfaceMuted),
        ),
        const SizedBox(height: 6),
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: QuestTheme.surfaceVariant,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(color: activeFill),
              ),
              Center(
                child: Text(
                  '$current / $max',
                  style: _pixelTextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black, offset: Offset(1, 1)),
                      Shadow(color: Colors.black, offset: Offset(-1, -1)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Toplam altın miktarını gösteren sarı/altın tonlu piksel kutusu.
class _GoldDisplay extends StatelessWidget {
  const _GoldDisplay({required this.gold});

  final int gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3200),
        border: Border.all(color: QuestTheme.secondary, width: 3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ALTIN',
            style: _pixelTextStyle(
              fontSize: 14,
              color: const Color(0xFFB8860B),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$gold G',
            style: _pixelTextStyle(
              fontSize: 18,
              color: QuestTheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Basıldığında içeri göçen retro piksel buton.
class _RetroPixelButton extends StatefulWidget {
  const _RetroPixelButton({
    required this.label,
    required this.onPressed,
    this.backgroundColor = QuestTheme.primary,
    this.foregroundColor = QuestTheme.background,
  });

  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  State<_RetroPixelButton> createState() => _RetroPixelButtonState();
}

class _RetroPixelButtonState extends State<_RetroPixelButton> {
  bool _isPressed = false;

  static const _borderWidth = 3.0;
  static const _pressOffset = 3.0;

  @override
  Widget build(BuildContext context) {
    final offset = _isPressed ? _pressOffset : 0.0;

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
          height: 52,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            border: Border.all(color: Colors.white, width: _borderWidth),
            boxShadow: _isPressed
                ? null
                : const [
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(_pressOffset, _pressOffset),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: _pixelTextStyle(
              fontSize: 16,
              color: widget.foregroundColor,
            ),
          ),
        ),
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
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Alarm kurulamadı: $e',
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        backgroundColor: QuestTheme.error,
      ),
    );
  }
}

/// Retro arayüz için ortak monospace metin stili.
TextStyle _pixelTextStyle({
  required double fontSize,
  Color color = QuestTheme.onBackground,
  List<Shadow>? shadows,
}) {
  return TextStyle(
    fontFamily: 'monospace',
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    color: color,
    letterSpacing: 1,
    shadows: shadows,
  );
}
