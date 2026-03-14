import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/routes/presentation/route_provider.dart';
import 'features/routes/presentation/route_select_screen.dart';

void main() async {
final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const PrestoApp());
}

class PrestoApp extends StatefulWidget {
  const PrestoApp({super.key});

  @override
  State<PrestoApp> createState() => _PrestoAppState();
}

class _PrestoAppState extends State<PrestoApp> {
  @override
  void initState() {
    super.initState();
    // Remover el splash al terminar la inicialización
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Pequeña pausa para que se vea el splash
    await Future.delayed(const Duration(milliseconds: 500));
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Presto',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            localizationsDelegates: const [
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
          );
        },
      ),
    );
  }
}