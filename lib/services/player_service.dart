import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/equipped_item.dart';
import '../models/global_settings.dart';
import '../models/game_map_definition.dart';
import '../models/item.dart';
import '../models/game_class_definition.dart';
import '../models/player.dart';
import '../models/shop_currency.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'global_settings_service.dart';
import 'storage_service.dart';
import 'user_document_sync_service.dart';

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
  insufficientDiamonds,
  levelTooLow,
  alreadyOwned,
  nothingToRepair,
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

  GlobalSettings get _economy => GlobalSettingsService.instance.current;

  /// Mevcut streak'e göre kazanç çarpanı (Firestore `global_settings/app`).
  double streakMultiplier(int streak) {
    return _economy.streakMultiplierFor(streak);
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

    final cloud = await _safeLoadCloudPlayer(uid);
    if (cloud == null) {
      // Buluta yazmayı arka planda dene — açılışı bloklamasın.
      unawaited(
        _safeSaveCloudPlayer(
          uid,
          local,
          updatedAtMs: localUpdatedAtMs > 0
              ? localUpdatedAtMs
              : DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return local;
    }

    final cloudUpdatedAtMs = cloud.updatedAtMs;

    // En güncel kaydı seç: local daha yeniyse cloud'a it, cloud yeniyse local'e çek.
    if (localUpdatedAtMs > cloudUpdatedAtMs) {
      unawaited(
        _safeSaveCloudPlayer(
          uid,
          local,
          updatedAtMs: localUpdatedAtMs,
        ),
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
    await _safeSaveCloudPlayer(
      uid,
      player,
      updatedAtMs: localUpdatedAtMs,
    );
  }

  Future<CloudPlayerData?> _safeLoadCloudPlayer(String uid) async {
    try {
      return await FirestoreService.instance.loadPlayerData(uid);
    } catch (e) {
      debugPrint('PlayerService cloud load skipped: $e');
      return null;
    }
  }

  Future<void> _safeSaveCloudPlayer(
    String uid,
    Player player, {
    int? updatedAtMs,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      final displayName = user?.displayName?.trim().isNotEmpty == true
          ? user!.displayName
          : user?.email?.split('@').first;
      await FirestoreService.instance.savePlayerData(
        uid,
        player,
        updatedAtMs: updatedAtMs,
        displayName: displayName,
      );
    } catch (e) {
      debugPrint('PlayerService cloud save skipped: $e');
    }
  }

  Future<void> syncFromCloudIfSignedIn() async {
    if (AuthService.instance.currentUser == null) return;
    _cached = await _loadBestSourcePlayer();
  }

  /// Firestore `users/{uid}` anlık güncellemesini yerel önbelleğe yansıtır (God Mode vb.).
  Future<void> mergeFromCloudIfNewer(UserDocumentSnapshot snap) async {
    final cloudPlayer = snap.player;
    if (cloudPlayer == null) return;

    final localMs = await StorageService.instance.loadPlayerUpdatedAtMs();
    if (snap.clientUpdatedAtMs > 0 && snap.clientUpdatedAtMs <= localMs) {
      return;
    }

    _cached = cloudPlayer;
    await StorageService.instance.savePlayerWithTimestamp(
      cloudPlayer,
      snap.clientUpdatedAtMs > 0
          ? snap.clientUpdatedAtMs
          : DateTime.now().millisecondsSinceEpoch,
    );
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
    final proXpMult = player.isPro ? _economy.proXpMultiplier : 1.0;
    final proGoldMult = player.isPro ? _economy.proGoldMultiplier : 1.0;
    final xp = ((baseXp ?? baseVictoryXp) *
            streakMulti *
            extraMultiplier *
            proXpMult)
        .round();
    final gold = ((baseGold ?? baseVictoryGold) *
            streakMulti *
            extraMultiplier *
            proGoldMult)
        .round();
    final totalMultiplier = streakMulti * extraMultiplier;
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

  /// Uyurken pusuya düşme: HP 0, seri sıfır, rastgele bir ekipman tamamen yok olur.
  Future<DefeatPenalty> applyAmbushPenalty() async {
    final player = await loadPlayer();
    final broken = <String>[];
    final random = Random();

    var weapon = player.equippedWeapon;
    var armor = player.equippedArmor;
    var clearWeapon = false;
    var clearArmor = false;

    final slots = <String>[];
    if (weapon != null) slots.add('weapon');
    if (armor != null) slots.add('armor');

    if (slots.isNotEmpty) {
      final picked = slots[random.nextInt(slots.length)];
      if (picked == 'weapon') {
        broken.add(weapon!.item.name);
        clearWeapon = true;
        weapon = null;
      } else {
        broken.add(armor!.item.name);
        clearArmor = true;
        armor = null;
      }
    }

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
      final xpNeeded = result.nextLevelXP;
      result = result.copyWith(
        level: result.level + 1,
        currentXP: result.currentXP - xpNeeded,
        nextLevelXP: _economy.scaledNextLevelXp(xpNeeded),
        maxHP: result.maxHP + 10,
        currentHP: result.maxHP + 10,
      );
    }
    return result;
  }

  /// Eksik dayanıklılık için tamir altın maliyeti (Firestore ekonomi ayarı).
  int repairCostForEquipped(EquippedItem? equipped, {required bool isPro}) {
    if (equipped == null) return 0;
    final missing = _missingDurability(equipped.durability);
    return _economy.repairGoldCost(missing, isPro: isPro);
  }

  /// Pro üyelik — IAP simülasyonu.
  Future<bool> activateProMembership() async {
    final player = await loadPlayer();
    if (player.isPro) return true;
    await _save(player.copyWith(isPro: true));
    return true;
  }

  static int _missingDurability(int durability) {
    final missing = 100 - durability;
    if (missing < 0) return 0;
    if (missing > 100) return 100;
    return missing;
  }

  /// Silah veya zırhı tamir eder (altın düşer).
  Future<PurchaseResult> repairEquipment({required bool repairWeapon}) async {
    final player = await loadPlayer();
    final equipped =
        repairWeapon ? player.equippedWeapon : player.equippedArmor;
    if (equipped == null) {
      return const PurchaseResult.failure(PurchaseFailure.nothingToRepair);
    }

    final missing = _missingDurability(equipped.durability);
    if (missing <= 0) {
      return const PurchaseResult.failure(PurchaseFailure.nothingToRepair);
    }

    final cost = _economy.repairGoldCost(missing, isPro: player.isPro);
    if (player.gold < cost) {
      return const PurchaseResult.failure(PurchaseFailure.insufficientGold);
    }

    final repaired = equipped.copyWith(durability: 100);
    final updated = repairWeapon
        ? player.copyWith(
            gold: player.gold - cost,
            equippedWeapon: repaired,
          )
        : player.copyWith(
            gold: player.gold - cost,
            equippedArmor: repaired,
          );

    await _save(updated);
    return const PurchaseResult.success();
  }

  Future<void> spendGold(int amount) async {
    final player = await loadPlayer();
    await _save(player.copyWith(gold: player.gold - amount));
  }

  Future<void> addGold(int amount) async {
    if (amount <= 0) return;
    final player = await loadPlayer();
    await _save(player.copyWith(gold: player.gold + amount));
  }

  Future<void> addDiamonds(int amount) async {
    if (amount <= 0) return;
    final player = await loadPlayer();
    await _save(player.copyWith(diamonds: player.diamonds + amount));
  }

  /// IAP simülasyonu — gerçek ödeme entegrasyonu sonradan eklenecek.
  Future<int> simulatePremiumPurchase(int diamondAmount) async {
    await addDiamonds(diamondAmount);
    return diamondAmount;
  }

  Future<void> setCharacterClass(CharacterClass characterClass) async {
    final player = await loadPlayer();
    await _save(player.copyWith(characterClass: characterClass));
  }

  Future<void> initializeProfileForNewUser() async {
    final initial = Player.initial(hasChosenClass: false);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _cached = initial;
    await StorageService.instance.savePlayerWithTimestamp(initial, timestamp);
    final uid = AuthService.instance.currentUser?.uid;
    if (uid != null) {
      await FirestoreService.instance.savePlayerData(
        uid,
        initial,
        updatedAtMs: timestamp,
      );
    }
  }

  Future<void> chooseCharacterClassOnce(CharacterClass characterClass) async {
    final player = await loadPlayer();
    if (player.hasChosenClass) return;
    await _save(
      player.copyWith(
        characterClass: characterClass,
        characterClassId: characterClass.name,
        hasChosenClass: true,
      ),
    );
  }

  /// Firestore `global_classes` kaydından tek seferlik sınıf seçimi.
  Future<void> chooseCharacterClassById(GameClassDefinition definition) async {
    final player = await loadPlayer();
    if (player.hasChosenClass) return;

    CharacterClass mapped = CharacterClass.warrior;
    for (final c in CharacterClass.values) {
      if (c.name == definition.id) {
        mapped = c;
        break;
      }
    }

    var updated = player.copyWith(
      characterClass: mapped,
      characterClassId: definition.id,
      hasChosenClass: true,
      maxHP: definition.startHp,
      currentHP: definition.startHp,
    );

    await _save(updated);
  }

  Future<void> resetAccountProgress() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid != null) {
      await FirestoreService.instance.deleteUserData(uid);
    }
    final resetPlayer = Player.initial(hasChosenClass: false);
    _cached = resetPlayer;
    await StorageService.instance.savePlayer(resetPlayer);
  }

  /// Mağazadan eşya satın alır ve kuşanır / kullanır.
  Future<PurchaseResult> purchaseItem(Item item) async {
    final player = await loadPlayer();
    if (player.level < item.requiredLevel) {
      return const PurchaseResult.failure(PurchaseFailure.levelTooLow);
    }

    final Player updated;
    if (item.shopCurrency == ShopCurrency.diamond) {
      if (player.diamonds < item.price) {
        return const PurchaseResult.failure(PurchaseFailure.insufficientDiamonds);
      }
      updated = player.copyWith(diamonds: player.diamonds - item.price);
    } else {
      if (player.gold < item.price) {
        return const PurchaseResult.failure(PurchaseFailure.insufficientGold);
      }
      updated = player.copyWith(gold: player.gold - item.price);
    }

    var equipped = updated;

    switch (item.itemType) {
      case ItemType.weapon:
        equipped = equipped.copyWith(
          equippedWeapon: EquippedItem(item: item, durability: 100),
        );
      case ItemType.armor:
        equipped = equipped.copyWith(
          equippedArmor: EquippedItem(item: item, durability: 100),
        );
      case ItemType.potion:
        equipped = equipped.copyWith(
          currentHP: (equipped.currentHP + 50).clamp(0, equipped.maxHP),
        );
    }

    await _save(equipped);
    return const PurchaseResult.success();
  }

  /// Ücretli haritayı açar (bir kez ödenir).
  Future<PurchaseResult> purchaseMapUnlock(GameMapDefinition map) async {
    final player = await loadPlayer();
    if (player.level < map.requiredLevel) {
      return const PurchaseResult.failure(PurchaseFailure.levelTooLow);
    }
    if (!map.requiresPurchase || player.hasUnlockedMap(map.id)) {
      return const PurchaseResult.success();
    }

    final Player paid;
    if (map.shopCurrency == ShopCurrency.diamond) {
      if (player.diamonds < map.unlockPrice) {
        return const PurchaseResult.failure(PurchaseFailure.insufficientDiamonds);
      }
      paid = player.copyWith(diamonds: player.diamonds - map.unlockPrice);
    } else {
      if (player.gold < map.unlockPrice) {
        return const PurchaseResult.failure(PurchaseFailure.insufficientGold);
      }
      paid = player.copyWith(gold: player.gold - map.unlockPrice);
    }

    final ids = [...paid.unlockedMapIds, map.id];
    await _save(paid.copyWith(unlockedMapIds: ids));
    return const PurchaseResult.success();
  }

  bool isMapAccessible(Player player, GameMapDefinition map) {
    if (player.level < map.requiredLevel) return false;
    if (!map.requiresPurchase) return true;
    return player.hasUnlockedMap(map.id);
  }

  void invalidateCache() => _cached = null;
}
