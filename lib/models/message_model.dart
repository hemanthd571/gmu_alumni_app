class MessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String message;
  final bool isRead;
  final String createdAt;
  final String senderName;
  final String senderProfilePicture;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.senderName,
    required this.senderProfilePicture,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      message: json['message'] ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'] ?? '',
      senderName: json['sender_name'] ?? '',
      senderProfilePicture: json['sender_profile_picture'] ?? 'default.jpg',
    );
  }
}

class ConversationModel {
  final int userId;
  final String name;
  final String profilePicture;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;

  ConversationModel({
    required this.userId,
    required this.name,
    required this.profilePicture,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      userId: json['user_id'],
      name: json['name'] ?? '',
      profilePicture: json['profile_picture'] ?? 'default.jpg',
      lastMessage: json['last_message'] ?? '',
      lastMessageTime: json['last_message_time'] ?? '',
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}
