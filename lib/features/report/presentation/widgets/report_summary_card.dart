import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../report_provider.dart';
import '../../../today/presentation/today_provider.dart';

class ReportSummaryCard extends StatelessWidget {
  const ReportSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer2<ReportProvider, TodayProvider>(
      builder: (context, reportProvider, todayProvider, _) {
        final base = reportProvider.baseAmount;
        final collected = todayProvider.totalCollected;
        final expenses = reportProvider.totalExpenses;
        final net =
            base + collected - expenses - reportProvider.totalRefinanced;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildRow(
                context: context,
                label: 'Base del día',
                amount: base,
                color: colorScheme.onSurface,
              ),
              const SizedBox(height: 10),
              _buildRow(
                context: context,
                label: 'Total cobrado',
                amount: collected,
                color: Colors.green.shade700,
              ),
              if (reportProvider.totalRefinanced > 0) ...[
                const SizedBox(height: 10),
                _buildRow(
                  context: context,
                  label: 'Refinanciamientos',
                  amount: reportProvider.totalRefinanced,
                  color: Colors.purple.shade600,
                  isNegative: true,
                ),
              ],
              const SizedBox(height: 10),
              _buildRow(
                context: context,
                label: 'Total gastos',
                amount: expenses,
                color: Colors.red.shade600,
                isNegative: true,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Neto del día',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _formatAmount(net),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: net >= 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow({
    required BuildContext context,
    required String label,
    required double amount,
    required Color color,
    bool isNegative = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          '${isNegative ? '- ' : ''}${_formatAmount(amount)}',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '₡$formatted';
  }
}
