import 'package:flutter/material.dart';

import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';

/// Sol ikonlu, gölgeli retro HP/XP/Altın göstergesi.
class RetroStatBar extends StatelessWidget {
  const RetroStatBar({
    super.key,
    required this.icon,
    required this.label,
    required this.current,
    required this.max,
    required this.fillColor,
    this.fillColorLow,
    this.lowThreshold = 0.0,
    this.showFraction = true,
    this.compact = false,
  });

  final String icon;
  final String label;
  final int current;
  final int max;
  final Color fillColor;
  final Color? fillColorLow;
  final double lowThreshold;
  final bool showFraction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final isLow = fillColorLow != null && ratio <= lowThreshold;
    final activeFill = isLow ? fillColorLow! : fillColor;
    final barHeight = compact ? 22.0 : 28.0;
    final labelSize = compact ? 8.0 : 10.0;
    final fractionSize = compact ? 9.0 : 11.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact)
          Text(
            label,
            style: pixelTextStyle(
              fontSize: labelSize,
              color: QuestTheme.onSurfaceMuted,
              letterSpacing: 1.5,
            ),
          ),
        if (!compact) const SizedBox(height: 4),
        Container(
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
              _StatIconBadge(icon: icon, height: barHeight),
              Expanded(
                child: Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: ratio,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                activeFill.withValues(alpha: 0.85),
                                activeFill,
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (showFraction)
                        Center(
                          child: Text(
                            '$current / $max',
                            style: pixelTextStyle(
                              fontSize: fractionSize,
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                  color: Colors.black,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
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

/// Altın sayacı — bar yerine kompakt retro satır.
class RetroGoldCounter extends StatelessWidget {
  const RetroGoldCounter({super.key, required this.gold, this.compact = false});

  final int gold;
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
          _StatIconBadge(icon: '🪙', height: barHeight),
          Expanded(
            child: Container(
              height: barHeight,
              padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3D3200), Color(0xFF5C4A00)],
                ),
                border: Border.all(color: QuestTheme.secondary, width: 2),
              ),
              alignment: Alignment.centerRight,
              child: Text(
                '$gold G',
                style: pixelTextStyle(
                  fontSize: compact ? 11 : 14,
                  color: QuestTheme.secondary,
                  shadows: const [
                    Shadow(color: Color(0xFF3D2800), offset: Offset(1, 1)),
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

class _StatIconBadge extends StatelessWidget {
  const _StatIconBadge({required this.icon, this.height = 28});

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
