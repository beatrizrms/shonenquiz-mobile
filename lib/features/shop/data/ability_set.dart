class AccessoryItem {
  final String itemRef;
  final String name;
  final String? emoji;

  const AccessoryItem({required this.itemRef, required this.name, this.emoji});

  factory AccessoryItem.fromJson(Map<String, dynamic> j) => AccessoryItem(
        itemRef: j['itemRef'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String?,
      );
}

class AbilitySet {
  final String itemRef;
  final String name;
  final String? description;
  final String? emoji;
  final int? priceCoins;
  final int? priceGems;
  final List<AccessoryItem> accessories;
  final int ownedCount;
  final int totalCount;

  final String? abilityName;
  final String? abilityDescription;
  final String? abilityType;      // chave de efeito: sharingan | eye_of_zeno | etc.
  final String? abilityEmoji;     // emoji da habilidade
  final String? abilityCategory;  // time | hint | question
  final int abilityCooldown;      // perguntas até reativar

  const AbilitySet({
    required this.itemRef,
    required this.name,
    this.description,
    this.emoji,
    this.priceCoins,
    this.priceGems,
    required this.accessories,
    required this.ownedCount,
    required this.totalCount,
    this.abilityName,
    this.abilityDescription,
    this.abilityType,
    this.abilityEmoji,
    this.abilityCategory,
    this.abilityCooldown = 3,
  });

  factory AbilitySet.fromJson(Map<String, dynamic> j) => AbilitySet(
        itemRef: j['itemRef'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        emoji: j['emoji'] as String?,
        priceCoins: (j['priceCoins'] as num?)?.toInt(),
        priceGems: (j['priceGems'] as num?)?.toInt(),
        accessories: (j['accessories'] as List)
            .map((e) => AccessoryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        ownedCount: (j['ownedCount'] as num? ?? 0).toInt(),
        totalCount: (j['totalCount'] as num? ?? 0).toInt(),
        abilityName: j['abilityName'] as String?,
        abilityDescription: j['abilityDescription'] as String?,
        abilityType: j['abilityType'] as String?,
        abilityEmoji: j['abilityEmoji'] as String?,
        abilityCategory: j['abilityCategory'] as String?,
        abilityCooldown: (j['abilityCooldown'] as num? ?? 3).toInt(),
      );
}
