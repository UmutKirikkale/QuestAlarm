/// Mağaza fiyatının hangi para birimiyle ödeneceği.
enum ShopCurrency {
  gold,
  diamond,
}

extension ShopCurrencyX on ShopCurrency {
  String get label => switch (this) {
        ShopCurrency.gold => 'Altın',
        ShopCurrency.diamond => 'Elmas',
      };

  String get symbol => switch (this) {
        ShopCurrency.gold => 'G',
        ShopCurrency.diamond => '💎',
      };

  String formatPrice(int price) => '$price $symbol';

  static ShopCurrency parse(String? value) {
    return ShopCurrency.values.firstWhere(
      (c) => c.name == value,
      orElse: () => ShopCurrency.gold,
    );
  }
}
