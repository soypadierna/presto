import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/routes/domain/route_model.dart';
import '../../../features/clients/presentation/client_list_screen.dart';
import '../../../features/clients/presentation/client_provider.dart';
import '../../../features/today/presentation/today_screen.dart';
import '../../../features/today/presentation/today_provider.dart';

class HomeScreen extends StatefulWidget {
  final RouteModel route;

  const HomeScreen({super.key, required this.route});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<({IconData icon, IconData activeIcon, String label})> _tabs = [
    (
      icon: Icons.today_outlined,
      activeIcon: Icons.today,
      label: 'Hoy',
    ),
    (
      icon: Icons.people_outlined,
      activeIcon: Icons.people,
      label: 'Clientes',
    ),
    (
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      label: 'Informe',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ClientProvider()..loadClients(widget.route.id),
        ),
        ChangeNotifierProvider(
          create: (_) => TodayProvider()
            ..loadTodayClients(widget.route.id),
        ),
      ],
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: [
                TodayScreen(route: widget.route),
                ClientListScreen(route: widget.route),
                _buildReportPlaceholder(context),
              ],
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withOpacity(0.15),
                  ),
                ),
              ),
              child: Consumer<TodayProvider>(
                builder: (context, todayProvider, _) {
                  return NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (index) {
                      setState(() => _currentIndex = index);
                    },
                    destinations: [
                      // Tab Hoy con badge de pendientes
                      NavigationDestination(
                        icon: Badge(
                          isLabelVisible: todayProvider.pendingCount > 0,
                          label: Text('${todayProvider.pendingCount}'),
                          child: Icon(_tabs[0].icon),
                        ),
                        selectedIcon: Badge(
                          isLabelVisible: todayProvider.pendingCount > 0,
                          label: Text('${todayProvider.pendingCount}'),
                          child: Icon(_tabs[0].activeIcon),
                        ),
                        label: _tabs[0].label,
                      ),
                      // Tab Clientes
                      NavigationDestination(
                        icon: Icon(_tabs[1].icon),
                        selectedIcon: Icon(_tabs[1].activeIcon),
                        label: _tabs[1].label,
                      ),
                      // Tab Informe
                      NavigationDestination(
                        icon: Icon(_tabs[2].icon),
                        selectedIcon: Icon(_tabs[2].activeIcon),
                        label: _tabs[2].label,
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.route.name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Informe del día',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Próximamente',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}