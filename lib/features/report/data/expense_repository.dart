import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../domain/expense_model.dart';

class ExpenseRepository {
  final _db = DatabaseHelper.instance;

  Future<List<ExpenseModel>> getExpensesByDate(
    String routeId,
    String date,
  ) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'expenses',
        where: 'route_id = ? AND expense_date = ?',
        whereArgs: [routeId, date],
        orderBy: 'created_at ASC',
      );
      return result.map((map) => ExpenseModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener gastos: $e');
    }
  }

  Future<void> insertExpense(ExpenseModel expense) async {
    try {
      final db = await _db.database;
      final newExpense = expense.copyWith(
        id: const Uuid().v4(),
        createdAt: DateTime.now().toIso8601String(),
      );
      await db.insert('expenses', newExpense.toMap());
    } catch (e) {
      throw Exception('Error al insertar gasto: $e');
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      final db = await _db.database;
      await db.update(
        'expenses',
        expense.toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );
    } catch (e) {
      throw Exception('Error al actualizar gasto: $e');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      final db = await _db.database;
      await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception('Error al eliminar gasto: $e');
    }
  }
}