import 'package:flutter/material.dart';

import '../services/app_settings_service.dart';
import '../services/player_service.dart';
import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';
import '../widgets/retro_window.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AppSettingsService.instance.loadSettings();
    if (!mounted) return;
    setState(() {
      _soundEnabled = settings.soundEnabled;
      _hapticEnabled = settings.hapticEnabled;
      _loading = false;
    });
  }

  Future<void> _toggleSound(bool value) async {
    setState(() => _soundEnabled = value);
    await AppSettingsService.instance.setSoundEnabled(value);
  }

  Future<void> _toggleHaptic(bool value) async {
    setState(() => _hapticEnabled = value);
    await AppSettingsService.instance.setHapticEnabled(value);
  }

  Future<void> _resetAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hesabı Sıfırla'),
          content: const Text(
            'Tüm Firestore verisi, altın ve seviye silinecek. Devam etmek istiyor musun?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Sıfırla',
                style: TextStyle(color: QuestTheme.error),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || _resetting) return;
    setState(() => _resetting = true);
    await PlayerService.instance.resetAccountProgress();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/initial', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AYARLAR')),
      backgroundColor: QuestTheme.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: QuestTheme.primary),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RetroWindow(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'OYUN AYARLARI',
                          style: pixelTextStyle(
                            fontSize: 13,
                            color: QuestTheme.primary,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        SwitchListTile(
                          title: const Text('Ses Aç/Kapat'),
                          value: _soundEnabled,
                          onChanged: _toggleSound,
                          activeThumbColor: QuestTheme.primary,
                        ),
                        SwitchListTile(
                          title: const Text('Titreşim Aç/Kapat'),
                          value: _hapticEnabled,
                          onChanged: _toggleHaptic,
                          activeThumbColor: QuestTheme.primary,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B0A0A),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: QuestTheme.error, width: 2),
                    ),
                    onPressed: _resetting ? null : _resetAccount,
                    child: Text(_resetting ? 'SIFIRLANIYOR...' : 'HESABI SIFIRLA'),
                  ),
                ],
              ),
            ),
    );
  }
}
