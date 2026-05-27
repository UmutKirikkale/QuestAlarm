import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/player.dart';

/// Uygulama tercihleri ve oyuncu verisi.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String _keyIsFirstTime = 'is_first_time';
  static const String _keyPlayer = 'player_data';
  static const String _keyPlayerUpdatedAt = 'player_updated_at_ms';

  Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsFirstTime) ?? true;
  }

  Future<void> completePermissionsSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsFirstTime, false);
  }

  Future<Player> loadPlayer() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPlayer);
    if (raw == null) {
      final initial = Player.initial();
      await savePlayer(initial);
      return initial;
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return Player.fromMap(map);
    } catch (_) {
      final initial = Player.initial();
      await savePlayer(initial);
      return initial;
    }
  }

  Future<void> savePlayer(Player player) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlayer, jsonEncode(player.toMap()));
    await prefs.setInt(_keyPlayerUpdatedAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> savePlayerWithTimestamp(Player player, int updatedAtMs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlayer, jsonEncode(player.toMap()));
    await prefs.setInt(_keyPlayerUpdatedAt, updatedAtMs);
  }

  Future<int> loadPlayerUpdatedAtMs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPlayerUpdatedAt) ?? 0;
  }
}
