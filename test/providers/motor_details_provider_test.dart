import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glimo/application/providers/motor_details_provider.dart';

void main() {
  group('MotorDetailsProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be empty', () {
      final state = container.read(motorDetailsProvider);
      expect(state.model, isNull);
      expect(state.type, isNull);
      expect(state.odometer, isNull);
    });

    test('setModel should update model', () {
      container.read(motorDetailsProvider.notifier).setModel('Honda Beat');
      final state = container.read(motorDetailsProvider);
      expect(state.model, 'Honda Beat');
    });

    test('setType should update type', () {
      container.read(motorDetailsProvider.notifier).setType('Matic');
      final state = container.read(motorDetailsProvider);
      expect(state.type, 'Matic');
    });

    test('setOdometer should update odometer', () {
      container.read(motorDetailsProvider.notifier).setOdometer('12000');
      final state = container.read(motorDetailsProvider);
      expect(state.odometer, '12000');
    });

    test('clearAll should reset all values', () {
      container.read(motorDetailsProvider.notifier)
        ..setModel('Honda Beat')
        ..setType('Matic')
        ..setOdometer('12000')
        ..clearAll();

      final state = container.read(motorDetailsProvider);
      expect(state.model, isNull);
      expect(state.type, isNull);
      expect(state.odometer, isNull);
    });
  });
}
