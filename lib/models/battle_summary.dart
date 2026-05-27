enum BattleOutcome {
  victory,
  defeat,
  forfeit,
}

class BattleSummary {
  const BattleSummary({
    required this.outcome,
    required this.monsterName,
    required this.streakBefore,
    required this.streakAfter,
    required this.timestampIso,
    this.gainedXp = 0,
    this.gainedGold = 0,
    this.reason,
    this.brokenItems = const [],
  });

  final BattleOutcome outcome;
  final String monsterName;
  final int streakBefore;
  final int streakAfter;
  final int gainedXp;
  final int gainedGold;
  final String? reason;
  final List<String> brokenItems;
  final String timestampIso;

  Map<String, dynamic> toMap() {
    return {
      'outcome': outcome.name,
      'monsterName': monsterName,
      'streakBefore': streakBefore,
      'streakAfter': streakAfter,
      'gainedXp': gainedXp,
      'gainedGold': gainedGold,
      'reason': reason,
      'brokenItems': brokenItems,
      'timestampIso': timestampIso,
    };
  }

  factory BattleSummary.fromMap(Map<String, dynamic> map) {
    final outcomeName = map['outcome'] as String? ?? BattleOutcome.defeat.name;
    final outcome = BattleOutcome.values.firstWhere(
      (o) => o.name == outcomeName,
      orElse: () => BattleOutcome.defeat,
    );

    return BattleSummary(
      outcome: outcome,
      monsterName: map['monsterName'] as String? ?? 'Bilinmeyen Tehdit',
      streakBefore: map['streakBefore'] as int? ?? 0,
      streakAfter: map['streakAfter'] as int? ?? 0,
      gainedXp: map['gainedXp'] as int? ?? 0,
      gainedGold: map['gainedGold'] as int? ?? 0,
      reason: map['reason'] as String?,
      brokenItems: (map['brokenItems'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      timestampIso:
          map['timestampIso'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}
