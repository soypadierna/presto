import 'package:flutter/material.dart';
import 'package:presto/features/today/presentation/widgets/today_summary_card.dart';
import 'package:provider/provider.dart';
import '../today_provider.dart';
import 'date_navigator.dart';

enum TodayFilter { all, pending, paid, skipped }

class TodayHeader extends StatelessWidget {
  final String routeId;
  final TodayFilter activeFilter;
  final ValueChanged<TodayFilter> onFilterChanged;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const TodayHeader({
    super.key,
    required this.routeId,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TodayProvider>(
      builder: (context, provider, _) {
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Navegador de fecha — primero
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: DateNavigator(
                selectedDate: provider.selectedDate,
                onDateChanged: (date) {
                  provider.loadTodayClients(routeId, date: date);
                },
              ),
            ),
            const TodaySummaryCard(),

            const SizedBox(height: 10),

            _buildFilters(context, provider),

            const SizedBox(height: 8),

            _buildSearch(context),

            const SizedBox(height: 6),
          ],
        );
      },
    );
  }

  Widget _buildFilters(BuildContext context, TodayProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final filters = [
      (TodayFilter.all, 'Todos', provider.todayClients.length, null),
      (TodayFilter.pending, 'Pendientes', provider.pendingCount, null),
      (
        TodayFilter.paid,
        'Pagaron',
        provider.paidCount,
        const Color(0xFF639922)
      ),
      (
        TodayFilter.skipped,
        'No dieron',
        provider.skippedCount,
        const Color(0xFFE24B4A)
      ),
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final (filter, label, count, dotColor) = filters[index];
          final isActive = activeFilter == filter;

          return GestureDetector(
            onTap: () => onFilterChanged(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? (isDark
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF1A1A1A))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Punto de color para pagaron y no dieron
                  if (dotColor != null && !isActive) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: isActive
                          ? (isDark ? const Color(0xFF1A1A1A) : Colors.white)
                          : colorScheme.onSurface.withValues(alpha: 0.8),
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: isActive
                          ? (isDark ? const Color(0xFF1A1A1A) : Colors.white)
                          : colorScheme.onSurface.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar cliente...',
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.35),
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search,
              size: 18,
            ),
          ),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  onPressed: () {
                    searchController.clear();
                    onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: colorScheme.onSurface.withValues(alpha: 0.07),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
