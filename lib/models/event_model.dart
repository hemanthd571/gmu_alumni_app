class EventModel {
  final String id;
  final String title;
  final String description;
  final String? location;
  final String? image;
  final DateTime eventDate;
  final DateTime? endDate;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.location,
    this.image,
    required this.eventDate,
    this.endDate,
    required this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'],
      image: json['image'],
      eventDate: DateTime.parse(json['event_date'] ?? DateTime.now().toString()),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
    );
  }
}
