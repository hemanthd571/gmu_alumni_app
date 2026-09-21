class AnnouncementModel {
  final int id;
  final int directorId;
  final String title;
  final String content;
  final String createdAt;
  final String directorName;
  final String directorProfilePicture;

  AnnouncementModel({
    required this.id,
    required this.directorId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.directorName,
    required this.directorProfilePicture,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'],
      directorId: json['director_id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['created_at'] ?? '',
      directorName: json['director_name'] ?? '',
      directorProfilePicture: json['director_profile_picture'] ?? 'default.jpg',
    );
  }
}
