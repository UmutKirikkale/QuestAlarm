import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item.dart';
import '../models/moderated_user.dart';
import '../models/player.dart';
import '../models/equipped_item.dart';
import 'firestore_service.dart';

/// Admin God Mode — oyuncu moderasyonu.
class PlayerModerationService {
  PlayerModerationService._();

  static final PlayerModerationService instance = PlayerModerationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String epicItemId = 'storm_spear';

  Stream<List<ModeratedUser>> watchAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs
          .map((d) => ModeratedUser.fromFirestore(d.id, d.data()))
          .toList();
      users.sort((a, b) => b.player.level.compareTo(a.player.level));
      return users;
    });
  }

  Future<ModeratedUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return ModeratedUser.fromFirestore(doc.id, doc.data()!);
  }

  Future<void> grantGold(String uid, int amount) async {
    await _mutatePlayer(uid, (p) => p.copyWith(gold: p.gold + amount));
  }

  Future<void> grantDiamonds(String uid, int amount) async {
    await _mutatePlayer(uid, (p) => p.copyWith(diamonds: p.diamonds + amount));
  }

  Future<void> grantEpicItem(String uid) async {
    final itemDoc = await _db.collection('global_items').doc(epicItemId).get();
    Item item;
    if (itemDoc.exists && itemDoc.data() != null) {
      item = Item.fromMap({...itemDoc.data()!, 'id': epicItemId});
    } else {
      item = const Item(
        id: 'storm_spear',
        name: 'Fırtına Mızrağı',
        price: 240,
        bonusDamage: 34,
        itemType: ItemType.weapon,
        rarity: ItemRarity.legendary,
        requiredLevel: 8,
        criticalChance: 0.25,
        imagePath: 'assets/images/items/sword.png',
      );
    }

    await _mutatePlayer(
      uid,
      (p) => p.copyWith(
        equippedWeapon: EquippedItem(item: item, durability: 100),
      ),
    );
  }

  /// Streak ve altını sıfırla; seviye korunur.
  Future<void> resetAccountProgress(String uid) async {
    await _mutatePlayer(
      uid,
      (p) => p.copyWith(gold: 0, diamonds: 0, streak: 0),
    );
  }

  Future<void> setShowOnLeaderboard(String uid, bool show) async {
    await _db.collection('users').doc(uid).set(
      {'showOnLeaderboard': show},
      SetOptions(merge: true),
    );
  }

  Future<void> setPro(String uid, bool isPro) async {
    await _mutatePlayer(uid, (p) => p.copyWith(isPro: isPro));
    await _db.collection('users').doc(uid).set(
      {'isPro': isPro},
      SetOptions(merge: true),
    );
  }

  Future<void> setBanned(String uid, bool banned) async {
    await _db.collection('users').doc(uid).set(
      {'isBanned': banned},
      SetOptions(merge: true),
    );
  }

  Future<void> _mutatePlayer(
    String uid,
    Player Function(Player current) transform,
  ) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      throw StateError('Oyuncu bulunamadı: $uid');
    }

    final user = ModeratedUser.fromFirestore(doc.id, doc.data()!);
    final updated = transform(user.player);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await FirestoreService.instance.savePlayerData(
      uid,
      updated,
      updatedAtMs: timestamp,
    );
  }
}
