class ExpenseModel {
  final String id;
  final String routeId;
  final String description;
  final double amount;
  final String expenseDate;
  final String createdAt;

  ExpenseModel({
    required this.id,
    required this.routeId,
    required this.description,
    required this.amount,
    required this.expenseDate,
    required this.createdAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as String,
      routeId: map['route_id'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      expenseDate: map['expense_date'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'route_id': routeId,
      'description': description,
      'amount': amount,
      'expense_date': expenseDate,
      'created_at': createdAt,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? routeId,
    String? description,
    double? amount,
    String? expenseDate,
    String? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}