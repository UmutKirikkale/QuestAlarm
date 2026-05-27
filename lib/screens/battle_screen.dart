import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/monster.dart';
import '../models/battle_summary.dart';
import '../models/player.dart';
import '../services/analytics_service.dart';
import '../services/app_settings_service.dart';
import '../services/battle_summary_service.dart';
import '../services/player_service.dart';
import '../services/widget_service.dart';
import '../theme/quest_theme.dart';
import '../widgets/pixel_asset_image.dart';

const _hitSoundAsset = 'audio/hit.mp3';

enum _RuneShape { z, triangle, circle }

/// Ekranda süzülen tek bir hasar yazısı kaydı.
class _FloatingDamageEntry {
  _FloatingDamageEntry({
    required this.id,
    required this.amount,
    required this.offsetX,
    required this.isCritical,
  });

  final int id;
  final int amount;
  final double offsetX;
  final bool isCritical;
}

/// Alarm çaldığında açılan savaş ekranı — telefonu sallayarak canavarı yen.
class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  static const _dungeonBackground = Color(0xFF080810);
  static const _shakeThreshold = 15.0;
  static const _shakeCooldownMs = 600;
  static const _normalBattleTimeout = Duration(minutes: 2);
  static const _bossBattleTimeout = Duration(minutes: 4);

  final AudioPlayer _hitPlayer = AudioPlayer();
  final Random _random = Random();
  Monster _monster = Monster.forPlayerLevel(1, Random());

  int _monsterHP = 50;
  bool _battleEnded = false;
  bool _showDamageFlash = false;
  int _combatShakeKey = 0;
  int _nextDamageId = 0;
  int _playerCurrentHP = 100;
  int _playerMaxHP = 100;
  int _equippedWeaponDamage = 0;
  double _criticalChance = 0.0;
  bool _isMage = false;
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  _RuneShape _currentRune = _RuneShape.z;
  final List<Offset> _drawnRunePoints = [];
  Size _runeAreaSize = const Size(1, 1);
  String _combatHint = 'TELEFONU SALLA!';
  Color _flashColor = Colors.red;

  final List<_FloatingDamageEntry> _floatingDamages = [];

  StreamSubscription<UserAccelerometerEvent>? _accelerometerSub;
  Timer? _battleTimeout;
  DateTime? _lastShakeTime;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPlayerStats());
  }

  Future<void> _loadPlayerStats() async {
    final player = await PlayerService.instance.loadPlayer();
    final monster = Monster.forPlayerLevel(player.level, _random);
    _battleTimeout = Timer(
      monster.isBoss ? _bossBattleTimeout : _normalBattleTimeout,
      () {
        if (!_battleEnded) {
          unawaited(_onDefeat('Süre doldu — telefonu sallamadın!'));
        }
      },
    );

    if (!mounted) return;
    setState(() {
      _isMage = player.characterClass == CharacterClass.mage;
      _playerCurrentHP = player.currentHP;
      _playerMaxHP = player.maxHP;
      _equippedWeaponDamage = player.equippedWeapon?.item.bonusDamage ?? 0;
      _criticalChance = player.equippedWeapon?.item.criticalChance ?? 0.0;
      _monster = monster;
      _monsterHP = monster.currentHP;
      _combatHint = _isMage ? 'RÜNÜ ÇİZ VE BÜYÜYÜ SERBEST BIRAK!' : 'KILICINI SALLA!';
      if (_isMage) {
        _currentRune = _RuneShape.values[_random.nextInt(_RuneShape.values.length)];
      }
    });

    final settings = await AppSettingsService.instance.loadSettings();
    if (!mounted) return;
    setState(() {
      _soundEnabled = settings.soundEnabled;
      _hapticEnabled = settings.hapticEnabled;
    });

    if (!_isMage) {
      _startAccelerometer();
    }
  }

  @override
  void dispose() {
    _battleTimeout?.cancel();
    _accelerometerSub?.cancel();
    _hitPlayer.dispose();
    super.dispose();
  }

  void _startAccelerometer() {
    _accelerometerSub =
        userAccelerometerEventStream().listen(_onAccelerometerEvent);
  }

  void _onAccelerometerEvent(UserAccelerometerEvent event) {
    if (_battleEnded || _isMage) return;

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

    final baseDamage = 10 + _equippedWeaponDamage;
    final isCritical = _random.nextDouble() <= _criticalChance;
    final damage = isCritical ? baseDamage * 2 : baseDamage;
    _dealDamage(damage, isCritical: isCritical);
  }

  Future<void> _playHitFeedback() async {
    unawaited(_triggerHeavyHaptic());
    unawaited(_playHitSound(playbackRate: 1.0));
  }

  Future<void> _playCriticalFeedback() async {
    unawaited(_triggerCriticalHaptic());
    unawaited(_playHitSound(playbackRate: 1.35));
  }

  Future<void> _triggerHeavyHaptic() async {
    if (!_hapticEnabled) return;
    try {
      if (await Haptics.canVibrate()) {
        await Haptics.vibrate(HapticsType.heavy);
      }
    } catch (e) {
      debugPrint('BattleScreen haptic: $e');
    }
  }

  Future<void> _triggerCriticalHaptic() async {
    if (!_hapticEnabled) return;
    try {
      if (await Haptics.canVibrate()) {
        await Haptics.vibrate(HapticsType.heavy);
        await Future<void>.delayed(const Duration(milliseconds: 45));
        await Haptics.vibrate(HapticsType.selection);
      }
    } catch (e) {
      debugPrint('BattleScreen critical haptic: $e');
    }
  }

  Future<void> _playHitSound({double playbackRate = 1.0}) async {
    if (!_soundEnabled) return;
    try {
      await _hitPlayer.stop();
      await _hitPlayer.setPlaybackRate(playbackRate);
      await _hitPlayer.play(AssetSource(_hitSoundAsset));
    } catch (e) {
      debugPrint('BattleScreen hit sound ($_hitSoundAsset): $e');
    }
  }

  void _removeFloatingDamage(int id) {
    if (!mounted) return;
    setState(() => _floatingDamages.removeWhere((e) => e.id == id));
  }

  void _dealDamage(
    int amount, {
    required bool isCritical,
    bool skipFeedback = false,
  }) {
    if (_battleEnded) return;

    if (!skipFeedback) {
      if (isCritical) {
        unawaited(_playCriticalFeedback());
      } else {
        unawaited(_playHitFeedback());
      }
    }

    setState(() {
      _monsterHP = (_monsterHP - amount).clamp(0, _monster.maxHP);
      _flashColor = isCritical ? const Color(0xFFFFD54F) : Colors.red;
      _showDamageFlash = true;
      _combatShakeKey++;
      _floatingDamages.add(
        _FloatingDamageEntry(
          id: _nextDamageId++,
          amount: amount,
          offsetX: (_random.nextDouble() - 0.5) * 56,
          isCritical: isCritical,
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _showDamageFlash = false);
    });

    if (_monsterHP <= 0) {
      _onVictory();
    }
  }

  Future<void> _onVictory() async {
    if (_battleEnded) return;
    setState(() => _battleEnded = true);
    _battleTimeout?.cancel();
    await _accelerometerSub?.cancel();
    _accelerometerSub = null;

    final streakBefore = (await PlayerService.instance.loadPlayer()).streak;
    final reward = await PlayerService.instance.applyVictory(
      baseXp: _monster.rewardXP,
      baseGold: _monster.rewardGold,
      extraMultiplier: _monster.isBoss ? 3.0 : 1.0,
      monsterName: _monster.name,
    );
    await BattleSummaryService.instance.save(
      BattleSummary(
        outcome: BattleOutcome.victory,
        monsterName: _monster.name,
        streakBefore: streakBefore,
        streakAfter: reward.newStreak,
        gainedXp: reward.xp,
        gainedGold: reward.gold,
        timestampIso: DateTime.now().toIso8601String(),
      ),
    );

    unawaited(
      AnalyticsService.instance.logMonsterDefeated(
        gainedXp: reward.xp,
        gainedGold: reward.gold,
      ),
    );
    unawaited(
      WidgetService.instance.updateLiveWidget(status: LiveWidgetStatus.happy),
    );

    if (!mounted) return;

    final bonusLabel = reward.multiplier > 1
        ? '\n(Seri x${reward.multiplier.toStringAsFixed(1)} bonus!)'
        : '';
    final monsterLine = _monster.isBoss
        ? 'PAZAR BOSSU YENILDI: ${_monster.name}\n'
        : '${_monster.name} yenildi.\n';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _VictoryDialog(
        xp: reward.xp,
        gold: reward.gold,
        streak: reward.newStreak,
        bonusLabel: '$monsterLine$bonusLabel',
        onConfirm: () => Navigator.pop(dialogContext),
      ),
    );

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _onDefeat(String reason) async {
    if (_battleEnded) return;
    setState(() => _battleEnded = true);
    _battleTimeout?.cancel();
    await _accelerometerSub?.cancel();
    _accelerometerSub = null;

    final streakBefore = (await PlayerService.instance.loadPlayer()).streak;
    final penalty = await PlayerService.instance.applyDefeat();
    await BattleSummaryService.instance.save(
      BattleSummary(
        outcome: BattleOutcome.defeat,
        monsterName: _monster.name,
        streakBefore: streakBefore,
        streakAfter: 0,
        reason: reason,
        brokenItems: penalty.brokenItemNames,
        timestampIso: DateTime.now().toIso8601String(),
      ),
    );
    unawaited(
      WidgetService.instance.updateLiveWidget(status: LiveWidgetStatus.sad),
    );

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DefeatDialog(
        reason: reason,
        brokenItems: penalty.brokenItemNames,
        onConfirm: () => Navigator.pop(dialogContext),
      ),
    );

    if (mounted) Navigator.pop(context, false);
  }

  Widget _buildFloatingDamageTexts() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final entry in _floatingDamages)
          Align(
            alignment: Alignment(entry.offsetX / 200, -0.15),
            child: _FloatingDamageLabel(
              amount: entry.amount,
                              isCritical: entry.isCritical,
              onAnimationEnd: () => _removeFloatingDamage(entry.id),
            ),
          ),
      ],
    );
  }

  List<Offset> _runeTemplatePoints(_RuneShape rune, Size size) {
    switch (rune) {
      case _RuneShape.z:
        return [
          Offset(size.width * 0.2, size.height * 0.2),
          Offset(size.width * 0.8, size.height * 0.2),
          Offset(size.width * 0.2, size.height * 0.8),
          Offset(size.width * 0.8, size.height * 0.8),
        ];
      case _RuneShape.triangle:
        return [
          Offset(size.width * 0.5, size.height * 0.15),
          Offset(size.width * 0.2, size.height * 0.8),
          Offset(size.width * 0.8, size.height * 0.8),
          Offset(size.width * 0.5, size.height * 0.15),
        ];
      case _RuneShape.circle:
        final points = <Offset>[];
        for (var i = 0; i < 18; i++) {
          final t = (i / 18) * pi * 2;
          points.add(
            Offset(
              size.width * 0.5 + cos(t) * size.width * 0.3,
              size.height * 0.5 + sin(t) * size.height * 0.3,
            ),
          );
        }
        return points;
    }
  }

  double _runeAccuracy() {
    if (_drawnRunePoints.length < 8) return 0;
    final template = _runeTemplatePoints(_currentRune, _runeAreaSize);
    if (template.isEmpty) return 0;

    final threshold = _runeAreaSize.shortestSide * 0.16;
    var hits = 0;
    for (final p in template) {
      final near = _drawnRunePoints.any((u) => (u - p).distance <= threshold);
      if (near) hits++;
    }
    return hits / template.length;
  }

  Future<void> _completeRuneIfValid() async {
    final accuracy = _runeAccuracy();
    if (accuracy < 0.8 || _battleEnded || !_isMage) {
      if (mounted) {
        setState(() => _drawnRunePoints.clear());
      }
      return;
    }

    final magicDamage = (_equippedWeaponDamage + 22);
    await _triggerCriticalHaptic();
    await _playHitSound(playbackRate: 0.82);
    _dealDamage(magicDamage, isCritical: true, skipFeedback: true);

    if (!mounted) return;
    setState(() {
      _flashColor = const Color(0xFFFFF176);
      _drawnRunePoints.clear();
      _currentRune = _RuneShape.values[_random.nextInt(_RuneShape.values.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _battleEnded) return;
        unawaited(_onDefeat('Savaştan kaçtın!'));
      },
      child: Scaffold(
        backgroundColor: _dungeonBackground,
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ShakableCombatZone(
                      shakeKey: _combatShakeKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _MonsterHpBar(
                            monsterName: _monster.name,
                            current: _monsterHP,
                            max: _monster.maxHP,
                          ),
                          const Spacer(),
                          _isMage
                              ? _RuneCircleArea(
                                  rune: _currentRune,
                                  drawnPoints: _drawnRunePoints,
                                  onAreaReady: (size) {
                                    _runeAreaSize = size;
                                  },
                                  onPanPoint: (local) {
                                    setState(() => _drawnRunePoints.add(local));
                                  },
                                  onPanEnd: (_) => unawaited(_completeRuneIfValid()),
                                )
                              : Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    _MonsterDisplay(monster: _monster),
                                    _buildFloatingDamageTexts(),
                                  ],
                                ),
                          if (_isMage)
                            SizedBox(
                              height: 70,
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [_buildFloatingDamageTexts()],
                              ),
                            ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    _PlayerHpBar(
                      current: _playerCurrentHP,
                      max: _playerMaxHP,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _battleEnded
                          ? 'SAVAŞ BİTTİ!'
                          : _combatHint,
                      textAlign: TextAlign.center,
                      style: _pixelTextStyle(
                        fontSize: 14,
                        color: QuestTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Silah +$_equippedWeaponDamage DMG · Kritik %${(_criticalChance * 100).toStringAsFixed(0)}',
                      textAlign: TextAlign.center,
                      style: _pixelTextStyle(
                        fontSize: 11,
                        color: QuestTheme.onSurfaceMuted,
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
                    color: _flashColor.withValues(alpha: 0.35),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Hasar alındığında HP + canavar bölgesini kısa süre sarsar.
class _ShakableCombatZone extends StatelessWidget {
  const _ShakableCombatZone({
    required this.shakeKey,
    required this.child,
  });

  final int shakeKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: child
          .animate(
            key: ValueKey(shakeKey),
            autoPlay: shakeKey > 0,
          )
          .shake(
            duration: 100.ms,
            hz: 6,
            rotation: 0.04,
          ),
    );
  }
}

class _RuneCircleArea extends StatefulWidget {
  const _RuneCircleArea({
    required this.rune,
    required this.drawnPoints,
    required this.onPanPoint,
    required this.onPanEnd,
    required this.onAreaReady,
  });

  final _RuneShape rune;
  final List<Offset> drawnPoints;
  final ValueChanged<Offset> onPanPoint;
  final GestureDragEndCallback onPanEnd;
  final ValueChanged<Size> onAreaReady;

  @override
  State<_RuneCircleArea> createState() => _RuneCircleAreaState();
}

class _RuneCircleAreaState extends State<_RuneCircleArea> {
  @override
  Widget build(BuildContext context) {
    const areaSize = Size(230, 230);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onAreaReady(areaSize);
    });

    return Center(
      child: Container(
        width: areaSize.width,
        height: areaSize.height,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1120),
          border: Border.all(color: const Color(0xFF9FC3FF), width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black87, offset: Offset(3, 3)),
          ],
        ),
        child: GestureDetector(
          onPanUpdate: (d) => widget.onPanPoint(d.localPosition),
          onPanEnd: widget.onPanEnd,
          child: CustomPaint(
            painter: _RunePainter(
              rune: widget.rune,
              drawnPoints: widget.drawnPoints,
            ),
            child: Center(
              child: Text(
                'BÜYÜ ÇEMBERİ',
                style: _pixelTextStyle(
                  fontSize: 11,
                  color: QuestTheme.onSurfaceMuted.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RunePainter extends CustomPainter {
  _RunePainter({
    required this.rune,
    required this.drawnPoints,
  });

  final _RuneShape rune;
  final List<Offset> drawnPoints;

  @override
  void paint(Canvas canvas, Size size) {
    final template = _templatePoints(rune, size);
    final templatePaint = Paint()
      ..color = const Color(0xFF88AAFF).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    if (template.length > 1) {
      final path = Path()..moveTo(template.first.dx, template.first.dy);
      for (final p in template.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, templatePaint);
    }

    final drawPaint = Paint()
      ..color = const Color(0xFF7EEDFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    if (drawnPoints.length > 1) {
      final path = Path()..moveTo(drawnPoints.first.dx, drawnPoints.first.dy);
      for (final p in drawnPoints.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, drawPaint);
    }
  }

  List<Offset> _templatePoints(_RuneShape rune, Size size) {
    switch (rune) {
      case _RuneShape.z:
        return [
          Offset(size.width * 0.2, size.height * 0.2),
          Offset(size.width * 0.8, size.height * 0.2),
          Offset(size.width * 0.2, size.height * 0.8),
          Offset(size.width * 0.8, size.height * 0.8),
        ];
      case _RuneShape.triangle:
        return [
          Offset(size.width * 0.5, size.height * 0.15),
          Offset(size.width * 0.2, size.height * 0.8),
          Offset(size.width * 0.8, size.height * 0.8),
          Offset(size.width * 0.5, size.height * 0.15),
        ];
      case _RuneShape.circle:
        final points = <Offset>[];
        for (var i = 0; i <= 20; i++) {
          final t = (i / 20) * pi * 2;
          points.add(
            Offset(
              size.width * 0.5 + cos(t) * size.width * 0.3,
              size.height * 0.5 + sin(t) * size.height * 0.3,
            ),
          );
        }
        return points;
    }
  }

  @override
  bool shouldRepaint(covariant _RunePainter oldDelegate) {
    return oldDelegate.rune != rune || oldDelegate.drawnPoints != drawnPoints;
  }
}

/// Yukarı süzülüp kaybolan kırmızı hasar yazısı.
class _FloatingDamageLabel extends StatelessWidget {
  const _FloatingDamageLabel({
    required this.amount,
    required this.isCritical,
    required this.onAnimationEnd,
  });

  final int amount;
  final bool isCritical;
  final VoidCallback onAnimationEnd;

  @override
  Widget build(BuildContext context) {
    return Text(
      isCritical ? 'KRİTİK! -$amount' : '-$amount',
      style: _pixelTextStyle(
        fontSize: isCritical ? 48 : 40,
        color: isCritical ? const Color(0xFFFFD54F) : QuestTheme.error,
        shadows: const [
          Shadow(color: Colors.black, offset: Offset(3, 3)),
          Shadow(color: Colors.white, offset: Offset(-2, -2)),
        ],
      ),
    )
        .animate()
        .fade(
          begin: 1,
          end: 0,
          duration: 650.ms,
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0,
          end: -0.35,
          duration: 650.ms,
          curve: Curves.easeOut,
        )
        .callback(callback: (_) => onAnimationEnd());
  }
}

/// Canavarın HP çubuğu — ekranın üst kısmında.
class _MonsterHpBar extends StatelessWidget {
  const _MonsterHpBar({
    required this.monsterName,
    required this.current,
    required this.max,
  });

  final String monsterName;
  final int current;
  final int max;

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$monsterName HP',
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
  const _MonsterDisplay({required this.monster});

  final Monster monster;

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
          child: ClipRect(
            child: PixelAssetImage(
              imagePath: monster.imagePath,
              width: 152,
              height: 152,
              fit: BoxFit.contain,
              placeholderSeed: monster.name,
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
            monster.name,
            style: _pixelTextStyle(
              fontSize: 14,
              color: monster.isBoss ? const Color(0xFFFFC800) : QuestTheme.secondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          monster.isBoss ? '[ Haftalik Boss ]' : '[ Gece Yarisi Tehdidi ]',
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
    required this.streak,
    required this.bonusLabel,
    required this.onConfirm,
  });

  final int xp;
  final int gold;
  final int streak;
  final String bonusLabel;
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
            const SizedBox(height: 8),
            Text(
              '🔥 SERİ: $streak GÜN',
              style: _pixelTextStyle(
                fontSize: 14,
                color: const Color(0xFFFF8844),
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
              '+$gold Altın$bonusLabel',
              textAlign: TextAlign.center,
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

/// Yenilgi / kaçış ceza diyalog kutusu.
class _DefeatDialog extends StatelessWidget {
  const _DefeatDialog({
    required this.reason,
    required this.brokenItems,
    required this.onConfirm,
  });

  final String reason;
  final List<String> brokenItems;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final brokenText = brokenItems.isEmpty
        ? 'Ekipman hasar gördü (-25%).'
        : 'KIRILDI: ${brokenItems.join(', ')}';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: QuestTheme.surface,
          border: Border.all(color: QuestTheme.error, width: 4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'YENİLGİ!',
              style: _pixelTextStyle(
                fontSize: 28,
                color: QuestTheme.error,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              reason,
              textAlign: TextAlign.center,
              style: _pixelTextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'Seri sıfırlandı · HP: 0',
              style: _pixelTextStyle(
                fontSize: 12,
                color: QuestTheme.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              brokenText,
              textAlign: TextAlign.center,
              style: _pixelTextStyle(
                fontSize: 12,
                color: QuestTheme.error,
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
