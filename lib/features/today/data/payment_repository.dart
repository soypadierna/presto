import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../domain/payment_model.dart';
import '../../../core/utils/image_helper.dart';

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

  Future<PaymentModel?> getPaymentByClientAndDate(
    String clientId,
    String date,
  ) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'payments',
        where: 'client_id = ? AND payment_date = ?',
        whereArgs: [clientId, date],
        limit: 1,
      );
      if (result.isEmpty) return null;
      return PaymentModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Error al obtener pago: $e');
    }
  }

  Future<List<PaymentModel>> getPaymentsByClient(String clientId) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'payments',
        where: 'client_id = ?',
        whereArgs: [clientId],
        orderBy: 'payment_date DESC',
      );
      return result.map((map) => PaymentModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener historial de pagos: $e');
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

  /// Elimina el pago y su imagen asociada si existe.
  Future<void> deletePayment(String id) async {
    try {
      final db = await _db.database;

      // Obtener imagen antes de eliminar
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
}