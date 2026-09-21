class JobModel {
  final String id;
  final String title;
  final String company;
  final String description;
  final String? requirements;
  final String? location;
  final String? jobType;
  final String? experienceLevel;
  final String? applicationLink;
  final String? salaryMax;
  final DateTime createdAt;

  JobModel({
    required this.id,
    required this.title,
    required this.company,
    required this.description,
    this.requirements,
    this.location,
    this.jobType,
    this.experienceLevel,
    this.applicationLink,
    this.salaryMax,
    required this.createdAt,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      company: json['company'] ?? '',
      description: json['description'] ?? '',
      requirements: json['requirements'],
      location: json['location'],
      jobType: json['job_type'],
      experienceLevel: json['experience_level'],
      applicationLink: json['application_link'],
      salaryMax: json['salary_max']?.toString(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
    );
  }
}
