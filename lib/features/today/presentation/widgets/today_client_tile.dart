import 'package:flutter/material.dart';

import 'package:presto/features/today/presentation/widgets/payment_bottom_sheet.dart';
import 'package:presto/features/today/presentation/widgets/skipped_bottom_sheet.dart';
import 'package:provider/provider.dart';
import '../../domain/today_client.dart';
import '../today_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/dark_mode_helper.dart';

class TodayClientTile extends StatelessWidget {
  final TodayClient todayClient;
  final VoidCallback? onBeforeAction;
  final VoidCallback? onAfterAction;

  const TodayClientTile({
    super.key,
    required this.todayClient,
    this.onBeforeAction,
    this.onAfterAction,
  });

  @override
  Widget build(BuildContext context) {
    // Capturar el provider aquí donde sí existe en el árbol
    final provider = context.read<TodayProvider>();

    if (!todayClient.isPending) {
      return GestureDetector(
        onLongPress: () => _showUndoConfirmation(context, provider),
        child: _buildTileContent(context),
      );
    }

    return Dismissible(
      key: Key('today_${todayClient.client.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          onBeforeAction?.call();
          if (context.mounted) {
            await SkippedBottomSheet.show(
              context,
              todayClient,
              provider: provider,
              onAfterAction: onAfterAction,
            );
          }
        } else {
          onBeforeAction?.call();
          if (context.mounted) {
            await PaymentBottomSheet.show(
              context,
              todayClient,
              provider: provider,
              onAfterAction: onAfterAction,
            );
          }
        }
        return false;
      },
      background: _buildSwipeBackground(
        color: Colors.green.shade500,
        icon: Icons.attach_money,
        label: 'Pagó',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        color: Colors.red.shade500,
        icon: Icons.money_off_outlined,
        label: 'No dio',
        alignment: Alignment.centerRight,
      ),
      child: _buildTileContent(context),
    );
  }

  Widget _buildTileContent(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _borderColor(context),
          width: 1.5,
        ),
        color: _backgroundColor(context),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Ícono estado
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _iconBackgroundColor(context),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                _statusIcon(),
                color: _iconColor(context),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayClient.client.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _buildSubtitle(context),
                  // Badge de reagendado
                  if (todayClient.isRescheduled) ...[
                    const SizedBox(height: 4),
                    _buildRescheduledBadge(context),
                  ],
                ],
              ),
            ),

            _buildStatusBadge(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRescheduledBadge(BuildContext context) {
    final scheduled = todayClient.scheduledPayment!;
    final date = DateTime.parse(scheduled.scheduledDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_outlined,
            size: 12,
            color: Colors.amber.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'Agendado · ${Formatters.formatShortDate(date)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.amber.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );

    if (todayClient.isPaid) {
      return Text(
        todayClient.payment?.note?.isNotEmpty == true
            ? todayClient.payment!.note!
            : 'Cobro registrado',
        style: subtitleStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (todayClient.isSkipped) {
      return Text(
        todayClient.payment?.note?.isNotEmpty == true
            ? todayClient.payment!.note!
            : 'Sin justificación',
        style: subtitleStyle?.copyWith(fontStyle: FontStyle.italic),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      Formatters.formatAmount(todayClient.client.credit),
      style: subtitleStyle,
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    if (todayClient.isPending) return const SizedBox.shrink();

    if (todayClient.isPaid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Formatters.formatAmount(todayClient.payment!.amount),
            style: TextStyle(
              color: Colors.green.shade400,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          Text(
            'hold para deshacer',
            style: TextStyle(
              color: Colors.green.shade400,
              fontSize: 10,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'No dio',
          style: TextStyle(
            color: Colors.red.shade400,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        Text(
          'hold para deshacer',
          style: TextStyle(
            color: Colors.red.shade400,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showUndoConfirmation(
    BuildContext context,
    TodayProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deshacer registro'),
        content: Text(
          '¿Deshacer el registro de ${todayClient.client.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deshacer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.undoPayment(todayClient);
    }
  }

  // Colores adaptados al modo oscuro
  Color _borderColor(BuildContext context) {
    if (todayClient.isPaid) return DarkModeHelper.paidBorder(context);
    if (todayClient.isSkipped) return DarkModeHelper.skippedBorder(context);
    if (todayClient.isRescheduled) return Colors.amber.shade300;
    return Theme.of(context).colorScheme.outline.withValues(alpha: 0.2);
  }

  Color _backgroundColor(BuildContext context) {
    if (todayClient.isPaid) return DarkModeHelper.paidBackground(context);
    if (todayClient.isSkipped) return DarkModeHelper.skippedBackground(context);
    if (todayClient.isRescheduled) return Colors.amber.shade50;
    return Theme.of(context).colorScheme.surface;
  }

  Color _iconBackgroundColor(BuildContext context) {
    if (todayClient.isPaid) return DarkModeHelper.paidIconBackground(context);
    if (todayClient.isSkipped)
      return DarkModeHelper.skippedIconBackground(context);
    if (todayClient.isRescheduled) return Colors.amber.shade100;
    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
  }

  Color _iconColor(BuildContext context) {
    if (todayClient.isPaid) return Colors.green.shade400;
    if (todayClient.isSkipped) return Colors.red.shade400;
    if (todayClient.isRescheduled) return Colors.amber.shade700;
    return Theme.of(context).colorScheme.primary;
  }

  IconData _statusIcon() {
    if (todayClient.isPaid) return Icons.check_circle_outline;
    if (todayClient.isSkipped) return Icons.cancel_outlined;
    if (todayClient.isRescheduled) return Icons.event_outlined;
    return Icons.person_outline;
  }
}
