import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/battle_summary.dart';

class BattleSummaryService {
  BattleSummaryService._();

  static final BattleSummaryService instance = BattleSummaryService._();
  static const _key = 'last_battle_summary';

  Future<void> save(BattleSummary summary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(summary.toMap()));
  }

  Future<BattleSummary?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return BattleSummary.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
