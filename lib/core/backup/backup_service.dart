import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import 'backup_validator.dart';

/// Servicio para exportar e importar la base de datos de Presto.
///
/// Los archivos de respaldo tienen extensión `.presto` y son
/// simplemente copias del archivo SQLite renombradas.
class BackupService {
  /// Retorna el nombre del archivo de respaldo con la fecha actual.
  /// Ejemplo: `presto_backup_2026-03-15.presto`
  static String getBackupFileName() {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return 'presto_backup_$date.presto';
  }

  /// Exporta la base de datos al directorio de documentos del dispositivo.
  ///
  /// Retorna la ruta absoluta del archivo creado.
  /// Lanza [Exception] si la base de datos no existe o falla la copia.
  static Future<String> exportBackup() async {
    try {
      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception('No se encontró la base de datos');
      }

      final Directory docsDir = await getApplicationDocumentsDirectory();
      final backupPath = p.join(docsDir.path, getBackupFileName());
      await dbFile.copy(backupPath);

      debugPrint('Respaldo creado en: $backupPath');
      return backupPath;
    } catch (e) {
      throw Exception('Error al crear respaldo: $e');
    }
  }

  /// Importa un archivo `.presto` sobre la base de datos actual.
  ///
  /// El proceso es:
  /// 1. Cierra la conexión activa
  /// 2. Hace backup de seguridad de la DB actual
  /// 3. Copia el archivo importado
  /// 4. Reinicializa la conexión
  /// 5. Si algo falla, restaura el backup de seguridad
  /// Valida e importa un archivo `.presto` sobre la base de datos actual.
  static Future<void> importBackup(String filePath) async {
    try {
      // 1. Validar el archivo antes de hacer cualquier cambio
      final validation = await BackupValidator.validate(filePath);
      if (!validation.isValid) {
        throw Exception(validation.errorMessage);
      }

      final backupFile = File(filePath);
      await DatabaseHelper.instance.closeDatabase();
      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final currentDb = File(dbPath);

      // 2. Backup de seguridad de la DB actual
      if (await currentDb.exists()) {
        await currentDb.copy('$dbPath.bak');
      }

      try {
        await backupFile.copy(dbPath);
        await DatabaseHelper.instance.reinitialize();

        final bakFile = File('$dbPath.bak');
        if (await bakFile.exists()) await bakFile.delete();

        debugPrint('Respaldo importado exitosamente');
      } catch (e) {
        // Restaurar DB original si algo salió mal
        final bakFile = File('$dbPath.bak');
        if (await bakFile.exists()) {
          await bakFile.copy(dbPath);
          await bakFile.delete();
        }
        await DatabaseHelper.instance.reinitialize();
        throw Exception('Error al importar: $e');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Valida un archivo sin importarlo — para mostrar info previa al usuario.
  static Future<BackupValidationResult> validateOnly(
    String filePath,
  ) async {
    return BackupValidator.validate(filePath);
  }

  /// Comparte el archivo de respaldo usando el sistema del dispositivo.
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
