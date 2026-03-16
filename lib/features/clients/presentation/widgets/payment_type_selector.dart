import 'package:flutter/material.dart';
import '../../domain/client_model.dart';

class PaymentTypeSelector extends StatelessWidget {
  final PaymentType selected;
  final ValueChanged<PaymentType> onChanged;

  const PaymentTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de cobro',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: PaymentType.values.map((type) {
            final isSelected = selected == type;
            return GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.4),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _iconForType(type),
                      size: 20,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _labelForType(type),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _iconForType(PaymentType type) {
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

  String _labelForType(PaymentType type) {
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
}
