import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Helper para gestionar imágenes de comprobantes de pago.
class ImageHelper {
  static final _picker = ImagePicker();

  /// Toma una foto con la cámara y la guarda en el directorio de la app.
  /// Retorna la ruta local del archivo o null si se canceló.
  static Future<String?> pickFromCamera() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (photo == null) return null;
      return await _saveImageToAppDir(photo.path);
    } catch (e) {
      debugPrint('Error tomando foto: $e');
      return null;
    }
  }

  /// Selecciona una imagen de la galería y la guarda en el directorio de la app.
  /// Retorna la ruta local del archivo o null si se canceló.
  static Future<String?> pickFromGallery() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (image == null) return null;
      return await _saveImageToAppDir(image.path);
    } catch (e) {
      debugPrint('Error seleccionando imagen: $e');
      return null;
    }
  }

  /// Elimina una imagen del almacenamiento local.
  static Future<void> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error eliminando imagen: $e');
    }
  }

  /// Muestra un bottom sheet para elegir entre cámara y galería.
  /// Retorna la ruta de la imagen seleccionada o null si se canceló.
  static Future<String?> showImageSourceDialog(
    BuildContext context,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showModalBottomSheet<String?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Adjuntar comprobante',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // Opción cámara
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: colorScheme.primary,
                  ),
                ),
                title: const Text('Tomar foto'),
                subtitle: const Text('Usar la cámara del dispositivo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final path = await pickFromCamera();
                  if (ctx.mounted && path != null) {
                    Navigator.pop(context, path);
                  } else if (ctx.mounted) {
                    Navigator.pop(context, null);
                  }
                },
              ),
              // Opción galería
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: colorScheme.primary,
                  ),
                ),
                title: const Text('Seleccionar de galería'),
                subtitle: const Text('Elegir imagen existente'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final path = await pickFromGallery();
                  if (ctx.mounted && path != null) {
                    Navigator.pop(context, path);
                  } else if (ctx.mounted) {
                    Navigator.pop(context, null);
                  }
                },
              ),
              const SizedBox(height: 8),
              // Cancelar
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Copia la imagen al directorio de documentos de la app
  /// con un nombre único para evitar colisiones.
  static Future<String> _saveImageToAppDir(String sourcePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(docsDir.path, 'payment_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final ext = p.extension(sourcePath);
    final fileName = '${const Uuid().v4()}$ext';
    final destPath = p.join(imagesDir.path, fileName);

    await File(sourcePath).copy(destPath);
    return destPath;
  }
}