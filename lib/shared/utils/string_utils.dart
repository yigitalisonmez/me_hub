/// String yardımcı fonksiyonları
class StringUtils {
  // Private constructor to prevent instantiation
  StringUtils._();

  /// String boş mu kontrol et
  static bool isEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// String dolu mu kontrol et
  static bool isNotEmpty(String? value) {
    return !isEmpty(value);
  }

  /// String'i temizle (başındaki ve sonundaki boşlukları kaldır)
  static String clean(String? value) {
    return value?.trim() ?? '';
  }

  /// String'i capitalize et (ilk harfi büyük yap)
  static String capitalize(String? value) {
    if (isEmpty(value)) return '';
    
    final cleaned = clean(value!);
    if (cleaned.isEmpty) return '';
    
    return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
  }

  /// String'i title case yap (her kelimenin ilk harfini büyük yap)
  static String titleCase(String? value) {
    if (isEmpty(value)) return '';
    
    final cleaned = clean(value!);
    if (cleaned.isEmpty) return '';
    
    return cleaned.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// String'i kısalt (belirli uzunluktan sonra ... ekle)
  static String truncate(String? value, int maxLength, {String suffix = '...'}) {
    if (isEmpty(value)) return '';
    
    final cleaned = clean(value!);
    if (cleaned.length <= maxLength) return cleaned;
    
    return cleaned.substring(0, maxLength) + suffix;
  }

  /// String'i belirli karakterle doldur
  static String padLeft(String? value, int width, {String padding = ' '}) {
    if (isEmpty(value)) return padding * width;
    
    final cleaned = clean(value!);
    if (cleaned.length >= width) return cleaned;
    
    return (padding * (width - cleaned.length)) + cleaned;
  }

  /// String'i sağdan belirli karakterle doldur
  static String padRight(String? value, int width, {String padding = ' '}) {
    if (isEmpty(value)) return padding * width;
    
    final cleaned = clean(value!);
    if (cleaned.length >= width) return cleaned;
    
    return cleaned + (padding * (width - cleaned.length));
  }

  /// String'de arama yap (case insensitive)
  static bool containsIgnoreCase(String? haystack, String? needle) {
    if (isEmpty(haystack) || isEmpty(needle)) return false;
    
    return haystack!.toLowerCase().contains(needle!.toLowerCase());
  }

  /// String'in belirli bir değerle başlayıp başlamadığını kontrol et
  static bool startsWithIgnoreCase(String? value, String? prefix) {
    if (isEmpty(value) || isEmpty(prefix)) return false;
    
    return value!.toLowerCase().startsWith(prefix!.toLowerCase());
  }

  /// String'in belirli bir değerle bitip bitmediğini kontrol et
  static bool endsWithIgnoreCase(String? value, String? suffix) {
    if (isEmpty(value) || isEmpty(suffix)) return false;
    
    return value!.toLowerCase().endsWith(suffix!.toLowerCase());
  }

  /// String'deki tüm boşlukları kaldır
  static String removeAllSpaces(String? value) {
    if (isEmpty(value)) return '';
    
    return value!.replaceAll(' ', '');
  }

  /// String'deki özel karakterleri kaldır
  static String removeSpecialCharacters(String? value) {
    if (isEmpty(value)) return '';
    
    return value!.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
  }

  /// String'i ters çevir
  static String reverse(String? value) {
    if (isEmpty(value)) return '';
    
    return value!.split('').reversed.join('');
  }

  /// String'deki kelime sayısını hesapla
  static int wordCount(String? value) {
    if (isEmpty(value)) return 0;
    
    final cleaned = clean(value!);
    if (cleaned.isEmpty) return 0;
    
    return cleaned.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  /// String'deki karakter sayısını hesapla (boşluklar dahil)
  static int characterCount(String? value) {
    return value?.length ?? 0;
  }

  /// String'deki karakter sayısını hesapla (boşluklar hariç)
  static int characterCountWithoutSpaces(String? value) {
    if (isEmpty(value)) return 0;
    
    return value!.replaceAll(' ', '').length;
  }

  /// String'i belirli karakterle böl
  static List<String> split(String? value, String delimiter) {
    if (isEmpty(value)) return [];
    
    return value!.split(delimiter);
  }

  /// String'deki belirli karakterleri değiştir
  static String replace(String? value, String from, String to) {
    if (isEmpty(value)) return '';
    
    return value!.replaceAll(from, to);
  }

  /// String'deki ilk karakteri büyük harf yap
  static String capitalizeFirst(String? value) {
    if (isEmpty(value)) return '';
    
    final cleaned = clean(value!);
    if (cleaned.isEmpty) return '';
    
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  /// String'deki son karakteri büyük harf yap
  static String capitalizeLast(String? value) {
    if (isEmpty(value)) return '';
    
    final cleaned = clean(value!);
    if (cleaned.isEmpty) return '';
    
    return cleaned.substring(0, cleaned.length - 1) + cleaned[cleaned.length - 1].toUpperCase();
  }

  /// String'in sadece rakam içerip içermediğini kontrol et
  static bool isNumeric(String? value) {
    if (isEmpty(value)) return false;
    
    return RegExp(r'^\d+$').hasMatch(value!);
  }

  /// String'in sadece harf içerip içermediğini kontrol et
  static bool isAlpha(String? value) {
    if (isEmpty(value)) return false;
    
    return RegExp(r'^[a-zA-Z]+$').hasMatch(value!);
  }

  /// String'in harf ve rakam içerip içermediğini kontrol et
  static bool isAlphaNumeric(String? value) {
    if (isEmpty(value)) return false;
    
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value!);
  }

  /// String'i belirli uzunlukta parçalara böl
  static List<String> chunk(String? value, int size) {
    if (isEmpty(value)) return [];
    
    final cleaned = clean(value!);
    if (cleaned.isEmpty) return [];
    
    final List<String> chunks = [];
    for (int i = 0; i < cleaned.length; i += size) {
      chunks.add(cleaned.substring(i, i + size > cleaned.length ? cleaned.length : i + size));
    }
    
    return chunks;
  }
}
