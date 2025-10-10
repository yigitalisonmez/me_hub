/// Result sınıfı - Clean Architecture için başarı/hata durumlarını yönetmek için
sealed class Result<T> {
  const Result();
}

/// Başarılı sonuç
class Success<T> extends Result<T> {
  final T data;
  
  const Success(this.data);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<T> && other.data == data;
  }

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success(data: $data)';
}

/// Hatalı sonuç
class Error<T> extends Result<T> {
  final String message;
  final String? code;
  
  const Error({
    required this.message,
    this.code,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Error<T> && other.message == message && other.code == code;
  }

  @override
  int get hashCode => message.hashCode ^ code.hashCode;

  @override
  String toString() => 'Error(message: $message, code: $code)';
}

/// Result extension'ları
extension ResultExtension<T> on Result<T> {
  /// Başarılı mı kontrol et
  bool get isSuccess => this is Success<T>;
  
  /// Hatalı mı kontrol et
  bool get isError => this is Error<T>;
  
  /// Veriyi al (sadece başarılı durumda)
  T? get data => isSuccess ? (this as Success<T>).data : null;
  
  /// Hata mesajını al (sadece hatalı durumda)
  String? get errorMessage => isError ? (this as Error<T>).message : null;
  
  /// Hata kodunu al (sadece hatalı durumda)
  String? get errorCode => isError ? (this as Error<T>).code : null;
  
  /// Başarılı durumda işlem yap
  Result<R> map<R>(R Function(T) mapper) {
    if (this is Success<T>) {
      try {
        return Success(mapper((this as Success<T>).data));
      } catch (e) {
        return Error<R>(message: e.toString());
      }
    }
    return Error<R>(message: (this as Error<T>).message, code: (this as Error<T>).code);
  }
  
  /// Hatalı durumda işlem yap
  Result<T> mapError(String Function(String) mapper) {
    if (this is Error<T>) {
      return Error<T>(message: mapper((this as Error<T>).message), code: (this as Error<T>).code);
    }
    return this;
  }
  
  /// Başarılı durumda işlem yap, hatalı durumda varsayılan değer döndür
  T fold<R>(T Function(T) onSuccess, T Function(String) onError) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).data);
    }
    return onError((this as Error<T>).message);
  }
}
