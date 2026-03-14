import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
        ChangeNotifierProvider(create: (_) => RouteProvider()),
      ],
      child: MaterialApp(
        title: 'Presto',
        debugShowCheckedModeBanner: false,
        // Localización en español
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'CR'),
          Locale('es'),
          Locale('en'),
        ],
        locale: const Locale('es', 'CR'),
        home: const RouteSelectScreen(),
      ),
    );
  }
}
