import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CustomAmountService {
  static const String _key = 'water_custom_amounts';

  /// Get all custom amounts
  static Future<List<int>> getCustomAmounts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.map((e) => e as int).toList();
    } catch (e) {
      return [];
    }
  }

  /// Add a custom amount
  static Future<void> addCustomAmount(int amount) async {
    final amounts = await getCustomAmounts();
    if (!amounts.contains(amount)) {
      amounts.add(amount);
      amounts.sort(); // Sort ascending
      await _saveCustomAmounts(amounts);
    }
  }

  /// Remove a custom amount
  static Future<void> removeCustomAmount(int amount) async {
    final amounts = await getCustomAmounts();
    amounts.remove(amount);
    await _saveCustomAmounts(amounts);
  }

  /// Save custom amounts
  static Future<void> _saveCustomAmounts(List<int> amounts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(amounts);
    await prefs.setString(_key, jsonString);
  }
}

