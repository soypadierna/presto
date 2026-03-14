  import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Script para generar los PNGs necesarios para ícono y splash
/// Ejecutar con: flutter run -t tools/generate_assets.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Crear directorios si no existen
  await Directory('assets/icon').create(recursive: true);
  await Directory('assets/splash').create(recursive: true);

  // Generar ícono 1024x1024
  await _generateIcon();

  // Generar foreground adaptativo 768x768
  await _generateAdaptiveForeground();

  // Generar splash 512x512
  await _generateSplash();

  debugPrint('✅ Assets generados correctamente');
  exit(0);
}

/// Genera el ícono principal 1024x1024
Future<void> _generateIcon() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = 1024.0;

  // Fondo negro
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, size, size),
    Paint()..color = const Color(0xFF1A1A1A),
  );

  // Círculo verde suave
  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    380,
    Paint()..color = const Color(0xFF4CAF50).withOpacity(0.12),
  );

  // Símbolo ₡
  final textPainter = TextPainter(
    text: const TextSpan(
      text: '₡',
      style: TextStyle(
        color: Color(0xFF4CAF50),
        fontSize: 520,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2 - 20,
    ),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  await File('assets/icon/app_icon.png')
      .writeAsBytes(bytes!.buffer.asUint8List());
  debugPrint('✅ app_icon.png generado (1024x1024)');
}

/// Genera el foreground adaptativo 768x768
Future<void> _generateAdaptiveForeground() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = 768.0;

  // Fondo transparente
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, size, size),
    Paint()..color = const Color(0x00000000),
  );

  // Símbolo ₡ centrado con padding
  final textPainter = TextPainter(
    text: const TextSpan(
      text: '₡',
      style: TextStyle(
        color: Color(0xFF4CAF50),
        fontSize: 400,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2 - 15,
    ),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  await File('assets/icon/app_icon_foreground.png')
      .writeAsBytes(bytes!.buffer.asUint8List());
  debugPrint('✅ app_icon_foreground.png generado (768x768)');
}

/// Genera el logo del splash 512x512
Future<void> _generateSplash() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = 512.0;

  // Fondo transparente
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, size, size),
    Paint()..color = const Color(0x00000000),
  );

  // Círculo verde suave
  canvas.drawCircle(
    const Offset(size / 2, size / 2 - 30),
    170,
    Paint()..color = const Color(0xFF4CAF50).withOpacity(0.12),
  );

  // Símbolo ₡
  final symbolPainter = TextPainter(
    text: const TextSpan(
      text: '₡',
      style: TextStyle(
        color: Color(0xFF4CAF50),
        fontSize: 240,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  symbolPainter.layout();
  symbolPainter.paint(
    canvas,
    Offset(
      (size - symbolPainter.width) / 2,
      size / 2 - symbolPainter.height / 2 - 40,
    ),
  );

  // Nombre PRESTO
  final namePainter = TextPainter(
    text: const TextSpan(
      text: 'PRESTO',
      style: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 64,
        fontWeight: FontWeight.bold,
        letterSpacing: 8,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  namePainter.layout();
  namePainter.paint(
    canvas,
    Offset(
      (size - namePainter.width) / 2,
      size / 2 + 100,
    ),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  await File('assets/splash/splash_logo.png')
      .writeAsBytes(bytes!.buffer.asUint8List());
  debugPrint('✅ splash_logo.png generado (512x512)');
}