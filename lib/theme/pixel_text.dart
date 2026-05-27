import 'package:flutter/material.dart';

import 'quest_theme.dart';

/// Retro arayüz için ortak monospace metin stili.
TextStyle pixelTextStyle({
  required double fontSize,
  Color color = QuestTheme.onBackground,
  List<Shadow>? shadows,
  double letterSpacing = 1,
}) {
  return TextStyle(
    fontFamily: 'monospace',
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    color: color,
    letterSpacing: letterSpacing,
    shadows: shadows,
  );
}
