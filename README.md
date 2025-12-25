# safe_executor

[![pub package](https://img.shields.io/pub/v/safe_executor.svg)](https://pub.dev/packages/safe_executor)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![style: effective dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://pub.dev/packages/effective_dart)

A lightweight, type-safe Dart package for executing asynchronous operations with built-in error handling, automatic retries, timeouts, and custom error mapping. Say goodbye to repetitive try-catch blocks and hello to clean, robust async code! 🚀

---

## The Problem

We've all been there. You're building an app, making API calls, fetching data from databases, or performing any async operation. And what do you do? You wrap everything in `try-catch` blocks:

```dart
try {
  final data = await fetchUserData();
  // handle success
} catch (e) {
  // handle error
}
```

Now add retries. Now add timeouts. Now add custom error types. Suddenly, your beautiful async function is buried under layers of boilerplate code. Your codebase becomes cluttered, and implementing these features consistently across your app feels like a chore.

**There has to be a better way, right?**

---

## ✨ The Solution

Enter **safe_executor** – a simple, elegant package that handles all of this for you. It wraps your async operations in a type-safe `Result` type, automatically handles retries and timeouts, and lets you map errors to your own custom types. Your code stays clean, your error handling stays robust, and you stay sane.

With `safe_executor`, you write less code, make fewer mistakes, and ship features faster. It's that simple.

---

## 🎯 Key Features

- **🛡️ Type-Safe Results (No more try-catch)**: Results are wrapped in a `Result<Success, Failure>` type, making error handling explicit and safe. Pattern matching makes it beautiful to work with.

- **🔁 Retry Logic**: Automatically retry failed operations with configurable attempts and delays. Perfect for flaky network requests or temporary failures.

- **⏱️ Timeout Support**: Set maximum execution times for your async operations. Never let a hanging request freeze your app again.

- **✨ Custom Error Mapping**: Transform generic exceptions into your own domain-specific error types. Make your error handling as precise as your business logic.

- **🍃 Lightweight & Zero-Dependency**: Pure Dart implementation with no external dependencies. Works everywhere Dart runs – Flutter, server-side, CLI tools, you name it.

---

## 📦 Installation

Add `safe_executor` to your `pubspec.yaml`:

```yaml
dependencies:
  safe_executor: ^1.0.1
```

Then run:

```bash
dart pub get
```

Or for Flutter projects:

```bash
flutter pub get
```

---

## 🚀 How to Use

### Basic Execution

The simplest use case – just wrap your async function and let `safe_executor` handle the rest:

```dart
import 'package:safe_executor/safe_executor.dart';

Future<void> fetchData() async {
  final result = await SafeExecutor.run(
    functionToExecute: () async {
      // Your async operation here
      final response = await http.get(Uri.parse('https://api.example.com/data'));
      return response.body;
    },
  );

  // Handle the result
  switch (result) {
    case Success(value: final data):
      print('✅ Success: $data');
    case Failure(value: final error):
      print('❌ Error: $error');
  }
}
```

That's it! No try-catch needed. The result is type-safe and explicit.

---

### Handling Results with Pattern Matching

Dart's pattern matching makes working with `Result` types incredibly clean:

```dart
Future<void> getUserProfile(String userId) async {
  final result = await SafeExecutor.run(
    functionToExecute: () async {
      return await apiClient.fetchUserProfile(userId);
    },
  );

  final message = switch (result) {
    Success(value: final profile) => 'Welcome, ${profile.name}!',
    Failure(value: final error) => 'Failed to load profile: $error',
  };

  print(message);
}
```

---

### Using Retries

Network hiccup? Database temporarily unavailable? No problem. Add automatic retries with a simple parameter:

```dart
Future<void> fetchWithRetries() async {
  final result = await SafeExecutor.run(
    functionToExecute: () async {
      // This might fail a few times before succeeding
      return await unreliableNetworkCall();
    },
    retries: 3, // Retry up to 3 times
    retryDelay: Duration(seconds: 2), // Wait 2 seconds between attempts
  );

  switch (result) {
    case Success(value: final data):
      print('Got the data (eventually): $data');
    case Failure(value: final error):
      print('Failed even after retries: $error');
  }
}
```

The executor will automatically retry your function if it fails, waiting for the specified delay between attempts. Perfect for handling transient failures!

---

### Using Timeouts

Don't let slow operations hang your app. Set a maximum execution time:

```dart
Future<void> fetchWithTimeout() async {
  final result = await SafeExecutor.run(
    functionToExecute: () async {
      // This might take a while...
      return await someSlowOperation();
    },
    timeout: Duration(seconds: 5), // Maximum 5 seconds
  );

  switch (result) {
    case Success(value: final data):
      print('Completed in time: $data');
    case Failure(value: final error):
      if (error.toString().contains('TimeoutException')) {
        print('⏱️ Operation timed out!');
      } else {
        print('❌ Other error: $error');
      }
  }
}
```

If the operation doesn't complete within the timeout, a `TimeoutException` will be caught and returned as a `Failure`.

---

### Custom Error Mapping (The Power Feature! ✨)

This is where `safe_executor` really shines. Map generic exceptions to your own domain-specific error types:

```dart
// Define your custom error class
class ApiError {
  final String message;
  final int? statusCode;

  ApiError(this.message, {this.statusCode});

  @override
  String toString() => 'ApiError: $message (${statusCode ?? 'unknown'})';
}

// Use it with error mapping
Future<void> fetchWithCustomErrors() async {
  final result = await SafeExecutor.run<String, ApiError>(
    functionToExecute: () async {
      final response = await http.get(Uri.parse('https://api.example.com/users'));
      
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      
      return response.body;
    },
    errorMapper: (error) {
      // Transform any exception into your custom error type
      if (error.toString().contains('HTTP')) {
        final code = int.tryParse(error.toString().replaceAll(RegExp(r'[^0-9]'), ''));
        return ApiError('Failed to fetch users', statusCode: code);
      }
      
      if (error.toString().contains('SocketException')) {
        return ApiError('No internet connection');
      }
      
      return ApiError('Unknown error occurred');
    },
  );

  switch (result) {
    case Success(value: final data):
      print('✅ Got users: $data');
    case Failure(value: final error):
      // error is now guaranteed to be ApiError, not just Object!
      print('❌ ${error.message}');
      if (error.statusCode != null) {
        print('Status code: ${error.statusCode}');
      }
  }
}
```

Notice how the `Failure` now contains your `ApiError` type, not just a generic `Object`. This gives you type safety and precise error handling throughout your app!

---

### Combining Everything

Of course, you can use all features together for maximum robustness:

```dart
class NetworkError {
  final String message;
  final DateTime timestamp;

  NetworkError(this.message) : timestamp = DateTime.now();

  @override
  String toString() => '$message at ${timestamp.toIso8601String()}';
}

Future<void> robustApiCall() async {
  final result = await SafeExecutor.run<Map<String, dynamic>, NetworkError>(
    functionToExecute: () async {
      final response = await http.get(
        Uri.parse('https://api.example.com/important-data'),
      );
      return jsonDecode(response.body);
    },
    retries: 3,
    retryDelay: Duration(seconds: 2),
    timeout: Duration(seconds: 10),
    errorMapper: (error) {
      if (error.toString().contains('TimeoutException')) {
        return NetworkError('Request timed out after 10 seconds');
      }
      if (error.toString().contains('SocketException')) {
        return NetworkError('No internet connection available');
      }
      return NetworkError('Failed to fetch data: ${error.toString()}');
    },
  );

  switch (result) {
    case Success(value: final data):
      print('✅ Data received: $data');
      // Process your data
    case Failure(value: final error):
      print('❌ ${error.message}');
      // Show user-friendly error message
  }
}
```

This gives you:
- ✅ Automatic retries (up to 3 times)
- ✅ Timeout protection (10 seconds max)
- ✅ Custom error types (NetworkError)
- ✅ Type-safe result handling
- ✅ Clean, readable code

---

## 🎨 Real-World Example

Here's how you might use `safe_executor` in a real Flutter app:

```dart
class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<Result<User, AppError>> getUser(String id) async {
    return SafeExecutor.run<User, AppError>(
      functionToExecute: () async {
        final response = await _apiClient.get('/users/$id');
        return User.fromJson(response.data);
      },
      retries: 2,
      timeout: Duration(seconds: 5),
      errorMapper: (error) {
        if (error.toString().contains('404')) {
          return AppError.notFound('User not found');
        }
        if (error.toString().contains('TimeoutException')) {
          return AppError.timeout('Request timed out');
        }
        if (error.toString().contains('SocketException')) {
          return AppError.noInternet('Check your connection');
        }
        return AppError.unknown('Something went wrong');
      },
    );
  }
}

// In your UI layer
void loadUser(String userId) async {
  setState(() => isLoading = true);

  final result = await userRepository.getUser(userId);

  setState(() {
    isLoading = false;
    switch (result) {
      case Success(value: final user):
        this.user = user;
        errorMessage = null;
      case Failure(value: final error):
        this.user = null;
        errorMessage = error.message;
    }
  });
}
```

Clean, type-safe, and production-ready! 🎉

---

## 🤝 Contributing

Contributions are welcome! If you find a bug or have a feature request, please open an issue on GitHub.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Made with ❤️ for developers who value clean code and robust error handling.**

Code on, safely! 🛡️