import 'package:flutter/foundation.dart';
import 'package:presto/features/report/domain/daily_base_model.dart';
import 'package:presto/features/today/domain/refinance_model.dart';
import 'package:uuid/uuid.dart';
import '../data/payment_repository.dart';
import '../data/scheduled_payment_repository.dart';
import '../domain/today_client.dart';
import '../domain/payment_model.dart';
import '../domain/scheduled_payment_model.dart';
import '../../clients/data/client_repository.dart';
import '../../clients/domain/client_model.dart';
import '../data/refinance_repository.dart';
import '../../report/data/daily_base_repository.dart';

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

  /// Cantidad de clientes refinanciados hoy
  int get refinancedCount =>
      _todayClients.where((tc) => tc.isRefinanced).length;

  /// Expone el formateo de fecha para uso externo
  String formatDatePublic(DateTime date) => _formatDate(date);

  double get totalCollected => _todayClients
      .where((tc) => tc.isPaid)
      .fold(0, (sum, tc) => sum + (tc.payment?.amount ?? 0));

  int get paidCount => _todayClients.where((tc) => tc.isPaid).length;
  int get skippedCount => _todayClients.where((tc) => tc.isSkipped).length;
  int get pendingCount => _todayClients.where((tc) => tc.isPending).length;

  /// IDs de clientes ya en la lista del día
  Set<String> get todayClientIds =>
      _todayClients.map((tc) => tc.client.id).toSet();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadTodayClients(String routeId, {DateTime? date}) async {
    _currentRouteId = routeId;
    _selectedDate = date ?? DateTime.now();
    _isLoading = true;
    _errorMessage = null;

    // Limpiar lista inmediatamente para no mostrar datos del día anterior
    _todayClients = [];
    notifyListeners();

    try {
      final dateStr = _formatDate(_selectedDate);

      // 1. Clientes del calendario
      final clients = await _clientRepository.getClientsForToday(
        routeId,
        _selectedDate,
      );

      // 2. Pagos del día
      final payments = await _paymentRepository.getPaymentsByDate(
        routeId,
        dateStr,
      );

      // 3. Cobros reagendados para hoy
      final scheduled = await _scheduledRepository.getScheduledPaymentsForDate(
          routeId, dateStr);

      // 4. Combinar clientes del calendario con sus pagos
      _todayClients = clients.map((client) {
        final matchingPayments = payments.where((p) => p.clientId == client.id);
        final payment =
            matchingPayments.isNotEmpty ? matchingPayments.first : null;
        final scheduledPayment =
            scheduled.where((s) => s.clientId == client.id).firstOrNull;

        return TodayClient(
          client: client,
          payment: payment,
          scheduledPayment: scheduledPayment,
        );
      }).toList();

      // 5. Agregar clientes reagendados fuera del calendario
      final calendarIds = clients.map((c) => c.id).toSet();
      final extraScheduled =
          scheduled.where((s) => !calendarIds.contains(s.clientId));

      for (final sched in extraScheduled) {
        final allClients = await _clientRepository.getClientsByRoute(routeId);
        final client =
            allClients.where((c) => c.id == sched.clientId).firstOrNull;
        if (client == null) continue;

        final matchingPayments = payments.where((p) => p.clientId == client.id);
        final payment =
            matchingPayments.isNotEmpty ? matchingPayments.first : null;

        _todayClients.add(TodayClient(
          client: client,
          payment: payment,
          scheduledPayment: sched,
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

      // Eliminar reagendamiento si existe
      if (todayClient.scheduledPayment != null) {
        await _scheduledRepository.deleteScheduledPaymentByClient(
          todayClient.client.id,
        );
      }

      // Actualizar lista en memoria
      final clientAlreadyInList = _todayClients.any(
        (tc) => tc.client.id == todayClient.client.id,
      );

      if (clientAlreadyInList) {
        _todayClients = _todayClients.map((tc) {
          if (tc.client.id == todayClient.client.id) {
            return tc.copyWith(
              payment: payment,
              clearScheduled: true,
            );
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

      notifyListeners();
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

      _todayClients = _todayClients.map((tc) {
        if (tc.client.id == todayClient.client.id) {
          return tc.copyWith(payment: payment);
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

  /// Reagenda el cobro de un cliente para una fecha futura.
  Future<void> reschedulePayment(
    TodayClient todayClient,
    DateTime scheduledDate,
    String? note,
  ) async {
    try {
      // Eliminar reagendamiento anterior si existe
      await _scheduledRepository.deleteScheduledPaymentByClient(
        todayClient.client.id,
      );

      // Crear nuevo reagendamiento
      final scheduled = ScheduledPaymentModel(
        id: const Uuid().v4(),
        clientId: todayClient.client.id,
        routeId: _currentRouteId,
        scheduledDate: _formatDate(scheduledDate),
        note: note,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _scheduledRepository.insertScheduledPayment(scheduled);

      // Actualizar en memoria
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
      debugPrint('Error reagendando cobro: $e');
    }
  }

  Future<void> undoPayment(TodayClient todayClient) async {
    try {
      if (todayClient.payment == null) return;
      await _paymentRepository.deletePayment(todayClient.payment!.id);

      _todayClients = _todayClients.map((tc) {
        if (tc.client.id == todayClient.client.id) {
          return tc.copyWith(clearPayment: true);
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

  /// Retorna clientes activos que NO están en la lista del día.
  Future<List<ClientModel>> getClientsNotInList(String routeId) async {
    try {
      final allClients = await _clientRepository.getClientsByRoute(routeId);
      final existingIds = _todayClients.map((tc) => tc.client.id).toSet();
      return allClients.where((c) => !existingIds.contains(c.id)).toList();
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

  /// Registra un refinanciamiento para un cliente.
  /// Si hay monto > 0 lo descuenta de la base del día.
  /// Si es "Dar tiempo" actualiza los días de pago del cliente.
  Future<void> refinanceClient(
    TodayClient todayClient,
    RefinanceModel refinance, {
    Map<String, dynamic>? newPaymentDays,
  }) async {
    try {
      // 1. Guardar el refinanciamiento
      await _refinanceRepository.insertRefinance(refinance);

      // 2. Si hay monto descontarlo de la base del día
      if (refinance.amount > 0) {
        final dateStr = _formatDate(_selectedDate);
        final existingBase = await _baseRepository.getBaseByDate(
          _currentRouteId,
          dateStr,
        );

        if (existingBase != null) {
          // Descontar del monto actual
          await _baseRepository.updateBase(
            existingBase.copyWith(
              amount: existingBase.amount - refinance.amount,
            ),
          );
        } else {
          // Crear base con monto negativo
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

      // 3. Si es "Dar tiempo" actualizar días de pago del cliente
      if (newPaymentDays != null) {
        await _clientRepository.updateClient(
          todayClient.client.copyWith(paymentDays: newPaymentDays),
        );
      }

      // 4. Actualizar en memoria
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
      debugPrint('Error refinanciando cliente: $e');
    }
  }
}
