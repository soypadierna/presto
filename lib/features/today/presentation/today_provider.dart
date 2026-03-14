import 'package:flutter/foundation.dart';
import '../data/payment_repository.dart';
import '../domain/today_client.dart';
import '../domain/payment_model.dart';
import '../../clients/data/client_repository.dart';
import 'package:uuid/uuid.dart';

class TodayProvider extends ChangeNotifier {
  final ClientRepository _clientRepository = ClientRepository();
  final PaymentRepository _paymentRepository = PaymentRepository();

  List<TodayClient> _todayClients = [];
  bool _isLoading = false;
  String _currentRouteId = '';
  DateTime _selectedDate = DateTime.now();

  List<TodayClient> get todayClients => _todayClients;
  bool get isLoading => _isLoading;
  String get currentRouteId => _currentRouteId;
  DateTime get selectedDate => _selectedDate;

  // Getters de resumen
  double get totalCollected => _todayClients
      .where((tc) => tc.isPaid)
      .fold(0, (sum, tc) => sum + (tc.payment?.amount ?? 0));

  int get paidCount => _todayClients.where((tc) => tc.isPaid).length;
  int get skippedCount => _todayClients.where((tc) => tc.isSkipped).length;
  int get pendingCount => _todayClients.where((tc) => tc.isPending).length;

  Future<void> loadTodayClients(String routeId, {DateTime? date}) async {
    _currentRouteId = routeId;
    _selectedDate = date ?? DateTime.now();
    _isLoading = true;
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

      // Corrección: usar where + firstOrNull en lugar de firstWhere con orElse
      _todayClients = clients.map((client) {
        final matchingPayments = payments.where((p) => p.clientId == client.id);
        final payment = matchingPayments.isNotEmpty
            ? matchingPayments.first
            : null;

        return TodayClient(client: client, payment: payment);
      }).toList();
    } catch (e) {
      debugPrint('Error cargando lista del día: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerPayment(
    TodayClient todayClient,
    double amount,
    String? note,
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
        amount: amount,
        status: PaymentStatus.paid,
        note: note,
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
      debugPrint('Error registrando no dio: $e');
    }
  }

  Future<void> undoPayment(TodayClient todayClient) async {
    try {
      if (todayClient.payment == null) return;
      await _paymentRepository.deletePayment(todayClient.payment!.id);
      await loadTodayClients(_currentRouteId, date: _selectedDate);
    } catch (e) {
      debugPrint('Error deshaciendo pago: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
