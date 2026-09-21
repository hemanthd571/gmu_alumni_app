class CoreTeamModel {
  final String id;
  final String name;
  final String position;
  final String? image;
  final String? email;
  final String? phone;

  CoreTeamModel({
    required this.id,
    required this.name,
    required this.position,
    this.image,
    this.email,
    this.phone,
  });

  factory CoreTeamModel.fromJson(Map<String, dynamic> json) {
    return CoreTeamModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      position: json['position'] ?? '',
      image: json['image'],
      email: json['email'],
      phone: json['phone'],
    );
  }
}
