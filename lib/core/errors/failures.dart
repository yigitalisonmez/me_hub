/// Error classes - For Clean Architecture
abstract class Failure {
  final String message;
  final String? code;
  
  const Failure({
    required this.message,
    this.code,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure && other.message == message && other.code == code;
  }

  @override
  int get hashCode => message.hashCode ^ code.hashCode;

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

/// Server error
class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'A server error occurred',
    super.code,
  });
}

/// Network error
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Please check your internet connection',
    super.code,
  });
}

/// Cache error
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'A local data error occurred',
    super.code,
  });
}

/// Validation error
class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'Invalid information entered',
    super.code,
  });
}

/// Authorization error
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authorization error',
    super.code,
  });
}

/// Timeout error
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'Request timed out',
    super.code,
  });
}

/// Unknown error
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unknown error occurred',
    super.code,
  });
}
