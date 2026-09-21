class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? batch;
  final String? department;
  final String? profilePicture;
  final String? role;
  final String? usn;
  final bool is_director;
  final bool is_spoc;
  bool isFollowed;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.batch,
    this.department,
    this.profilePicture,
    this.role,
    this.usn,
    this.is_director = false,
    this.is_spoc = false,
    this.isFollowed = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    print('DEBUG: UserModel.fromJson received: $json');
    final parsedUser = UserModel(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      email: (json['email'] ?? json['email_id'])?.toString() ?? '',
      phone: (json['phone'] ?? json['phone_number'])?.toString(),
      batch: (json['batch'] ?? json['year_of_graduation'])?.toString(),
      department: (json['department'] ?? json['branch'])?.toString(),
      profilePicture: json['profile_picture']?.toString(),
      role: json['role']?.toString(),
      usn: json['usn']?.toString(),
      is_director: _toBool(json['is_director']) || 
                  _toBool(json['is_direactor']) || 
                  json['role']?.toString().toLowerCase() == 'director' ||
                  json['role']?.toString().toLowerCase() == 'admin' ||
                  json['role']?.toString().toLowerCase() == 'superadmin',
      is_spoc: _toBool(json['is_spoc']) || 
               json['role']?.toString().toLowerCase() == 'spoc',
      isFollowed: false, // Mocking initial state
    );
    print('DEBUG: UserModel parsed department: ${parsedUser.department}, batch: ${parsedUser.batch}, profilePicture: ${parsedUser.profilePicture}');
    return parsedUser;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'batch': batch,
      'department': department,
      'profile_picture': profilePicture,
      'role': role,
      'usn': usn,
      'is_director': is_director ? 1 : 0,
      'is_spoc': is_spoc ? 1 : 0,
    };
  }
}

