import 'dart:ui';

import 'package:flutter/material.dart';

/// Configura el manejo global de errores de la app.
/// Llamar una sola vez en main() antes de runApp.
class ErrorHandler {
  static void initialize() {
    // 1. Errores de Flutter (framework, widgets, rendering)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('═══ FLUTTER ERROR ═══');
      debugPrint('${details.exception}');
      debugPrint('${details.stack}');
    };

    // 2. Errores asíncronos no capturados (Future, async/await)
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('═══ DART ERROR ═══');
      debugPrint('$error');
      debugPrint('$stack');
      return true; // true = error manejado, no crashea la app
    };
  }
}