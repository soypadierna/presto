import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
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
        ChangeNotifierProvider(create: (_) => RouteProvider()),
      ],
      child: MaterialApp(
        title: 'Presto',
        debugShowCheckedModeBanner: false,
        // theme: AppTheme.lightTheme,
        home: const RouteSelectScreen(),
      ),
    );
  }
}