/// Form doğrulama yardımcıları
class Validators {
  // Private constructor to prevent instantiation
  Validators._();

  /// Email doğrulama
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email adresi gerekli';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir email adresi girin';
    }
    
    return null;
  }

  /// Şifre doğrulama
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }
    
    if (value.length < 8) {
      return 'Şifre en az 8 karakter olmalı';
    }
    
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$');
    if (!passwordRegex.hasMatch(value)) {
      return 'Şifre en az bir küçük harf, bir büyük harf ve bir rakam içermeli';
    }
    
    return null;
  }

  /// Basit şifre doğrulama (minimum 6 karakter)
  static String? simplePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }
    
    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }
    
    return null;
  }

  /// Telefon numarası doğrulama
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefon numarası gerekli';
    }
    
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', '').replaceAll('-', ''))) {
      return 'Geçerli bir telefon numarası girin';
    }
    
    return null;
  }

  /// Ad doğrulama
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ad gerekli';
    }
    
    if (value.length < 2) {
      return 'Ad en az 2 karakter olmalı';
    }
    
    if (value.length > 50) {
      return 'Ad en fazla 50 karakter olabilir';
    }
    
    return null;
  }

  /// Boş alan doğrulama
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Bu alan'} gerekli';
    }
    return null;
  }

  /// Minimum uzunluk doğrulama
  static String? minLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Bu alan'} gerekli';
    }
    
    if (value.length < minLength) {
      return '${fieldName ?? 'Bu alan'} en az $minLength karakter olmalı';
    }
    
    return null;
  }

  /// Maksimum uzunluk doğrulama
  static String? maxLength(String? value, int maxLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null; // Boş alan için başka validator kullan
    }
    
    if (value.length > maxLength) {
      return '${fieldName ?? 'Bu alan'} en fazla $maxLength karakter olabilir';
    }
    
    return null;
  }

  /// Sayı doğrulama
  static String? number(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Bu alan'} gerekli';
    }
    
    if (double.tryParse(value) == null) {
      return '${fieldName ?? 'Bu alan'} sayı olmalı';
    }
    
    return null;
  }

  /// Pozitif sayı doğrulama
  static String? positiveNumber(String? value, {String? fieldName}) {
    final numberError = number(value, fieldName: fieldName);
    if (numberError != null) return numberError;
    
    if (double.parse(value!) <= 0) {
      return '${fieldName ?? 'Bu alan'} pozitif bir sayı olmalı';
    }
    
    return null;
  }

  /// URL doğrulama
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL gerekli';
    }
    
    final urlRegex = RegExp(r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$');
    if (!urlRegex.hasMatch(value)) {
      return 'Geçerli bir URL girin';
    }
    
    return null;
  }
}
