import 'dart:convert';

/// Tipos de cobro disponibles para un cliente.
enum PaymentType { daily, weekly, biweekly, monthly }

/// Representa un cliente dentro de una ruta de cobros.
///
/// El campo [paymentDays] es un JSON que varía según [paymentType]:
/// - `daily`:    `{"days": ["mon","tue","wed","thu","fri","sat"]}`
/// - `weekly`:   `{"day": "mon"}`
/// - `biweekly`: `{"dates": [1, 15]}`
/// - `monthly`:  `{"date": 1}`
class ClientModel {
  final String id;
  final String routeId;
  final String name;
  final double credit;
  final PaymentType paymentType;
  final Map<String, dynamic> paymentDays;

  /// Posición en la lista del día (drag & drop).
  final int position;

  /// Si es false el cliente está eliminado (soft delete).
  final bool isActive;
  final String createdAt;

  ClientModel({
    required this.id,
    required this.routeId,
    required this.name,
    required this.credit,
    required this.paymentType,
    required this.paymentDays,
    required this.position,
    required this.isActive,
    required this.createdAt,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] as String,
      routeId: map['route_id'] as String,
      name: map['name'] as String,
      credit: (map['credit'] as num).toDouble(),
      paymentType: PaymentType.values.firstWhere(
        (e) => e.name == map['payment_type'],
      ),
      paymentDays: jsonDecode(map['payment_days'] as String),
      position: map['position'] as int,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'route_id': routeId,
      'name': name,
      'credit': credit,
      'payment_type': paymentType.name,
      'payment_days': jsonEncode(paymentDays),
      'position': position,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }

  ClientModel copyWith({
    String? id,
    String? routeId,
    String? name,
    double? credit,
    PaymentType? paymentType,
    Map<String, dynamic>? paymentDays,
    int? position,
    bool? isActive,
    String? createdAt,
  }) {
    return ClientModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      name: name ?? this.name,
      credit: credit ?? this.credit,
      paymentType: paymentType ?? this.paymentType,
      paymentDays: paymentDays ?? this.paymentDays,
      position: position ?? this.position,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Determina si este cliente debe aparecer en la lista del día
  /// según su tipo de cobro y la fecha proporcionada.
  ///
  /// Nunca retorna true para domingo a menos que sea un cliente
  /// diario con domingo explícitamente configurado.
  bool isScheduledForDate(DateTime date) {
    switch (paymentType) {
      case PaymentType.daily:
        // Respetar los días específicos configurados
        final days = List<String>.from(
          paymentDays['days'] as List? ??
          ['mon', 'tue', 'wed', 'thu', 'fri', 'sat'],
        );
        return days.contains(_weekdayToString(date.weekday));

      case PaymentType.weekly:
        // Solo el día de la semana configurado
        final configuredDay = paymentDays['day'] as String;
        return _weekdayFromString(configuredDay) == date.weekday;

      case PaymentType.biweekly:
        // Los dos días del mes configurados
        final dates = List<int>.from(paymentDays['dates'] as List);
        return dates.contains(date.day);

      case PaymentType.monthly:
        // El día del mes configurado
        final configuredDate = paymentDays['date'] as int;
        return date.day == configuredDate;
    }
  }

  /// Convierte un string de día (`"mon"`) al entero de Flutter (`DateTime.monday`).
  int _weekdayFromString(String day) {
    const map = {
      'mon': DateTime.monday,
      'tue': DateTime.tuesday,
      'wed': DateTime.wednesday,
      'thu': DateTime.thursday,
      'fri': DateTime.friday,
      'sat': DateTime.saturday,
      'sun': DateTime.sunday,
    };
    return map[day] ?? DateTime.monday;
  }

  /// Convierte un entero de día de Flutter al string corto (`"mon"`).
  String _weekdayToString(int weekday) {
    const map = {
      DateTime.monday: 'mon',
      DateTime.tuesday: 'tue',
      DateTime.wednesday: 'wed',
      DateTime.thursday: 'thu',
      DateTime.friday: 'fri',
      DateTime.saturday: 'sat',
      DateTime.sunday: 'sun',
    };
    return map[weekday] ?? 'mon';
  }
}