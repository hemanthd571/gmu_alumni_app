class FeedbackModel {
  final int? id;
  final int userId;
  final int rating;
  final int? eventId;
  final String? feedbackText;
  final String? videoPath;

  FeedbackModel({
    this.id,
    required this.userId,
    required this.rating,
    this.eventId,
    this.feedbackText,
    this.videoPath,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'],
      userId: json['user_id'] is String ? int.tryParse(json['user_id']) ?? 0 : json['user_id'],
      eventId: json['event_id'] != null ? (json['event_id'] is String ? int.tryParse(json['event_id']) : json['event_id']) : null,
      rating: json['rating'] is String ? int.tryParse(json['rating']) ?? 0 : json['rating'],
      feedbackText: json['feedback_text'],
      videoPath: json['video_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'rating': rating,
      'feedback_text': feedbackText,
      'video_path': videoPath,
    };
  }
}
