import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class BackupService {
  /// Nombre del archivo de respaldo con fecha actual
  static String getBackupFileName() {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return 'presto_backup_$date.presto';
  }

  /// Exporta la base de datos a un archivo .presto
  /// Retorna la ruta del archivo creado
  static Future<String> exportBackup() async {
    try {
      // Obtener ruta de la DB
      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception('No se encontró la base de datos');
      }

      // Directorio de documentos del dispositivo
      final Directory docsDir = await getApplicationDocumentsDirectory();
      final backupPath = p.join(docsDir.path, getBackupFileName());

      // Copiar archivo DB al destino
      await dbFile.copy(backupPath);

      debugPrint('Respaldo creado en: $backupPath');
      return backupPath;
    } catch (e) {
      throw Exception('Error al crear respaldo: $e');
    }
  }

  /// Importa un archivo .presto sobre la base de datos actual
  static Future<void> importBackup(String filePath) async {
    try {
      final backupFile = File(filePath);

      if (!await backupFile.exists()) {
        throw Exception('El archivo seleccionado no existe');
      }

      // Verificar que es un archivo válido (mayor a 0 bytes)
      final fileSize = await backupFile.length();
      if (fileSize == 0) {
        throw Exception('El archivo de respaldo está vacío');
      }

      // Cerrar la conexión actual a la DB
      await DatabaseHelper.instance.closeDatabase();

      // Obtener ruta de la DB actual
      final dbPath = await DatabaseHelper.instance.getDatabasePath();

      // Hacer backup de seguridad de la DB actual
      final currentDb = File(dbPath);
      if (await currentDb.exists()) {
        await currentDb.copy('$dbPath.bak');
      }

      try {
        // Copiar el archivo de respaldo sobre la DB actual
        await backupFile.copy(dbPath);

        // Reinicializar la conexión a la DB
        await DatabaseHelper.instance.reinitialize();

        // Eliminar el backup de seguridad si todo salió bien
        final bakFile = File('$dbPath.bak');
        if (await bakFile.exists()) {
          await bakFile.delete();
        }

        debugPrint('Respaldo importado exitosamente');
      } catch (e) {
        // Si algo salió mal, restaurar la DB original
        final bakFile = File('$dbPath.bak');
        if (await bakFile.exists()) {
          await bakFile.copy(dbPath);
          await bakFile.delete();
        }
        await DatabaseHelper.instance.reinitialize();
        throw Exception('Error al importar: $e');
      }
    } catch (e) {
      throw Exception('Error al importar respaldo: $e');
    }
  }

  /// Comparte el archivo de respaldo
  static Future<void> shareBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('El archivo de respaldo no existe');
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Respaldo Presto — ${getBackupFileName()}',
        text: 'Respaldo de datos de Presto',
      );
    } catch (e) {
      throw Exception('Error al compartir respaldo: $e');
    }
  }
}