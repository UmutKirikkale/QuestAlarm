import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    required this.soundEnabled,
    required this.hapticEnabled,
  });

  final bool soundEnabled;
  final bool hapticEnabled;
}

class AppSettingsService {
  AppSettingsService._();

  static final AppSettingsService instance = AppSettingsService._();

  static const _keySoundEnabled = 'settings_sound_enabled';
  static const _keyHapticEnabled = 'settings_haptic_enabled';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      soundEnabled: prefs.getBool(_keySoundEnabled) ?? true,
      hapticEnabled: prefs.getBool(_keyHapticEnabled) ?? true,
    );
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundEnabled, enabled);
  }

  Future<void> setHapticEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHapticEnabled, enabled);
  }
}
