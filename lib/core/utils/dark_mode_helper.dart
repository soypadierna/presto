import 'package:flutter/material.dart';

/// Helper para adaptar colores hardcodeados al modo oscuro
class DarkModeHelper {
  /// Retorna color según el brightness actual del contexto
  static Color adaptColor({
    required BuildContext context,
    required Color lightColor,
    required Color darkColor,
  }) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkColor : lightColor;
  }

  /// Verde suave para fondo de cliente pagado
  static Color paidBackground(BuildContext context) => adaptColor(
        context: context,
        lightColor: Colors.green.shade50,
        darkColor: Colors.green.shade900.withOpacity(0.3),
      );

  /// Borde verde para cliente pagado
  static Color paidBorder(BuildContext context) => adaptColor(
        context: context,
        lightColor: Colors.green.shade300,
        darkColor: Colors.green.shade700,
      );

  /// Fondo del ícono de cliente pagado
  static Color paidIconBackground(BuildContext context) => adaptColor(
        context: context,
        lightColor: Colors.green.shade100,
        darkColor: Colors.green.shade900.withOpacity(0.5),
      );

  /// Rojo suave para fondo de cliente que no dio
  static Color skippedBackground(BuildContext context) => adaptColor(
        context: context,
        lightColor: Colors.red.shade50,
        darkColor: Colors.red.shade900.withOpacity(0.3),
      );

  /// Borde rojo para cliente que no dio
  static Color skippedBorder(BuildContext context) => adaptColor(
        context: context,
        lightColor: Colors.red.shade300,
        darkColor: Colors.red.shade700,
      );

  /// Fondo del ícono de cliente que no dio
  static Color skippedIconBackground(BuildContext context) => adaptColor(
        context: context,
        lightColor: Colors.red.shade100,
        darkColor: Colors.red.shade900.withOpacity(0.5),
      );

  /// Fondo del ícono de gasto
  static Color expenseIconBackground(BuildContext context) => adaptColor(
        context: context,
        lightColor: Colors.red.shade50,
        darkColor: Colors.red.shade900.withOpacity(0.3),
      );
}