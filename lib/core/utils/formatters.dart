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

  /// Colores en escala de grises para el tipo de cobro
  static Color paymentTypeColor(PaymentType type) {
    switch (type) {
      case PaymentType.daily:
        return const Color(0xFF212121); // casi negro
      case PaymentType.weekly:
        return const Color(0xFF424242); // gris muy oscuro
      case PaymentType.biweekly:
        return const Color(0xFF616161); // gris oscuro
      case PaymentType.monthly:
        return const Color(0xFF757575); // gris medio
    }
  }

  /// Colores en escala de grises para dark mode
  static Color paymentTypeColorDark(PaymentType type) {
    switch (type) {
      case PaymentType.daily:
        return const Color(0xFFEEEEEE); // casi blanco
      case PaymentType.weekly:
        return const Color(0xFFBDBDBD); // gris claro
      case PaymentType.biweekly:
        return const Color(0xFF9E9E9E); // gris medio claro
      case PaymentType.monthly:
        return const Color(0xFF757575); // gris medio
    }
  }

  /// Retorna el color correcto según el brightness
  static Color paymentTypeColorAdaptive(
    PaymentType type,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? paymentTypeColorDark(type) : paymentTypeColor(type);
  }

  /// Formato corto para el navegador: "Lun 25 Mar"
  static String formatShortDateNavigator(DateTime date) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName ${date.day} $monthName';
  }
}
