import 'package:intl/intl.dart';

/// Tarih ve zaman yardımcı fonksiyonları
class DateUtils {
  // Private constructor to prevent instantiation
  DateUtils._();

  /// Şu anki tarih ve zaman
  static DateTime get now => DateTime.now();

  /// Bugünün tarihi (sadece tarih, saat 00:00:00)
  static DateTime get today => DateTime(now.year, now.month, now.day);

  /// Dünün tarihi
  static DateTime get yesterday => today.subtract(const Duration(days: 1));

  /// Yarının tarihi
  static DateTime get tomorrow => today.add(const Duration(days: 1));

  /// Bu haftanın başlangıcı (Pazartesi)
  static DateTime get startOfWeek {
    final now = DateTime.now();
    final weekday = now.weekday;
    return now.subtract(Duration(days: weekday - 1));
  }

  /// Bu haftanın sonu (Pazar)
  static DateTime get endOfWeek {
    return startOfWeek.add(const Duration(days: 6));
  }

  /// Bu ayın başlangıcı
  static DateTime get startOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Bu ayın sonu
  static DateTime get endOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0);
  }

  /// Bu yılın başlangıcı
  static DateTime get startOfYear {
    final now = DateTime.now();
    return DateTime(now.year, 1, 1);
  }

  /// Bu yılın sonu
  static DateTime get endOfYear {
    final now = DateTime.now();
    return DateTime(now.year, 12, 31);
  }

  /// Tarihi formatla
  static String formatDate(DateTime date, {String pattern = 'dd/MM/yyyy'}) {
    return DateFormat(pattern).format(date);
  }

  /// Saati formatla
  static String formatTime(DateTime date, {String pattern = 'HH:mm'}) {
    return DateFormat(pattern).format(date);
  }

  /// Tarih ve saati formatla
  static String formatDateTime(
    DateTime date, {
    String pattern = 'dd/MM/yyyy HH:mm',
  }) {
    return DateFormat(pattern).format(date);
  }

  /// Göreceli tarih formatı (örn: "2 gün önce", "1 hafta önce")
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Şimdi';
        }
        return '${difference.inMinutes} dakika önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks hafta önce';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ay önce';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years yıl önce';
    }
  }

  /// İki tarih arasındaki farkı hesapla
  static Duration difference(DateTime from, DateTime to) {
    return to.difference(from);
  }

  /// Tarih aralığı oluştur
  static List<DateTime> generateDateRange(DateTime start, DateTime end) {
    final List<DateTime> dates = [];
    DateTime current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  /// Hafta günü adını al
  static String getWeekdayName(DateTime date) {
    const weekdays = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return weekdays[date.weekday - 1];
  }

  /// Ay adını al
  static String getMonthName(DateTime date) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return months[date.month - 1];
  }

  /// Yaş hesapla
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  /// Tarih geçerli mi kontrol et
  static bool isValidDate(int year, int month, int day) {
    try {
      DateTime(year, month, day);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Tarih karşılaştır
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Tarih bu hafta içinde mi
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Tarih bu ay içinde mi
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Tarih bu yıl içinde mi
  static bool isThisYear(DateTime date) {
    return date.year == DateTime.now().year;
  }
}
