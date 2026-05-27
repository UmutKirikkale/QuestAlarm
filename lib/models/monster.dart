import 'dart:math';

/// Alarm savaşında kullanılacak canavar modeli.
class Monster {
  const Monster({
    required this.name,
    required this.maxHP,
    required this.currentHP,
    required this.rewardGold,
    required this.rewardXP,
    required this.imagePath,
    this.isBoss = false,
  });

  final String name;
  final int maxHP;
  final int currentHP;
  final int rewardGold;
  final int rewardXP;
  final String imagePath;
  final bool isBoss;

  Monster copyWith({
    String? name,
    int? maxHP,
    int? currentHP,
    int? rewardGold,
    int? rewardXP,
    String? imagePath,
    bool? isBoss,
  }) {
    return Monster(
      name: name ?? this.name,
      maxHP: maxHP ?? this.maxHP,
      currentHP: currentHP ?? this.currentHP,
      rewardGold: rewardGold ?? this.rewardGold,
      rewardXP: rewardXP ?? this.rewardXP,
      imagePath: imagePath ?? this.imagePath,
      isBoss: isBoss ?? this.isBoss,
    );
  }

  static const String monstersBase = 'assets/images/monsters';

  static String monsterImage(String fileName) => '$monstersBase/$fileName';

  static const Monster sundayBoss = Monster(
    name: 'Pijama Ejderhasi',
    maxHP: 500,
    currentHP: 500,
    rewardGold: 180,
    rewardXP: 90,
    imagePath: 'assets/images/monsters/pajama_dragon.png',
    isBoss: true,
  );

  static const List<Monster> _bossPool = [
    Monster(
      name: 'Alarm Minotauru',
      maxHP: 420,
      currentHP: 420,
      rewardGold: 150,
      rewardXP: 75,
      imagePath: 'assets/images/monsters/nightmare_orc.png',
      isBoss: true,
    ),
    Monster(
      name: 'Rüya Kemik Lordu',
      maxHP: 460,
      currentHP: 460,
      rewardGold: 165,
      rewardXP: 82,
      imagePath: 'assets/images/monsters/insomniac_lich.png',
      isBoss: true,
    ),
  ];

  static const List<Monster> _earlyGame = [
    Monster(
      name: 'Uykulu Slime',
      maxHP: 50,
      currentHP: 50,
      rewardGold: 28,
      rewardXP: 12,
      imagePath: 'assets/images/monsters/slime.png',
    ),
    Monster(
      name: 'Yorgun Yarasa',
      maxHP: 70,
      currentHP: 70,
      rewardGold: 35,
      rewardXP: 16,
      imagePath: 'assets/images/monsters/tired_bat.png',
    ),
    Monster(
      name: 'Yastik Mimigi',
      maxHP: 80,
      currentHP: 80,
      rewardGold: 40,
      rewardXP: 18,
      imagePath: 'assets/images/monsters/slime.png',
    ),
    Monster(
      name: 'Uyanik Fare',
      maxHP: 95,
      currentHP: 95,
      rewardGold: 44,
      rewardXP: 20,
      imagePath: 'assets/images/monsters/tired_bat.png',
    ),
  ];

  static const List<Monster> _midGame = [
    Monster(
      name: 'Horlayan Goblin',
      maxHP: 120,
      currentHP: 120,
      rewardGold: 52,
      rewardXP: 25,
      imagePath: 'assets/images/monsters/snoring_goblin.png',
    ),
    Monster(
      name: 'Kabusa Kapilan Ork',
      maxHP: 150,
      currentHP: 150,
      rewardGold: 62,
      rewardXP: 30,
      imagePath: 'assets/images/monsters/nightmare_orc.png',
    ),
    Monster(
      name: 'Sis Sovalyesi',
      maxHP: 170,
      currentHP: 170,
      rewardGold: 70,
      rewardXP: 34,
      imagePath: 'assets/images/monsters/snoring_goblin.png',
    ),
    Monster(
      name: 'Yatak Bugu Kolonisi',
      maxHP: 185,
      currentHP: 185,
      rewardGold: 74,
      rewardXP: 37,
      imagePath: 'assets/images/monsters/nightmare_orc.png',
    ),
  ];

  static const List<Monster> _lateGame = [
    Monster(
      name: 'Yatak Hayaleti',
      maxHP: 250,
      currentHP: 250,
      rewardGold: 95,
      rewardXP: 48,
      imagePath: 'assets/images/monsters/bed_ghost.png',
    ),
    Monster(
      name: 'Uykusuz Lich',
      maxHP: 320,
      currentHP: 320,
      rewardGold: 120,
      rewardXP: 58,
      imagePath: 'assets/images/monsters/insomniac_lich.png',
    ),
    Monster(
      name: 'Kabus Valkiri',
      maxHP: 360,
      currentHP: 360,
      rewardGold: 132,
      rewardXP: 64,
      imagePath: 'assets/images/monsters/bed_ghost.png',
    ),
    Monster(
      name: 'Zifir Golem',
      maxHP: 390,
      currentHP: 390,
      rewardGold: 145,
      rewardXP: 70,
      imagePath: 'assets/images/monsters/insomniac_lich.png',
    ),
  ];

  static Monster forPlayerLevel(int level, Random random) {
    if (DateTime.now().weekday == DateTime.sunday) {
      return sundayBoss;
    }

    // Pazar dışı günlerde de yüksek seviyelerde ara sıra boss karşılaşması.
    if (level >= 8 && random.nextDouble() < 0.18) {
      return _bossPool[random.nextInt(_bossPool.length)];
    }

    final pool = level >= 10
        ? _lateGame
        : level >= 5
            ? _midGame
            : _earlyGame;
    return pool[random.nextInt(pool.length)];
  }
}
