import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../domain/daily_base_model.dart';

class DailyBaseRepository {
  final _db = DatabaseHelper.instance;

  Future<DailyBaseModel?> getBaseByDate(
    String routeId,
    String date,
  ) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'daily_base',
        where: 'route_id = ? AND base_date = ?',
        whereArgs: [routeId, date],
        limit: 1,
      );
      if (result.isEmpty) return null;
      return DailyBaseModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Error al obtener base: $e');
    }
  }

  Future<void> insertBase(DailyBaseModel base) async {
    try {
      final db = await _db.database;
      final newBase = base.copyWith(
        id: const Uuid().v4(),
        createdAt: DateTime.now().toIso8601String(),
      );
      await db.insert('daily_base', newBase.toMap());
    } catch (e) {
      throw Exception('Error al insertar base: $e');
    }
  }

  Future<void> updateBase(DailyBaseModel base) async {
    try {
      final db = await _db.database;
      await db.update(
        'daily_base',
        base.toMap(),
        where: 'id = ?',
        whereArgs: [base.id],
      );
    } catch (e) {
      throw Exception('Error al actualizar base: $e');
    }
  }
}