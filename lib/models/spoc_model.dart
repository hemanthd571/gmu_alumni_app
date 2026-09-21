class SpocModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String institute;
  final String branch;
  final String usn;
  final String profilePicture;
  final String createdAt;

  SpocModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.institute,
    required this.branch,
    required this.usn,
    required this.profilePicture,
    required this.createdAt,
  });

  factory SpocModel.fromJson(Map<String, dynamic> json) {
    return SpocModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      institute: json['institute']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
      usn: json['usn']?.toString() ?? '',
      profilePicture: json['profile_picture']?.toString() ?? 'default.jpg',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'institute': institute,
      'branch': branch,
      'usn': usn,
      'profile_picture': profilePicture,
      'created_at': createdAt,
    };
  }
}
