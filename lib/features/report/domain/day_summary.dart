import 'payment_with_client.dart';

class DaySummary {
  final String date;
  final double totalCollected;
  final double totalExpenses;
  final double baseAmount;
  final double netTotal;
  final int paidCount;
  final int skippedCount;
  final List<PaymentWithClient> payments;

  const DaySummary({
    required this.date,
    required this.totalCollected,
    required this.totalExpenses,
    required this.baseAmount,
    required this.netTotal,
    required this.paidCount,
    required this.skippedCount,
    required this.payments,
  });
}