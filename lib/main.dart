import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/error/app_error_widget.dart';
import 'core/error/error_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/routes/presentation/route_provider.dart';
import 'features/routes/presentation/route_select_screen.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Inicializar manejo global de errores
  ErrorHandler.initialize();

  // Reemplazar la pantalla roja por nuestra pantalla de error
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return AppErrorWidget(details: details);
  };

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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Pequeña pausa para que se vea el splash
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Error inicializando app: $e');
    } finally {
      // SIEMPRE remover el splash — incluso si hay error
      FlutterNativeSplash.remove();
    }
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
            // Builder para capturar errores de navegación
            builder: (context, child) {
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
