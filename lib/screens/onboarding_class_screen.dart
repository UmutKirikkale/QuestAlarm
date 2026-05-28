import 'package:flutter/material.dart';

import '../models/game_class_definition.dart';
import '../services/game_content_service.dart';
import '../services/player_service.dart';
import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';
import '../widgets/retro_arcade_button.dart';
import '../widgets/retro_window.dart';

/// İlk girişte sınıf seçimi — `global_classes` koleksiyonunu dinler.
class OnboardingClassScreen extends StatefulWidget {
  const OnboardingClassScreen({super.key});

  @override
  State<OnboardingClassScreen> createState() => _OnboardingClassScreenState();
}

class _OnboardingClassScreenState extends State<OnboardingClassScreen> {
  bool _isSaving = false;
  String? _selectedId;

  Future<void> _choose(GameClassDefinition definition) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _selectedId = definition.id;
    });
    await PlayerService.instance.chooseCharacterClassById(definition);
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
              constraints: const BoxConstraints(maxWidth: 520),
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
                      'Bu seçim bir kez yapılır. Sınıflar sunucudan yüklenir.',
                      textAlign: TextAlign.center,
                      style: pixelTextStyle(
                        fontSize: 11,
                        color: QuestTheme.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<GameClassDefinition>>(
                      stream: GameContentService.instance.watchClasses(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                            'Sınıflar yüklenemedi.\n${snapshot.error}',
                            style: pixelTextStyle(
                              fontSize: 11,
                              color: QuestTheme.error,
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: QuestTheme.primary,
                              ),
                            ),
                          );
                        }
                        final classes = snapshot.data!;
                        return Column(
                          children: [
                            for (var i = 0; i < classes.length; i++) ...[
                              if (i > 0) const SizedBox(height: 10),
                              _ClassChoiceButton(
                                definition: classes[i],
                                busy: _isSaving && _selectedId == classes[i].id,
                                onPressed: () => _choose(classes[i]),
                              ),
                            ],
                          ],
                        );
                      },
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

class _ClassChoiceButton extends StatelessWidget {
  const _ClassChoiceButton({
    required this.definition,
    required this.busy,
    required this.onPressed,
  });

  final GameClassDefinition definition;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final icon = switch (definition.actionType) {
      ClassActionType.runeDraw => '🪄',
      ClassActionType.timed => '⏱️',
      ClassActionType.shake => '⚔️',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RetroArcadeButton(
          label: busy ? 'KAYDEDILIYOR...' : definition.name.toUpperCase(),
          icon: icon,
          onPressed: busy ? () {} : onPressed,
        ),
        if (definition.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            definition.description,
            textAlign: TextAlign.center,
            style: pixelTextStyle(
              fontSize: 10,
              color: QuestTheme.onSurfaceMuted,
            ),
          ),
        ],
      ],
    );
  }
}
