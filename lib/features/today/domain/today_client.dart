import '../../clients/domain/client_model.dart';
import '../domain/payment_model.dart';
import '../domain/scheduled_payment_model.dart';

class TodayClient {
  final ClientModel client;
  final PaymentModel? payment;
  final ScheduledPaymentModel? scheduledPayment;

  const TodayClient({
    required this.client,
    this.payment,
    this.scheduledPayment,
  });

  bool get isPaid => payment?.status == PaymentStatus.paid;
  bool get isSkipped => payment?.status == PaymentStatus.skipped;
  bool get isPending => payment == null;

  /// True si tiene un cobro reagendado y aún no ha pagado
  bool get isRescheduled => scheduledPayment != null && isPending;

  TodayClient copyWith({
    ClientModel? client,
    PaymentModel? payment,
    ScheduledPaymentModel? scheduledPayment,
    bool clearPayment = false,
    bool clearScheduled = false,
  }) {
    return TodayClient(
      client: client ?? this.client,
      payment: clearPayment ? null : payment ?? this.payment,
      scheduledPayment: clearScheduled
          ? null
          : scheduledPayment ?? this.scheduledPayment,
    );
  }
}