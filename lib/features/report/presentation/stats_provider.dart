import 'package:flutter/foundation.dart';
import '../data/stats_repository.dart';
import '../domain/day_summary.dart';
import '../domain/month_summary.dart';

class StatsProvider extends ChangeNotifier {
  final StatsRepository _repository = StatsRepository();

  List<DaySummary> _recentDays = [];
  MonthSummary? _currentMonth;
  bool _isLoading = false;
  String _currentRouteId = '';

  List<DaySummary> get recentDays => _recentDays;
  MonthSummary? get currentMonth => _currentMonth;
  bool get isLoading => _isLoading;

  Future<void> loadStats(String routeId, {DateTime? date}) async {
    _currentRouteId = routeId;
    _isLoading = true;
    notifyListeners();

    try {
      final now = date ?? DateTime.now();

      // Cargar resumen del mes actual
      _currentMonth = await _repository.getMonthSummary(
        routeId,
        now.year,
        now.month,
      );

      // Cargar últimos 30 días trabajados
      final days = await _repository.getDaysWorked(routeId);
      final recent = days.take(30).toList();
      _recentDays = await Future.wait(
        recent.map((d) => _repository.getDaySummary(routeId, d)),
      );
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DaySummary> loadDaySummary(String routeId, String date) async {
    return await _repository.getDaySummary(routeId, date);
  }
}