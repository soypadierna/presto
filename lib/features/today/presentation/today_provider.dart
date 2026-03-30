import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/payment_repository.dart';
import '../domain/today_client.dart';
import '../domain/payment_model.dart';
import '../../clients/data/client_repository.dart';
import '../../clients/domain/client_model.dart';

class TodayProvider extends ChangeNotifier {
  final ClientRepository _clientRepository = ClientRepository();
  final PaymentRepository _paymentRepository = PaymentRepository();

  List<TodayClient> _todayClients = [];
  bool _isLoading = false;
  String _currentRouteId = '';
  DateTime _selectedDate = DateTime.now();
  String? _errorMessage;

  List<TodayClient> get todayClients => _todayClients;
  bool get isLoading => _isLoading;
  String get currentRouteId => _currentRouteId;
  DateTime get selectedDate => _selectedDate;
  String? get errorMessage => _errorMessage;

  double get totalCollected => _todayClients
      .where((tc) => tc.isPaid)
      .fold(0, (sum, tc) => sum + (tc.payment?.amount ?? 0));

  int get paidCount => _todayClients.where((tc) => tc.isPaid).length;
  int get skippedCount => _todayClients.where((tc) => tc.isSkipped).length;
  int get pendingCount => _todayClients.where((tc) => tc.isPending).length;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// IDs de clientes que ya están en la lista del día
  Set<String> get todayClientIds =>
      _todayClients.map((tc) => tc.client.id).toSet();

  /// Retorna clientes activos que NO están en la lista del día
  Future<List<ClientModel>> getClientsNotInList(String routeId) async {
    try {
      final allClients = await _clientRepository.getClientsByRoute(routeId);
      // Usar _todayClients actualizado en memoria
      final existingIds = _todayClients.map((tc) => tc.client.id).toSet();
      return allClients.where((c) => !existingIds.contains(c.id)).toList();
    } catch (e) {
      debugPrint('Error obteniendo clientes fuera de lista: $e');
      return [];
    }
  }

  Future<void> loadTodayClients(String routeId, {DateTime? date}) async {
    _currentRouteId = routeId;
    _selectedDate = date ?? DateTime.now();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final clients = await _clientRepository.getClientsForToday(
        routeId,
        _selectedDate,
      );

      final dateStr = _formatDate(_selectedDate);
      final payments = await _paymentRepository.getPaymentsByDate(
        routeId,
        dateStr,
      );

      _todayClients = clients.map((client) {
        final matchingPayments = payments.where((p) => p.clientId == client.id);
        final payment =
            matchingPayments.isNotEmpty ? matchingPayments.first : null;
        return TodayClient(client: client, payment: payment);
      }).toList();
    } catch (e) {
      _errorMessage = 'No se pudo cargar la lista del día';
      debugPrint('Error cargando lista del día: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registra un pago. Si el cliente no está en la lista del día
  /// lo agrega automáticamente después de registrar.
  Future<void> registerPayment(
    TodayClient todayClient,
    double amount,
    String? note, {
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? imagePath,
  }) async {
    try {
      debugPrint('=== registerPayment iniciado ===');
      debugPrint('Cliente: ${todayClient.client.name}');
      debugPrint('Monto: $amount');
      debugPrint('Clientes en lista: ${_todayClients.length}');

      final dateStr = _formatDate(_selectedDate);
      final existing = await _paymentRepository.getPaymentByClientAndDate(
        todayClient.client.id,
        dateStr,
      );

      debugPrint('Pago existente: ${existing?.id}');

      final payment = PaymentModel(
        id: existing?.id ?? const Uuid().v4(),
        clientId: todayClient.client.id,
        routeId: _currentRouteId,
        amount: amount,
        status: PaymentStatus.paid,
        note: note,
        paymentDate: dateStr,
        createdAt: existing?.createdAt ?? DateTime.now().toIso8601String(),
        paymentMethod: paymentMethod,
        imagePath: imagePath,
      );

      if (existing != null) {
        await _paymentRepository.updatePayment(payment);
        debugPrint('Pago actualizado en DB');
      } else {
        await _paymentRepository.insertPayment(payment);
        debugPrint('Pago insertado en DB');
      }

      final clientAlreadyInList = _todayClients.any(
        (tc) => tc.client.id == todayClient.client.id,
      );

      debugPrint('Cliente ya en lista: $clientAlreadyInList');

      if (clientAlreadyInList) {
        _todayClients = _todayClients.map((tc) {
          if (tc.client.id == todayClient.client.id) {
            return tc.copyWith(payment: payment);
          }
          return tc;
        }).toList();
      } else {
        _todayClients = [
          ..._todayClients,
          TodayClient(
            client: todayClient.client,
            payment: payment,
          ),
        ];
      }

      debugPrint('Clientes en lista después: ${_todayClients.length}');
      debugPrint('Total cobrado: $totalCollected');
      notifyListeners();
      debugPrint('notifyListeners llamado');
    } catch (e) {
      debugPrint('ERROR en registerPayment: $e');
      _errorMessage = 'No se pudo registrar el pago';
      notifyListeners();
    }
  }

  Future<void> registerSkipped(
    TodayClient todayClient,
    String? justification,
  ) async {
    try {
      final dateStr = _formatDate(_selectedDate);
      final existing = await _paymentRepository.getPaymentByClientAndDate(
        todayClient.client.id,
        dateStr,
      );

      final payment = PaymentModel(
        id: existing?.id ?? const Uuid().v4(),
        clientId: todayClient.client.id,
        routeId: _currentRouteId,
        amount: 0,
        status: PaymentStatus.skipped,
        note: justification,
        paymentDate: dateStr,
        createdAt: existing?.createdAt ?? DateTime.now().toIso8601String(),
      );

      if (existing != null) {
        await _paymentRepository.updatePayment(payment);
      } else {
        await _paymentRepository.insertPayment(payment);
      }

      await loadTodayClients(_currentRouteId, date: _selectedDate);
    } catch (e) {
      _errorMessage = 'No se pudo registrar el estado';
      notifyListeners();
      debugPrint('Error registrando no dio: $e');
    }
  }

  Future<void> undoPayment(TodayClient todayClient) async {
    try {
      if (todayClient.payment == null) return;
      await _paymentRepository.deletePayment(todayClient.payment!.id);
      await loadTodayClients(_currentRouteId, date: _selectedDate);
    } catch (e) {
      _errorMessage = 'No se pudo deshacer el registro';
      notifyListeners();
      debugPrint('Error deshaciendo pago: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
