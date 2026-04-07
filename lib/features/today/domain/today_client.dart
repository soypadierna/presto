import '../../clients/domain/client_model.dart';
import '../domain/payment_model.dart';
import '../domain/scheduled_payment_model.dart';
import '../domain/refinance_model.dart';

class TodayClient {
  final ClientModel client;
  final List<PaymentModel> payments;
  final ScheduledPaymentModel? scheduledPayment;
  final RefinanceModel? refinance;

  const TodayClient({
    required this.client,
    this.payments = const [],
    this.scheduledPayment,
    this.refinance,
  });

  /// True si hay al menos un pago exitoso
  bool get isPaid => payments.any((p) => p.status == PaymentStatus.paid);

  /// True si hay un skipped y ningún paid
  bool get isSkipped =>
      payments.any((p) => p.status == PaymentStatus.skipped) && !isPaid;

  /// True si no hay ningún pago registrado
  bool get isPending => payments.isEmpty;

  /// True si tiene reagendamiento activo y no ha pagado
  bool get isRescheduled => scheduledPayment != null && isPending;

  /// True si está refinanciado
  bool get isRefinanced => refinance != null;

  /// True si tiene más de un pago exitoso
  bool get hasMultiplePayments =>
      payments.where((p) => p.status == PaymentStatus.paid).length > 1;

  /// Suma total de pagos exitosos
  double get totalPaid => payments
      .where((p) => p.status == PaymentStatus.paid)
      .fold(0, (sum, p) => sum + p.amount);

  /// Total en efectivo
  double get cashTotal => payments
      .where((p) =>
          p.status == PaymentStatus.paid &&
          p.paymentMethod == PaymentMethod.cash)
      .fold(0, (sum, p) => sum + p.amount);

  /// Total en transferencia
  double get transferTotal => payments
      .where((p) =>
          p.status == PaymentStatus.paid &&
          p.paymentMethod == PaymentMethod.transfer)
      .fold(0, (sum, p) => sum + p.amount);

  /// Primer pago skipped si existe
  PaymentModel? get skippedPayment => payments
      .where((p) => p.status == PaymentStatus.skipped)
      .firstOrNull;

  /// Último pago registrado
  PaymentModel? get lastPayment =>
      payments.isNotEmpty ? payments.last : null;

  TodayClient copyWith({
    ClientModel? client,
    List<PaymentModel>? payments,
    ScheduledPaymentModel? scheduledPayment,
    RefinanceModel? refinance,
    bool clearPayments = false,
    bool clearScheduled = false,
    bool clearRefinance = false,
  }) {
    return TodayClient(
      client: client ?? this.client,
      payments: clearPayments ? [] : payments ?? this.payments,
      scheduledPayment: clearScheduled
          ? null
          : scheduledPayment ?? this.scheduledPayment,
      refinance:
          clearRefinance ? null : refinance ?? this.refinance,
    );
  }
}