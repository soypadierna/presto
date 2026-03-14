import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../features/clients/domain/client_model.dart';

class Formatters {
  /// Formatea un monto con símbolo ₡ y separadores de miles
  static String formatAmount(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '₡$formatted';
  }

  /// Fecha larga en español: "Lunes 14 de marzo, 2026"
  static String formatDate(DateTime date) {
    final str = DateFormat("EEEE d 'de' MMMM, yyyy", 'es').format(date);
    return str[0].toUpperCase() + str.substring(1);
  }

  /// Fecha corta: "14/03/2026"
  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Label en español para el tipo de cobro
  static String paymentTypeLabel(PaymentType type) {
    switch (type) {
      case PaymentType.daily:
        return 'Diario';
      case PaymentType.weekly:
        return 'Semanal';
      case PaymentType.biweekly:
        return 'Quincenal';
      case PaymentType.monthly:
        return 'Mensual';
    }
  }

  /// Ícono para el tipo de cobro
  static IconData paymentTypeIcon(PaymentType type) {
    switch (type) {
      case PaymentType.daily:
        return Icons.today_outlined;
      case PaymentType.weekly:
        return Icons.view_week_outlined;
      case PaymentType.biweekly:
        return Icons.calendar_view_month_outlined;
      case PaymentType.monthly:
        return Icons.calendar_month_outlined;
    }
  }

  /// Color para el tipo de cobro
  static Color paymentTypeColor(PaymentType type) {
    switch (type) {
      case PaymentType.daily:
        return Colors.green.shade600;
      case PaymentType.weekly:
        return Colors.blue.shade600;
      case PaymentType.biweekly:
        return Colors.orange.shade600;
      case PaymentType.monthly:
        return Colors.purple.shade600;
    }
  }
}