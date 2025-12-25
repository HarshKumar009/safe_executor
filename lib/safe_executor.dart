/// A Dart package for safely executing asynchronous tasks.
///
/// This library provides a simple and type-safe way to handle async operations
/// that may fail, using a Result type that encapsulates either success or failure.
///
/// Example usage:
/// ```dart
/// import 'package:safe_executor/safe_executor.dart';
///
/// Future<void> main() async {
///   final result = await SafeExecutor.run(() async {
///     // Your async operation here
///     return await someAsyncOperation();
///   });
///
///   switch (result) {
///     case Success(value: final data):
///       print('Operation succeeded: $data');
///     case Failure(value: final error):
///       print('Operation failed: $error');
///   }
/// }
/// ```
library safe_executor;

export 'src/result/result.dart';
export 'src/executor/executor.dart';