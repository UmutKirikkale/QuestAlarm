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
  final CharacterClass characterClass;
  final bool hasChosenClass;

  /// Ardışık uyanma / zafer günü serisi.
  final int streak;

  final EquippedItem? equippedWeapon;
  final EquippedItem? equippedArmor;

  const Player({
    required this.level,
    required this.currentXP,
    required this.nextLevelXP,
    required this.currentHP,
    required this.maxHP,
    required this.gold,
    required this.characterClass,
    this.hasChosenClass = true,
    this.streak = 0,
    this.equippedWeapon,
    this.equippedArmor,
  });

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
      'characterClass': characterClass.name,
      'hasChosenClass': hasChosenClass,
      'streak': streak,
      if (equippedWeapon != null) 'equippedWeapon': equippedWeapon!.toMap(),
      if (equippedArmor != null) 'equippedArmor': equippedArmor!.toMap(),
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
      characterClass: _parseCharacterClass(map['characterClass'] as String?),
      hasChosenClass: map['hasChosenClass'] as bool? ?? true,
      streak: map['streak'] as int? ?? 0,
      equippedWeapon: parseEquipped('equippedWeapon'),
      equippedArmor: parseEquipped('equippedArmor'),
    );
  }

  Player copyWith({
    int? level,
    int? currentXP,
    int? nextLevelXP,
    int? currentHP,
    int? maxHP,
    int? gold,
    CharacterClass? characterClass,
    bool? hasChosenClass,
    int? streak,
    EquippedItem? equippedWeapon,
    EquippedItem? equippedArmor,
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
      characterClass: characterClass ?? this.characterClass,
      hasChosenClass: hasChosenClass ?? this.hasChosenClass,
      streak: streak ?? this.streak,
      equippedWeapon: clearWeapon ? null : (equippedWeapon ?? this.equippedWeapon),
      equippedArmor: clearArmor ? null : (equippedArmor ?? this.equippedArmor),
    );
  }

  static CharacterClass _parseCharacterClass(String? value) {
    return CharacterClass.values.firstWhere(
      (c) => c.name == value,
      orElse: () => CharacterClass.warrior,
    );
  }
}
