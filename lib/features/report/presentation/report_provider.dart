import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/expense_repository.dart';
import '../data/daily_base_repository.dart';
import '../domain/expense_model.dart';
import '../domain/daily_base_model.dart';

class ReportProvider extends ChangeNotifier {
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final DailyBaseRepository _baseRepository = DailyBaseRepository();

  List<ExpenseModel> _expenses = [];
  DailyBaseModel? _dailyBase;
  bool _isLoading = false;
  String _currentRouteId = '';
  DateTime _selectedDate = DateTime.now();
  String? _errorMessage;

  List<ExpenseModel> get expenses => _expenses;
  DailyBaseModel? get dailyBase => _dailyBase;
  bool get isLoading => _isLoading;
  String get currentRouteId => _currentRouteId;
  DateTime get selectedDate => _selectedDate;
  String? get errorMessage => _errorMessage;

  double get totalExpenses =>
      _expenses.fold(0, (sum, e) => sum + e.amount);
  double get baseAmount => _dailyBase?.amount ?? 0;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadReport(String routeId, {DateTime? date}) async {
    _currentRouteId = routeId;
    _selectedDate = date ?? DateTime.now();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dateStr = _formatDate(_selectedDate);
      _expenses = await _expenseRepository.getExpensesByDate(
        routeId,
        dateStr,
      );
      _dailyBase = await _baseRepository.getBaseByDate(routeId, dateStr);
    } catch (e) {
      _errorMessage = 'No se pudo cargar el informe';
      debugPrint('Error cargando reporte: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(String description, double amount) async {
    try {
      final expense = ExpenseModel(
        id: const Uuid().v4(),
        routeId: _currentRouteId,
        description: description,
        amount: amount,
        expenseDate: _formatDate(_selectedDate),
        createdAt: DateTime.now().toIso8601String(),
      );
      await _expenseRepository.insertExpense(expense);
      await loadReport(_currentRouteId, date: _selectedDate);
    } catch (e) {
      _errorMessage = 'No se pudo agregar el gasto';
      notifyListeners();
      debugPrint('Error agregando gasto: $e');
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await _expenseRepository.updateExpense(expense);
      await loadReport(_currentRouteId, date: _selectedDate);
    } catch (e) {
      _errorMessage = 'No se pudo actualizar el gasto';
      notifyListeners();
      debugPrint('Error actualizando gasto: $e');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _expenseRepository.deleteExpense(id);
      await loadReport(_currentRouteId, date: _selectedDate);
    } catch (e) {
      _errorMessage = 'No se pudo eliminar el gasto';
      notifyListeners();
      debugPrint('Error eliminando gasto: $e');
    }
  }

  Future<void> saveBase(double amount) async {
    try {
      final dateStr = _formatDate(_selectedDate);
      if (_dailyBase != null) {
        await _baseRepository.updateBase(
          _dailyBase!.copyWith(amount: amount),
        );
      } else {
        final base = DailyBaseModel(
          id: const Uuid().v4(),
          routeId: _currentRouteId,
          amount: amount,
          baseDate: dateStr,
          createdAt: DateTime.now().toIso8601String(),
        );
        await _baseRepository.insertBase(base);
      }
      await loadReport(_currentRouteId, date: _selectedDate);
    } catch (e) {
      _errorMessage = 'No se pudo guardar la base';
      notifyListeners();
      debugPrint('Error guardando base: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}