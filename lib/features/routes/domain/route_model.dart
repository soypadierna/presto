class RouteModel {
  final String id;
  final String name;
  final String createdAt;

  RouteModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
    };
  }

  RouteModel copyWith({
    String? id,
    String? name,
    String? createdAt,
  }) {
    return RouteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}