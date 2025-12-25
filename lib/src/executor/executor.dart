import '../result/result.dart';

/// A utility class for safely executing asynchronous operations.
///
/// [SafeExecutor] provides methods to run async functions and capture
/// their results or exceptions in a type-safe manner using the [Result] type.
class SafeExecutor {
  // Private constructor to prevent instantiation
  SafeExecutor._();

  /// Safely executes an asynchronous function and returns its result wrapped in a [Result].
  ///
  /// This method runs the provided [functionToExecute] and captures either its
  /// successful return value or any exception that occurs during execution.
  ///
  /// If the function fails, it will automatically retry based on the [retries] parameter.
  /// Between retry attempts, the method will wait for the duration specified by [retryDelay].
  ///
  /// If a [timeout] is provided, the function execution will be limited to that duration.
  /// If the timeout is exceeded, a [TimeoutException] will be caught and returned as a [Failure].
  ///
  /// The [errorMapper] function allows you to transform caught exceptions into custom error types.
  /// If not provided, the original exception will be returned (cast to type [F]).
  ///
  /// Parameters:
  /// - [functionToExecute]: The async function to execute (required)
  /// - [retries]: The number of retry attempts after the initial execution (default: 0)
  /// - [retryDelay]: The duration to wait between retry attempts (default: 1 second)
  /// - [timeout]: Optional maximum duration for each execution attempt (default: null, no timeout)
  /// - [errorMapper]: Optional function to map exceptions to custom error types
  ///
  /// Returns:
  /// - [Success] containing the result of type [T] if the function completes successfully
  /// - [Failure] containing the error of type [F] if all attempts fail or timeout is exceeded
  ///
  /// Type parameters:
  /// - [T]: The return type of the function being executed
  /// - [F]: The type of the failure value (defaults to [Object] if not specified)
  ///
  /// Example:
  /// ```dart
  /// // Simple execution without retries
  /// final result = await SafeExecutor.run(
  ///   functionToExecute: () async {
  ///     return await fetchData();
  ///   },
  /// );
  ///
  /// // With retry logic
  /// final resultWithRetry = await SafeExecutor.run(
  ///   functionToExecute: () async => await fetchData(),
  ///   retries: 3,
  ///   retryDelay: Duration(seconds: 2),
  /// );
  ///
  /// // With timeout
  /// final resultWithTimeout = await SafeExecutor.run(
  ///   functionToExecute: () async => await fetchData(),
  ///   timeout: Duration(seconds: 5),
  /// );
  ///
  /// // With custom error mapping
  /// final resultWithMapping = await SafeExecutor.run<String, AppError>(
  ///   functionToExecute: () async => await fetchData(),
  ///   errorMapper: (error) => AppError(message: error.toString()),
  /// );
  ///
  /// // Combining all features
  /// final resultComplete = await SafeExecutor.run<String, AppError>(
  ///   functionToExecute: () async => await fetchData(),
  ///   retries: 3,
  ///   retryDelay: Duration(seconds: 2),
  ///   timeout: Duration(seconds: 5),
  ///   errorMapper: (error) {
  ///     if (error is TimeoutException) {
  ///       return AppError(message: 'Request timed out');
  ///     }
  ///     return AppError(message: error.toString());
  ///   },
  /// );
  ///
  /// switch (resultComplete) {
  ///   case Success(value: final data):
  ///     print('Success: $data');
  ///   case Failure(value: final error):
  ///     print('Error: ${error.message}');
  /// }
  /// ```
  static Future<Result<T, F>> run<T, F>({
    required Future<T> Function() functionToExecute,
    int retries = 0,
    Duration retryDelay = const Duration(seconds: 1),
    Duration? timeout,
    F Function(Object error)? errorMapper,
  }) async {
    final totalAttempts = retries + 1;

    for (var attempt = 0; attempt < totalAttempts; attempt++) {
      try {
        final future = functionToExecute();
        final result = timeout != null
            ? await future.timeout(timeout)
            : await future;
        return Success(result);
      } catch (e) {
        // If this is the final attempt, return the failure
        if (attempt == totalAttempts - 1) {
          final error = errorMapper != null ? errorMapper(e) : e as F;
          return Failure(error);
        }

        // Wait before the next retry attempt
        await Future.delayed(retryDelay);
      }
    }

    // This line should never be reached, but is here for type safety
    throw StateError('Unexpected state in SafeExecutor.run');
  }
}