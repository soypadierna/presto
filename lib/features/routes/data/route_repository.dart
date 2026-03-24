import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../domain/route_model.dart';

class RouteRepository {
  final _db = DatabaseHelper.instance;

  Future<List<RouteModel>> getAllRoutes() async {
    try {
      final db = await _db.database;
      final result = await db.query('routes', orderBy: 'created_at ASC');
      return result.map((map) => RouteModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener rutas: $e');
    }
  }

  Future<void> insertRoute(String name) async {
    try {
      final db = await _db.database;
      final route = RouteModel(
        id: const Uuid().v4(),
        name: name,
        createdAt: DateTime.now().toIso8601String(),
      );
      await db.insert('routes', route.toMap());
    } catch (e) {
      throw Exception('Error al insertar ruta: $e');
    }
  }

  Future<void> updateRoute(RouteModel route) async {
    try {
      final db = await _db.database;
      await db.update(
        'routes',
        route.toMap(),
        where: 'id = ?',
        whereArgs: [route.id],
      );
    } catch (e) {
      throw Exception('Error al actualizar ruta: $e');
    }
  }

  /// Elimina una ruta.
  ///
  /// Si [force] es false lanza excepción si tiene clientes activos.
  /// Si [force] es true elimina en cascada todos los datos relacionados
  /// usando una transacción SQLite para garantizar atomicidad.
  Future<void> deleteRoute(String id, {bool force = false}) async {
    try {
      final db = await _db.database;

      if (!force) {
        // Verificar si tiene clientes activos
        final clients = await db.query(
          'clients',
          where: 'route_id = ? AND is_active = 1',
          whereArgs: [id],
        );

        if (clients.isNotEmpty) {
          throw Exception(
            'No se puede eliminar: la ruta tiene ${clients.length} '
            'cliente(s) activo(s). Elimina los clientes primero '
            'o usa la opción "Eliminar todo".',
          );
        }

        await db.delete('routes', where: 'id = ?', whereArgs: [id]);
      } else {
        // Eliminación en cascada dentro de una transacción
        await db.transaction((txn) async {
          // 1. Eliminar pagos
          await txn.delete(
            'payments',
            where: 'route_id = ?',
            whereArgs: [id],
          );

          // 2. Eliminar gastos
          await txn.delete(
            'expenses',
            where: 'route_id = ?',
            whereArgs: [id],
          );

          // 3. Eliminar base diaria
          await txn.delete(
            'daily_base',
            where: 'route_id = ?',
            whereArgs: [id],
          );

          // 4. Eliminar clientes
          await txn.delete(
            'clients',
            where: 'route_id = ?',
            whereArgs: [id],
          );

          // 5. Eliminar la ruta
          await txn.delete(
            'routes',
            where: 'id = ?',
            whereArgs: [id],
          );
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Retorna estadísticas de una ruta antes de eliminarla.
  Future<RouteDeleteStats> getRouteStats(String id) async {
    try {
      final db = await _db.database;

      final clients = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM clients WHERE route_id = ?',
          [id],
        ),
      ) ?? 0;

      final payments = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM payments WHERE route_id = ?',
          [id],
        ),
      ) ?? 0;

      final expenses = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM expenses WHERE route_id = ?',
          [id],
        ),
      ) ?? 0;

      return RouteDeleteStats(
        clientCount: clients,
        paymentCount: payments,
        expenseCount: expenses,
      );
    } catch (e) {
      throw Exception('Error al obtener estadísticas de ruta: $e');
    }
  }
}

/// Estadísticas de una ruta para mostrar antes de eliminarla.
class RouteDeleteStats {
  final int clientCount;
  final int paymentCount;
  final int expenseCount;

  const RouteDeleteStats({
    required this.clientCount,
    required this.paymentCount,
    required this.expenseCount,
  });
}