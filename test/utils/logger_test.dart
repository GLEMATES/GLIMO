import 'package:flutter_test/flutter_test.dart';
import 'package:glimo/core/utils/logger.dart';

void main() {
  group('Logger', () {
    test('log should not throw error', () {
      expect(() => Logger.log('Test message'), returnsNormally);
    });

    test('error should not throw error', () {
      expect(() => Logger.error('Test error'), returnsNormally);
    });

    test('warn should not throw error', () {
      expect(() => Logger.warn('Test warning'), returnsNormally);
    });

    test('info should not throw error', () {
      expect(() => Logger.info('Test info'), returnsNormally);
    });

    test('success should not throw error', () {
      expect(() => Logger.success('Test success'), returnsNormally);
    });

    test('log with tag should not throw error', () {
      expect(() => Logger.log('Test message', tag: 'TEST'), returnsNormally);
    });

    test('error with tag and error object should not throw error', () {
      expect(
        () => Logger.error('Test error', tag: 'TEST', error: Exception('test')),
        returnsNormally,
      );
    });
  });
}
