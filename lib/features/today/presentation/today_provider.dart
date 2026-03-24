import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/payment_repository.dart';
import '../domain/today_client.dart';
import '../domain/payment_model.dart';
import '../../clients/data/client_repository.dart';

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

  /// Registra un pago con tipo de método e imagen opcional.
  Future<void> registerPayment(
    TodayClient todayClient,
    double amount,
    String? note, {
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? imagePath,
  }) async {
    try {
      final dateStr = _formatDate(_selectedDate);
      final existing = await _paymentRepository.getPaymentByClientAndDate(
        todayClient.client.id,
        dateStr,
      );

      // Si había imagen anterior y se está reemplazando, eliminarla
      if (existing?.imagePath != null && existing!.imagePath != imagePath) {
        await _paymentRepository.deletePayment(existing.id);
      }

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
      } else {
        await _paymentRepository.insertPayment(payment);
      }

      await loadTodayClients(_currentRouteId, date: _selectedDate);
    } catch (e) {
      _errorMessage = 'No se pudo registrar el pago';
      notifyListeners();
      debugPrint('Error registrando pago: $e');
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
