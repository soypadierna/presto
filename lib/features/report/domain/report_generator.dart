import 'package:intl/intl.dart';
import 'package:presto/features/today/domain/refinance_model.dart';
import '../../today/domain/today_client.dart';
import '../../today/domain/payment_model.dart';
import '../domain/expense_model.dart';
import '../domain/daily_base_model.dart';
import '../domain/day_summary.dart';

/// Genera el texto plano del informe del día para compartir o copiar.
///
/// El formato es compatible con WhatsApp y cualquier app de mensajería.
class ReportGenerator {
  /// Genera el informe desde los datos en tiempo real del día actual.
  static String generate({
    required String routeName,
    required DateTime date,
    required List<TodayClient> todayClients,
    required List<ExpenseModel> expenses,
    required DailyBaseModel? dailyBase,
    List<RefinanceModel> refinances = const [],
  }) {
    final buffer = StringBuffer();
    final dateStr = DateFormat("EEEE d 'de' MMMM, yyyy", 'es').format(date);

    final totalCollected = todayClients.fold<double>(
      0,
      (sum, tc) => sum + tc.totalPaid,
    );
    final totalCash = todayClients.fold<double>(
      0,
      (sum, tc) => sum + tc.cashTotal,
    );
    final totalTransfer = todayClients.fold<double>(
      0,
      (sum, tc) => sum + tc.transferTotal,
    );

    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    final totalRefinanced =
        refinances.fold<double>(0, (sum, r) => sum + r.amount);

    final baseAmount = dailyBase?.amount ?? 0;
    final netTotal =
        baseAmount + totalCollected - totalExpenses - totalRefinanced;

    buffer.writeln('PRESTO — Informe del día');
    buffer.writeln(_capitalize(dateStr));
    buffer.writeln('Ruta: $routeName');
    buffer.writeln();
    buffer.writeln('BASE: ${_formatAmount(baseAmount)}');
    buffer.writeln();
    buffer.writeln('COBROS:');

    final registered =
        todayClients.where((tc) => tc.isPaid || tc.isSkipped).toList();

    if (registered.isEmpty) {
      buffer.writeln('  (Sin registros)');
    } else {
      // En la sección COBROS reemplazar el loop:
      for (int i = 0; i < registered.length; i++) {
        final tc = registered[i];

        if (tc.hasMultiplePayments) {
          buffer.writeln('${i + 1}. ${tc.client.name}');
          if (tc.cashTotal > 0) {
            buffer.writeln(
              _formatLine('   Efectivo', '', _formatAmount(tc.cashTotal)),
            );
          }
          if (tc.transferTotal > 0) {
            buffer.writeln(
              _formatLine(
                  '   Transferencia', '', _formatAmount(tc.transferTotal)),
            );
          }
          buffer.writeln(
            _formatLine('   Total', '', _formatAmount(tc.totalPaid)),
          );
        } else {
          final value = tc.isPaid ? _formatAmount(tc.totalPaid) : 'No dio';
          buffer.writeln(
            _formatLine('${i + 1}.', tc.client.name, value),
          );
        }
      }

// Al final reemplazar TOTAL COBRADO por desglose:
      buffer.writeln();
      if (totalCash > 0) {
        buffer.writeln('TOTAL EFECTIVO: ${_formatAmount(totalCash)}');
      }
      if (totalTransfer > 0) {
        buffer.writeln('TOTAL TRANSFERENCIA: ${_formatAmount(totalTransfer)}');
      }
      buffer.writeln('TOTAL COBRADO: ${_formatAmount(totalCollected)}');
    }

    buffer.writeln();
    buffer.writeln('TOTAL COBRADO: ${_formatAmount(totalCollected)}');

    // Sección refinanciamientos
    if (refinances.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('REFINANCIAMIENTOS:');
      for (final r in refinances) {
        final client =
            todayClients.where((tc) => tc.client.id == r.clientId).firstOrNull;
        final clientName = client?.client.name ?? 'Cliente';
        final typeLabel =
            r.type == RefinanceType.money ? 'Dar dinero' : 'Dar tiempo';
        final value = r.amount > 0 ? _formatAmount(r.amount) : 'Sin monto';
        buffer.writeln(
          _formatLine('- $clientName ($typeLabel)', '', value),
        );
      }
      buffer.writeln();
      buffer.writeln(
        'TOTAL REFINANCIADO: ${_formatAmount(totalRefinanced)}',
      );
    }

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

    buffer.writeln();
    buffer.writeln('─' * 32);
    buffer.writeln('NETO: ${_formatAmount(netTotal)}');

    return buffer.toString();
  }

  /// Genera el informe desde un [DaySummary] del historial.
  static String generateFromSummary({
    required String routeName,
    required DaySummary summary,
  }) {
    final buffer = StringBuffer();
    final date = DateTime.parse(summary.date);
    final dateStr = DateFormat("EEEE d 'de' MMMM, yyyy", 'es').format(date);

    buffer.writeln('PRESTO — Informe del día');
    buffer.writeln(_capitalize(dateStr));
    buffer.writeln('Ruta: $routeName');
    buffer.writeln();
    buffer.writeln('BASE: ${_formatAmount(summary.baseAmount)}');
    buffer.writeln();
    buffer.writeln('COBROS:');

    if (summary.payments.isEmpty) {
      buffer.writeln('  (Sin registros)');
    } else {
      for (int i = 0; i < summary.payments.length; i++) {
        final pwc = summary.payments[i];
        final isPaid = pwc.payment.status == PaymentStatus.paid;
        final value = isPaid ? _formatAmount(pwc.payment.amount) : 'No dio';
        buffer.writeln(_formatLine('${i + 1}.', pwc.clientName, value));
      }
    }

    buffer.writeln();
    buffer.writeln('TOTAL COBRADO: ${_formatAmount(summary.totalCollected)}');

    if (summary.totalExpenses > 0) {
      buffer.writeln();
      buffer.writeln('TOTAL GASTOS: ${_formatAmount(summary.totalExpenses)}');
    }

    buffer.writeln();
    buffer.writeln('─' * 32);
    buffer.writeln('NETO: ${_formatAmount(summary.netTotal)}');

    return buffer.toString();
  }

  /// Formatea una línea con puntos de relleno para alinear el valor a la derecha.
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
