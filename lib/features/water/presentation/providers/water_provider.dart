import 'package:flutter/foundation.dart';
import '../../domain/entities/water_intake.dart';
import '../../domain/usecases/usecases.dart';

class WaterProvider with ChangeNotifier {
  final GetTodayWaterIntake _getTodayWaterIntake;
  final AddWater _addWater;
  final RemoveLastLog _removeLastLog;
  final GetWaterHistory _getWaterHistory;

  WaterProvider({
    required GetTodayWaterIntake getTodayWaterIntake,
    required AddWater addWater,
    required RemoveLastLog removeLastLog,
    required GetWaterHistory getWaterHistory,
  })  : _getTodayWaterIntake = getTodayWaterIntake,
        _addWater = addWater,
        _removeLastLog = removeLastLog,
        _getWaterHistory = getWaterHistory;

  WaterIntake? _todayIntake;
  List<WaterIntake> _history = [];
  bool _isLoading = false;
  String? _error;

  WaterIntake? get todayIntake => _todayIntake;
  List<WaterIntake> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get today's water intake amount
  int get todayAmount => _todayIntake?.amountMl ?? 0;

  /// Get today's progress (0.0 to 1.0)
  double get todayProgress => _todayIntake?.getProgress() ?? 0.0;

  /// Check if today's goal is reached
  bool get isGoalReached => _todayIntake?.isGoalReached() ?? false;

  /// Load today's water intake
  Future<void> loadTodayWaterIntake() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todayIntake = await _getTodayWaterIntake();
    } catch (e) {
      _error = 'Failed to load water intake';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add water amount
  Future<void> addWaterAmount(int amountMl) async {
    try {
      await _addWater(DateTime.now(), amountMl);
      await loadTodayWaterIntake();
    } catch (e) {
      _error = 'Failed to add water';
      notifyListeners();
    }
  }

  /// Remove last water log (undo)
  Future<void> undoLastLog() async {
    if (_todayIntake == null || _todayIntake!.logs.isEmpty) return;

    try {
      await _removeLastLog(DateTime.now());
      await loadTodayWaterIntake();
    } catch (e) {
      _error = 'Failed to undo';
      notifyListeners();
    }
  }

  /// Load water history
  Future<void> loadHistory({int days = 7}) async {
    try {
      _history = await _getWaterHistory(days);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load history';
      notifyListeners();
    }
  }
}

