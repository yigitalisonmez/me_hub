import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/quick_add_amount.dart';

class QuickAddAmountsService {
  static const String _key = 'water_quick_add_amounts';

  // Default quick add amounts
  static const List<QuickAddAmount> defaultAmounts = [
    QuickAddAmount(amountMl: 250, label: '1 Glass'),
    QuickAddAmount(amountMl: 500, label: '1 Bottle'),
    QuickAddAmount(amountMl: 1000, label: '1 Liter'),
  ];

  /// Get all quick add amounts (default + custom)
  static Future<List<QuickAddAmount>> getQuickAddAmounts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) {
      // Return defaults if nothing is saved
      return List.from(defaultAmounts);
    }

    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded
          .map((e) => QuickAddAmount.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return List.from(defaultAmounts);
    }
  }

  /// Save quick add amounts
  static Future<void> saveQuickAddAmounts(List<QuickAddAmount> amounts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(amounts.map((a) => a.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  /// Add a quick add amount
  static Future<void> addQuickAddAmount(QuickAddAmount amount) async {
    // Validation: Amount must be positive and reasonable
    if (amount.amountMl <= 0 || amount.amountMl > 5000) {
      return;
    }

    final amounts = await getQuickAddAmounts();
    // Check if amount already exists
    if (!amounts.any((a) => a.amountMl == amount.amountMl)) {
      amounts.add(amount);
      amounts.sort((a, b) => a.amountMl.compareTo(b.amountMl));
      await saveQuickAddAmounts(amounts);
    }
  }

  /// Remove a quick add amount
  static Future<void> removeQuickAddAmount(int amountMl) async {
    final amounts = await getQuickAddAmounts();
    amounts.removeWhere((a) => a.amountMl == amountMl);
    await saveQuickAddAmounts(amounts);
  }

  /// Update a quick add amount
  static Future<void> updateQuickAddAmount(
    int oldAmountMl,
    QuickAddAmount newAmount,
  ) async {
    // Validation: Amount must be positive and reasonable
    if (newAmount.amountMl <= 0 || newAmount.amountMl > 5000) {
      return;
    }

    final amounts = await getQuickAddAmounts();
    final index = amounts.indexWhere((a) => a.amountMl == oldAmountMl);
    if (index != -1) {
      amounts[index] = newAmount;
      amounts.sort((a, b) => a.amountMl.compareTo(b.amountMl));
      await saveQuickAddAmounts(amounts);
    }
  }
}
