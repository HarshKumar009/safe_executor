/// A sealed class representing the result of an operation that can either succeed or fail.
///
/// [Result] is a discriminated union type with two possible variants:
/// - [Success]: Represents a successful operation with a value of type [S]
/// - [Failure]: Represents a failed operation with a value of type [F]
///
/// Type parameters:
/// - [S]: The type of the success value
/// - [F]: The type of the failure value
sealed class Result<S, F> {
  const Result();
}

/// Represents a successful result containing a value of type [S].
final class Success<S, F> extends Result<S, F> {
  /// The success value.
  final S value;

  /// Creates a [Success] instance with the given [value].
  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Success<S, F> &&
              runtimeType == other.runtimeType &&
              value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// Represents a failed result containing a value of type [F].
final class Failure<S, F> extends Result<S, F> {
  /// The failure value.
  final F value;

  /// Creates a [Failure] instance with the given [value].
  const Failure(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Failure<S, F> &&
              runtimeType == other.runtimeType &&
              value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Failure($value)';
}