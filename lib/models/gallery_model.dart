class GalleryModel {
  final String id;
  final String name;
  final String? description;
  final String? coverImage;
  final int imageCount;
  final DateTime createdAt;

  GalleryModel({
    required this.id,
    required this.name,
    this.description,
    this.coverImage,
    required this.imageCount,
    required this.createdAt,
  });

  factory GalleryModel.fromJson(Map<String, dynamic> json) {
    return GalleryModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'],
      coverImage: json['cover_image'],
      imageCount: int.tryParse(json['image_count'].toString()) ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
    );
  }
}
