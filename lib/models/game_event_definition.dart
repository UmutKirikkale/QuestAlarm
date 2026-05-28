/// Firestore `global_events` dokümanı.
class GameEventDefinition {
  const GameEventDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.targetCount,
    required this.rewardGold,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String description;
  final int targetCount;
  final int rewardGold;
  final bool isActive;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'targetCount': targetCount,
      'rewardGold': rewardGold,
      'isActive': isActive,
    };
  }

  factory GameEventDefinition.fromMap(String id, Map<String, dynamic> map) {
    return GameEventDefinition(
      id: id,
      name: map['name'] as String? ?? id,
      description: map['description'] as String? ?? '',
      targetCount: (map['targetCount'] as num?)?.toInt() ?? 1,
      rewardGold: (map['rewardGold'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}
