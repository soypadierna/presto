import 'day_summary.dart';

class MonthSummary {
  final int year;
  final int month;
  final double totalCollected;
  final double totalExpenses;
  final double netTotal;
  final int daysWorked;
  final List<DaySummary> days;

  const MonthSummary({
    required this.year,
    required this.month,
    required this.totalCollected,
    required this.totalExpenses,
    required this.netTotal,
    required this.daysWorked,
    required this.days,
  });
}