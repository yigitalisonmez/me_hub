/// Exception sınıfları - Data katmanı için
class ServerException implements Exception {
  final String message;
  final String? code;
  
  const ServerException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'ServerException(message: $message, code: $code)';
}

class NetworkException implements Exception {
  final String message;
  final String? code;
  
  const NetworkException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'NetworkException(message: $message, code: $code)';
}

class CacheException implements Exception {
  final String message;
  final String? code;
  
  const CacheException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'CacheException(message: $message, code: $code)';
}

class ValidationException implements Exception {
  final String message;
  final String? code;
  
  const ValidationException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'ValidationException(message: $message, code: $code)';
}

class AuthException implements Exception {
  final String message;
  final String? code;
  
  const AuthException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'AuthException(message: $message, code: $code)';
}

class TimeoutException implements Exception {
  final String message;
  final String? code;
  
  const TimeoutException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'TimeoutException(message: $message, code: $code)';
}

class UnknownException implements Exception {
  final String message;
  final String? code;
  
  const UnknownException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'UnknownException(message: $message, code: $code)';
}
