/// Firestore `premium_packages` — gerçek parayla satılacak elmas paketi.
class PremiumPackage {
  const PremiumPackage({
    required this.id,
    required this.name,
    required this.diamondAmount,
    required this.price,
    required this.iconPath,
    this.currencyLabel = 'TRY',
  });

  final String id;
  final String name;
  final int diamondAmount;
  final double price;
  final String iconPath;

  /// Fiyat etiketi (örn. TRY, USD).
  final String currencyLabel;

  String get formattedPrice {
    final symbol = switch (currencyLabel.toUpperCase()) {
      'USD' => '\$',
      'EUR' => '€',
      'TRY' => '₺',
      _ => '$currencyLabel ',
    };
    if (currencyLabel.toUpperCase() == 'TRY') {
      return '$symbol${price.toStringAsFixed(0)}';
    }
    return '$symbol${price.toStringAsFixed(2)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'diamondAmount': diamondAmount,
      'price': price,
      'iconPath': iconPath,
      'currencyLabel': currencyLabel,
    };
  }

  factory PremiumPackage.fromMap(String id, Map<String, dynamic> map) {
    return PremiumPackage(
      id: id,
      name: map['name'] as String? ?? id,
      diamondAmount: (map['diamondAmount'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      iconPath: map['iconPath'] as String? ?? 'assets/images/items/health_potion.png',
      currencyLabel: map['currencyLabel'] as String? ?? 'TRY',
    );
  }
}
