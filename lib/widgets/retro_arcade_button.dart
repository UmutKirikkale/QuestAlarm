import 'package:flutter/material.dart';

import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';

/// Arcade tarzı basılabilir retro buton — kalın gölge + press efekti.
class RetroArcadeButton extends StatefulWidget {
  const RetroArcadeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = QuestTheme.primary,
    this.foregroundColor = QuestTheme.background,
    this.shadowColor = Colors.black,
    this.height = 52,
    this.icon,
    this.fontSize = 15,
  });

  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color shadowColor;
  final double height;
  final String? icon;
  final double fontSize;

  @override
  State<RetroArcadeButton> createState() => _RetroArcadeButtonState();
}

class _RetroArcadeButtonState extends State<RetroArcadeButton> {
  bool _pressed = false;

  static const _pressDepth = 3.0;
  static const _shadowDepth = 5.0;

  @override
  Widget build(BuildContext context) {
    final pressOffset = _pressed ? _pressDepth : 0.0;
    final shadowOffset = _pressed ? 1.0 : _shadowDepth;
    final shadowDepth = widget.height > 44 ? _shadowDepth : 4.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: SizedBox(
        height: widget.height + shadowDepth,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: shadowOffset,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.shadowColor,
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              left: 0,
              right: 0,
              top: pressOffset,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: _pressed
                      ? null
                      : const [
                          BoxShadow(
                            color: Color(0x40FFFFFF),
                            offset: Offset(0, -1),
                            blurRadius: 0,
                          ),
                        ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Text(widget.icon!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: pixelTextStyle(
                        fontSize: widget.fontSize,
                        color: widget.foregroundColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
