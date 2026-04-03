import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../domain/refinance_model.dart';

/// Repositorio para gestionar refinanciamientos.
class RefinanceRepository {
  final _db = DatabaseHelper.instance;

  /// Retorna refinanciamientos de un cliente ordenados por fecha desc.
  Future<List<RefinanceModel>> getRefinancesByClient(
    String clientId,
  ) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'refinances',
        where: 'client_id = ?',
        whereArgs: [clientId],
        orderBy: 'refinance_date DESC',
      );
      return result.map((map) => RefinanceModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener refinanciamientos: $e');
    }
  }

  /// Retorna refinanciamientos del día para una ruta.
  Future<List<RefinanceModel>> getRefinancesByDate(
    String routeId,
    String date,
  ) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'refinances',
        where: 'route_id = ? AND refinance_date = ?',
        whereArgs: [routeId, date],
        orderBy: 'created_at ASC',
      );
      return result.map((map) => RefinanceModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener refinanciamientos del día: $e');
    }
  }

  /// Inserta un nuevo refinanciamiento.
  Future<void> insertRefinance(RefinanceModel refinance) async {
    try {
      final db = await _db.database;
      final newRefinance = refinance.copyWith(
        id: const Uuid().v4(),
        createdAt: DateTime.now().toIso8601String(),
      );
      await db.insert('refinances', newRefinance.toMap());
    } catch (e) {
      throw Exception('Error al insertar refinanciamiento: $e');
    }
  }

  /// Elimina un refinanciamiento por ID.
  Future<void> deleteRefinance(String id) async {
    try {
      final db = await _db.database;
      await db.delete(
        'refinances',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Error al eliminar refinanciamiento: $e');
    }
  }
}