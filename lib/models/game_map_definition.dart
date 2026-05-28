import 'shop_currency.dart';

/// Firestore `global_maps` dokümanı.
class GameMapDefinition {
  const GameMapDefinition({
    required this.id,
    required this.name,
    required this.requiredLevel,
    required this.monsterCount,
    required this.backgroundImagePath,
    this.unlockPrice = 0,
    this.shopCurrency = ShopCurrency.gold,
    this.isProOnly = false,
  });

  final String id;
  final String name;
  final int requiredLevel;
  final int monsterCount;
  final String backgroundImagePath;

  /// 0 = sadece seviye ile açılır; >0 = bir kez satın alınır.
  final int unlockPrice;
  final ShopCurrency shopCurrency;

  /// Sadece Pro üyeler girebilir.
  final bool isProOnly;

  bool get requiresPurchase => unlockPrice > 0;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'requiredLevel': requiredLevel,
      'monsterCount': monsterCount,
      'backgroundImagePath': backgroundImagePath,
      'unlockPrice': unlockPrice,
      'shopCurrency': shopCurrency.name,
      'isProOnly': isProOnly,
    };
  }

  factory GameMapDefinition.fromMap(String id, Map<String, dynamic> map) {
    return GameMapDefinition(
      id: id,
      name: map['name'] as String? ?? id,
      requiredLevel: (map['requiredLevel'] as num?)?.toInt() ?? 1,
      monsterCount: (map['monsterCount'] as num?)?.toInt() ?? 3,
      backgroundImagePath:
          map['backgroundImagePath'] as String? ?? 'assets/images/maps/default.png',
      unlockPrice: (map['unlockPrice'] as num?)?.toInt() ?? 0,
      shopCurrency: ShopCurrencyX.parse(map['shopCurrency'] as String?),
      isProOnly: map['isProOnly'] as bool? ?? false,
    );
  }
}
