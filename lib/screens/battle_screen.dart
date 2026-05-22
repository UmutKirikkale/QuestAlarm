import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../theme/quest_theme.dart';

/// Alarm çaldığında açılan savaş ekranı — telefonu sallayarak canavarı yen.
class BattleScreen extends StatefulWidget {
  const BattleScreen({
    super.key,
    this.playerCurrentHP = 80,
    this.playerMaxHP = 100,
    this.damagePerShake = 10,
  });

  final int playerCurrentHP;
  final int playerMaxHP;
  final int damagePerShake;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  static const _dungeonBackground = Color(0xFF080810);
  static const _shakeThreshold = 15.0;
  static const _shakeCooldownMs = 600;

  static const int _monsterMaxHP = 100;
  static const int _victoryXP = 20;
  static const int _victoryGold = 50;

  int _monsterHP = _monsterMaxHP;
  bool _battleEnded = false;
  bool _showDamageFlash = false;
  String? _floatingDamageText;

  StreamSubscription<UserAccelerometerEvent>? _accelerometerSub;
  DateTime? _lastShakeTime;

  @override
  void initState() {
    super.initState();
    _startAccelerometer();
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    super.dispose();
  }

  void _startAccelerometer() {
    _accelerometerSub = userAccelerometerEvents.listen(_onAccelerometerEvent);
  }

  void _onAccelerometerEvent(UserAccelerometerEvent event) {
    if (_battleEnded) return;

    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    if (magnitude <= _shakeThreshold) return;

    final now = DateTime.now();
    if (_lastShakeTime != null &&
        now.difference(_lastShakeTime!).inMilliseconds < _shakeCooldownMs) {
      return;
    }
    _lastShakeTime = now;

    _dealDamage(widget.damagePerShake);
  }

  void _dealDamage(int amount) {
    if (_battleEnded) return;

    setState(() {
      _monsterHP = (_monsterHP - amount).clamp(0, _monsterMaxHP);
      _floatingDamageText = '-$amount';
      _showDamageFlash = true;
    });

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _showDamageFlash = false);
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _floatingDamageText = null);
    });

    if (_monsterHP <= 0) {
      _onVictory();
    }
  }

  Future<void> _onVictory() async {
    setState(() => _battleEnded = true);
    await _accelerometerSub?.cancel();
    _accelerometerSub = null;

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _VictoryDialog(
        xp: _victoryXP,
        gold: _victoryGold,
        onConfirm: () => Navigator.pop(dialogContext),
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dungeonBackground,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MonsterHpBar(
                    current: _monsterHP,
                    max: _monsterMaxHP,
                  ),
                  const Spacer(),
                  _MonsterDisplay(),
                  const Spacer(),
                  _PlayerHpBar(
                    current: widget.playerCurrentHP,
                    max: widget.playerMaxHP,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _battleEnded
                        ? 'SAVAŞ BİTTİ!'
                        : 'TELEFONU SALLA!',
                    textAlign: TextAlign.center,
                    style: _pixelTextStyle(
                      fontSize: 14,
                      color: QuestTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showDamageFlash)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  color: Colors.red.withValues(alpha: 0.35),
                ),
              ),
            ),
          if (_floatingDamageText != null)
            Center(
              child: IgnorePointer(
                child: Text(
                  _floatingDamageText!,
                  style: _pixelTextStyle(
                    fontSize: 48,
                    color: QuestTheme.error,
                    shadows: const [
                      Shadow(color: Colors.black, offset: Offset(3, 3)),
                      Shadow(color: Colors.white, offset: Offset(-2, -2)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Canavarın HP çubuğu — ekranın üst kısmında.
class _MonsterHpBar extends StatelessWidget {
  const _MonsterHpBar({
    required this.current,
    required this.max,
  });

  final int current;
  final int max;

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CANAVAR HP',
          style: _pixelTextStyle(fontSize: 12, color: QuestTheme.error),
        ),
        const SizedBox(height: 6),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A0A),
            border: Border.all(color: Colors.black, width: 4),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  color: const Color(0xFFCC2222),
                ),
              ),
              Center(
                child: Text(
                  '$current / $max',
                  style: _pixelTextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black, offset: Offset(2, 2)),
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

/// Ortadaki piksel canavar kutusu.
class _MonsterDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 160,
          height: 160,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF2A1A3A),
            border: Border.all(color: Colors.black, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF6A4A8A),
                offset: Offset(4, 4),
              ),
            ],
          ),
          child: Text(
            '(^_^)',
            style: _pixelTextStyle(
              fontSize: 40,
              color: const Color(0xFF88FF44),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: QuestTheme.surface,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Text(
            'Sabah Canavarı',
            style: _pixelTextStyle(
              fontSize: 16,
              color: QuestTheme.secondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '[ Slime ]',
          style: _pixelTextStyle(
            fontSize: 12,
            color: QuestTheme.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}

/// Oyuncunun HP çubuğu — ekranın alt kısmında.
class _PlayerHpBar extends StatelessWidget {
  const _PlayerHpBar({
    required this.current,
    required this.max,
  });

  final int current;
  final int max;

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SENİN HP',
          style: _pixelTextStyle(fontSize: 12, color: QuestTheme.primary),
        ),
        const SizedBox(height: 6),
        Container(
          height: 28,
          decoration: BoxDecoration(
            color: QuestTheme.surfaceVariant,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(color: const Color(0xFF39FF14)),
              ),
              Center(
                child: Text(
                  '$current / $max',
                  style: _pixelTextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Zafer sonrası retro ödül diyalog kutusu.
class _VictoryDialog extends StatelessWidget {
  const _VictoryDialog({
    required this.xp,
    required this.gold,
    required this.onConfirm,
  });

  final int xp;
  final int gold;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: QuestTheme.surface,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ZAFER!',
              style: _pixelTextStyle(
                fontSize: 28,
                color: QuestTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '+$xp XP',
              style: _pixelTextStyle(
                fontSize: 18,
                color: const Color(0xFF4488FF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+$gold Altın',
              style: _pixelTextStyle(
                fontSize: 18,
                color: QuestTheme.secondary,
              ),
            ),
            const SizedBox(height: 24),
            _VictoryOkButton(onPressed: onConfirm),
          ],
        ),
      ),
    );
  }
}

class _VictoryOkButton extends StatefulWidget {
  const _VictoryOkButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_VictoryOkButton> createState() => _VictoryOkButtonState();
}

class _VictoryOkButtonState extends State<_VictoryOkButton> {
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
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: QuestTheme.primary,
            border: Border.all(color: Colors.black, width: 3),
          ),
          alignment: Alignment.center,
          child: Text(
            'TAMAM',
            style: _pixelTextStyle(
              fontSize: 16,
              color: QuestTheme.background,
            ),
          ),
        ),
      ),
    );
  }
}

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
