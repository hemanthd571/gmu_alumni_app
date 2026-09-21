class NoticeModel {
  final String id;
  final String title;
  final String content;
  final String? category;
  final String? attachment;
  final DateTime createdAt;

  NoticeModel({
    required this.id,
    required this.title,
    required this.content,
    this.category,
    this.attachment,
    required this.createdAt,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    return NoticeModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'],
      attachment: json['attachment'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
    );
  }
}
