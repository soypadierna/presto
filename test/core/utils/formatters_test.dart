import 'package:flutter_test/flutter_test.dart';
import 'package:presto/core/utils/formatters.dart';
import 'package:presto/features/clients/domain/client_model.dart';

void main() {
  group('Formatters.formatAmount', () {
    test('formatea números con separadores de miles', () {
      expect(Formatters.formatAmount(1000), equals('₡1,000'));
      expect(Formatters.formatAmount(10000), equals('₡10,000'));
      expect(Formatters.formatAmount(100000), equals('₡100,000'));
      expect(Formatters.formatAmount(1000000), equals('₡1,000,000'));
    });

    test('formatea números menores a 1000 sin separadores', () {
      expect(Formatters.formatAmount(500), equals('₡500'));
      expect(Formatters.formatAmount(0), equals('₡0'));
    });

    test('redondea decimales', () {
      expect(Formatters.formatAmount(1000.99), equals('₡1,001'));
      expect(Formatters.formatAmount(1000.01), equals('₡1,000'));
    });
  });

  group('Formatters.formatShortDate', () {
    test('formatea fecha en dd/MM/yyyy', () {
      expect(
        Formatters.formatShortDate(DateTime(2026, 3, 15)),
        equals('15/03/2026'),
      );
    });

    test('agrega ceros a día y mes menores a 10', () {
      expect(
        Formatters.formatShortDate(DateTime(2026, 1, 5)),
        equals('05/01/2026'),
      );
    });
  });

  group('Formatters.paymentTypeLabel', () {
    test('retorna labels en español', () {
      expect(
        Formatters.paymentTypeLabel(PaymentType.daily),
        equals('Diario'),
      );
      expect(
        Formatters.paymentTypeLabel(PaymentType.weekly),
        equals('Semanal'),
      );
      expect(
        Formatters.paymentTypeLabel(PaymentType.biweekly),
        equals('Quincenal'),
      );
      expect(
        Formatters.paymentTypeLabel(PaymentType.monthly),
        equals('Mensual'),
      );
    });
  });
}