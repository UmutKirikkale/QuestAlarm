/// Mağazada satılan eşyanın türünü temsil eder.
enum ItemType {
  weapon,
  armor,
  potion,
}

/// Mağazada satılacak eşyaları temsil eden veri modeli.
///
/// Silahlar [bonusDamage], zırhlar [bonusDefense] değerlerini taşır.
/// İksirler ileride farklı etkiler için genişletilebilir.
class Item {
  /// Eşyanın benzersiz kimliği.
  final String id;

  /// Eşyanın görünen adı.
  final String name;

  /// Mağazadaki satış fiyatı (altın).
  final int price;

  /// Silah bonus hasarı (yalnızca [ItemType.weapon] için anlamlı).
  final int bonusDamage;

  /// Zırh bonus savunması (yalnızca [ItemType.armor] için anlamlı).
  final int bonusDefense;

  /// Eşyanın türü (Silah, Zırh, İksir).
  final ItemType itemType;

  const Item({
    required this.id,
    required this.name,
    required this.price,
    this.bonusDamage = 0,
    this.bonusDefense = 0,
    required this.itemType,
  });

  /// [shared_preferences] veya JSON depolama için Map'e dönüştürür.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'bonusDamage': bonusDamage,
      'bonusDefense': bonusDefense,
      'itemType': itemType.name,
    };
  }

  /// Map verisinden [Item] nesnesi oluşturur.
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown Item',
      price: map['price'] as int? ?? 0,
      bonusDamage: map['bonusDamage'] as int? ?? 0,
      bonusDefense: map['bonusDefense'] as int? ?? 0,
      itemType: _parseItemType(map['itemType'] as String?),
    );
  }

  /// String değerini güvenli şekilde [ItemType] enum'una çevirir.
  static ItemType _parseItemType(String? value) {
    return ItemType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => ItemType.potion,
    );
  }
}
