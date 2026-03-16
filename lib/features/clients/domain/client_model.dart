import 'dart:convert';

enum PaymentType { daily, weekly, biweekly, monthly }

class ClientModel {
  final String id;
  final String routeId;
  final String name;
  final double credit;
  final PaymentType paymentType;
  final Map<String, dynamic> paymentDays;
  final int position;
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

  /// Determina si este cliente debe cobrar en la fecha dada
  bool isScheduledForDate(DateTime date) {
    // Domingo = 7, no se cobra nunca
    if (date.weekday == DateTime.sunday) return false;

    switch (paymentType) {
      case PaymentType.daily:
        // Si tiene días específicos configurados, respetar esa selección
        final days = List<String>.from(
          paymentDays['days'] as List? ??
              ['mon', 'tue', 'wed', 'thu', 'fri', 'sat'],
        );
        final todayStr = _weekdayToString(date.weekday);
        return days.contains(todayStr);

      case PaymentType.weekly:
        // Solo el día configurado: "mon", "tue", etc.
        final configuredDay = paymentDays['day'] as String;
        return _weekdayFromString(configuredDay) == date.weekday;

      case PaymentType.biweekly:
        // Las dos fechas del mes configuradas
        final dates = List<int>.from(paymentDays['dates'] as List);
        return dates.contains(date.day);

      case PaymentType.monthly:
        // El día del mes configurado
        final configuredDate = paymentDays['date'] as int;
        return date.day == configuredDate;
    }
  }

  int _weekdayFromString(String day) {
    const map = {
      'mon': DateTime.monday,
      'tue': DateTime.tuesday,
      'wed': DateTime.wednesday,
      'thu': DateTime.thursday,
      'fri': DateTime.friday,
      'sat': DateTime.saturday,
    };
    return map[day] ?? DateTime.monday;
  }

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
