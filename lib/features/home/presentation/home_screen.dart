import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/routes/domain/route_model.dart';
import '../../../features/clients/presentation/client_list_screen.dart';
import '../../../features/clients/presentation/client_provider.dart';
import '../../../features/today/presentation/today_screen.dart';
import '../../../features/today/presentation/today_provider.dart';
import '../../../features/report/presentation/report_screen.dart';
import '../../../features/report/presentation/report_provider.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ClientProvider()..loadClients(widget.route.id),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              TodayProvider()..loadTodayClients(widget.route.id),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportProvider()..loadReport(widget.route.id),
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
                ReportScreen(route: widget.route),
              ],
            ),
            bottomNavigationBar: Consumer<TodayProvider>(
              builder: (context, todayProvider, _) {
                return NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
                  },
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
        },
      ),
    );
  }
}