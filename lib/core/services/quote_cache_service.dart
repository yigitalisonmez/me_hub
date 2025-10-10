import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'quote_service.dart';

class QuoteCacheService {
  static const String _quoteKey = 'daily_quote';
  static const String _dateKey = 'quote_date';

  /// Günlük quote'u getir (cache'den veya API'den)
  static Future<Quote?> getDailyQuote() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split(
        'T',
      )[0]; // YYYY-MM-DD
      final cachedDate = prefs.getString(_dateKey);

      // Eğer bugünün quote'u cache'de varsa onu döndür
      if (cachedDate == today) {
        final cachedQuote = prefs.getString(_quoteKey);
        if (cachedQuote != null) {
          final quoteData = json.decode(cachedQuote);
          return Quote.fromJson(quoteData);
        }
      }

      // Cache'de yoksa API'den çek ve cache'le
      final quote = await QuoteService.getTodayQuote();
      if (quote != null) {
        await _cacheQuote(quote, today);
      }

      return quote;
    } catch (e) {
      print('Quote cache error: $e');
      return null;
    }
  }

  /// Quote'u cache'le
  static Future<void> _cacheQuote(Quote quote, String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _quoteKey,
        json.encode({'q': quote.text, 'a': quote.author}),
      );
      await prefs.setString(_dateKey, date);
    } catch (e) {
      print('Quote cache save error: $e');
    }
  }

  /// Cache'i temizle
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_quoteKey);
      await prefs.remove(_dateKey);
    } catch (e) {
      print('Quote cache clear error: $e');
    }
  }
}
