import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../today_provider.dart';
import '../../../../core/utils/formatters.dart';

class TodaySummaryCard extends StatelessWidget {
  const TodaySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<TodayProvider>(
      builder: (context, provider, _) {
        final total = provider.todayClients.length;
        final done = provider.paidCount + provider.skippedCount;
        final progress = total > 0 ? done / total : 0.0;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            // Gradiente en escala de grises
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF2C2C2C),
                      const Color(0xFF1E1E1E),
                    ]
                  : [
                      const Color(0xFF212121),
                      const Color(0xFF424242),
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total cobrado',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Formatters.formatAmount(provider.totalCollected),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _buildProgress(context, provider, progress, done, total),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Verde funcional — estado de pago exitoso
                  _buildChip(
                    label: '${provider.paidCount} pagaron',
                    icon: Icons.check_circle_outline,
                    color: Colors.green.shade300,
                  ),
                  const SizedBox(width: 8),
                  // Rojo funcional — estado de no pago
                  _buildChip(
                    label: '${provider.skippedCount} no dieron',
                    icon: Icons.cancel_outlined,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(width: 8),
                  // Gris neutro — pendientes
                  _buildChip(
                    label: '${provider.pendingCount} pendientes',
                    icon: Icons.schedule_outlined,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgress(
    BuildContext context,
    TodayProvider provider,
    double progress,
    int done,
    int total,
  ) {

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 4,
        backgroundColor: Colors.grey[600],
        valueColor: AlwaysStoppedAnimation<Color>(
          const Color(0xFF639922),
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
