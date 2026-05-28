import 'equipped_item.dart';
import 'item.dart';

/// Oyuncu karakterinin sınıfını temsil eder.
enum CharacterClass {
  warrior,
  mage,
  rogue,
}

/// RPG karakterinin tüm istatistiklerini tutan veri modeli.
class Player {
  final int level;
  final int currentXP;
  final int nextLevelXP;
  final int currentHP;
  final int maxHP;
  final int gold;

  /// Premium elmas para birimi.
  final int diamonds;

  final CharacterClass characterClass;

  /// Firestore `global_classes` doküman kimliği (dinamik sınıflar).
  final String characterClassId;

  final bool hasChosenClass;

  /// Ardışık uyanma / zafer günü serisi.
  final int streak;

  final EquippedItem? equippedWeapon;
  final EquippedItem? equippedArmor;

  /// Satın alınmış harita kimlikleri (`global_maps`).
  final List<String> unlockedMapIds;

  /// Pro üyelik — reklamsız deneyim ve bonus ekonomi.
  final bool isPro;

  Player({
    required this.level,
    required this.currentXP,
    required this.nextLevelXP,
    required this.currentHP,
    required this.maxHP,
    required this.gold,
    this.diamonds = 0,
    required this.characterClass,
    String? characterClassId,
    this.hasChosenClass = true,
    this.streak = 0,
    this.equippedWeapon,
    this.equippedArmor,
    this.unlockedMapIds = const [],
    this.isPro = false,
  }) : characterClassId = characterClassId ?? characterClass.name;

  bool hasUnlockedMap(String mapId) => unlockedMapIds.contains(mapId);

  /// Yeni oyuncu — başlangıç kılıcı %100 dayanıklılıkla kuşanılı.
  factory Player.initial({
    CharacterClass characterClass = CharacterClass.warrior,
    bool hasChosenClass = false,
  }) {
    return Player(
      level: 1,
      currentXP: 0,
      nextLevelXP: 100,
      currentHP: 100,
      maxHP: 100,
      gold: 0,
      characterClass: characterClass,
      hasChosenClass: hasChosenClass,
      streak: 0,
      equippedWeapon: EquippedItem(
        item: Item(
          id: 'rusty_sword',
          name: 'Paslı Kılıç',
          price: 50,
          bonusDamage: 10,
          criticalChance: 0.05,
          itemType: ItemType.weapon,
          imagePath: 'assets/images/items/sword.png',
        ),
        durability: 100,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'currentXP': currentXP,
      'nextLevelXP': nextLevelXP,
      'currentHP': currentHP,
      'maxHP': maxHP,
      'gold': gold,
      'diamonds': diamonds,
      'characterClass': characterClass.name,
      'characterClassId': characterClassId,
      'hasChosenClass': hasChosenClass,
      'streak': streak,
      if (equippedWeapon != null) 'equippedWeapon': equippedWeapon!.toMap(),
      if (equippedArmor != null) 'equippedArmor': equippedArmor!.toMap(),
      'unlockedMapIds': unlockedMapIds,
      'isPro': isPro,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    EquippedItem? parseEquipped(String key) {
      final raw = map[key];
      if (raw is Map<String, dynamic>) {
        return EquippedItem.fromMap(raw);
      }
      return null;
    }

    return Player(
      level: map['level'] as int? ?? 1,
      currentXP: map['currentXP'] as int? ?? 0,
      nextLevelXP: map['nextLevelXP'] as int? ?? 100,
      currentHP: map['currentHP'] as int? ?? 100,
      maxHP: map['maxHP'] as int? ?? 100,
      gold: map['gold'] as int? ?? 0,
      diamonds: map['diamonds'] as int? ?? 0,
      characterClass: _parseCharacterClass(map['characterClass'] as String?),
      characterClassId: map['characterClassId'] as String? ??
          map['characterClass'] as String?,
      hasChosenClass: map['hasChosenClass'] as bool? ?? true,
      streak: map['streak'] as int? ?? 0,
      equippedWeapon: parseEquipped('equippedWeapon'),
      equippedArmor: parseEquipped('equippedArmor'),
      unlockedMapIds: _parseStringList(map['unlockedMapIds']),
      isPro: map['isPro'] as bool? ?? false,
    );
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList(growable: false);
    }
    return const [];
  }

  Player copyWith({
    int? level,
    int? currentXP,
    int? nextLevelXP,
    int? currentHP,
    int? maxHP,
    int? gold,
    int? diamonds,
    CharacterClass? characterClass,
    String? characterClassId,
    bool? hasChosenClass,
    int? streak,
    EquippedItem? equippedWeapon,
    EquippedItem? equippedArmor,
    List<String>? unlockedMapIds,
    bool? isPro,
    bool clearWeapon = false,
    bool clearArmor = false,
  }) {
    return Player(
      level: level ?? this.level,
      currentXP: currentXP ?? this.currentXP,
      nextLevelXP: nextLevelXP ?? this.nextLevelXP,
      currentHP: currentHP ?? this.currentHP,
      maxHP: maxHP ?? this.maxHP,
      gold: gold ?? this.gold,
      diamonds: diamonds ?? this.diamonds,
      characterClass: characterClass ?? this.characterClass,
      characterClassId: characterClassId ?? this.characterClassId,
      hasChosenClass: hasChosenClass ?? this.hasChosenClass,
      streak: streak ?? this.streak,
      equippedWeapon: clearWeapon ? null : (equippedWeapon ?? this.equippedWeapon),
      equippedArmor: clearArmor ? null : (equippedArmor ?? this.equippedArmor),
      unlockedMapIds: unlockedMapIds ?? this.unlockedMapIds,
      isPro: isPro ?? this.isPro,
    );
  }

  static CharacterClass _parseCharacterClass(String? value) {
    return CharacterClass.values.firstWhere(
      (c) => c.name == value,
      orElse: () => CharacterClass.warrior,
    );
  }
}
