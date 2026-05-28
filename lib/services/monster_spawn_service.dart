import 'dart:math';

import '../models/monster.dart';
import 'game_content_service.dart';

/// Sabah savaşı için Firestore `global_monsters` havuzundan canavar seçer.
class MonsterSpawnService {
  MonsterSpawnService._();

  static final MonsterSpawnService instance = MonsterSpawnService._();

  /// Her savaş girişinde Firestore'dan taze havuz çeker (oturum önbelleği yok).
  Future<Monster> pickForPlayerLevel(int level, Random random) async {
    try {
      final pool = await GameContentService.instance.fetchMonstersOnce();
      if (pool.isEmpty) {
        return Monster.forPlayerLevel(level, random);
      }

      final eligible =
          pool.where((m) => m.minLevel <= level).toList(growable: false);
      final pickFrom = eligible.isEmpty ? pool : eligible;
      final def = pickFrom[random.nextInt(pickFrom.length)];
      return Monster.fromDefinition(def);
    } catch (_) {
      return Monster.forPlayerLevel(level, random);
    }
  }

  /// Geriye dönük uyumluluk — artık önbellek yok.
  void invalidateCache() {}
}
