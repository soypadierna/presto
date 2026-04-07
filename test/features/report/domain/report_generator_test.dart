import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:presto/features/report/domain/report_generator.dart';
import 'package:presto/features/report/domain/daily_base_model.dart';
import 'package:presto/features/report/domain/expense_model.dart';
import 'package:presto/features/today/domain/today_client.dart';
import 'package:presto/features/today/domain/payment_model.dart';
import 'package:presto/features/clients/domain/client_model.dart';

void main() {
    // Inicializar localización español antes de todos los tests
  setUpAll(() async {
    await initializeDateFormatting('es', null);
  });
  group('ReportGenerator.generate', () {
    test('genera informe con todos los datos', () {
      final report = ReportGenerator.generate(
        routeName: 'Ruta Norte',
        date: DateTime(2026, 3, 15),
        todayClients: [
          _makeTodayClient(
            name: 'Juan Pérez',
            amount: 5000,
            status: PaymentStatus.paid,
          ),
          _makeTodayClient(
            name: 'María López',
            amount: 0,
            status: PaymentStatus.skipped,
          ),
        ],
        expenses: [
          _makeExpense(description: 'Gasolina', amount: 2000),
        ],
        dailyBase: _makeBase(amount: 50000),
      );

      expect(report, contains('PRESTO — Informe del día'));
      expect(report, contains('Ruta Norte'));
      expect(report, contains('Juan Pérez'));
      expect(report, contains('María López'));
      expect(report, contains('No dio'));
      expect(report, contains('Gasolina'));
      expect(report, contains('BASE:'));
      expect(report, contains('TOTAL COBRADO:'));
      expect(report, contains('NETO:'));
    });

    test('genera informe sin gastos', () {
      final report = ReportGenerator.generate(
        routeName: 'Ruta Sur',
        date: DateTime(2026, 3, 15),
        todayClients: [
          _makeTodayClient(
            name: 'Pedro Gómez',
            amount: 3000,
            status: PaymentStatus.paid,
          ),
        ],
        expenses: [],
        dailyBase: null,
      );

      expect(report, isNot(contains('GASTOS')));
      expect(report, contains('Pedro Gómez'));
    });

    test('genera informe sin clientes registrados', () {
      final report = ReportGenerator.generate(
        routeName: 'Ruta Este',
        date: DateTime(2026, 3, 15),
        todayClients: [],
        expenses: [],
        dailyBase: null,
      );

      expect(report, contains('Sin registros'));
      expect(report, contains('TOTAL COBRADO: ₡0'));
    });

    test('calcula el neto correctamente', () {
      final report = ReportGenerator.generate(
        routeName: 'Ruta Test',
        date: DateTime(2026, 3, 15),
        todayClients: [
          _makeTodayClient(
            name: 'Cliente A',
            amount: 10000,
            status: PaymentStatus.paid,
          ),
        ],
        expenses: [
          _makeExpense(description: 'Gasto', amount: 2000),
        ],
        dailyBase: _makeBase(amount: 5000),
      );

      // Neto = base(5000) + cobrado(10000) - gastos(2000) = 13000
      expect(report, contains('₡13,000'));
    });
  });
}

// ── Helpers ──────────────────────────────────────────────────

TodayClient _makeTodayClient({
  required String name,
  required double amount,
  required PaymentStatus status,
}) {
  return TodayClient(
    client: ClientModel(
      id: 'client-${name.hashCode}',
      routeId: 'route-id',
      name: name,
      credit: amount,
      paymentType: PaymentType.daily,
      paymentDays: {'days': ['mon', 'tue', 'wed', 'thu', 'fri', 'sat']},
      position: 0,
      isActive: true,
      createdAt: DateTime.now().toIso8601String(),
    ),
  );
}

ExpenseModel _makeExpense({
  required String description,
  required double amount,
}) {
  return ExpenseModel(
    id: 'expense-${description.hashCode}',
    routeId: 'route-id',
    description: description,
    amount: amount,
    expenseDate: '2026-03-15',
    createdAt: DateTime.now().toIso8601String(),
  );
}

DailyBaseModel _makeBase({required double amount}) {
  return DailyBaseModel(
    id: 'base-id',
    routeId: 'route-id',
    amount: amount,
    baseDate: '2026-03-15',
    createdAt: DateTime.now().toIso8601String(),
  );
}