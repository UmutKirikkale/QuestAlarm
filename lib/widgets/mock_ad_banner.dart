import 'package:flutter/material.dart';

import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';

/// Sahte banner reklam — Pro üyelerde gösterilmez.
class MockAdBanner extends StatelessWidget {
  const MockAdBanner({
    super.key,
    required this.isPro,
    this.compact = false,
  });

  final bool isPro;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (isPro) return const SizedBox.shrink();

    return Container(
      margin: compact ? EdgeInsets.zero : const EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1428),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF5A4A78), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 36 : 44,
            height: compact ? 36 : 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF2E2440),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: QuestTheme.secondary),
            ),
            child: Text(
              'AD',
              style: pixelTextStyle(
                fontSize: compact ? 10 : 11,
                color: QuestTheme.secondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SPONSOR · QuestKahve',
                  style: pixelTextStyle(
                    fontSize: compact ? 9 : 10,
                    color: const Color(0xFFFFD54F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  compact
                      ? 'Sabah enerjisi +50 HP (mock)'
                      : 'Sabah enerjisi için +50 HP — Reklam simülasyonu',
                  style: pixelTextStyle(
                    fontSize: compact ? 8 : 9,
                    color: QuestTheme.onSurfaceMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '×',
            style: pixelTextStyle(
              fontSize: 12,
              color: QuestTheme.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
