import 'package:flutter/material.dart';
import 'package:presto/features/today/domain/today_client.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../routes/domain/route_model.dart';
import 'today_provider.dart';
import 'widgets/today_client_tile.dart';
import 'widgets/today_summary_card.dart';
import '../../../../core/error/error_listener.dart';

/// Filtros disponibles para la lista del día.
enum TodayFilter { all, pending, paid, skipped }

class TodayScreen extends StatefulWidget {
  final RouteModel route;

  const TodayScreen({super.key, required this.route});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with ErrorListenerMixin, AutomaticKeepAliveClientMixin {

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  TodayFilter _activeFilter = TodayFilter.all;

  // Mapa para recordar la posición de scroll por cliente
  final Map<String, double> _scrollPositions = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TodayProvider>();
      provider.loadTodayClients(widget.route.id);

      listenForErrors<TodayProvider>(
        errorSelector: (p) => p.errorMessage,
        clearError: provider.clearError,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat("EEEE d 'de' MMMM, yyyy", 'es').format(date);
  }

  /// Filtra los clientes según el filtro activo y la búsqueda.
  List<TodayClient> _applyFilters(List<TodayClient> clients) {
    var filtered = clients;

    // Aplicar filtro de estado
    switch (_activeFilter) {
      case TodayFilter.pending:
        filtered = filtered.where((tc) => tc.isPending).toList();
        break;
      case TodayFilter.paid:
        filtered = filtered.where((tc) => tc.isPaid).toList();
        break;
      case TodayFilter.skipped:
        filtered = filtered.where((tc) => tc.isSkipped).toList();
        break;
      case TodayFilter.all:
        break;
    }

    // Aplicar búsqueda por nombre
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((tc) => tc.client.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  /// Guarda la posición actual del scroll antes de registrar un pago.
  void _saveScrollPosition() {
    _scrollPositions['current'] = _scrollController.offset;
  }

  /// Restaura la posición del scroll después de registrar un pago.
  void _restoreScrollPosition() {
    final position = _scrollPositions['current'];
    if (position != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(
            position.clamp(0, _scrollController.position.maxScrollExtent),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.route.name),
            Consumer<TodayProvider>(
              builder: (_, provider, __) => Text(
                _formatDate(provider.selectedDate),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Consumer<TodayProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = _applyFilters(provider.todayClients);

          return Column(
            children: [
              // Resumen del día
              const TodaySummaryCard(),

              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
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

              // Filtros
              _buildFilterChips(context, provider),

              // Lista del día
              Expanded(
                child: provider.todayClients.isEmpty
                    ? _buildEmptyState(context)
                    : filtered.isEmpty
                        ? _buildEmptyFilterState(context)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: filtered.length,
                            cacheExtent: 500,
                            itemBuilder: (context, index) =>
                                RepaintBoundary(
                              child: TodayClientTile(
                                key: ValueKey(filtered[index].client.id),
                                todayClient: filtered[index],
                                onBeforeAction: _saveScrollPosition,
                                onAfterAction: _restoreScrollPosition,
                              ),
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    TodayProvider provider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              context: context,
              label: 'Todos',
              count: provider.todayClients.length,
              filter: TodayFilter.all,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context: context,
              label: 'Pendientes',
              count: provider.pendingCount,
              filter: TodayFilter.pending,
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context: context,
              label: 'Pagaron',
              count: provider.paidCount,
              filter: TodayFilter.paid,
              color: Colors.green.shade600,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context: context,
              label: 'No dieron',
              count: provider.skippedCount,
              filter: TodayFilter.skipped,
              color: Colors.red.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required int count,
    required TodayFilter filter,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = _activeFilter == filter;

    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? color : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isActive ? Colors.white : colorScheme.onSurface,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.25)
                    : colorScheme.outline.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? Colors.white
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final messages = {
      TodayFilter.pending: 'Sin clientes pendientes',
      TodayFilter.paid: 'Ningún cliente ha pagado aún',
      TodayFilter.skipped: 'Ningún cliente marcado como "no dio"',
      TodayFilter.all: 'Sin resultados',
    };

    final icons = {
      TodayFilter.pending: Icons.schedule_outlined,
      TodayFilter.paid: Icons.check_circle_outline,
      TodayFilter.skipped: Icons.cancel_outlined,
      TodayFilter.all: Icons.search_off_rounded,
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icons[_activeFilter]!,
            size: 52,
            color: colorScheme.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 14),
          Text(
            _searchQuery.isNotEmpty
                ? 'Sin resultados para "$_searchQuery"'
                : messages[_activeFilter]!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          if (_activeFilter != TodayFilter.all) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  setState(() => _activeFilter = TodayFilter.all),
              child: const Text('Ver todos'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin cobros para hoy',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ningún cliente tiene cobro programado hoy',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}