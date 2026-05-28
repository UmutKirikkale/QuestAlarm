import 'package:flutter/material.dart';

import '../services/global_settings_service.dart';
import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';

/// Ana ekranda kayan günün görevi metni.
class DailyQuestTicker extends StatefulWidget {
  const DailyQuestTicker({super.key});

  @override
  State<DailyQuestTicker> createState() => _DailyQuestTickerState();
}

class _DailyQuestTickerState extends State<DailyQuestTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: GlobalSettingsService.instance.watchSettings(),
      builder: (context, snapshot) {
        final text = snapshot.data?.dailyQuestText.trim() ?? '';
        if (text.isEmpty) return const SizedBox.shrink();

        if (text != _text) {
          _text = text;
          _controller
            ..reset()
            ..repeat();
        }

        return Container(
          height: 28,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: QuestTheme.surface.withValues(alpha: 0.85),
            border: Border.all(color: QuestTheme.primary.withValues(alpha: 0.4)),
          ),
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final width = MediaQuery.sizeOf(context).width;
                final offset = _controller.value * (width + 200) - 100;
                return Transform.translate(
                  offset: Offset(-offset, 0),
                  child: child,
                );
              },
              child: Text(
                '★ $text ★   ',
                style: pixelTextStyle(
                  fontSize: 11,
                  color: QuestTheme.secondary,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
