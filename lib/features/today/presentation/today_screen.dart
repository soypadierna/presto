import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/domain/route_model.dart';
import 'today_provider.dart';
import 'widgets/today_client_tile.dart';
import 'widgets/today_header.dart';
import 'widgets/client_picker_bottom_sheet.dart';
import 'widgets/payment_bottom_sheet.dart';
import '../../today/domain/today_client.dart';
import '../../../../core/error/error_listener.dart';

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
          .where((tc) =>
              tc.client.name.toLowerCase().contains(_searchQuery.toLowerCase()))
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
        title: Text(
          widget.route.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          Consumer<TodayProvider>(
            builder: (context, provider, _) => IconButton(
              icon: const Icon(Icons.person_add_outlined),
              tooltip: 'Registrar abono',
              onPressed: () => _showClientPicker(context, provider),
            ),
          ),
        ],
      ),
      body: Consumer<TodayProvider>(
        builder: (context, provider, _) {
          final filtered = _applyFilters(provider.todayClients);

          return Column(
            children: [
              TodayHeader(
                routeId: widget.route.id,
                activeFilter: _activeFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _activeFilter = filter;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                searchController: _searchController,
                onSearchChanged: (v) => setState(() => _searchQuery = v),
              ),

              // Lista
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.todayClients.isEmpty
                        ? _buildEmptyState(context, provider)
                        : filtered.isEmpty
                            ? _buildEmptyFilterState(context)
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  bottom: 24,
                                ),
                                itemCount: filtered.length,
                                cacheExtent: 500,
                                itemBuilder: (context, index) =>
                                    RepaintBoundary(
                                  child: TodayClientTile(
                                    key: ValueKey(filtered[index].client.id),
                                    todayClient: filtered[index],
                                    orderIndex: index, // ← agregar
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
            size: 56,
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 14),
          Text(
            isToday ? 'Sin cobros para hoy' : 'Sin cobros para este día',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState(BuildContext context) {
    final theme = Theme.of(context);
    final messages = {
      TodayFilter.pending: 'Sin clientes pendientes',
      TodayFilter.paid: 'Ningún cliente ha pagado',
      TodayFilter.skipped: 'Ningún cliente marcado como no dio',
      TodayFilter.all: 'Sin resultados',
    };
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'Sin resultados para "$_searchQuery"'
                : messages[_activeFilter]!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          if (_activeFilter != TodayFilter.all) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => setState(() => _activeFilter = TodayFilter.all),
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
