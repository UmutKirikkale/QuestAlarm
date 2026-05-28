/// Firestore `global_settings/app` tek dokümanı.
class GlobalSettings {
  const GlobalSettings({
    this.maintenanceMode = false,
    this.dailyQuestText = '',
    this.levelXpExponent = defaultLevelXpExponent,
    this.streakBonusPerDay = defaultStreakBonusPerDay,
    this.maxStreakMultiplier = defaultMaxStreakMultiplier,
    this.repairCostPerDurability = defaultRepairCostPerDurability,
    this.proXpMultiplier = defaultProXpMultiplier,
    this.proGoldMultiplier = defaultProGoldMultiplier,
    this.proRepairCost = defaultProRepairCost,
  });

  static const String documentId = 'app';

  static const double defaultLevelXpExponent = 1.2;
  static const double defaultStreakBonusPerDay = 0.1;
  static const double defaultMaxStreakMultiplier = 2.0;
  static const double defaultRepairCostPerDurability = 0.5;
  static const double defaultProXpMultiplier = 1.1;
  static const double defaultProGoldMultiplier = 1.2;
  static const double defaultProRepairCost = 0.3;

  final bool maintenanceMode;
  final String dailyQuestText;

  /// Sonraki seviye için gereken XP = mevcut * üs.
  final double levelXpExponent;

  /// Her streak günü için ek çarpan: 1 + (streak × bu değer).
  final double streakBonusPerDay;

  /// Streak ödül çarpanı üst sınırı (örn. 2.0 = en fazla 2×).
  final double maxStreakMultiplier;

  /// 1 dayanıklılık puanı başına tamir altın maliyeti.
  final double repairCostPerDurability;

  /// Pro oyuncular için ek XP çarpanı (zafer ödülü).
  final double proXpMultiplier;

  /// Pro oyuncular için ek altın çarpanı (zafer ödülü).
  final double proGoldMultiplier;

  /// Pro oyuncular için dayanıklılık başına tamir maliyeti.
  final double proRepairCost;

  Map<String, dynamic> toMap() {
    return {
      'maintenanceMode': maintenanceMode,
      'dailyQuestText': dailyQuestText,
      'levelXpExponent': levelXpExponent,
      'streakBonusPerDay': streakBonusPerDay,
      'maxStreakMultiplier': maxStreakMultiplier,
      'repairCostPerDurability': repairCostPerDurability,
      'proXpMultiplier': proXpMultiplier,
      'proGoldMultiplier': proGoldMultiplier,
      'proRepairCost': proRepairCost,
    };
  }

  factory GlobalSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const GlobalSettings();
    return GlobalSettings(
      maintenanceMode: map['maintenanceMode'] as bool? ?? false,
      dailyQuestText: map['dailyQuestText'] as String? ?? '',
      levelXpExponent: _readDouble(map['levelXpExponent'], defaultLevelXpExponent),
      streakBonusPerDay:
          _readDouble(map['streakBonusPerDay'], defaultStreakBonusPerDay),
      maxStreakMultiplier:
          _readDouble(map['maxStreakMultiplier'], defaultMaxStreakMultiplier),
      repairCostPerDurability: _readDouble(
        map['repairCostPerDurability'],
        defaultRepairCostPerDurability,
      ),
      proXpMultiplier:
          _readDouble(map['proXpMultiplier'], defaultProXpMultiplier),
      proGoldMultiplier:
          _readDouble(map['proGoldMultiplier'], defaultProGoldMultiplier),
      proRepairCost: _readDouble(map['proRepairCost'], defaultProRepairCost),
    );
  }

  static double _readDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  /// Streak'e göre zafer ödül çarpanı (1.0 … [maxStreakMultiplier]).
  double streakMultiplierFor(int streak) {
    if (streak <= 0) return 1.0;
    final raw = 1.0 + (streak * streakBonusPerDay);
    return raw.clamp(1.0, maxStreakMultiplier);
  }

  /// Seviye atlayınca bir sonraki seviye XP eşiği.
  int scaledNextLevelXp(int currentNextLevelXp) {
    final base = currentNextLevelXp > 0 ? currentNextLevelXp : 100;
    final scaled = (base * levelXpExponent).round();
    return scaled < 1 ? 1 : scaled;
  }

  /// Eksik dayanıklılık puanları için tamir altın maliyeti.
  int repairGoldCost(int missingDurabilityPoints, {bool isPro = false}) {
    if (missingDurabilityPoints <= 0) return 0;
    final rate =
        isPro ? proRepairCost : repairCostPerDurability;
    final cost = missingDurabilityPoints * rate;
    return cost.ceil().clamp(0, 999999999);
  }

  GlobalSettings copyWith({
    bool? maintenanceMode,
    String? dailyQuestText,
    double? levelXpExponent,
    double? streakBonusPerDay,
    double? maxStreakMultiplier,
    double? repairCostPerDurability,
    double? proXpMultiplier,
    double? proGoldMultiplier,
    double? proRepairCost,
  }) {
    return GlobalSettings(
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      dailyQuestText: dailyQuestText ?? this.dailyQuestText,
      levelXpExponent: levelXpExponent ?? this.levelXpExponent,
      streakBonusPerDay: streakBonusPerDay ?? this.streakBonusPerDay,
      maxStreakMultiplier: maxStreakMultiplier ?? this.maxStreakMultiplier,
      repairCostPerDurability:
          repairCostPerDurability ?? this.repairCostPerDurability,
      proXpMultiplier: proXpMultiplier ?? this.proXpMultiplier,
      proGoldMultiplier: proGoldMultiplier ?? this.proGoldMultiplier,
      proRepairCost: proRepairCost ?? this.proRepairCost,
    );
  }
}
