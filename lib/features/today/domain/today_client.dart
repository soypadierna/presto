import '../../clients/domain/client_model.dart';
import '../domain/payment_model.dart';

class TodayClient {
  final ClientModel client;
  final PaymentModel? payment;

  const TodayClient({
    required this.client,
    this.payment,
  });

  bool get isPaid => payment?.status == PaymentStatus.paid;
  bool get isSkipped => payment?.status == PaymentStatus.skipped;
  bool get isPending => payment == null;

  TodayClient copyWith({
    ClientModel? client,
    PaymentModel? payment,
    bool clearPayment = false,
  }) {
    return TodayClient(
      client: client ?? this.client,
      payment: clearPayment ? null : payment ?? this.payment,
    );
  }
} 