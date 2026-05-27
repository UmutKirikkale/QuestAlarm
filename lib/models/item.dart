/// Mağazada satılan eşyanın türünü temsil eder.
enum ItemType {
  weapon,
  armor,
  potion,
}

/// Eşya nadirlik katmanı.
enum ItemRarity {
  common,
  rare,
  epic,
  legendary,
}

/// Mağazada satılacak eşyaları temsil eden veri modeli.
///
/// Silahlar [bonusDamage], zırhlar [bonusDefense] değerlerini taşır.
/// İksirler ileride farklı etkiler için genişletilebilir.
class Item {
  static const String itemsBase = 'assets/images/items';

  /// Eşya id'sine göre varsayılan sprite yolu.
  static String defaultImagePath(String id) => '$itemsBase/$id.png';

  /// Eşyanın benzersiz kimliği.
  final String id;

  /// Eşyanın görünen adı.
  final String name;

  /// Mağazadaki satış fiyatı (altın).
  final int price;

  /// Silah bonus hasarı (yalnızca [ItemType.weapon] için anlamlı).
  final int bonusDamage;

  /// Kritik vuruş olasılığı (0.0 - 1.0).
  final double criticalChance;

  /// Zırh bonus savunması (yalnızca [ItemType.armor] için anlamlı).
  final int bonusDefense;

  /// Eşyanın türü (Silah, Zırh, İksir).
  final ItemType itemType;

  /// Eşyanın nadirlik seviyesi.
  final ItemRarity rarity;

  /// Satın almak için gereken minimum oyuncu seviyesi.
  final int requiredLevel;

  /// Piksel sprite dosya yolu.
  final String imagePath;

  const Item({
    required this.id,
    required this.name,
    required this.price,
    this.bonusDamage = 0,
    this.criticalChance = 0.0,
    this.bonusDefense = 0,
    required this.itemType,
    this.rarity = ItemRarity.common,
    this.requiredLevel = 1,
    String? imagePath,
  }) : assert(criticalChance >= 0.0 && criticalChance <= 1.0),
       imagePath = imagePath ?? '$itemsBase/$id.png';

  /// [shared_preferences] veya JSON depolama için Map'e dönüştürür.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'bonusDamage': bonusDamage,
      'criticalChance': criticalChance,
      'bonusDefense': bonusDefense,
      'itemType': itemType.name,
      'rarity': rarity.name,
      'requiredLevel': requiredLevel,
      'imagePath': imagePath,
    };
  }

  /// Map verisinden [Item] nesnesi oluşturur.
  factory Item.fromMap(Map<String, dynamic> map) {
    final id = map['id'] as String? ?? '';
    return Item(
      id: id,
      name: map['name'] as String? ?? 'Unknown Item',
      price: map['price'] as int? ?? 0,
      bonusDamage: map['bonusDamage'] as int? ?? 0,
      criticalChance: (map['criticalChance'] as num?)?.toDouble() ?? 0.0,
      bonusDefense: map['bonusDefense'] as int? ?? 0,
      itemType: _parseItemType(map['itemType'] as String?),
      rarity: _parseItemRarity(map['rarity'] as String?),
      requiredLevel: map['requiredLevel'] as int? ?? 1,
      imagePath: map['imagePath'] as String? ?? defaultImagePath(id),
    );
  }

  /// String değerini güvenli şekilde [ItemType] enum'una çevirir.
  static ItemType _parseItemType(String? value) {
    return ItemType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => ItemType.potion,
    );
  }

  static ItemRarity _parseItemRarity(String? value) {
    return ItemRarity.values.firstWhere(
      (r) => r.name == value,
      orElse: () => ItemRarity.common,
    );
  }
}
