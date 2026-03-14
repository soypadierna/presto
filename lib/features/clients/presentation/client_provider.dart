import 'package:flutter/foundation.dart';
import '../data/client_repository.dart';
import '../domain/client_model.dart';

class ClientProvider extends ChangeNotifier {
  final ClientRepository _repository = ClientRepository();

  List<ClientModel> _clients = [];
  bool _isLoading = false;
  String _currentRouteId = '';

  List<ClientModel> get clients => _clients;
  bool get isLoading => _isLoading;
  String get currentRouteId => _currentRouteId;

  Future<void> loadClients(String routeId) async {
    _currentRouteId = routeId;
    _isLoading = true;
    notifyListeners();

    try {
      _clients = await _repository.getClientsByRoute(routeId);
    } catch (e) {
      debugPrint('Error cargando clientes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addClient(ClientModel client) async {
    try {
      // Asignar posición al final de la lista
      final position = _clients.length;
      await _repository.insertClient(client.copyWith(position: position));
      await loadClients(_currentRouteId);
    } catch (e) {
      debugPrint('Error agregando cliente: $e');
    }
  }

  Future<void> updateClient(ClientModel client) async {
    try {
      await _repository.updateClient(client);
      await loadClients(_currentRouteId);
    } catch (e) {
      debugPrint('Error actualizando cliente: $e');
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      await _repository.deleteClient(id);
      await loadClients(_currentRouteId);
    } catch (e) {
      debugPrint('Error eliminando cliente: $e');
    }
  }

  Future<void> reorderClients(int oldIndex, int newIndex) async {
    try {
      // Ajustar índice para ReorderableListView
      if (newIndex > oldIndex) newIndex--;

      final client = _clients.removeAt(oldIndex);
      _clients.insert(newIndex, client);
      notifyListeners();

      // Actualizar posiciones en la base de datos
      for (int i = 0; i < _clients.length; i++) {
        await _repository.updateClientPosition(_clients[i].id, i);
      }
    } catch (e) {
      debugPrint('Error reordenando clientes: $e');
    }
  }
}