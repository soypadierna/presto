import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../domain/client_model.dart';

class ClientRepository {
  final _db = DatabaseHelper.instance;

  Future<List<ClientModel>> getClientsByRoute(String routeId) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'clients',
        where: 'route_id = ? AND is_active = 1',
        whereArgs: [routeId],
        orderBy: 'position ASC',
      );
      return result.map((map) => ClientModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener clientes: $e');
    }
  }

  Future<List<ClientModel>> getClientsForToday(
    String routeId,
    DateTime date,
  ) async {
    try {
      final allClients = await getClientsByRoute(routeId);
      return allClients
          .where((client) => client.isScheduledForDate(date))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener clientes de hoy: $e');
    }
  }

  Future<void> insertClient(ClientModel client) async {
    try {
      final db = await _db.database;
      final newClient = client.copyWith(
        id: const Uuid().v4(),
        createdAt: DateTime.now().toIso8601String(),
      );
      await db.insert('clients', newClient.toMap());
    } catch (e) {
      throw Exception('Error al insertar cliente: $e');
    }
  }

  Future<void> updateClient(ClientModel client) async {
    try {
      final db = await _db.database;
      await db.update(
        'clients',
        client.toMap(),
        where: 'id = ?',
        whereArgs: [client.id],
      );
    } catch (e) {
      throw Exception('Error al actualizar cliente: $e');
    }
  }

  Future<void> updateClientPosition(String id, int position) async {
    try {
      final db = await _db.database;
      await db.update(
        'clients',
        {'position': position},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Error al actualizar posición: $e');
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      final db = await _db.database;
      await db.update(
        'clients',
        {'is_active': 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Error al eliminar cliente: $e');
    }
  }
}