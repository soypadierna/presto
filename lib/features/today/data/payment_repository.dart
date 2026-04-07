import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../domain/payment_model.dart';
import '../../../core/utils/image_helper.dart';
import '../../clients/domain/client_model.dart';

class PaymentRepository {
  final _db = DatabaseHelper.instance;

  Future<List<PaymentModel>> getPaymentsByDate(
    String routeId,
    String date,
  ) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'payments',
        where: 'route_id = ? AND payment_date = ?',
        whereArgs: [routeId, date],
        orderBy: 'created_at ASC',
      );
      return result.map((map) => PaymentModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener pagos: $e');
    }
  }

  /// Retorna todos los pagos de un cliente en una fecha específica.
  Future<List<PaymentModel>> getPaymentsByClientAndDate(
    String clientId,
    String date,
  ) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'payments',
        where: 'client_id = ? AND payment_date = ?',
        whereArgs: [clientId, date],
        orderBy: 'created_at ASC',
      );
      return result.map((map) => PaymentModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener pagos del cliente: $e');
    }
  }

  /// Retorna el primer pago de un cliente en una fecha — para compatibilidad.
  Future<PaymentModel?> getPaymentByClientAndDate(
    String clientId,
    String date,
  ) async {
    final payments = await getPaymentsByClientAndDate(clientId, date);
    return payments.isNotEmpty ? payments.first : null;
  }

  Future<List<PaymentModel>> getPaymentsByClient(
    String clientId,
  ) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'payments',
        where: 'client_id = ?',
        whereArgs: [clientId],
        orderBy: 'payment_date DESC, created_at DESC',
      );
      return result.map((map) => PaymentModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener historial: $e');
    }
  }

  Future<void> insertPayment(PaymentModel payment) async {
    try {
      final db = await _db.database;
      final newPayment = payment.copyWith(
        id: const Uuid().v4(),
        createdAt: DateTime.now().toIso8601String(),
      );
      await db.insert('payments', newPayment.toMap());
    } catch (e) {
      throw Exception('Error al insertar pago: $e');
    }
  }

  Future<void> updatePayment(PaymentModel payment) async {
    try {
      final db = await _db.database;
      await db.update(
        'payments',
        payment.toMap(),
        where: 'id = ?',
        whereArgs: [payment.id],
      );
    } catch (e) {
      throw Exception('Error al actualizar pago: $e');
    }
  }

  Future<void> deletePayment(String id) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'payments',
        columns: ['image_path'],
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isNotEmpty) {
        final imagePath = result.first['image_path'] as String?;
        if (imagePath != null) {
          await ImageHelper.deleteImage(imagePath);
        }
      }
      await db.delete('payments', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception('Error al eliminar pago: $e');
    }
  }

  Future<List<ClientModel>> getClientsWithoutPayment(
    String routeId,
    String date,
  ) async {
    try {
      final db = await _db.database;
      final result = await db.rawQuery('''
        SELECT c.* FROM clients c
        WHERE c.route_id = ?
          AND c.is_active = 1
          AND c.id NOT IN (
            SELECT p.client_id FROM payments p
            WHERE p.route_id = ? AND p.payment_date = ?
          )
        ORDER BY c.position ASC
      ''', [routeId, routeId, date]);
      return result.map((map) => ClientModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener clientes sin pago: $e');
    }
  }
}