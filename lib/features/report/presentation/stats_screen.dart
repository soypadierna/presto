import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/error/error_listener.dart';
import '../../routes/domain/route_model.dart';
import '../../../core/utils/formatters.dart';
import '../domain/day_summary.dart';
import '../domain/month_summary.dart';
import 'stats_provider.dart';
import 'day_detail_screen.dart';

class StatsScreen extends StatefulWidget {
  final RouteModel route;

  const StatsScreen({super.key, required this.route});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin, ErrorListenerMixin {
  late TabController _tabController;

@override
void initState() {
  super.initState();
  _tabController = TabController(length: 2, vsync: this);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final provider = context.read<StatsProvider>();
    provider.loadStats(widget.route.id);

    // Escuchar errores
    listenForErrors<StatsProvider>(
      errorSelector: (p) => p.errorMessage,
      clearError: provider.clearError,
    );
  });
}

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Estadísticas'),
            Text(
              widget.route.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mes actual'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: Consumer<StatsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildMonthTab(context, provider),
              _buildHistoryTab(context, provider),
            ],
          );
        },
      ),
    );
  }

  // ── Tab Mes actual ──────────────────────────────────────────
  Widget _buildMonthTab(BuildContext context, StatsProvider provider) {
    final month = provider.currentMonth;

    if (month == null || month.daysWorked == 0) {
      return _buildEmptyState(
        context,
        icon: Icons.bar_chart_outlined,
        message: 'Sin datos para este mes',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMonthSummaryCard(context, month),
        const SizedBox(height: 20),
        _buildBarChart(context, month),
      ],
    );
  }

  Widget _buildMonthSummaryCard(BuildContext context, MonthSummary month) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final monthName = _monthName(month.month);

  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
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
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$monthName ${month.year}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          Formatters.formatAmount(month.netTotal),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildMonthStatChip(
              label: 'Cobrado',
              value: Formatters.formatAmount(month.totalCollected),
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(width: 10),
            _buildMonthStatChip(
              label: 'Gastos',
              value: Formatters.formatAmount(month.totalExpenses),
              color: Colors.red.shade300,
            ),
            const SizedBox(width: 10),
            _buildMonthStatChip(
              label: 'Días',
              value: '${month.daysWorked}',
              color: Colors.white.withOpacity(0.9),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildBarChart(BuildContext context, MonthSummary month) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  if (month.days.isEmpty) return const SizedBox.shrink();

  final maxNet = month.days
      .map((d) => d.netTotal.abs())
      .reduce((a, b) => a > b ? a : b);

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: colorScheme.outline.withOpacity(0.15),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Neto por día',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: month.days.map((day) {
              final ratio = maxNet > 0
                  ? (day.netTotal.abs() / maxNet).clamp(0.05, 1.0)
                  : 0.05;
              final barHeight = 120 * ratio;
              final isPositive = day.netTotal >= 0;
              final date = DateTime.parse(day.date);

              return Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToDayDetail(context, day),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            // Gris oscuro para positivo,
                            // rojo funcional para negativo
                            color: isPositive
                                ? (isDark
                                    ? const Color(0xFFBDBDBD)
                                    : const Color(0xFF424242))
                                : Colors.red.shade400,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 9,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(
              context: context,
              color: isDark
                  ? const Color(0xFFBDBDBD)
                  : const Color(0xFF424242),
              label: 'Positivo',
            ),
            const SizedBox(width: 16),
            _buildLegendItem(
              context: context,
              color: Colors.red.shade400,
              label: 'Negativo',
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildMonthStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required BuildContext context,
    required Color color,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // ── Tab Historial ───────────────────────────────────────────
  Widget _buildHistoryTab(BuildContext context, StatsProvider provider) {
    if (provider.recentDays.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.history_outlined,
        message: 'Sin historial disponible',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.recentDays.length,
      itemBuilder: (context, index) {
        final day = provider.recentDays[index];
        return _buildDayHistoryTile(context, day);
      },
    );
  }

  Widget _buildDayHistoryTile(BuildContext context, DaySummary day) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final date = DateTime.parse(day.date);
    final isPositive = day.netTotal >= 0;

    return InkWell(
      onTap: () => _navigateToDayDetail(context, day),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            // Fecha
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    _shortMonthName(date.month),
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.primary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.formatDate(date),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Cobrado: ${Formatters.formatAmount(day.totalCollected)} · '
                    '${day.paidCount} pagaron',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Neto
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatAmount(day.netTotal),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isPositive
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                  ),
                ),
                Text(
                  'neto',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withOpacity(0.3),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDayDetail(BuildContext context, DaySummary day) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DayDetailScreen(
          summary: day,
          routeName: widget.route.name,
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return names[month];
  }

  String _shortMonthName(int month) {
    const names = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return names[month];
  }
}