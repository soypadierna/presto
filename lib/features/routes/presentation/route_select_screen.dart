import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/route_model.dart';
import 'route_provider.dart';
import 'widgets/route_card.dart';
import '../../home/presentation/home_screen.dart';
import '../../home/presentation/settings_screen.dart';
import '../../../core/error/error_listener.dart';
import '../data/route_repository.dart';

class RouteSelectScreen extends StatefulWidget {
  const RouteSelectScreen({super.key});

  @override
  State<RouteSelectScreen> createState() => _RouteSelectScreenState();
}

class _RouteSelectScreenState extends State<RouteSelectScreen>
    with ErrorListenerMixin {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RouteProvider>();
      listenForErrors<RouteProvider>(
        errorSelector: (p) => p.errorMessage,
        clearError: provider.clearError,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Presto',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
            ),
            centerTitle: false,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.routes.isEmpty
                  ? _buildEmptyState(context)
                  : RefreshIndicator(
                      onRefresh: provider.loadRoutes,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: provider.routes.length,
                        itemBuilder: (context, index) {
                          final route = provider.routes[index];
                          return RouteCard(
                            route: route,
                            onTap: () => _navigateToRoute(context, route),
                            onEdit: () =>
                                _showEditDialog(context, provider, route),
                            onDelete: () =>
                                _handleDeleteRoute(context, provider, route),
                          );
                        },
                      ),
                    ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Nueva ruta'),
          ),
        );
      },
    );
  }

  /// Maneja la eliminación de una ruta —
  /// primero intenta sin forzar y si falla muestra el dialog de confirmación.
  Future<void> _handleDeleteRoute(
    BuildContext context,
    RouteProvider provider,
    RouteModel route,
  ) async {
    final deleted = await provider.deleteRoute(route.id);

    if (deleted || !context.mounted) return;

    // Tiene datos — obtener estadísticas y mostrar confirmación
    final stats = await provider.getRouteStats(route.id);
    if (!context.mounted) return;

    await _showForceDeleteDialog(context, provider, route, stats);
  }

  Future<void> _showForceDeleteDialog(
    BuildContext context,
    RouteProvider provider,
    RouteModel route,
    RouteDeleteStats stats,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: colorScheme.error, size: 24),
            const SizedBox(width: 8),
            const Text('Eliminar ruta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La ruta "${route.name}" contiene datos que '
              'también serán eliminados permanentemente:',
            ),
            const SizedBox(height: 16),
            // Estadísticas
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    context: ctx,
                    icon: Icons.people_outline,
                    label: 'Clientes',
                    value: '${stats.clientCount}',
                  ),
                  const SizedBox(height: 6),
                  _buildStatRow(
                    context: ctx,
                    icon: Icons.payments_outlined,
                    label: 'Pagos registrados',
                    value: '${stats.paymentCount}',
                  ),
                  const SizedBox(height: 6),
                  _buildStatRow(
                    context: ctx,
                    icon: Icons.receipt_outlined,
                    label: 'Gastos',
                    value: '${stats.expenseCount}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Esta acción no se puede deshacer.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: const Text('Eliminar todo'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await provider.forceDeleteRoute(route.id);
    }
  }

  Widget _buildStatRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.route_outlined,
                size: 52,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin rutas todavía',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Crea tu primera ruta para empezar a gestionar tus cobros.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Crear primera ruta'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToRoute(BuildContext context, RouteModel route) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(route: route),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final provider = context.read<RouteProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva ruta'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre de la ruta',
              hintText: 'Ej: Ruta Norte',
              prefixIcon: Icon(Icons.route_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre no puede estar vacío';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                provider.addRoute(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    RouteProvider provider,
    RouteModel route,
  ) {
    final controller = TextEditingController(text: route.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar ruta'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre de la ruta',
              prefixIcon: Icon(Icons.route_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre no puede estar vacío';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                provider.updateRoute(
                  route.copyWith(name: controller.text.trim()),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}