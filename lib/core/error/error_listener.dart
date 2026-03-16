import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Mixin que agrega escucha de errores a cualquier State.
/// Usar en pantallas que tienen un provider con errorMessage.
mixin ErrorListenerMixin<T extends StatefulWidget> on State<T> {
  /// Registra un listener de errores para el provider dado.
  /// Muestra un SnackBar automáticamente cuando hay un error
  /// y lo limpia del provider después de mostrarlo.
  void listenForErrors<P extends ChangeNotifier>({
    required String? Function(P provider) errorSelector,
    required VoidCallback clearError,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<P>().addListener(() {
        if (!mounted) return;
        final error = errorSelector(context.read<P>());
        if (error != null) {
          _showErrorSnackBar(error);
          clearError();
        }
      });
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}