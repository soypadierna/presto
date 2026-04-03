import '../../clients/domain/client_model.dart';
import '../domain/payment_model.dart';
import '../domain/scheduled_payment_model.dart';
import '../domain/refinance_model.dart';

class TodayClient {
  final ClientModel client;
  final PaymentModel? payment;
  final ScheduledPaymentModel? scheduledPayment;
  final RefinanceModel? refinance;

  const TodayClient({
    required this.client,
    this.payment,
    this.scheduledPayment,
    this.refinance,
  });

  bool get isPaid => payment?.status == PaymentStatus.paid;
  bool get isSkipped => payment?.status == PaymentStatus.skipped;
  bool get isPending => payment == null;
  bool get isRescheduled => scheduledPayment != null && isPending;
  bool get isRefinanced => refinance != null;

  TodayClient copyWith({
    ClientModel? client,
    PaymentModel? payment,
    ScheduledPaymentModel? scheduledPayment,
    RefinanceModel? refinance,
    bool clearPayment = false,
    bool clearScheduled = false,
    bool clearRefinance = false,
  }) {
    return TodayClient(
      client: client ?? this.client,
      payment: clearPayment ? null : payment ?? this.payment,
      scheduledPayment:
          clearScheduled ? null : scheduledPayment ?? this.scheduledPayment,
      refinance: clearRefinance ? null : refinance ?? this.refinance,
    );
  }
}
