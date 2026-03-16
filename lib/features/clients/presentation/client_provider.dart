import 'package:flutter/foundation.dart';
import '../data/client_repository.dart';
import '../domain/client_model.dart';

class ClientProvider extends ChangeNotifier {
  final ClientRepository _repository = ClientRepository();

  List<ClientModel> _clients = [];
  bool _isLoading = false;
  String _currentRouteId = '';
  String? _errorMessage;
  VoidCallback? onClientsChanged;

  List<ClientModel> get clients => _clients;
  bool get isLoading => _isLoading;
  String get currentRouteId => _currentRouteId;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadClients(String routeId) async {
    _currentRouteId = routeId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _clients = await _repository.getClientsByRoute(routeId);
    } catch (e) {
      _errorMessage = 'No se pudieron cargar los clientes';
      debugPrint('Error cargando clientes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addClient(ClientModel client) async {
    try {
      final position = _clients.length;
      await _repository.insertClient(client.copyWith(position: position));
      await loadClients(_currentRouteId);
      onClientsChanged?.call();
    } catch (e) {
      _errorMessage = 'No se pudo crear el cliente';
      notifyListeners();
      debugPrint('Error agregando cliente: $e');
    }
  }

  Future<void> updateClient(ClientModel client) async {
    try {
      await _repository.updateClient(client);
      await loadClients(_currentRouteId);
      onClientsChanged?.call();
    } catch (e) {
      _errorMessage = 'No se pudo actualizar el cliente';
      notifyListeners();
      debugPrint('Error actualizando cliente: $e');
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      await _repository.deleteClient(id);
      await loadClients(_currentRouteId);
      onClientsChanged?.call();
    } catch (e) {
      _errorMessage = 'No se pudo eliminar el cliente';
      notifyListeners();
      debugPrint('Error eliminando cliente: $e');
    }
  }

  Future<void> reorderClients(int oldIndex, int newIndex) async {
    try {
      if (newIndex > oldIndex) newIndex--;
      final client = _clients.removeAt(oldIndex);
      _clients.insert(newIndex, client);
      notifyListeners();

      for (int i = 0; i < _clients.length; i++) {
        await _repository.updateClientPosition(_clients[i].id, i);
      }
    } catch (e) {
      _errorMessage = 'No se pudo reordenar los clientes';
      notifyListeners();
      debugPrint('Error reordenando clientes: $e');
    }
  }
}