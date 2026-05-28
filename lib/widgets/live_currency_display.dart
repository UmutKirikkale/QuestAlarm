import 'dart:async';

import 'package:flutter/material.dart';

import '../services/user_document_sync_service.dart';
import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';
import 'retro_stat_bar.dart';

/// Firestore `users/{uid}` üzerinden canlı altın ve elmas — değişince parlar.
class LiveCurrencyDisplay extends StatefulWidget {
  const LiveCurrencyDisplay({
    super.key,
    required this.fallbackGold,
    required this.fallbackDiamonds,
    this.compact = false,
    this.showDiamonds = true,
  });

  final int fallbackGold;
  final int fallbackDiamonds;
  final bool compact;
  final bool showDiamonds;

  @override
  State<LiveCurrencyDisplay> createState() => _LiveCurrencyDisplayState();
}

class _LiveCurrencyDisplayState extends State<LiveCurrencyDisplay>
    with TickerProviderStateMixin {
  late final AnimationController _goldPulse;
  late final AnimationController _diamondPulse;
  StreamSubscription<UserDocumentSnapshot>? _sub;

  int _gold = 0;
  int _diamonds = 0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _gold = widget.fallbackGold;
    _diamonds = widget.fallbackDiamonds;
    _goldPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _diamondPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    if (UserDocumentSyncService.instance.isAttached) {
      _apply(UserDocumentSyncService.instance.latest, animate: false);
    }
    _sub = UserDocumentSyncService.instance.stream.listen(
      (snap) => _apply(snap, animate: true),
    );
  }

  @override
  void didUpdateWidget(covariant LiveCurrencyDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_initialized) {
      _gold = widget.fallbackGold;
      _diamonds = widget.fallbackDiamonds;
    }
  }

  void _apply(UserDocumentSnapshot snap, {required bool animate}) {
    final newGold = snap.player != null ? snap.gold : _gold;
    final newDiamonds = snap.player != null ? snap.diamonds : _diamonds;

    final goldChanged = newGold != _gold;
    final diamondChanged = newDiamonds != _diamonds;

    if (!_initialized || goldChanged || diamondChanged) {
      setState(() {
        _gold = newGold;
        _diamonds = newDiamonds;
        _initialized = snap.player != null || _initialized;
      });
    }

    if (animate && goldChanged) {
      _goldPulse.forward(from: 0);
    }
    if (animate && diamondChanged) {
      _diamondPulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _goldPulse.dispose();
    _diamondPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showDiamonds) {
      return _PulsingWrap(
        controller: _goldPulse,
        child: RetroGoldCounter(gold: _gold, compact: widget.compact),
      );
    }

    final gap = widget.compact ? 6.0 : 8.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _PulsingWrap(
            controller: _goldPulse,
            child: RetroGoldCounter(gold: _gold, compact: widget.compact),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _PulsingWrap(
            controller: _diamondPulse,
            child: _DiamondCounter(diamonds: _diamonds, compact: widget.compact),
          ),
        ),
      ],
    );
  }
}

class _PulsingWrap extends StatelessWidget {
  const _PulsingWrap({required this.controller, required this.child});

  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(controller.value);
        final scale = 1.0 + (0.12 * (1 - t));
        final glow = Color.lerp(
          Colors.transparent,
          QuestTheme.primary.withValues(alpha: 0.55),
          (1 - t),
        )!;
        return Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: glow,
                  blurRadius: 14 * (1 - t),
                  spreadRadius: 2 * (1 - t),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _DiamondCounter extends StatelessWidget {
  const _DiamondCounter({required this.diamonds, required this.compact});

  final int diamonds;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final barHeight = compact ? 22.0 : 28.0;
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            offset: Offset(compact ? 2 : 3, compact ? 2 : 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          _CurrencyIconBadge(icon: '💎', height: barHeight),
          Expanded(
            child: Container(
              height: barHeight,
              padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A1830), Color(0xFF142848)],
                ),
                border: Border.all(color: const Color(0xFF66CCFF), width: 2),
              ),
              alignment: Alignment.centerRight,
              child: Text(
                '$diamonds',
                style: pixelTextStyle(
                  fontSize: compact ? 11 : 14,
                  color: const Color(0xFF88DDFF),
                  shadows: const [
                    Shadow(color: Color(0xFF0A2040), offset: Offset(1, 1)),
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

class _CurrencyIconBadge extends StatelessWidget {
  const _CurrencyIconBadge({required this.icon, required this.height});

  final String icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF141420),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(icon, style: TextStyle(fontSize: height * 0.5)),
    );
  }
}
