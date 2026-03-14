import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/client_model.dart';
import '../client_form_screen.dart';
import '../client_provider.dart';
import '../client_history_screen.dart';
import '../../../../core/utils/formatters.dart';

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
    final typeColor = Formatters.paymentTypeColorAdaptive(
      client.paymentType,
      context,
    );

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
        color: theme.colorScheme.primary,
        icon: Icons.edit_outlined,
        label: 'Editar',
        alignment: Alignment.centerLeft,
        foreground: theme.colorScheme.onPrimary,
      ),
      secondaryBackground: _buildSwipeBackground(
        color: theme.colorScheme.error,
        icon: Icons.delete_outline,
        label: 'Eliminar',
        alignment: Alignment.centerRight,
        foreground: theme.colorScheme.onError,
      ),
      child: InkWell(
        onTap: () => _navigateToHistory(context),
        borderRadius: BorderRadius.circular(14),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Ícono tipo de cobro
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: typeColor.withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    Formatters.paymentTypeIcon(client.paymentType),
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
                            Formatters.formatAmount(client.credit),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTypeChip(context, typeColor),
                        ],
                      ),
                    ],
                  ),
                ),

                // Flecha + drag handle
                Column(
                  children: [
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.drag_handle_rounded,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        Formatters.paymentTypeLabel(client.paymentType),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
    required Color foreground,
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
          Icon(icon, color: foreground, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToHistory(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientHistoryScreen(client: client),
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
}