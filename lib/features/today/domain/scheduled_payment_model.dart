/// Representa un cobro reagendado para una fecha específica.
/// No modifica el calendario original del cliente.
class ScheduledPaymentModel {
  final String id;
  final String clientId;
  final String routeId;
  final String scheduledDate;
  final String? note;
  final String createdAt;

  const ScheduledPaymentModel({
    required this.id,
    required this.clientId,
    required this.routeId,
    required this.scheduledDate,
    this.note,
    required this.createdAt,
  });

  factory ScheduledPaymentModel.fromMap(Map<String, dynamic> map) {
    return ScheduledPaymentModel(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      routeId: map['route_id'] as String,
      scheduledDate: map['scheduled_date'] as String,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'route_id': routeId,
      'scheduled_date': scheduledDate,
      'note': note,
      'created_at': createdAt,
    };
  }

  ScheduledPaymentModel copyWith({
    String? id,
    String? clientId,
    String? routeId,
    String? scheduledDate,
    String? note,
    String? createdAt,
  }) {
    return ScheduledPaymentModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      routeId: routeId ?? this.routeId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}