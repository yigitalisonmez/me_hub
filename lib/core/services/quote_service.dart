import 'dart:convert';
import 'package:http/http.dart' as http;

class Quote {
  final String text;
  final String author;

  Quote({required this.text, required this.author});

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(text: json['q'] ?? '', author: json['a'] ?? '');
  }
}

class QuoteService {
  static const String _baseUrl = 'https://zenquotes.io/api';

  /// Günlük quote'u getir
  static Future<Quote?> getTodayQuote() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/today'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return Quote.fromJson(data[0]);
        }
      }
      return null;
    } catch (e) {
      print('Quote API Error: $e');
      return null;
    }
  }

  /// Rastgele quote getir
  static Future<Quote?> getRandomQuote() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/random'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return Quote.fromJson(data[0]);
        }
      }
      return null;
    } catch (e) {
      print('Quote API Error: $e');
      return null;
    }
  }
}
