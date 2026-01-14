import 'package:flutter_test/flutter_test.dart';
import 'package:laze/utils/result.dart';

void main() {
  group('Result', () {
    test('Result.ok creates Ok instance', () {
      final result = Result.ok(42);
      
      expect(result, isA<Ok<int>>());
      expect(result.asOk.value, equals(42));
    });

    test('Result.error creates Error instance', () {
      final exception = Exception('Test error');
      final result = Result<int>.error(exception);
      
      expect(result, isA<Error<int>>());
      expect(result.asError.error, equals(exception));
    });

    test('Ok toString returns correct format', () {
      final result = Result.ok('test');
      
      expect(result.toString(), contains('Result<String>.ok(test)'));
    });

    test('Error toString returns correct format', () {
      final exception = Exception('Test error');
      final result = Result<String>.error(exception);
      
      expect(result.toString(), contains('Result<String>.error'));
      expect(result.toString(), contains('Test error'));
    });

    test('apply executes isOk callback for Ok result', () {
      final result = Result.ok(10);
      
      final output = result.apply(
        (value) => value * 2,
        (error) => -1,
      );
      
      expect(output, equals(20));
    });

    test('apply executes isError callback for Error result', () {
      final result = Result<int>.error(Exception('Error'));
      
      final output = result.apply(
        (value) => value * 2,
        (error) => -1,
      );
      
      expect(output, equals(-1));
    });

    test('asOk conversion works for Ok result', () {
      final result = Result.ok('success');
      final ok = result.asOk;
      
      expect(ok.value, equals('success'));
    });

    test('asError conversion works for Error result', () {
      final exception = Exception('failure');
      final result = Result<String>.error(exception);
      final error = result.asError;
      
      expect(error.error, equals(exception));
    });
  });
}
