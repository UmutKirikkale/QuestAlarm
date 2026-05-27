import 'item.dart';

/// Envanterde veya kuşanılmış durumda bir eşya + dayanıklılık (0–100).
class EquippedItem {
  const EquippedItem({
    required this.item,
    this.durability = 100,
  }) : assert(durability >= 0 && durability <= 100);

  final Item item;
  final int durability;

  bool get isBroken => durability <= 0;

  EquippedItem copyWith({
    Item? item,
    int? durability,
  }) {
    return EquippedItem(
      item: item ?? this.item,
      durability: durability ?? this.durability,
    );
  }

  /// Dayanıklılığı [amount] kadar azaltır (0–100 ölçeğinde).
  EquippedItem reduceDurability(int amount) {
    return copyWith(durability: (durability - amount).clamp(0, 100));
  }

  Map<String, dynamic> toMap() {
    return {
      'item': item.toMap(),
      'durability': durability,
    };
  }

  factory EquippedItem.fromMap(Map<String, dynamic> map) {
    return EquippedItem(
      item: Item.fromMap(map['item'] as Map<String, dynamic>? ?? {}),
      durability: map['durability'] as int? ?? 100,
    );
  }
}
