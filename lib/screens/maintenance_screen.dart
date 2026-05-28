import 'package:flutter/material.dart';

import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';
import '../widgets/retro_window.dart';

/// Bakım modu veya ban kilidi — retro tam ekran.
class LiveOpsLockScreen extends StatelessWidget {
  const LiveOpsLockScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = '🔧',
  });

  final String title;
  final String subtitle;
  final String icon;

  factory LiveOpsLockScreen.maintenance() {
    return const LiveOpsLockScreen(
      icon: '🔧',
      title: 'Zindanda Temizlik Var!',
      subtitle: 'Bakım Modu — Kısa süre sonra geri döneceğiz.',
    );
  }

  factory LiveOpsLockScreen.banned() {
    return const LiveOpsLockScreen(
      icon: '⛔',
      title: 'Hesap Askıda',
      subtitle: 'Bu hesaba giriş geçici olarak engellendi.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuestTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: RetroWindow(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: pixelTextStyle(
                        fontSize: 16,
                        color: QuestTheme.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: pixelTextStyle(
                        fontSize: 12,
                        color: QuestTheme.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
