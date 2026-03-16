import 'package:flutter_test/flutter_test.dart';
import 'package:presto/features/clients/domain/client_model.dart';

void main() {
  group('ClientModel.isScheduledForDate', () {
    // ── Diario ──────────────────────────────────────────────
    group('tipo diario', () {
      test('aparece en días configurados', () {
        final client = _makeClient(
          type: PaymentType.daily,
          days: {'days': ['mon', 'wed', 'fri']},
        );

        expect(
          client.isScheduledForDate(DateTime(2026, 3, 16)), // lunes
          isTrue,
        );
        expect(
          client.isScheduledForDate(DateTime(2026, 3, 18)), // miércoles
          isTrue,
        );
        expect(
          client.isScheduledForDate(DateTime(2026, 3, 20)), // viernes
          isTrue,
        );
      });

      test('no aparece en días no configurados', () {
        final client = _makeClient(
          type: PaymentType.daily,
          days: {'days': ['mon', 'wed', 'fri']},
        );

        expect(
          client.isScheduledForDate(DateTime(2026, 3, 17)), // martes
          isFalse,
        );
        expect(
          client.isScheduledForDate(DateTime(2026, 3, 19)), // jueves
          isFalse,
        );
        expect(
          client.isScheduledForDate(DateTime(2026, 3, 21)), // sábado
          isFalse,
        );
      });

      test('puede incluir domingo si está configurado', () {
        final client = _makeClient(
          type: PaymentType.daily,
          days: {'days': ['sun']},
        );

        expect(
          client.isScheduledForDate(DateTime(2026, 3, 22)), // domingo
          isTrue,
        );
      });

      test('usa lunes a sábado por defecto si no hay días configurados', () {
        final client = _makeClient(
          type: PaymentType.daily,
          days: {},
        );

        expect(
          client.isScheduledForDate(DateTime(2026, 3, 16)), // lunes
          isTrue,
        );
        expect(
          client.isScheduledForDate(DateTime(2026, 3, 21)), // sábado
          isTrue,
        );
        expect(
          client.isScheduledForDate(DateTime(2026, 3, 22)), // domingo
          isFalse,
        );
      });
    });

    // ── Semanal ─────────────────────────────────────────────
    group('tipo semanal', () {
      test('aparece solo el día configurado', () {
        final client = _makeClient(
          type: PaymentType.weekly,
          days: {'day': 'wed'},
        );

        expect(
          client.isScheduledForDate(DateTime(2026, 3, 18)), // miércoles
          isTrue,
        );
      });

      test('no aparece otros días de la semana', () {
        final client = _makeClient(
          type: PaymentType.weekly,
          days: {'day': 'wed'},
        );

        expect(
          client.isScheduledForDate(DateTime(2026, 3, 16)), // lunes
          isFalse,
        );
        expect(
          client.isScheduledForDate(DateTime(2026, 3, 17)), // martes
          isFalse,
        );
        expect(
          client.isScheduledForDate(DateTime(2026, 3, 19)), // jueves
          isFalse,
        );
      });

      test('aparece la siguiente semana en el mismo día', () {
        final client = _makeClient(
          type: PaymentType.weekly,
          days: {'day': 'wed'},
        );

        expect(
          client.isScheduledForDate(DateTime(2026, 3, 25)), // siguiente miércoles
          isTrue,
        );
      });
    });

    // ── Quincenal ────────────────────────────────────────────
    group('tipo quincenal', () {
      test('aparece en las dos fechas configuradas', () {
        final client = _makeClient(
          type: PaymentType.biweekly,
          days: {'dates': [1, 15]},
        );

        expect(
          client.isScheduledForDate(DateTime(2026, 3, 1)),
          isTrue,
        );
        expect(
          client.isScheduledForDate(DateTime(2026, 3, 15)),
          isTrue,
        );
      });

      test('no aparece en otras fechas del mes', () {
        final client = _makeClient(
          type: PaymentType.biweekly,
          days: {'dates': [1, 15]},
        );

        expect(
          client.isScheduledForDate(DateTime(2026, 3, 10)),
          isFalse,
        );
        expect(
          client.isScheduledForDate(DateTime(2026, 3, 20)),
          isFalse,
        );
      });

      test('funciona con fechas personalizadas', () {
        final client = _makeClient(
          type: PaymentType.biweekly,
          days: {'dates': [5, 20]},
        );

        expect(
          client.isScheduledForDate(DateTime(2026, 3, 5)),
          isTrue,
        );
        expect(
          client.isScheduledForDate(DateTime(2026, 3, 20)),
          isTrue,
        );
        expect(
          client.isScheduledForDate(DateTime(2026, 3, 15)),
          isFalse,
        );
      });
    });

    // ── Mensual ──────────────────────────────────────────────
    group('tipo mensual', () {
      test('aparece solo el día del mes configurado', () {
        final client = _makeClient(
          type: PaymentType.monthly,
          days: {'date': 10},
        );

        expect(
          client.isScheduledForDate(DateTime(2026, 3, 10)),
          isTrue,
        );
      });

      test('no aparece otros días del mes', () {
        final client = _makeClient(
          type: PaymentType.monthly,
          days: {'date': 10},
        );

        expect(
          client.isScheduledForDate(DateTime(2026, 3, 9)),
          isFalse,
        );
        expect(
          client.isScheduledForDate(DateTime(2026, 3, 11)),
          isFalse,
        );
      });

      test('aparece el mismo día en meses diferentes', () {
        final client = _makeClient(
          type: PaymentType.monthly,
          days: {'date': 10},
        );

        expect(
          client.isScheduledForDate(DateTime(2026, 4, 10)),
          isTrue,
        );
        expect(
          client.isScheduledForDate(DateTime(2026, 5, 10)),
          isTrue,
        );
      });
    });
  });
}

/// Helper para crear un ClientModel de prueba fácilmente.
ClientModel _makeClient({
  required PaymentType type,
  required Map<String, dynamic> days,
}) {
  return ClientModel(
    id: 'test-id',
    routeId: 'route-id',
    name: 'Cliente Test',
    credit: 10000,
    paymentType: type,
    paymentDays: days,
    position: 0,
    isActive: true,
    createdAt: DateTime.now().toIso8601String(),
  );
}