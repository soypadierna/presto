import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/payment_repository.dart';
import '../data/scheduled_payment_repository.dart';
import '../data/refinance_repository.dart';
import '../domain/today_client.dart';
import '../domain/payment_model.dart';
import '../domain/scheduled_payment_model.dart';
import '../domain/refinance_model.dart';
import '../../clients/data/client_repository.dart';
import '../../clients/domain/client_model.dart';
import '../../report/data/daily_base_repository.dart';
import '../../report/domain/daily_base_model.dart';

class TodayProvider extends ChangeNotifier {
  final ClientRepository _clientRepository = ClientRepository();
  final PaymentRepository _paymentRepository = PaymentRepository();
  final ScheduledPaymentRepository _scheduledRepository =
      ScheduledPaymentRepository();
  final RefinanceRepository _refinanceRepository = RefinanceRepository();
  final DailyBaseRepository _baseRepository = DailyBaseRepository();

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

  /// Total general cobrado
  double get totalCollected => _todayClients.fold(
        0,
        (sum, tc) => sum + tc.totalPaid,
      );

  /// Total en efectivo
  double get totalCash => _todayClients.fold(
        0,
        (sum, tc) => sum + tc.cashTotal,
      );

  /// Total en transferencia
  double get totalTransfer => _todayClients.fold(
        0,
        (sum, tc) => sum + tc.transferTotal,
      );

  int get paidCount => _todayClients.where((tc) => tc.isPaid).length;
  int get skippedCount => _todayClients.where((tc) => tc.isSkipped).length;
  int get pendingCount => _todayClients.where((tc) => tc.isPending).length;
  int get refinancedCount =>
      _todayClients.where((tc) => tc.isRefinanced).length;

  Set<String> get todayClientIds =>
      _todayClients.map((tc) => tc.client.id).toSet();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String formatDatePublic(DateTime date) => _formatDate(date);

  Future<void> loadTodayClients(
    String routeId, {
    DateTime? date,
  }) async {
    _currentRouteId = routeId;
    _selectedDate = date ?? DateTime.now();
    _isLoading = true;
    _errorMessage = null;
    _todayClients = [];
    notifyListeners();

    try {
      final dateStr = _formatDate(_selectedDate);

      final clients = await _clientRepository.getClientsForToday(
        routeId,
        _selectedDate,
      );

      final allPayments = await _paymentRepository.getPaymentsByDate(
        routeId,
        dateStr,
      );

      final scheduled = await _scheduledRepository
          .getScheduledPaymentsForDate(routeId, dateStr);

      final refinances = await _refinanceRepository.getRefinancesByDate(
        routeId,
        dateStr,
      );

      // Agrupar pagos por cliente
      final paymentsByClient = <String, List<PaymentModel>>{};
      for (final p in allPayments) {
        paymentsByClient.putIfAbsent(p.clientId, () => []).add(p);
      }

      _todayClients = clients.map((client) {
        final clientPayments = paymentsByClient[client.id] ?? [];
        final scheduledPayment =
            scheduled.where((s) => s.clientId == client.id).firstOrNull;
        final refinance =
            refinances.where((r) => r.clientId == client.id).firstOrNull;

        return TodayClient(
          client: client,
          payments: clientPayments,
          scheduledPayment: scheduledPayment,
          refinance: refinance,
        );
      }).toList();

      // Agregar clientes reagendados fuera del calendario
      final calendarIds = clients.map((c) => c.id).toSet();
      final extraScheduled =
          scheduled.where((s) => !calendarIds.contains(s.clientId));

      for (final sched in extraScheduled) {
        final allClients =
            await _clientRepository.getClientsByRoute(routeId);
        final client =
            allClients.where((c) => c.id == sched.clientId).firstOrNull;
        if (client == null) continue;

        final clientPayments = paymentsByClient[client.id] ?? [];
        final refinance =
            refinances.where((r) => r.clientId == client.id).firstOrNull;

        _todayClients.add(TodayClient(
          client: client,
          payments: clientPayments,
          scheduledPayment: sched,
          refinance: refinance,
        ));
      }
    } catch (e) {
      _errorMessage = 'No se pudo cargar la lista del día';
      debugPrint('Error cargando lista del día: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registra un nuevo pago — siempre inserta, permite múltiples pagos.
  Future<void> registerPayment(
    TodayClient todayClient,
    double amount,
    String? note, {
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? imagePath,
  }) async {
    try {
      final dateStr = _formatDate(_selectedDate);

      final payment = PaymentModel(
        id: const Uuid().v4(),
        clientId: todayClient.client.id,
        routeId: _currentRouteId,
        amount: amount,
        status: PaymentStatus.paid,
        note: note,
        paymentDate: dateStr,
        createdAt: DateTime.now().toIso8601String(),
        paymentMethod: paymentMethod,
        imagePath: imagePath,
      );

      await _paymentRepository.insertPayment(payment);

      // Eliminar reagendamiento si existe
      if (todayClient.scheduledPayment != null) {
        await _scheduledRepository.deleteScheduledPaymentByClient(
          todayClient.client.id,
        );
      }

      // Actualizar en memoria
      final clientAlreadyInList = _todayClients.any(
        (tc) => tc.client.id == todayClient.client.id,
      );

      if (clientAlreadyInList) {
        _todayClients = _todayClients.map((tc) {
          if (tc.client.id == todayClient.client.id) {
            return tc.copyWith(
              payments: [...tc.payments, payment],
              clearScheduled: todayClient.scheduledPayment != null,
            );
          }
          return tc;
        }).toList();
      } else {
        _todayClients = [
          ..._todayClients,
          TodayClient(
            client: todayClient.client,
            payments: [payment],
          ),
        ];
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'No se pudo registrar el pago';
      notifyListeners();
      debugPrint('Error registrando pago: $e');
    }
  }

  /// Registra "no dio" — solo si no hay pagos previos.
  Future<void> registerSkipped(
    TodayClient todayClient,
    String? justification,
  ) async {
    try {
      // No permitir "no dio" si ya hay pagos
      if (todayClient.isPaid) {
        _errorMessage =
            'No se puede registrar "no dio" si el cliente ya pagó';
        notifyListeners();
        return;
      }

      final dateStr = _formatDate(_selectedDate);

      final payment = PaymentModel(
        id: const Uuid().v4(),
        clientId: todayClient.client.id,
        routeId: _currentRouteId,
        amount: 0,
        status: PaymentStatus.skipped,
        note: justification,
        paymentDate: dateStr,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _paymentRepository.insertPayment(payment);

      _todayClients = _todayClients.map((tc) {
        if (tc.client.id == todayClient.client.id) {
          return tc.copyWith(payments: [payment]);
        }
        return tc;
      }).toList();

      notifyListeners();
    } catch (e) {
      _errorMessage = 'No se pudo registrar el estado';
      notifyListeners();
      debugPrint('Error registrando no dio: $e');
    }
  }

  Future<void> reschedulePayment(
    TodayClient todayClient,
    DateTime scheduledDate,
    String? note,
  ) async {
    try {
      await _scheduledRepository.deleteScheduledPaymentByClient(
        todayClient.client.id,
      );

      final scheduled = ScheduledPaymentModel(
        id: const Uuid().v4(),
        clientId: todayClient.client.id,
        routeId: _currentRouteId,
        scheduledDate: _formatDate(scheduledDate),
        note: note,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _scheduledRepository.insertScheduledPayment(scheduled);

      _todayClients = _todayClients.map((tc) {
        if (tc.client.id == todayClient.client.id) {
          return tc.copyWith(scheduledPayment: scheduled);
        }
        return tc;
      }).toList();

      notifyListeners();
    } catch (e) {
      _errorMessage = 'No se pudo reagendar el cobro';
      notifyListeners();
      debugPrint('Error reagendando: $e');
    }
  }

  Future<void> refinanceClient(
    TodayClient todayClient,
    RefinanceModel refinance, {
    Map<String, dynamic>? newPaymentDays,
  }) async {
    try {
      await _refinanceRepository.insertRefinance(refinance);

      if (refinance.amount > 0) {
        final dateStr = _formatDate(_selectedDate);
        final existingBase =
            await _baseRepository.getBaseByDate(_currentRouteId, dateStr);

        if (existingBase != null) {
          await _baseRepository.updateBase(
            existingBase.copyWith(
              amount: existingBase.amount - refinance.amount,
            ),
          );
        } else {
          await _baseRepository.insertBase(
            DailyBaseModel(
              id: const Uuid().v4(),
              routeId: _currentRouteId,
              amount: -refinance.amount,
              baseDate: dateStr,
              createdAt: DateTime.now().toIso8601String(),
            ),
          );
        }
      }

      if (newPaymentDays != null) {
        await _clientRepository.updateClient(
          todayClient.client.copyWith(paymentDays: newPaymentDays),
        );
      }

      _todayClients = _todayClients.map((tc) {
        if (tc.client.id == todayClient.client.id) {
          return tc.copyWith(refinance: refinance);
        }
        return tc;
      }).toList();

      notifyListeners();
    } catch (e) {
      _errorMessage = 'No se pudo registrar el refinanciamiento';
      notifyListeners();
      debugPrint('Error refinanciando: $e');
    }
  }

  Future<void> undoPayment(TodayClient todayClient) async {
    try {
      // Eliminar el último pago
      final lastPayment = todayClient.lastPayment;
      if (lastPayment == null) return;

      await _paymentRepository.deletePayment(lastPayment.id);

      final updatedPayments = todayClient.payments
          .where((p) => p.id != lastPayment.id)
          .toList();

      _todayClients = _todayClients.map((tc) {
        if (tc.client.id == todayClient.client.id) {
          return tc.copyWith(payments: updatedPayments);
        }
        return tc;
      }).toList();

      notifyListeners();
    } catch (e) {
      _errorMessage = 'No se pudo deshacer el registro';
      notifyListeners();
      debugPrint('Error deshaciendo pago: $e');
    }
  }

  Future<List<ClientModel>> getClientsNotInList(String routeId) async {
    try {
      final allClients =
          await _clientRepository.getClientsByRoute(routeId);
      final existingIds =
          _todayClients.map((tc) => tc.client.id).toSet();
      return allClients
          .where((c) => !existingIds.contains(c.id))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo clientes fuera de lista: $e');
      return [];
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}