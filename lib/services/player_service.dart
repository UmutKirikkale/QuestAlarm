import 'dart:async';

import '../models/equipped_item.dart';
import '../models/item.dart';
import '../models/player.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'storage_service.dart';

/// Zafer sonrası ödül özeti.
class VictoryReward {
  const VictoryReward({
    required this.xp,
    required this.gold,
    required this.newStreak,
    required this.multiplier,
    this.monsterName,
  });

  final int xp;
  final int gold;
  final int newStreak;
  final double multiplier;
  final String? monsterName;
}

/// Yenilgi / kaçış ceza özeti.
class DefeatPenalty {
  const DefeatPenalty({
    required this.brokenItemNames,
  });

  final List<String> brokenItemNames;
}

enum PurchaseFailure {
  insufficientGold,
  levelTooLow,
}

class PurchaseResult {
  const PurchaseResult._({
    required this.success,
    this.failure,
  });

  const PurchaseResult.success() : this._(success: true);

  const PurchaseResult.failure(PurchaseFailure failure)
      : this._(success: false, failure: failure);

  final bool success;
  final PurchaseFailure? failure;
}

/// Oyuncu ilerlemesi, seri ve ekipman ceza/ödül mantığı.
class PlayerService {
  PlayerService._();

  static final PlayerService instance = PlayerService._();

  static const int baseVictoryXp = 20;
  static const int baseVictoryGold = 50;
  static const int defeatDurabilityLoss = 25;

  Player? _cached;

  /// Mevcut streak'e göre kazanç çarpanı.
  static double streakMultiplier(int streak) {
    if (streak >= 10) return 1.5;
    if (streak >= 5) return 1.2;
    return 1.0;
  }

  Future<Player> loadPlayer() async {
    _cached ??= await _loadBestSourcePlayer();
    return _cached!;
  }

  Future<void> _save(Player player) async {
    _cached = player;
    await StorageService.instance.savePlayer(player);
    unawaited(_backupToCloud(player));
  }

  Future<Player> _loadBestSourcePlayer() async {
    final local = await StorageService.instance.loadPlayer();
    final localUpdatedAtMs = await StorageService.instance.loadPlayerUpdatedAtMs();
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return local;

    final cloud = await FirestoreService.instance.loadPlayerData(uid);
    if (cloud == null) {
      // Bulutta kayıt yoksa mevcut lokali ilk yedek olarak yükle.
      await FirestoreService.instance.savePlayerData(
        uid,
        local,
        updatedAtMs: localUpdatedAtMs > 0
            ? localUpdatedAtMs
            : DateTime.now().millisecondsSinceEpoch,
      );
      return local;
    }

    final cloudUpdatedAtMs = cloud.updatedAtMs;

    // En güncel kaydı seç: local daha yeniyse cloud'a it, cloud yeniyse local'e çek.
    if (localUpdatedAtMs > cloudUpdatedAtMs) {
      await FirestoreService.instance.savePlayerData(
        uid,
        local,
        updatedAtMs: localUpdatedAtMs,
      );
      return local;
    }

    await StorageService.instance.savePlayerWithTimestamp(
      cloud.player,
      cloudUpdatedAtMs > 0
          ? cloudUpdatedAtMs
          : DateTime.now().millisecondsSinceEpoch,
    );
    return cloud.player;
  }

  Future<void> _backupToCloud(Player player) async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;
    final localUpdatedAtMs = await StorageService.instance.loadPlayerUpdatedAtMs();
    await FirestoreService.instance.savePlayerData(
      uid,
      player,
      updatedAtMs: localUpdatedAtMs,
    );
  }

  Future<void> syncFromCloudIfSignedIn() async {
    if (AuthService.instance.currentUser == null) return;
    _cached = await _loadBestSourcePlayer();
  }

  /// Canavar yenildiğinde: seri +1, çarpanlı XP/altın.
  Future<VictoryReward> applyVictory({
    int? baseXp,
    int? baseGold,
    double extraMultiplier = 1.0,
    String? monsterName,
  }) async {
    final player = await loadPlayer();
    final streakMulti = streakMultiplier(player.streak);
    final totalMultiplier = streakMulti * extraMultiplier;
    final xp = ((baseXp ?? baseVictoryXp) * totalMultiplier).round();
    final gold = ((baseGold ?? baseVictoryGold) * totalMultiplier).round();
    final newStreak = player.streak + 1;

    var updated = player.copyWith(
      streak: newStreak,
      currentXP: player.currentXP + xp,
      gold: player.gold + gold,
      currentHP: player.maxHP,
    );

    updated = _applyLevelUps(updated);
    await _save(updated);

    return VictoryReward(
      xp: xp,
      gold: gold,
      newStreak: newStreak,
      multiplier: totalMultiplier,
      monsterName: monsterName,
    );
  }

  /// Savaştan kaçış / yenilgi: seri sıfır, HP 0, ekipman hasarı.
  Future<DefeatPenalty> applyDefeat() async {
    final player = await loadPlayer();
    final broken = <String>[];

    var weapon = player.equippedWeapon;
    var armor = player.equippedArmor;
    var clearWeapon = false;
    var clearArmor = false;

    final damagedWeapon = _damageEquipped(weapon, broken);
    if (player.equippedWeapon != null && damagedWeapon == null) {
      clearWeapon = true;
    }
    weapon = damagedWeapon;

    final damagedArmor = _damageEquipped(armor, broken);
    if (player.equippedArmor != null && damagedArmor == null) {
      clearArmor = true;
    }
    armor = damagedArmor;

    final updated = player.copyWith(
      streak: 0,
      currentHP: 0,
      equippedWeapon: weapon,
      equippedArmor: armor,
      clearWeapon: clearWeapon,
      clearArmor: clearArmor,
    );

    await _save(updated);
    return DefeatPenalty(brokenItemNames: broken);
  }

  EquippedItem? _damageEquipped(EquippedItem? equipped, List<String> broken) {
    if (equipped == null) return null;

    final damaged = equipped.reduceDurability(defeatDurabilityLoss);
    if (damaged.isBroken) {
      broken.add(equipped.item.name);
      return null;
    }
    return damaged;
  }

  Player _applyLevelUps(Player player) {
    var result = player;
    while (result.currentXP >= result.nextLevelXP) {
      result = result.copyWith(
        level: result.level + 1,
        currentXP: result.currentXP - result.nextLevelXP,
        nextLevelXP: (result.nextLevelXP * 1.25).round(),
        maxHP: result.maxHP + 10,
        currentHP: result.maxHP + 10,
      );
    }
    return result;
  }

  Future<void> spendGold(int amount) async {
    final player = await loadPlayer();
    await _save(player.copyWith(gold: player.gold - amount));
  }

  Future<void> setCharacterClass(CharacterClass characterClass) async {
    final player = await loadPlayer();
    await _save(player.copyWith(characterClass: characterClass));
  }

  /// Mağazadan eşya satın alır ve kuşanır / kullanır.
  Future<PurchaseResult> purchaseItem(Item item) async {
    final player = await loadPlayer();
    if (player.level < item.requiredLevel) {
      return const PurchaseResult.failure(PurchaseFailure.levelTooLow);
    }
    if (player.gold < item.price) {
      return const PurchaseResult.failure(PurchaseFailure.insufficientGold);
    }

    var updated = player.copyWith(gold: player.gold - item.price);

    switch (item.itemType) {
      case ItemType.weapon:
        updated = updated.copyWith(
          equippedWeapon: EquippedItem(item: item, durability: 100),
        );
      case ItemType.armor:
        updated = updated.copyWith(
          equippedArmor: EquippedItem(item: item, durability: 100),
        );
      case ItemType.potion:
        updated = updated.copyWith(
          currentHP: (updated.currentHP + 50).clamp(0, updated.maxHP),
        );
    }

    await _save(updated);
    return const PurchaseResult.success();
  }

  void invalidateCache() => _cached = null;
}
