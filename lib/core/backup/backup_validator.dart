import 'dart:io';
import 'package:sqflite/sqflite.dart';

/// Resultado de la validación de un archivo de respaldo.
class BackupValidationResult {
  final bool isValid;
  final String? errorMessage;
  final BackupInfo? info;

  const BackupValidationResult({
    required this.isValid,
    this.errorMessage,
    this.info,
  });

  factory BackupValidationResult.valid(BackupInfo info) {
    return BackupValidationResult(isValid: true, info: info);
  }

  factory BackupValidationResult.invalid(String message) {
    return BackupValidationResult(isValid: false, errorMessage: message);
  }
}

/// Información extraída del archivo de respaldo validado.
class BackupInfo {
  final int routeCount;
  final int clientCount;
  final int paymentCount;
  final int expenseCount;
  final String? oldestDate;
  final String? newestDate;
  final int fileSizeKb;

  const BackupInfo({
    required this.routeCount,
    required this.clientCount,
    required this.paymentCount,
    required this.expenseCount,
    this.oldestDate,
    this.newestDate,
    required this.fileSizeKb,
  });
}

/// Valida que un archivo .presto sea una base de datos SQLite
/// compatible con Presto antes de importarlo.
class BackupValidator {
  /// Tablas requeridas en la base de datos de Presto.
  static const _requiredTables = [
    'routes',
    'clients',
    'payments',
    'expenses',
    'daily_base',
  ];

  /// Valida el archivo de respaldo y retorna un resultado detallado.
  ///
  /// Verifica:
  /// 1. Que el archivo exista y no esté vacío
  /// 2. Que sea un archivo SQLite válido (magic bytes)
  /// 3. Que contenga todas las tablas requeridas
  /// 4. Que las tablas tengan la estructura correcta
  static Future<BackupValidationResult> validate(String filePath) async {
    try {
      // 1. Verificar que el archivo existe
      final file = File(filePath);
      if (!await file.exists()) {
        return BackupValidationResult.invalid(
          'El archivo no existe',
        );
      }

      // 2. Verificar tamaño mínimo
      final fileSize = await file.length();
      if (fileSize < 100) {
        return BackupValidationResult.invalid(
          'El archivo está vacío o corrupto',
        );
      }

      // 3. Verificar magic bytes de SQLite
      // Los primeros 16 bytes de un SQLite válido son:
      // "SQLite format 3\000"
      final bytes = await file.openRead(0, 16).first;
      final header = String.fromCharCodes(bytes.take(15));
      if (header != 'SQLite format 3') {
        return BackupValidationResult.invalid(
          'El archivo no es un respaldo válido de Presto',
        );
      }

      // 4. Abrir la DB temporalmente para validar estructura
      Database? tempDb;
      try {
        tempDb = await openDatabase(filePath, readOnly: true);

        // 5. Verificar que existen todas las tablas requeridas
        final tables = await tempDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'",
        );
        final tableNames = tables
            .map((t) => t['name'] as String)
            .toList();

        for (final required in _requiredTables) {
          if (!tableNames.contains(required)) {
            return BackupValidationResult.invalid(
              'El archivo no es compatible con esta versión de Presto '
              '(tabla "$required" no encontrada)',
            );
          }
        }

        // 6. Verificar columnas críticas de cada tabla
        final columnsValidation = await _validateColumns(tempDb);
        if (!columnsValidation.isValid) {
          return columnsValidation;
        }

        // 7. Extraer información del respaldo
        final info = await _extractInfo(tempDb, fileSize);

        return BackupValidationResult.valid(info);
      } finally {
        await tempDb?.close();
      }
    } catch (e) {
      return BackupValidationResult.invalid(
        'No se pudo leer el archivo: ${e.toString()}',
      );
    }
  }

  /// Verifica que las columnas críticas existen en cada tabla.
  static Future<BackupValidationResult> _validateColumns(
    Database db,
  ) async {
    final requiredColumns = {
      'routes': ['id', 'name', 'created_at'],
      'clients': [
        'id', 'route_id', 'name', 'credit',
        'payment_type', 'payment_days', 'position',
        'is_active', 'created_at',
      ],
      'payments': [
        'id', 'client_id', 'route_id', 'amount',
        'status', 'payment_date', 'created_at',
      ],
      'expenses': [
        'id', 'route_id', 'description',
        'amount', 'expense_date', 'created_at',
      ],
      'daily_base': [
        'id', 'route_id', 'amount',
        'base_date', 'created_at',
      ],
    };

    for (final entry in requiredColumns.entries) {
      final table = entry.key;
      final columns = entry.value;

      final tableInfo = await db.rawQuery(
        'PRAGMA table_info($table)',
      );
      final existingColumns = tableInfo
          .map((c) => c['name'] as String)
          .toList();

      for (final column in columns) {
        if (!existingColumns.contains(column)) {
          return BackupValidationResult.invalid(
            'El archivo no es compatible: columna "$column" '
            'no encontrada en "$table"',
          );
        }
      }
    }

    return const BackupValidationResult(isValid: true);
  }

  /// Extrae información resumida del respaldo para mostrar al usuario.
  static Future<BackupInfo> _extractInfo(
    Database db,
    int fileSize,
  ) async {
    final routes = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM routes'),
    ) ?? 0;

    final clients = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM clients WHERE is_active = 1',
      ),
    ) ?? 0;

    final payments = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM payments'),
    ) ?? 0;

    final expenses = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM expenses'),
    ) ?? 0;

    final oldestResult = await db.rawQuery(
      'SELECT MIN(payment_date) as date FROM payments',
    );
    final newestResult = await db.rawQuery(
      'SELECT MAX(payment_date) as date FROM payments',
    );

    return BackupInfo(
      routeCount: routes,
      clientCount: clients,
      paymentCount: payments,
      expenseCount: expenses,
      oldestDate: oldestResult.first['date'] as String?,
      newestDate: newestResult.first['date'] as String?,
      fileSizeKb: (fileSize / 1024).round(),
    );
  }
}