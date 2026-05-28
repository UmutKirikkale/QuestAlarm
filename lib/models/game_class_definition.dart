/// Savaş ekranında kullanılan sınıf aksiyon tipi.
enum ClassActionType {
  shake,
  runeDraw,
  timed,
}

/// Firestore `global_classes` dokümanı.
class GameClassDefinition {
  const GameClassDefinition({
    required this.id,
    required this.name,
    required this.startHp,
    required this.startEnergy,
    required this.description,
    required this.actionType,
  });

  final String id;
  final String name;
  final int startHp;
  final int startEnergy;
  final String description;
  final ClassActionType actionType;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'startHp': startHp,
      'startEnergy': startEnergy,
      'description': description,
      'actionType': actionType.name,
    };
  }

  factory GameClassDefinition.fromMap(String id, Map<String, dynamic> map) {
    return GameClassDefinition(
      id: id,
      name: map['name'] as String? ?? id,
      startHp: (map['startHp'] as num?)?.toInt() ?? 100,
      startEnergy: (map['startEnergy'] as num?)?.toInt() ?? 0,
      description: map['description'] as String? ?? '',
      actionType: _parseActionType(map['actionType'] as String?),
    );
  }

  static ClassActionType _parseActionType(String? value) {
    return ClassActionType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => ClassActionType.shake,
    );
  }

  static String actionTypeLabel(ClassActionType type) {
    return switch (type) {
      ClassActionType.shake => 'Telefon Sallama',
      ClassActionType.runeDraw => 'Rün Çizme',
      ClassActionType.timed => 'Sabit Zamanlama',
    };
  }
}
