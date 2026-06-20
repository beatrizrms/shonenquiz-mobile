class ShopItem {
  final String itemRef;
  final String name;
  final String category;
  final String? description;
  final String? emoji;
  final String? setRef;
  final int? priceCoins;
  final int? priceGems;
  final bool isRotating;

  const ShopItem({
    required this.itemRef,
    required this.name,
    required this.category,
    this.description,
    this.emoji,
    this.setRef,
    this.priceCoins,
    this.priceGems,
    this.isRotating = false,
  });

  /// Item só comprável com gemas (premium).
  bool get isGemOnly => priceGems != null && priceCoins == null;

  factory ShopItem.fromJson(Map<String, dynamic> j) => ShopItem(
        itemRef: j['itemRef'] as String,
        name: j['name'] as String,
        category: j['category'] as String,
        description: j['description'] as String?,
        emoji: j['emoji'] as String?,
        setRef: j['setRef'] as String?,
        priceCoins: (j['priceCoins'] as num?)?.toInt(),
        priceGems: (j['priceGems'] as num?)?.toInt(),
        isRotating: j['isRotating'] as bool? ?? false,
      );
}
