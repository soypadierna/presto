import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';

class DateNavigator extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const DateNavigator({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Color del contenedor — más oscuro que el fondo en dark, más claro en light
    final containerColor = isDark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFE6E6E6);

    return Container(
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Flecha izquierda — mismo color que contenedor
          _buildArrow(
            context,
            Icons.chevron_left,
            containerColor,
            () => onDateChanged(
              selectedDate.subtract(const Duration(days: 1)),
            ),
          ),

          // Fecha central
          Expanded(
            child: GestureDetector(
              onTap: () => _showDatePicker(context),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: Text(
                  key: ValueKey(selectedDate.toIso8601String()),
                  _formatLabel(selectedDate),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),

          // Flecha derecha — mismo color que contenedor
          _buildArrow(
            context,
            Icons.chevron_right,
            containerColor,
            () => onDateChanged(
              selectedDate.add(const Duration(days: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrow(
    BuildContext context,
    IconData icon,
    Color containerColor,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          // Mismo color que el contenedor — se funde visualmente
          color: containerColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Selecciona el día',
    );
    if (picked != null) onDateChanged(picked);
  }

  String _formatLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    switch (diff) {
      case 0:
        return 'Hoy · ${Formatters.formatShortDateNavigator(date)}';
      case -1:
        return 'Ayer · ${Formatters.formatShortDateNavigator(date)}';
      case 1:
        return 'Mañana · ${Formatters.formatShortDateNavigator(date)}';
      default:
        return _formatFull(date);
    }
  }

  String _formatFull(DateTime date) {
    const days = [
      'Lunes', 'Martes', 'Miércoles',
      'Jueves', 'Viernes', 'Sábado', 'Domingo'
    ];
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${days[date.weekday - 1]} ${date.day} de '
        '${months[date.month - 1]}, ${date.year}';
  }
}