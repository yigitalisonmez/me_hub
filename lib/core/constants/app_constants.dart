/// Me Hub uygulaması için global sabitler
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // Uygulama bilgileri
  static const String appName = 'Me Hub';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'All-in-one personal tracking app';

  // API sabitleri
  static const String baseUrl = 'https://api.mehub.com';
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Local storage anahtarları
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';

  // Animasyon süreleri
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // UI sabitleri
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultRadius = 8.0;
  static const double smallRadius = 4.0;
  static const double largeRadius = 16.0;

  // Sayfa boyutları
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Dosya boyut limitleri
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB

  // Regex patterns
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^\+?[1-9]\d{1,14}$';
  static const String passwordPattern = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$';

  // Hata mesajları
  static const String networkErrorMessage = 'İnternet bağlantınızı kontrol edin';
  static const String serverErrorMessage = 'Sunucu hatası oluştu';
  static const String unknownErrorMessage = 'Bilinmeyen bir hata oluştu';
  static const String timeoutErrorMessage = 'İstek zaman aşımına uğradı';
}
