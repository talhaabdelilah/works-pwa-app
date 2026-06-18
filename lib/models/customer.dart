import 'project.dart';

class Customer {
  final int id;
  String name;
  String phone;
  List<Project> projects;

  Customer({required this.id, required this.name, this.phone = '', List<Project>? projects})
      : projects = projects ?? [];

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'phone': phone,
    'projects': projects.map((p) => p.toJson()).toList(),
  };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch,
    name: json['name'] ?? '',
    phone: json['phone'] ?? '',
    projects: (json['projects'] as List?)?.map((p) => Project.fromJson(p)).toList() ?? [],
  );
}
