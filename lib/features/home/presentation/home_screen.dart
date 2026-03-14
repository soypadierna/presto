import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/routes/domain/route_model.dart';
import '../../../features/clients/presentation/client_list_screen.dart';
import '../../../features/clients/presentation/client_provider.dart';
import '../../../features/today/presentation/today_screen.dart';
import '../../../features/today/presentation/today_provider.dart';
import '../../../features/report/presentation/report_screen.dart';
import '../../../features/report/presentation/report_provider.dart';
import '../../../features/report/presentation/stats_provider.dart';

class HomeScreen extends StatefulWidget {
  final RouteModel route;

  const HomeScreen({super.key, required this.route});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _previousIndex = 0;

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TodayProvider()..loadTodayClients(widget.route.id),
        ),
        ChangeNotifierProxyProvider<TodayProvider, ClientProvider>(
          create: (context) => ClientProvider()..loadClients(widget.route.id),
          update: (context, todayProvider, clientProvider) {
            // Conectar el callback cada vez que se actualiza
            clientProvider!.onClientsChanged = () {
              todayProvider.loadTodayClients(widget.route.id);
            };
            return clientProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => ReportProvider()..loadReport(widget.route.id),
        ),
        ChangeNotifierProvider(
          create: (_) => StatsProvider()..loadStats(widget.route.id),
        ),
      ],
      child: Builder(builder: (context) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              TodayScreen(route: widget.route),
              ClientListScreen(route: widget.route),
              ReportScreen(route: widget.route),
            ],
          ),
          bottomNavigationBar: Consumer<TodayProvider>(
            builder: (context, todayProvider, _) {
              return NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) => _onTabChanged(context, index),
                destinations: [
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
                  NavigationDestination(
                    icon: Icon(_tabs[1].icon),
                    selectedIcon: Icon(_tabs[1].activeIcon),
                    label: _tabs[1].label,
                  ),
                  NavigationDestination(
                    icon: Icon(_tabs[2].icon),
                    selectedIcon: Icon(_tabs[2].activeIcon),
                    label: _tabs[2].label,
                  ),
                ],
              );
            },
          ),
        );
      }),
    );
  }

  void _onTabChanged(BuildContext context, int newIndex) {
    final todayProvider = context.read<TodayProvider>();
    final clientProvider = context.read<ClientProvider>();

    // Si venía de clientes y va a hoy → refrescar lista del día
    if (_previousIndex == 1 && newIndex == 0) {
      todayProvider.loadTodayClients(widget.route.id);
    }

    // Si va a clientes → refrescar lista de clientes
    if (newIndex == 1) {
      clientProvider.loadClients(widget.route.id);
    }

    // Si va a hoy directamente → siempre refrescar
    if (newIndex == 0) {
      todayProvider.loadTodayClients(widget.route.id);
    }

    _previousIndex = _currentIndex;
    setState(() => _currentIndex = newIndex);
  }
}
