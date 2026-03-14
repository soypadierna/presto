import 'package:uuid/uuid.dart';
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

  Future<void> deleteRoute(String id) async {
    try {
      final db = await _db.database;

      // Verificar si tiene clientes activos
      final clients = await db.query(
        'clients',
        where: 'route_id = ? AND is_active = 1',
        whereArgs: [id],
      );

      if (clients.isNotEmpty) {
        throw Exception(
          'No se puede eliminar: la ruta tiene ${clients.length} '
          'cliente(s) activo(s). Elimina los clientes primero.',
        );
      }

      await db.delete('routes', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      rethrow;
    }
  }
}
