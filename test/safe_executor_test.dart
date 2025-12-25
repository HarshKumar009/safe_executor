import 'package:test/test.dart';
import 'package:safe_executor/safe_executor.dart';

// Custom error class for testing error mapper
class CustomError {
  final String message;
  CustomError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CustomError && message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'CustomError: $message';
}

void main() {
  group('SafeExecutor - Basic functionality', () {
    test('returns Success when function completes successfully', () async {
      final result = await SafeExecutor.run(
        functionToExecute: () async {
          return 42;
        },
      );

      expect(result, isA<Success<int, Object>>());
      expect((result as Success).value, 42);
    });

    test('returns Success with String value', () async {
      final result = await SafeExecutor.run(
        functionToExecute: () async {
          return 'Hello, World!';
        },
      );

      expect(result, isA<Success<String, Object>>());
      expect((result as Success).value, 'Hello, World!');
    });

    test('returns Failure when function throws an exception', () async {
      final result = await SafeExecutor.run(
        functionToExecute: () async {
          throw Exception('Something went wrong');
        },
      );

      expect(result, isA<Failure<dynamic, Object>>());
      expect((result as Failure).value, isA<Exception>());
    });

    test('returns Failure with the thrown error message', () async {
      final errorMessage = 'Custom error message';
      final result = await SafeExecutor.run(
        functionToExecute: () async {
          throw Exception(errorMessage);
        },
      );

      expect(result, isA<Failure<dynamic, Object>>());
      final failure = result as Failure;
      expect(failure.value.toString(), contains(errorMessage));
    });

    test('handles async operations correctly', () async {
      final result = await SafeExecutor.run(
        functionToExecute: () async {
          await Future.delayed(Duration(milliseconds: 10));
          return 'Delayed result';
        },
      );

      expect(result, isA<Success<String, Object>>());
      expect((result as Success).value, 'Delayed result');
    });

    test('can be used with pattern matching', () async {
      final result = await SafeExecutor.run(
        functionToExecute: () async {
          return 100;
        },
      );

      final message = switch (result) {
        Success(value: final data) => 'Got: $data',
        Failure(value: final error) => 'Error: $error',
      };

      expect(message, 'Got: 100');
    });
  });

  group('SafeExecutor - Retry functionality', () {
    test('succeeds without retries when function works', () async {
      var attempts = 0;
      final result = await SafeExecutor.run(
        functionToExecute: () async {
          attempts++;
          return 'success';
        },
        retries: 3,
      );

      expect(result, isA<Success<String, Object>>());
      expect((result as Success).value, 'success');
      expect(attempts, 1); // Should only run once
    });

    test('retries and succeeds on second attempt', () async {
      var attempts = 0;
      final result = await SafeExecutor.run(
        functionToExecute: () async {
          attempts++;
          if (attempts < 2) {
            throw Exception('Attempt $attempts failed');
          }
          return 'success on attempt $attempts';
        },
        retries: 2,
        retryDelay: Duration(milliseconds: 50),
      );

      expect(result, isA<Success<String, Object>>());
      expect((result as Success).value, 'success on attempt 2');
      expect(attempts, 2);
    });

    test('fails after exhausting all retries', () async {
      var attempts = 0;
      final result = await SafeExecutor.run(
        functionToExecute: () async {
          attempts++;
          throw Exception('Always fails');
        },
        retries: 2,
        retryDelay: Duration(milliseconds: 50),
      );

      expect(result, isA<Failure<dynamic, Object>>());
      expect(attempts, 3); // Initial attempt + 2 retries
    });

    test('respects retry delay', () async {
      final startTime = DateTime.now();
      var attempts = 0;

      await SafeExecutor.run(
        functionToExecute: () async {
          attempts++;
          throw Exception('Always fails');
        },
        retries: 2,
        retryDelay: Duration(milliseconds: 100),
      );

      final elapsed = DateTime.now().difference(startTime);
      expect(attempts, 3);
      // Should take at least 200ms (2 retries × 100ms delay)
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(200));
    });
  });

  group('SafeExecutor - Timeout functionality', () {
    test('succeeds when function completes before timeout', () async {
      final result = await SafeExecutor.run(
        functionToExecute: () async {
          await Future.delayed(Duration(milliseconds: 50));
          return 'completed';
        },
        timeout: Duration(milliseconds: 200),
      );

      expect(result, isA<Success<String, Object>>());
      expect((result as Success).value, 'completed');
    });

    test('fails when function exceeds timeout', () async {
      final result = await SafeExecutor.run(
        functionToExecute: () async {
          await Future.delayed(Duration(milliseconds: 300));
          return 'should not return';
        },
        timeout: Duration(milliseconds: 100),
      );

      expect(result, isA<Failure<dynamic, Object>>());
      final failure = result as Failure;
      expect(failure.value.toString(), contains('TimeoutException'));
    });

    test('timeout applies to each retry attempt', () async {
      var attempts = 0;
      final startTime = DateTime.now();

      final result = await SafeExecutor.run(
        functionToExecute: () async {
          attempts++;
          await Future.delayed(Duration(milliseconds: 150));
          throw Exception('Too slow');
        },
        retries: 2,
        timeout: Duration(milliseconds: 100),
        retryDelay: Duration(milliseconds: 50),
      );

      final elapsed = DateTime.now().difference(startTime);
      expect(result, isA<Failure<dynamic, Object>>());
      expect(attempts, 3); // Should attempt all retries despite timeouts
      // Each attempt times out at 100ms, plus retry delays
      expect(elapsed.inMilliseconds, lessThan(500));
    });
  });

  group('SafeExecutor - Error mapper functionality', () {
    test('maps errors to custom type when errorMapper is provided', () async {
      final result = await SafeExecutor.run<String, CustomError>(
        functionToExecute: () async {
          throw Exception('Original error');
        },
        errorMapper: (error) => CustomError('Mapped: ${error.toString()}'),
      );

      expect(result, isA<Failure<String, CustomError>>());
      final failure = result as Failure<String, CustomError>;
      expect(failure.value, isA<CustomError>());
      expect(failure.value.message, contains('Mapped:'));
    });

    test('returns original error when errorMapper is null', () async {
      final result = await SafeExecutor.run<String, Exception>(
        functionToExecute: () async {
          throw Exception('Test error');
        },
      );

      expect(result, isA<Failure<String, Exception>>());
      final failure = result as Failure;
      expect(failure.value.toString(), contains('Test error'));
    });

    test('errorMapper can handle different exception types', () async {
      final result = await SafeExecutor.run<String, CustomError>(
        functionToExecute: () async {
          throw ArgumentError('Invalid argument');
        },
        errorMapper: (error) {
          if (error is ArgumentError) {
            return CustomError('Argument error: ${error.message}');
          }
          return CustomError('Unknown error');
        },
      );

      expect(result, isA<Failure<String, CustomError>>());
      final failure = result as Failure<String, CustomError>;
      expect(failure.value.message, contains('Argument error'));
    });
  });

  group('SafeExecutor - Combined features', () {
    test('retries with timeout and error mapper work together', () async {
      var attempts = 0;
      final result = await SafeExecutor.run<String, CustomError>(
        functionToExecute: () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('Attempt $attempts failed');
          }
          return 'success';
        },
        retries: 3,
        timeout: Duration(seconds: 1),
        retryDelay: Duration(milliseconds: 50),
        errorMapper: (error) => CustomError('Failed: ${error.toString()}'),
      );

      expect(result, isA<Success<String, CustomError>>());
      expect((result as Success).value, 'success');
      expect(attempts, 3);
    });
  });

  group('Result types', () {
    test('Success stores and retrieves value correctly', () {
      final success = Success<int, String>(42);
      expect(success.value, 42);
    });

    test('Failure stores and retrieves value correctly', () {
      final failure = Failure<int, String>('error');
      expect(failure.value, 'error');
    });

    test('Success equality works correctly', () {
      final success1 = Success<int, String>(42);
      final success2 = Success<int, String>(42);
      final success3 = Success<int, String>(43);

      expect(success1, equals(success2));
      expect(success1, isNot(equals(success3)));
    });

    test('Failure equality works correctly', () {
      final failure1 = Failure<int, String>('error');
      final failure2 = Failure<int, String>('error');
      final failure3 = Failure<int, String>('different error');

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failure3)));
    });

    test('Success toString returns correct format', () {
      final success = Success<int, String>(42);
      expect(success.toString(), 'Success(42)');
    });

    test('Failure toString returns correct format', () {
      final failure = Failure<int, String>('error');
      expect(failure.toString(), 'Failure(error)');
    });
  });
}