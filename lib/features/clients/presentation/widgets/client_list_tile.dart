import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/client_model.dart';
import '../client_form_screen.dart';
import '../client_provider.dart';

class ClientListTile extends StatelessWidget {
  final ClientModel client;
  final String routeId;

  const ClientListTile({
    super.key,
    required this.client,
    required this.routeId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = _colorForType(context, client.paymentType);

    return Dismissible(
      key: Key('client_${client.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _showDeleteConfirmation(context);
        } else {
          await _navigateToEdit(context);
          return false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          context.read<ClientProvider>().deleteClient(client.id);
        }
      },
      background: _buildSwipeBackground(
        context: context,
        color: theme.colorScheme.primary,
        icon: Icons.edit_outlined,
        label: 'Editar',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        context: context,
        color: theme.colorScheme.error,
        icon: Icons.delete_outline,
        label: 'Eliminar',
        alignment: Alignment.centerRight,
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Ícono tipo de cobro
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForType(client.paymentType),
                  color: typeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Info del cliente
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₡${_formatAmount(client.credit)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildTypeChip(context, typeColor),
                      ],
                    ),
                  ],
                ),
              ),

              // Drag handle
              Icon(
                Icons.drag_handle_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _labelForType(client.paymentType),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required BuildContext context,
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
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEdit(BuildContext context) async {
    final provider = context.read<ClientProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: ClientFormScreen(
            routeId: routeId,
            client: client,
          ),
        ),
      ),
    );
    await provider.loadClients(routeId);
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a "${client.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Color _colorForType(BuildContext context, PaymentType type) {
    switch (type) {
      case PaymentType.daily:
        return Colors.green.shade600;
      case PaymentType.weekly:
        return Colors.blue.shade600;
      case PaymentType.biweekly:
        return Colors.orange.shade600;
      case PaymentType.monthly:
        return Colors.purple.shade600;
    }
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

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}