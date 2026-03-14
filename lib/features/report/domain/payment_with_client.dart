import '../../today/domain/payment_model.dart';

class PaymentWithClient {
  final PaymentModel payment;
  final String clientName;

  const PaymentWithClient({
    required this.payment,
    required this.clientName,
  });
}