import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/domain/route_model.dart';
import 'today_provider.dart';
import 'widgets/today_client_tile.dart';
import 'widgets/today_summary_card.dart';
import 'widgets/date_navigator.dart';
import 'widgets/client_picker_bottom_sheet.dart';
import 'widgets/payment_bottom_sheet.dart';
import '../../today/domain/today_client.dart';
import '../../../../core/error/error_listener.dart';

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

  List<TodayClient> _applyFilters(List<TodayClient> clients) {
    var filtered = clients;

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

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((tc) => tc.client.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  void _saveScrollPosition() {
    _scrollPositions['current'] = _scrollController.offset;
  }

  void _restoreScrollPosition() {
    final position = _scrollPositions['current'];
    if (position != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(
            position.clamp(
              0,
              _scrollController.position.maxScrollExtent,
            ),
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
        // Nombre de la ruta a la izquierda
        title: Text(
          widget.route.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        // Navegador de fechas centrado
        centerTitle: false,
        actions: [
          // Botón agregar abono
          Consumer<TodayProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: const Icon(Icons.person_add_outlined),
                tooltip: 'Registrar abono',
                onPressed: () => _showClientPicker(context, provider),
              );
            },
          ),
        ],
        // Navegador de fechas en el bottom del AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Consumer<TodayProvider>(
            builder: (context, provider, _) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DateNavigator(
                  selectedDate: provider.selectedDate,
                  onDateChanged: (date) {
                    provider.loadTodayClients(
                      widget.route.id,
                      date: date,
                    );
                    // Resetear filtros y búsqueda al cambiar fecha
                    setState(() {
                      _activeFilter = TodayFilter.all;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                ),
              );
            },
          ),
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
                    ? _buildEmptyState(context, provider)
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
                                key: ValueKey(
                                    filtered[index].client.id),
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
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isActive ? color : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? color
                : colorScheme.outline.withValues(alpha: 0.3),
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

  Widget _buildEmptyState(
    BuildContext context,
    TodayProvider provider,
  ) {
    final theme = Theme.of(context);
    final isToday = _isToday(provider.selectedDate);

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
            isToday
                ? 'Sin cobros para hoy'
                : 'Sin cobros para este día',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ningún cliente tiene cobro programado',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final messages = {
      TodayFilter.pending: 'Sin clientes pendientes',
      TodayFilter.paid: 'Ningún cliente ha pagado',
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

  Future<void> _showClientPicker(
    BuildContext context,
    TodayProvider provider,
  ) async {
    final clients = await provider.getClientsNotInList(widget.route.id);

    if (!context.mounted) return;

    final selectedClient = await ClientPickerBottomSheet.show(
      context,
      clients: clients,
    );

    if (selectedClient == null || !context.mounted) return;

    final tempTodayClient = TodayClient(
      client: selectedClient,
      payment: null,
    );

    if (!context.mounted) return;

    await PaymentBottomSheet.show(
      context,
      tempTodayClient,
      provider: provider,
      onAfterAction: null,
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}