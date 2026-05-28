/// Firestore `global_monsters` dokümanı.
class GameMonsterDefinition {
  const GameMonsterDefinition({
    required this.id,
    required this.name,
    required this.hp,
    required this.rewardGold,
    required this.rewardXp,
    required this.imagePath,
    this.minLevel = 1,
    this.isBoss = false,
  });

  final String id;
  final String name;
  final int hp;
  final int rewardGold;
  final int rewardXp;
  final String imagePath;
  final int minLevel;
  final bool isBoss;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'hp': hp,
      'rewardGold': rewardGold,
      'rewardXp': rewardXp,
      'imagePath': imagePath,
      'minLevel': minLevel,
      'isBoss': isBoss,
    };
  }

  factory GameMonsterDefinition.fromMap(String id, Map<String, dynamic> map) {
    return GameMonsterDefinition(
      id: id,
      name: map['name'] as String? ?? id,
      hp: (map['hp'] as num?)?.toInt() ?? 50,
      rewardGold: (map['rewardGold'] as num?)?.toInt() ?? 20,
      rewardXp: (map['rewardXp'] as num?)?.toInt() ?? 10,
      imagePath:
          map['imagePath'] as String? ?? 'assets/images/monsters/slime.png',
      minLevel: (map['minLevel'] as num?)?.toInt() ?? 1,
      isBoss: map['isBoss'] as bool? ?? false,
    );
  }
}
