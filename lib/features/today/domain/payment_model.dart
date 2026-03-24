/// Tipo de pago del cobro.
enum PaymentMethod { cash, transfer }

/// Estado del cobro.
enum PaymentStatus { paid, skipped }

/// Representa un cobro registrado en un día específico.
class PaymentModel {
  final String id;
  final String clientId;
  final String routeId;
  final double amount;
  final PaymentStatus status;
  final String? note;
  final String paymentDate;
  final String createdAt;

  /// Tipo de pago: efectivo o transferencia.
  final PaymentMethod paymentMethod;

  /// Ruta local de la imagen del comprobante (solo para transferencias).
  final String? imagePath;

  PaymentModel({
    required this.id,
    required this.clientId,
    required this.routeId,
    required this.amount,
    required this.status,
    this.note,
    required this.paymentDate,
    required this.createdAt,
    this.paymentMethod = PaymentMethod.cash,
    this.imagePath,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      routeId: map['route_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
      ),
      note: map['note'] as String?,
      paymentDate: map['payment_date'] as String,
      createdAt: map['created_at'] as String,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == (map['payment_method'] as String? ?? 'cash'),
        orElse: () => PaymentMethod.cash,
      ),
      imagePath: map['image_path'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'route_id': routeId,
      'amount': amount,
      'status': status.name,
      'note': note,
      'payment_date': paymentDate,
      'created_at': createdAt,
      'payment_method': paymentMethod.name,
      'image_path': imagePath,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? clientId,
    String? routeId,
    double? amount,
    PaymentStatus? status,
    String? note,
    String? paymentDate,
    String? createdAt,
    PaymentMethod? paymentMethod,
    String? imagePath,
    bool clearImage = false,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      routeId: routeId ?? this.routeId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      note: note ?? this.note,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      imagePath: clearImage ? null : imagePath ?? this.imagePath,
    );
  }
}