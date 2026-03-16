import 'package:flutter/material.dart';
import '../../domain/client_model.dart';

class PaymentConfigWidget extends StatelessWidget {
  final PaymentType paymentType;
  final Map<String, dynamic> paymentDays;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const PaymentConfigWidget({
    super.key,
    required this.paymentType,
    required this.paymentDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (paymentType) {
      case PaymentType.daily:
        return _buildDailyConfig(context);
      case PaymentType.weekly:
        return _buildWeeklyConfig(context);
      case PaymentType.biweekly:
        return _buildBiweeklyConfig(context);
      case PaymentType.monthly:
        return _buildMonthlyConfig(context);
    }
  }

  Widget _buildDailyConfig(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Días seleccionados — por defecto lunes a sábado
    final selectedDays = List<String>.from(
      paymentDays['days'] as List? ??
          ['mon', 'tue', 'wed', 'thu', 'fri', 'sat'],
    );

    const List<Map<String, String>> days = [
      {'key': 'mon', 'label': 'Lun'},
      {'key': 'tue', 'label': 'Mar'},
      {'key': 'wed', 'label': 'Mié'},
      {'key': 'thu', 'label': 'Jue'},
      {'key': 'fri', 'label': 'Vie'},
      {'key': 'sat', 'label': 'Sáb'},
      {'key': 'sun', 'label': 'Dom'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Días de cobro',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: days.map((day) {
            final isSelected = selectedDays.contains(day['key']);
            return GestureDetector(
              onTap: () {
                final updated = List<String>.from(selectedDays);
                if (isSelected) {
                  if (updated.length > 1) {
                    updated.remove(day['key']);
                  }
                } else {
                  updated.add(day['key']!);
                }
                onChanged({'days': updated});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    day['label']!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        // Indicador de días seleccionados
        Text(
          '${selectedDays.length} día(s) seleccionado(s)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyConfig(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDay = paymentDays['day'] as String? ?? 'mon';

    final days = [
      {'key': 'mon', 'label': 'Lun'},
      {'key': 'tue', 'label': 'Mar'},
      {'key': 'wed', 'label': 'Mié'},
      {'key': 'thu', 'label': 'Jue'},
      {'key': 'fri', 'label': 'Vie'},
      {'key': 'sat', 'label': 'Sáb'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Día de cobro',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: days.map((day) {
            final isSelected = selectedDay == day['key'];
            return GestureDetector(
              onTap: () => onChanged({'day': day['key']}),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    day['label']!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBiweeklyConfig(BuildContext context) {
    final theme = Theme.of(context);
    final dates = List<int>.from(
      paymentDays['dates'] as List? ?? [1, 15],
    );

    final dayOptions = List.generate(31, (i) => i + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fechas de cobro',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildDateDropdown(
                context: context,
                label: 'Primera fecha',
                value: dates[0],
                options: dayOptions,
                onChanged: (val) {
                  if (val != null) {
                    onChanged({
                      'dates': [val, dates[1]]
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateDropdown(
                context: context,
                label: 'Segunda fecha',
                value: dates[1],
                options: dayOptions,
                onChanged: (val) {
                  if (val != null) {
                    onChanged({
                      'dates': [dates[0], val]
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyConfig(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDate = paymentDays['date'] as int? ?? 1;
    final dayOptions = List.generate(31, (i) => i + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Día de cobro mensual',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 10),
        _buildDateDropdown(
          context: context,
          label: 'Día del mes',
          value: selectedDate,
          options: dayOptions,
          onChanged: (val) {
            if (val != null) {
              onChanged({'date': val});
            }
          },
        ),
      ],
    );
  }

  Widget _buildDateDropdown({
    required BuildContext context,
    required String label,
    required int value,
    required List<int> options,
    required ValueChanged<int?> onChanged,
  }) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
      ),
      items: options
          .map((d) => DropdownMenuItem(
                value: d,
                child: Text('Día $d'),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
