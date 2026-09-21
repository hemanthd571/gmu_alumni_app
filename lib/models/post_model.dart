class PostModel {
  final int id;
  final int userId;
  final String content;
  final String mediaType;
  final String? mediaUrl;
  final String status;
  final String createdAt;
  final PostUser user;
  final int likeCount;
  final int shareCount;
  final bool isLiked;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.mediaType,
    this.mediaUrl,
    required this.status,
    required this.createdAt,
    required this.user,
    required this.likeCount,
    required this.shareCount,
    required this.isLiked,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      userId: json['user_id'],
      content: json['content'] ?? '',
      mediaType: json['media_type'] ?? 'none',
      mediaUrl: json['media_url'],
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
      user: PostUser.fromJson(json['user']),
      likeCount: json['like_count'] ?? 0,
      shareCount: json['share_count'] ?? 0,
      isLiked: json['is_liked'] == 1 || json['is_liked'] == true,
    );
  }
}

class PostUser {
  final int id;
  final String name;
  final String profilePicture;
  final String usn;

  PostUser({
    required this.id,
    required this.name,
    required this.profilePicture,
    required this.usn,
  });

  factory PostUser.fromJson(Map<String, dynamic> json) {
    return PostUser(
      id: json['id'],
      name: json['name'] ?? '',
      profilePicture: json['profile_picture'] ?? 'default.jpg',
      usn: json['usn'] ?? '',
    );
  }
}
