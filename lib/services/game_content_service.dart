import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/game_class_definition.dart';
import '../models/game_event_definition.dart';
import '../models/game_map_definition.dart';
import '../models/game_monster_definition.dart';
import '../models/item.dart';
import '../models/premium_package.dart';

/// Canlı oyun içeriği: global_items, global_classes, global_maps.
class GameContentService {
  GameContentService._();

  static final GameContentService instance = GameContentService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String itemsCollection = 'global_items';
  static const String classesCollection = 'global_classes';
  static const String mapsCollection = 'global_maps';
  static const String eventsCollection = 'global_events';
  static const String premiumPackagesCollection = 'premium_packages';
  static const String monstersCollection = 'global_monsters';

  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection(itemsCollection);
  CollectionReference<Map<String, dynamic>> get _classes =>
      _db.collection(classesCollection);
  CollectionReference<Map<String, dynamic>> get _maps =>
      _db.collection(mapsCollection);
  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection(eventsCollection);
  CollectionReference<Map<String, dynamic>> get _premiumPackages =>
      _db.collection(premiumPackagesCollection);
  CollectionReference<Map<String, dynamic>> get _monsters =>
      _db.collection(monstersCollection);

  // ——— Items ———

  Stream<List<Item>> watchShopItems() {
    return _items.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return defaultShopItems;
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Item.fromMap({...data, 'id': doc.id});
      }).toList()
        ..sort((a, b) => a.requiredLevel.compareTo(b.requiredLevel));
    });
  }

  Future<void> upsertItem(String id, Item item) async {
    await _items.doc(id).set(item.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteItem(String id) async {
    await _items.doc(id).delete();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchItemDocs() {
    return _items.snapshots().map((s) => s.docs);
  }

  // ——— Classes ———

  Stream<List<GameClassDefinition>> watchClasses() {
    return _classes.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return defaultClasses;
      return snapshot.docs
          .map((d) => GameClassDefinition.fromMap(d.id, d.data()))
          .toList();
    });
  }

  Future<GameClassDefinition?> getClassById(String id) async {
    final doc = await _classes.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return GameClassDefinition.fromMap(doc.id, doc.data()!);
    }
    for (final c in defaultClasses) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> upsertClass(String id, GameClassDefinition definition) async {
    await _classes.doc(id).set(definition.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteClass(String id) async {
    await _classes.doc(id).delete();
  }

  // ——— Maps ———

  Stream<List<GameMapDefinition>> watchMaps() {
    return _maps.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return defaultMaps;
      return snapshot.docs
          .map((d) => GameMapDefinition.fromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) => a.requiredLevel.compareTo(b.requiredLevel));
    });
  }

  Future<void> upsertMap(String id, GameMapDefinition definition) async {
    await _maps.doc(id).set(definition.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteMap(String id) async {
    await _maps.doc(id).delete();
  }

  // ——— Monsters ———

  Stream<List<GameMonsterDefinition>> watchMonsters() {
    return _monsters.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return defaultMonsters;
      return snapshot.docs
          .map((d) => GameMonsterDefinition.fromMap(d.id, d.data()))
          .toList();
    });
  }

  Future<List<GameMonsterDefinition>> fetchMonstersOnce() async {
    final snap = await _monsters.get();
    if (snap.docs.isEmpty) return defaultMonsters;
    return snap.docs
        .map((d) => GameMonsterDefinition.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> upsertMonster(String id, GameMonsterDefinition monster) async {
    await _monsters.doc(id).set(monster.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteMonster(String id) async {
    await _monsters.doc(id).delete();
  }

  // ——— Live Events ———

  Stream<List<GameEventDefinition>> watchEvents() {
    return _events.snapshots().map((snapshot) {
      return snapshot.docs
          .map((d) => GameEventDefinition.fromMap(d.id, d.data()))
          .where((e) => e.isActive)
          .toList();
    });
  }

  Stream<List<GameEventDefinition>> watchAllEventsAdmin() {
    return _events.snapshots().map((snapshot) {
      return snapshot.docs
          .map((d) => GameEventDefinition.fromMap(d.id, d.data()))
          .toList();
    });
  }

  Future<void> upsertEvent(String id, GameEventDefinition event) async {
    await _events.doc(id).set(event.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteEvent(String id) async {
    await _events.doc(id).delete();
  }

  // ——— Premium Packages ———

  Stream<List<PremiumPackage>> watchPremiumPackages() {
    return _premiumPackages.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return defaultPremiumPackages;
      return snapshot.docs
          .map((d) => PremiumPackage.fromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) => a.price.compareTo(b.price));
    });
  }

  Future<void> upsertPremiumPackage(String id, PremiumPackage package) async {
    await _premiumPackages.doc(id).set(package.toMap(), SetOptions(merge: true));
  }

  Future<void> deletePremiumPackage(String id) async {
    await _premiumPackages.doc(id).delete();
  }

  /// Mobil / admin için yerel yedek mağaza listesi.
  static List<Item> get defaultShopItems => [
        const Item(
          id: 'rusty_sword',
          name: 'Paslı Kılıç',
          price: 50,
          bonusDamage: 10,
          itemType: ItemType.weapon,
          rarity: ItemRarity.common,
          requiredLevel: 1,
          criticalChance: 0.05,
          imagePath: 'assets/images/items/sword.png',
        ),
        const Item(
          id: 'iron_armor',
          name: 'Demir Zırh',
          price: 100,
          bonusDefense: 5,
          itemType: ItemType.armor,
          rarity: ItemRarity.common,
          requiredLevel: 2,
          imagePath: 'assets/images/items/iron_armor.png',
        ),
        const Item(
          id: 'health_potion',
          name: 'Can İksiri',
          price: 20,
          itemType: ItemType.potion,
          rarity: ItemRarity.common,
          requiredLevel: 1,
          imagePath: 'assets/images/items/health_potion.png',
        ),
      ];

  static List<GameClassDefinition> get defaultClasses => [
        const GameClassDefinition(
          id: 'warrior',
          name: 'Savaşçı',
          startHp: 100,
          startEnergy: 0,
          description: 'Kılıcını sallayarak canavarları yen.',
          actionType: ClassActionType.shake,
        ),
        const GameClassDefinition(
          id: 'mage',
          name: 'Büyücü',
          startHp: 80,
          startEnergy: 100,
          description: 'Rün çizerek büyü yapar.',
          actionType: ClassActionType.runeDraw,
        ),
      ];

  static List<GameMapDefinition> get defaultMaps => [
        const GameMapDefinition(
          id: 'bedroom_dungeon',
          name: 'Yatak Odası Zindanı',
          requiredLevel: 1,
          monsterCount: 3,
          backgroundImagePath: 'assets/images/maps/bedroom.png',
        ),
        const GameMapDefinition(
          id: 'lava_cave',
          name: 'Lav Mağarası',
          requiredLevel: 5,
          monsterCount: 5,
          backgroundImagePath: 'assets/images/maps/lava.png',
        ),
      ];

  static List<GameMonsterDefinition> get defaultMonsters => [
        const GameMonsterDefinition(
          id: 'sleepy_slime',
          name: 'Uykulu Slime',
          hp: 50,
          rewardGold: 28,
          rewardXp: 12,
          imagePath: 'assets/images/monsters/slime.png',
        ),
        const GameMonsterDefinition(
          id: 'tired_bat',
          name: 'Yorgun Yarasa',
          hp: 70,
          rewardGold: 35,
          rewardXp: 16,
          imagePath: 'assets/images/monsters/tired_bat.png',
          minLevel: 3,
        ),
      ];

  static List<PremiumPackage> get defaultPremiumPackages => [
        const PremiumPackage(
          id: 'gem_starter',
          name: 'Başlangıç Kesesi',
          diamondAmount: 100,
          price: 29.99,
          iconPath: 'assets/images/items/health_potion.png',
          currencyLabel: 'TRY',
        ),
        const PremiumPackage(
          id: 'gem_pouch',
          name: 'Kese Dolusu Elmas',
          diamondAmount: 500,
          price: 149.99,
          iconPath: 'assets/images/items/health_potion.png',
          currencyLabel: 'TRY',
        ),
      ];
}
