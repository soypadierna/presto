import 'package:flutter/material.dart';

class DarkModeHelper {
  static Color adaptColor({
    required BuildContext context,
    required Color lightColor,
    required Color darkColor,
  }) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkColor : lightColor;
  }

  // ── Pagado ───────────────────────────────────────────────
  static Color paidBackground(BuildContext context) => adaptColor(
        context: context,
        lightColor: Colors.green.shade50,
        darkColor: Colors.green.shade900.withValues(alpha: 0.3),
      );

  static Color paidBorder(BuildContext context) => adaptColor(
        context: context,
        lightColor: Colors.green.shade300,
        darkColor: Colors.green.shade700,
      );

  static Color paidIconBackground(BuildContext context) => adaptColor(
        context: context,
        lightColor: Colors.green.shade100,
        darkColor: Colors.green.shade900.withValues(alpha: 0.5),
      );

  // ── No dio ───────────────────────────────────────────────
  static Color skippedBackground(BuildContext context) => adaptColor(
        context: context,
        lightColor: Colors.red.shade50,
        darkColor: Colors.red.shade900.withValues(alpha: 0.3),
      );

  static Color skippedBorder(BuildContext context) => adaptColor(
        context: context,
        lightColor: Colors.red.shade300,
        darkColor: Colors.red.shade700,
      );

  static Color skippedIconBackground(BuildContext context) => adaptColor(
        context: context,
        lightColor: Colors.red.shade100,
        darkColor: Colors.red.shade900.withValues(alpha: 0.5),
      );

  // ── Refinanciado ─────────────────────────────────────────
  static Color refinancedBackground(BuildContext context) => adaptColor(
        context: context,
        lightColor: Colors.amber.shade50,
        darkColor: const Color(0xFF412402), // c-amber 900
      );

  static Color refinancedBorder(BuildContext context) => adaptColor(
        context: context,
        lightColor: Colors.amber.shade300,
        darkColor: const Color(0xFF854F0B), // c-amber 600
      );

  static Color refinancedIconBackground(BuildContext context) => adaptColor(
        context: context,
        lightColor: Colors.amber.shade100,
        darkColor: const Color(0xFF2A1E08),
      );

  // ── Reagendado ───────────────────────────────────────────
  static Color rescheduledBackground(BuildContext context) => adaptColor(
        context: context,
        lightColor: const Color(0xFFFFFBF0),
        darkColor: Theme.of(context).colorScheme.surface,
      );

  static Color rescheduledBorder(BuildContext context) => adaptColor(
        context: context,
        lightColor: Colors.amber.shade200,
        darkColor: Theme.of(context)
            .colorScheme
            .outline
            .withValues(alpha: 0.2),
      );

  // ── Gastos ───────────────────────────────────────────────
  static Color expenseIconBackground(BuildContext context) => adaptColor(
        context: context,
        lightColor: Colors.red.shade50,
        darkColor: Colors.red.shade900.withValues(alpha: 0.3),
      );
}