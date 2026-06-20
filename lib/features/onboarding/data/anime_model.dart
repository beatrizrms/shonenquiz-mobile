class AnimeModel {
  final String id;
  final String name;
  final String slug;
  final String category;
  final bool isFixed;
  final String? coverUrl;

  const AnimeModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.category,
    required this.isFixed,
    this.coverUrl,
  });

  factory AnimeModel.fromJson(Map<String, dynamic> json) => AnimeModel(
        id:       json['id']       as String,
        name:     json['name']     as String,
        slug:     json['slug']     as String,
        category: json['category'] as String,
        isFixed:  json['isFixed']  as bool,
        coverUrl: json['coverUrl'] as String?,
      );
}
