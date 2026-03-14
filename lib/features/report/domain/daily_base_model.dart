class DailyBaseModel {
  final String id;
  final String routeId;
  final double amount;
  final String baseDate;
  final String createdAt;

  DailyBaseModel({
    required this.id,
    required this.routeId,
    required this.amount,
    required this.baseDate,
    required this.createdAt,
  });

  factory DailyBaseModel.fromMap(Map<String, dynamic> map) {
    return DailyBaseModel(
      id: map['id'] as String,
      routeId: map['route_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      baseDate: map['base_date'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'route_id': routeId,
      'amount': amount,
      'base_date': baseDate,
      'created_at': createdAt,
    };
  }

  DailyBaseModel copyWith({
    String? id,
    String? routeId,
    double? amount,
    String? baseDate,
    String? createdAt,
  }) {
    return DailyBaseModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      amount: amount ?? this.amount,
      baseDate: baseDate ?? this.baseDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}