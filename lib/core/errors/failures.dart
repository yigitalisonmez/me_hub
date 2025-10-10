/// Hata sınıfları - Clean Architecture için
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

/// Sunucu hatası
class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Sunucu hatası oluştu',
    super.code,
  });
}

/// Ağ hatası
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'İnternet bağlantınızı kontrol edin',
    super.code,
  });
}

/// Cache hatası
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Yerel veri hatası oluştu',
    super.code,
  });
}

/// Doğrulama hatası
class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'Girilen bilgiler geçersiz',
    super.code,
  });
}

/// Yetkilendirme hatası
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Yetkilendirme hatası',
    super.code,
  });
}

/// Zaman aşımı hatası
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'İstek zaman aşımına uğradı',
    super.code,
  });
}

/// Bilinmeyen hata
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Bilinmeyen bir hata oluştu',
    super.code,
  });
}
