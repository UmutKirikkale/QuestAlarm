import 'package:flutter/material.dart';

import '../models/player.dart';
import '../services/player_service.dart';
import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';
import '../widgets/retro_arcade_button.dart';
import '../widgets/retro_window.dart';

class ClassSelectionScreen extends StatefulWidget {
  const ClassSelectionScreen({super.key});

  @override
  State<ClassSelectionScreen> createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends State<ClassSelectionScreen> {
  bool _isSaving = false;

  Future<void> _choose(CharacterClass value) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    await PlayerService.instance.chooseCharacterClassOnce(value);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/initial');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuestTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: RetroWindow(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SINIF SECIMI',
                      textAlign: TextAlign.center,
                      style: pixelTextStyle(
                        fontSize: 16,
                        color: QuestTheme.primary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bu seçim bir kez yapılır.',
                      textAlign: TextAlign.center,
                      style: pixelTextStyle(
                        fontSize: 11,
                        color: QuestTheme.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RetroArcadeButton(
                      label: _isSaving ? 'KAYDEDILIYOR...' : 'SAVASCI',
                      icon: '⚔️',
                      onPressed: () => _choose(CharacterClass.warrior),
                    ),
                    const SizedBox(height: 10),
                    RetroArcadeButton(
                      label: _isSaving ? 'KAYDEDILIYOR...' : 'BUYUCU',
                      icon: '🪄',
                      backgroundColor: const Color(0xFF2D3D5A),
                      foregroundColor: QuestTheme.secondary,
                      onPressed: () => _choose(CharacterClass.mage),
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
