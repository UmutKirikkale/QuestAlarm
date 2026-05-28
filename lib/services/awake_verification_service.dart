import 'package:shared_preferences/shared_preferences.dart';

/// Sabah alarmı sonrası gerçekten uyanıp savaşıp savaşmadığını takip eder.
class AwakeVerificationService {
  AwakeVerificationService._();

  static final AwakeVerificationService instance = AwakeVerificationService._();

  static const String _keyAwakeVerified = 'is_awake_verified';

  Future<bool> isAwakeVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAwakeVerified) ?? false;
  }

  Future<void> resetForNewAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAwakeVerified, false);
  }

  Future<void> markAwakeVerified() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAwakeVerified, true);
  }
}
