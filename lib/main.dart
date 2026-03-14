import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/routes/presentation/route_provider.dart';
import 'features/routes/presentation/route_select_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PrestoApp());
}

class PrestoApp extends StatelessWidget {
  const PrestoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Solo RouteProvider es global
        // ClientProvider y TodayProvider se inyectan
        // localmente en HomeScreen por ruta
        ChangeNotifierProvider(create: (_) => RouteProvider()),
      ],
      child: MaterialApp(
        title: 'Presto',
        debugShowCheckedModeBanner: false,
        home: const RouteSelectScreen(),
      ),
    );
  }
}