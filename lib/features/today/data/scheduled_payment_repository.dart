import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../domain/scheduled_payment_model.dart';

/// Repositorio para gestionar cobros reagendados.
class ScheduledPaymentRepository {
  final _db = DatabaseHelper.instance;

  /// Retorna cobros reagendados para una fecha y ruta específica.
  Future<List<ScheduledPaymentModel>> getScheduledPaymentsForDate(
    String routeId,
    String date,
  ) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'scheduled_payments',
        where: 'route_id = ? AND scheduled_date = ?',
        whereArgs: [routeId, date],
      );
      return result
          .map((map) => ScheduledPaymentModel.fromMap(map))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener cobros reagendados: $e');
    }
  }

  /// Retorna el reagendamiento activo de un cliente si existe.
  Future<ScheduledPaymentModel?> getScheduledPaymentByClient(
    String clientId,
  ) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'scheduled_payments',
        where: 'client_id = ?',
        whereArgs: [clientId],
        limit: 1,
      );
      if (result.isEmpty) return null;
      return ScheduledPaymentModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Error al obtener reagendamiento: $e');
    }
  }

  /// Inserta un nuevo reagendamiento.
  Future<void> insertScheduledPayment(
    ScheduledPaymentModel scheduled,
  ) async {
    try {
      final db = await _db.database;
      final newScheduled = scheduled.copyWith(
        id: const Uuid().v4(),
        createdAt: DateTime.now().toIso8601String(),
      );
      await db.insert('scheduled_payments', newScheduled.toMap());
    } catch (e) {
      throw Exception('Error al insertar reagendamiento: $e');
    }
  }

  /// Elimina un reagendamiento por ID.
  Future<void> deleteScheduledPayment(String id) async {
    try {
      final db = await _db.database;
      await db.delete(
        'scheduled_payments',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Error al eliminar reagendamiento: $e');
    }
  }

  /// Elimina el reagendamiento activo de un cliente.
  Future<void> deleteScheduledPaymentByClient(String clientId) async {
    try {
      final db = await _db.database;
      await db.delete(
        'scheduled_payments',
        where: 'client_id = ?',
        whereArgs: [clientId],
      );
    } catch (e) {
      throw Exception('Error al eliminar reagendamiento del cliente: $e');
    }
  }
}