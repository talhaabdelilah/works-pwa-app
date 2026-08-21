import 'project.dart';

class Customer {
  final int id;
  String name;
  String phone;
  String location;
  List<Project> projects;

  Customer({required this.id, required this.name, this.phone = '', this.location = '', List<Project>? projects})
      : projects = projects ?? [];

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'phone': phone, 'location': location,
    'projects': projects.map((p) => p.toJson()).toList(),
  };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch,
    name: json['name'] ?? '',
    phone: json['phone'] ?? '',
    location: json['location'] ?? '',
    projects: (json['projects'] as List?)?.map((p) => Project.fromJson(Map<String, dynamic>.from(p))).toList() ?? [],
  );
}
