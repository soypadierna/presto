import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';

/// Widget de navegación entre fechas con flechas y selector.
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
    final isToday = _isToday(selectedDate);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Flecha anterior
        _buildArrowButton(
          context: context,
          icon: Icons.chevron_left,
          onTap: () => onDateChanged(
            selectedDate.subtract(const Duration(days: 1)),
          ),
        ),

        // Fecha central — abre DatePicker al tocar
        GestureDetector(
          onTap: () => _showDatePicker(context),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Container(
              key: ValueKey(selectedDate.toIso8601String()),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isToday
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatDateLabel(selectedDate),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  // Punto indicador para hoy
                  if (isToday) ...[
                    const SizedBox(height: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Flecha siguiente
        _buildArrowButton(
          context: context,
          icon: Icons.chevron_right,
          onTap: () => onDateChanged(
            selectedDate.add(const Duration(days: 1)),
          ),
        ),
      ],
    );
  }

  Widget _buildArrowButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      iconSize: 22,
      color: colorScheme.onSurface.withValues(alpha: 0.7),
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

    if (picked != null) {
      onDateChanged(picked);
    }
  }

  /// Formatea la fecha con etiquetas especiales para hoy, ayer y mañana.
  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    switch (diff) {
      case 0:
        return 'Hoy';
      case -1:
        return 'Ayer';
      case 1:
        return 'Mañana';
      default:
        // Formato corto: "Lun 25 Mar"
        return Formatters.formatShortDateNavigator(date);
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}