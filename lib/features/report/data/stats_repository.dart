import '../../../core/database/database_helper.dart';
import '../../../features/today/domain/payment_model.dart';
import '../domain/day_summary.dart';
import '../domain/month_summary.dart';
import '../domain/payment_with_client.dart';
import '../../report/data/expense_repository.dart';
import '../../report/data/daily_base_repository.dart';

class StatsRepository {
  final _db = DatabaseHelper.instance;
  final _expenseRepo = ExpenseRepository();
  final _baseRepo = DailyBaseRepository();

  /// Retorna fechas únicas con al menos un pago ordenadas desc
  Future<List<String>> getDaysWorked(String routeId) async {
    try {
      final db = await _db.database;
      final result = await db.rawQuery('''
        SELECT DISTINCT payment_date
        FROM payments
        WHERE route_id = ?
        ORDER BY payment_date DESC
      ''', [routeId]);
      return result.map((r) => r['payment_date'] as String).toList();
    } catch (e) {
      throw Exception('Error obteniendo días trabajados: $e');
    }
  }

  /// Retorna el resumen completo de un día
  Future<DaySummary> getDaySummary(String routeId, String date) async {
    try {
      final db = await _db.database;

      // Obtener pagos con nombre del cliente
      final paymentsResult = await db.rawQuery('''
        SELECT p.*, c.name as client_name
        FROM payments p
        INNER JOIN clients c ON p.client_id = c.id
        WHERE p.route_id = ? AND p.payment_date = ?
        ORDER BY c.position ASC
      ''', [routeId, date]);

      final payments = paymentsResult.map((row) {
        final payment = PaymentModel.fromMap(row);
        final clientName = row['client_name'] as String;
        return PaymentWithClient(
          payment: payment,
          clientName: clientName,
        );
      }).toList();

      // Calcular totales
      final paidPayments = payments
          .where((p) => p.payment.status == PaymentStatus.paid);
      final totalCollected = paidPayments.fold<double>(
        0,
        (sum, p) => sum + p.payment.amount,
      );
      final paidCount = paidPayments.length;
      final skippedCount = payments
          .where((p) => p.payment.status == PaymentStatus.skipped)
          .length;

      // Gastos del día
      final expenses = await _expenseRepo.getExpensesByDate(routeId, date);
      final totalExpenses =
          expenses.fold<double>(0, (sum, e) => sum + e.amount);

      // Base del día
      final base = await _baseRepo.getBaseByDate(routeId, date);
      final baseAmount = base?.amount ?? 0;

      return DaySummary(
        date: date,
        totalCollected: totalCollected,
        totalExpenses: totalExpenses,
        baseAmount: baseAmount,
        netTotal: baseAmount + totalCollected - totalExpenses,
        paidCount: paidCount,
        skippedCount: skippedCount,
        payments: payments,
      );
    } catch (e) {
      throw Exception('Error obteniendo resumen del día: $e');
    }
  }

  /// Retorna el resumen del mes
  Future<MonthSummary> getMonthSummary(
    String routeId,
    int year,
    int month,
  ) async {
    try {
      // Formato del mes para comparar: YYYY-MM
      final monthStr =
          '$year-${month.toString().padLeft(2, '0')}';

      // Días trabajados en el mes
      final allDays = await getDaysWorked(routeId);
      final monthDays =
          allDays.where((d) => d.startsWith(monthStr)).toList();

      if (monthDays.isEmpty) {
        return MonthSummary(
          year: year,
          month: month,
          totalCollected: 0,
          totalExpenses: 0,
          netTotal: 0,
          daysWorked: 0,
          days: [],
        );
      }

      // Obtener resumen de cada día
      final daySummaries = await Future.wait(
        monthDays.map((date) => getDaySummary(routeId, date)),
      );

      final totalCollected = daySummaries.fold<double>(
        0,
        (sum, d) => sum + d.totalCollected,
      );
      final totalExpenses = daySummaries.fold<double>(
        0,
        (sum, d) => sum + d.totalExpenses,
      );
      final netTotal = daySummaries.fold<double>(
        0,
        (sum, d) => sum + d.netTotal,
      );

      return MonthSummary(
        year: year,
        month: month,
        totalCollected: totalCollected,
        totalExpenses: totalExpenses,
        netTotal: netTotal,
        daysWorked: monthDays.length,
        days: daySummaries,
      );
    } catch (e) {
      throw Exception('Error obteniendo resumen del mes: $e');
    }
  }
}