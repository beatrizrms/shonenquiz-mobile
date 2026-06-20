abstract final class AppAssets {
  static const logoUrl = 'https://pub-87999cdcc1b04a62a24b644753ae3d15.r2.dev/assets/logo-2.webp';

  static const _avatarBase = 'https://pub-87999cdcc1b04a62a24b644753ae3d15.r2.dev/assets/avatar';

  /// URL do PNG do gato (base do avatar).
  static String catUrl(String file) => '$_avatarBase/gatos/$file';

  /// URL do PNG dos olhos (overlay do avatar).
  static String eyeUrl(String file) => '$_avatarBase/olhos/$file';

  /// URL do PNG do cenário (fundo do avatar).
  static String backgroundUrl(String file) => '$_avatarBase/cenarios/$file';

  static const _storeBase = 'https://pub-87999cdcc1b04a62a24b644753ae3d15.r2.dev/store';

  /// URL da arte do conjunto/personagem (cosplay completo). Ex: 'naruto' → store/sets/naruto.webp
  static String setImageUrl(String setName) => '$_storeBase/sets/$setName.webp';

  /// URL do item avulso (overlay), nomeado pelo itemRef em store/items.
  static String itemImageUrl(String itemRef) => '$_storeBase/items/$itemRef.webp';
}
