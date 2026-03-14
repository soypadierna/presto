import 'package:intl/intl.dart';
import '../../today/domain/today_client.dart';
import '../domain/expense_model.dart';
import '../domain/daily_base_model.dart';

class ReportGenerator {
  /// Genera el texto del informe del día
  static String generate({
    required String routeName,
    required DateTime date,
    required List<TodayClient> todayClients,
    required List<ExpenseModel> expenses,
    required DailyBaseModel? dailyBase,
  }) {
    final buffer = StringBuffer();
    final dateStr = DateFormat("EEEE d 'de' MMMM, yyyy", 'es').format(date);

    // Calcular totales
    final totalCollected = todayClients
        .where((tc) => tc.isPaid)
        .fold<double>(0, (sum, tc) => sum + (tc.payment?.amount ?? 0));

    final totalExpenses =
        expenses.fold<double>(0, (sum, e) => sum + e.amount);

    final baseAmount = dailyBase?.amount ?? 0;
    final netTotal = baseAmount + totalCollected - totalExpenses;

    // Encabezado
    buffer.writeln('PRESTO — Informe del día');
    buffer.writeln(_capitalize(dateStr));
    buffer.writeln('Ruta: $routeName');
    buffer.writeln();

    // Base
    buffer.writeln('BASE: ${_formatAmount(baseAmount)}');
    buffer.writeln();

    // Cobros
    buffer.writeln('COBROS:');
    final paidAndSkipped = todayClients
        .where((tc) => tc.isPaid || tc.isSkipped)
        .toList();

    if (paidAndSkipped.isEmpty) {
      buffer.writeln('  (Sin registros)');
    } else {
      for (int i = 0; i < paidAndSkipped.length; i++) {
        final tc = paidAndSkipped[i];
        final num = '${i + 1}.';
        final name = tc.client.name;
        final value = tc.isPaid
            ? _formatAmount(tc.payment!.amount)
            : 'No dio';

        buffer.writeln(_formatLine(num, name, value));
      }
    }

    buffer.writeln();
    buffer.writeln('TOTAL COBRADO: ${_formatAmount(totalCollected)}');

    // Gastos
    if (expenses.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('GASTOS:');
      for (final expense in expenses) {
        buffer.writeln(
          _formatLine('-', expense.description, _formatAmount(expense.amount)),
        );
      }
      buffer.writeln();
      buffer.writeln('TOTAL GASTOS: ${_formatAmount(totalExpenses)}');
    }

    // Neto
    buffer.writeln();
    buffer.writeln('─' * 32);
    buffer.writeln('NETO: ${_formatAmount(netTotal)}');

    return buffer.toString();
  }

  /// Formatea una línea con puntos de relleno
  static String _formatLine(String prefix, String name, String value) {
    const lineWidth = 40;
    final left = '$prefix $name';
    final dots = lineWidth - left.length - value.length;
    final dotStr = dots > 0 ? ' ${'.' * dots} ' : ' ';
    return '$left$dotStr$value';
  }

  static String _formatAmount(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '₡$formatted';
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}