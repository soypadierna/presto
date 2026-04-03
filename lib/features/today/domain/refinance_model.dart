/// Tipo de refinanciamiento.
enum RefinanceType { money, time }

/// Método de pago del refinanciamiento.
enum RefinanceMethod { cash, transfer }

/// Representa un refinanciamiento registrado para un cliente.
class RefinanceModel {
  final String id;
  final String clientId;
  final String routeId;
  final double amount;
  final RefinanceMethod method;
  final RefinanceType type;
  final String? imagePath;
  final String? newPaymentDate;
  final String? note;
  final String refinanceDate;
  final String createdAt;

  const RefinanceModel({
    required this.id,
    required this.clientId,
    required this.routeId,
    required this.amount,
    required this.method,
    required this.type,
    this.imagePath,
    this.newPaymentDate,
    this.note,
    required this.refinanceDate,
    required this.createdAt,
  });

  factory RefinanceModel.fromMap(Map<String, dynamic> map) {
    return RefinanceModel(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      routeId: map['route_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      method: RefinanceMethod.values.firstWhere(
        (e) => e.name == map['method'],
        orElse: () => RefinanceMethod.cash,
      ),
      type: RefinanceType.values.firstWhere(
        (e) => e.name == map['type'],
      ),
      imagePath: map['image_path'] as String?,
      newPaymentDate: map['new_payment_date'] as String?,
      note: map['note'] as String?,
      refinanceDate: map['refinance_date'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'route_id': routeId,
      'amount': amount,
      'method': method.name,
      'type': type.name,
      'image_path': imagePath,
      'new_payment_date': newPaymentDate,
      'note': note,
      'refinance_date': refinanceDate,
      'created_at': createdAt,
    };
  }

  RefinanceModel copyWith({
    String? id,
    String? clientId,
    String? routeId,
    double? amount,
    RefinanceMethod? method,
    RefinanceType? type,
    String? imagePath,
    String? newPaymentDate,
    String? note,
    String? refinanceDate,
    String? createdAt,
    bool clearImage = false,
  }) {
    return RefinanceModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      routeId: routeId ?? this.routeId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      type: type ?? this.type,
      imagePath: clearImage ? null : imagePath ?? this.imagePath,
      newPaymentDate: newPaymentDate ?? this.newPaymentDate,
      note: note ?? this.note,
      refinanceDate: refinanceDate ?? this.refinanceDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}