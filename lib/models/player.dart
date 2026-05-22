/// Oyuncu karakterinin sınıfını temsil eder.
enum CharacterClass {
  warrior,
  mage,
  rogue,
}

/// RPG karakterinin tüm istatistiklerini tutan veri modeli.
///
/// [shared_preferences] ile kalıcı depolama için [toMap] ve [fromMap]
/// metodları kullanılır.
class Player {
  /// Karakter seviyesi.
  final int level;

  /// Mevcut deneyim puanı.
  final int currentXP;

  /// Bir sonraki seviyeye ulaşmak için gereken XP.
  final int nextLevelXP;

  /// Güncel can puanı.
  final int currentHP;

  /// Maksimum can puanı.
  final int maxHP;

  /// Toplanan altın miktarı.
  final int gold;

  /// Karakterin sınıfı (Savaşçı, Büyücü, Hırsız).
  final CharacterClass characterClass;

  const Player({
    required this.level,
    required this.currentXP,
    required this.nextLevelXP,
    required this.currentHP,
    required this.maxHP,
    required this.gold,
    required this.characterClass,
  });

  /// Yeni oyuncu için varsayılan başlangıç değerleri.
  factory Player.initial({CharacterClass characterClass = CharacterClass.warrior}) {
    return Player(
      level: 1,
      currentXP: 0,
      nextLevelXP: 100,
      currentHP: 100,
      maxHP: 100,
      gold: 0,
      characterClass: characterClass,
    );
  }

  /// [shared_preferences] veya JSON depolama için Map'e dönüştürür.
  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'currentXP': currentXP,
      'nextLevelXP': nextLevelXP,
      'currentHP': currentHP,
      'maxHP': maxHP,
      'gold': gold,
      'characterClass': characterClass.name,
    };
  }

  /// Map verisinden [Player] nesnesi oluşturur.
  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      level: map['level'] as int? ?? 1,
      currentXP: map['currentXP'] as int? ?? 0,
      nextLevelXP: map['nextLevelXP'] as int? ?? 100,
      currentHP: map['currentHP'] as int? ?? 100,
      maxHP: map['maxHP'] as int? ?? 100,
      gold: map['gold'] as int? ?? 0,
      characterClass: _parseCharacterClass(map['characterClass'] as String?),
    );
  }

  /// Belirtilen alanları güncelleyerek yeni bir [Player] kopyası döndürür.
  Player copyWith({
    int? level,
    int? currentXP,
    int? nextLevelXP,
    int? currentHP,
    int? maxHP,
    int? gold,
    CharacterClass? characterClass,
  }) {
    return Player(
      level: level ?? this.level,
      currentXP: currentXP ?? this.currentXP,
      nextLevelXP: nextLevelXP ?? this.nextLevelXP,
      currentHP: currentHP ?? this.currentHP,
      maxHP: maxHP ?? this.maxHP,
      gold: gold ?? this.gold,
      characterClass: characterClass ?? this.characterClass,
    );
  }

  /// String değerini güvenli şekilde [CharacterClass] enum'una çevirir.
  static CharacterClass _parseCharacterClass(String? value) {
    return CharacterClass.values.firstWhere(
      (c) => c.name == value,
      orElse: () => CharacterClass.warrior,
    );
  }
}
