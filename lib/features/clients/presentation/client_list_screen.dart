import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/client_model.dart';
import '../../routes/domain/route_model.dart';
import 'client_provider.dart';
import 'client_form_screen.dart';
import 'widgets/client_list_tile.dart';
import '../../../core/error/error_listener.dart';

class ClientListScreen extends StatefulWidget {
  final RouteModel route;

  const ClientListScreen({super.key, required this.route});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen>
    with ErrorListenerMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ClientProvider>();
      provider.loadClients(widget.route.id);

      // Escuchar errores
      listenForErrors<ClientProvider>(
        errorSelector: (p) => p.errorMessage,
        clearError: provider.clearError,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ClientModel> _filterClients(List<ClientModel> clients) {
    if (_searchQuery.isEmpty) return clients;
    return clients
        .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.route.name),
            Consumer<ClientProvider>(
              builder: (_, provider, __) => Text(
                '${provider.clients.length} clientes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<ClientProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final filtered = _filterClients(provider.clients);

                if (provider.clients.isEmpty) {
                  return _buildEmptyState(context);
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sin resultados para "$_searchQuery"',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_searchQuery.isNotEmpty) {
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => ClientListTile(
                      client: filtered[index],
                      routeId: widget.route.id,
                    ),
                  );
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: provider.clients.length,
                  onReorder: provider.reorderClients,
                  itemBuilder: (context, index) => ClientListTile(
                    key: Key('tile_${provider.clients[index].id}'),
                    client: provider.clients[index],
                    routeId: widget.route.id,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAdd(context),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Nuevo cliente'),
      ),
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
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 44,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin clientes todavía',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Agrega tu primer cliente a esta ruta.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => _navigateToAdd(context),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Agregar cliente'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToAdd(BuildContext context) async {
    final provider = context.read<ClientProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: ClientFormScreen(routeId: widget.route.id),
        ),
      ),
    );
    await provider.loadClients(widget.route.id);
  }
}
