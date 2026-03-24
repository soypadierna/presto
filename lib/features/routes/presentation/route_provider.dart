import 'package:flutter/foundation.dart';
import '../data/route_repository.dart';
import '../domain/route_model.dart';

class RouteProvider extends ChangeNotifier {
  final RouteRepository _repository = RouteRepository();

  List<RouteModel> _routes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RouteModel> get routes => _routes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  RouteProvider() {
    loadRoutes();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadRoutes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _routes = await _repository.getAllRoutes();
    } catch (e) {
      _errorMessage = 'No se pudieron cargar las rutas';
      debugPrint('Error cargando rutas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRoute(String name) async {
    try {
      await _repository.insertRoute(name);
      await loadRoutes();
    } catch (e) {
      _errorMessage = 'No se pudo crear la ruta';
      notifyListeners();
      debugPrint('Error agregando ruta: $e');
    }
  }

  Future<void> updateRoute(RouteModel route) async {
    try {
      await _repository.updateRoute(route);
      await loadRoutes();
    } catch (e) {
      _errorMessage = 'No se pudo actualizar la ruta';
      notifyListeners();
      debugPrint('Error actualizando ruta: $e');
    }
  }

  /// Intenta eliminar la ruta sin forzar.
  /// Si tiene clientes retorna las estadísticas para que
  /// la UI muestre el dialog de confirmación.
  Future<bool> deleteRoute(String id) async {
    try {
      await _repository.deleteRoute(id, force: false);
      await loadRoutes();
      return true;
    } catch (e) {
      // No es un error real — tiene clientes, necesita confirmación
      debugPrint('Ruta tiene datos, requiere confirmación: $e');
      return false;
    }
  }

  /// Elimina la ruta y todos sus datos en cascada.
  Future<void> forceDeleteRoute(String id) async {
    try {
      await _repository.deleteRoute(id, force: true);
      await loadRoutes();
    } catch (e) {
      _errorMessage = 'No se pudo eliminar la ruta';
      notifyListeners();
      debugPrint('Error eliminando ruta: $e');
    }
  }

  /// Obtiene estadísticas de la ruta antes de eliminarla.
  Future<RouteDeleteStats> getRouteStats(String id) async {
    return await _repository.getRouteStats(id);
  }
}