import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:OhMyGERD/presentation/components/activity_card.dart'; 

class MealActivityProvider extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _initialized = false;
  static const String _lastResetDateKey = 'lastMealResetDate';
  static const String _firstLaunchDateKey = 'firstLaunchDate';
  bool _isDayChanged = false;

  bool get isDayChanged => _isDayChanged;

  MealActivityProvider() {
    _loadSavedStatus();
  }

  ActivityStatus _breakfastStatus = ActivityStatus.inactive;
  ActivityStatus _lunchStatus = ActivityStatus.inactive;
  ActivityStatus _dinnerStatus = ActivityStatus.inactive;

  ActivityStatus get breakfastStatus => _breakfastStatus;
  ActivityStatus get lunchStatus => _lunchStatus;
  ActivityStatus get dinnerStatus => _dinnerStatus;
  bool get isInitialized => _initialized;

  Future<void> _loadSavedStatus() async {
    _prefs = await SharedPreferences.getInstance();

    if (!_prefs!.containsKey(_firstLaunchDateKey)) {
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      await _prefs!.setString(_firstLaunchDateKey, todayStr);
    }

    _isDayChanged = await _checkAndResetIfNewDay();

    if (_prefs!.containsKey('breakfastStatus')) {
      _breakfastStatus =
          ActivityStatus.values[_prefs!.getInt('breakfastStatus') ?? 0];
    }
    if (_prefs!.containsKey('lunchStatus')) {
      _lunchStatus = ActivityStatus.values[_prefs!.getInt('lunchStatus') ?? 0];
    }
    if (_prefs!.containsKey('dinnerStatus')) {
      _dinnerStatus =
          ActivityStatus.values[_prefs!.getInt('dinnerStatus') ?? 0];
    }

    _initialized = true;
    updateMealStatuses();
    notifyListeners();
  }

  Future<bool> _checkAndResetIfNewDay() async {
    if (_prefs == null) return false;

    final String? lastResetDateStr = _prefs!.getString(_lastResetDateKey);
    final DateTime now = DateTime.now();

    final String todayDateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    print(
      'Last reset date: $lastResetDateStr, Today: $todayDateStr',
    );

    if (lastResetDateStr == null || lastResetDateStr != todayDateStr) {
      print('Resetting meals for new day'); 

      _breakfastStatus = ActivityStatus.inactive;
      _lunchStatus = ActivityStatus.inactive;
      _dinnerStatus = ActivityStatus.inactive;

      await _prefs!.setInt('breakfastStatus', ActivityStatus.inactive.index);
      await _prefs!.setInt('lunchStatus', ActivityStatus.inactive.index);
      await _prefs!.setInt('dinnerStatus', ActivityStatus.inactive.index);

      await _prefs!.setString(_lastResetDateKey, todayDateStr);

      notifyListeners();

      return true;
    }
    return false;
  }

  Future<bool> checkForDayReset() async {
    return await _checkAndResetIfNewDay();
  }



  Future<void> _saveStatus() async {
    if (_prefs == null) return; // Guard clause jika preferences belum ready

    // Simpan status untuk setiap waktu makan
    await _prefs!.setInt('breakfastStatus', _breakfastStatus.index);
    await _prefs!.setInt('lunchStatus', _lunchStatus.index);
    await _prefs!.setInt('dinnerStatus', _dinnerStatus.index);

    // Save current date as last reset date if it hasn't been set
    if (!_prefs!.containsKey(_lastResetDateKey)) {
      final now = DateTime.now();
      await _prefs!.setString(
        _lastResetDateKey,
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
      );
    }
  }

  // Check if this is first launch of the day
  Future<bool> isFirstLaunchOfDay() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }

    final String? firstLaunchDate = _prefs!.getString(_firstLaunchDateKey);
    final String? lastResetDate = _prefs!.getString(_lastResetDateKey);

    // If first launch date equals last reset date, then it's not the first launch of a new day
    return firstLaunchDate != lastResetDate;
  }

  // Update status berdasarkan waktu sekarang
  void updateMealStatuses() {
    if (!_initialized) return; // Skip if not initialized yet

    // First check if we need to reset for a new day
    _checkAndResetIfNewDay().then((wasReset) {
      // Only update times if a reset didn't just happen, or always update
      // but with respect to the most current status values
      final now = DateTime.now();
      final currentHour = now.hour;

      print('Updating meal statuses at hour: $currentHour'); // Debug log

      // Only update active/inactive states - don't change success states except on day change
      if (!wasReset) {
        // Breakfast time check
        if (currentHour >= 5 && currentHour < 9) {
          if (_breakfastStatus != ActivityStatus.success) {
            _breakfastStatus = ActivityStatus.active;
          }
        } else if (_breakfastStatus != ActivityStatus.success) {
          _breakfastStatus = ActivityStatus.inactive;
        }

        // Lunch time check
        if (currentHour >= 11 && currentHour < 15) {
          if (_lunchStatus != ActivityStatus.success) {
            _lunchStatus = ActivityStatus.active;
          }
        } else if (_lunchStatus != ActivityStatus.success) {
          _lunchStatus = ActivityStatus.inactive;
        }

        // Dinner time check
        if (currentHour >= 17 && currentHour < 21) {
          if (_dinnerStatus != ActivityStatus.success) {
            _dinnerStatus = ActivityStatus.active;
          }
        } else if (_dinnerStatus != ActivityStatus.success) {
          _dinnerStatus = ActivityStatus.inactive;
        }

        _saveStatus(); // Save updated statuses
      }

      notifyListeners(); // Notify listeners

      print(
        'Status updated - Breakfast: $_breakfastStatus, Lunch: $_lunchStatus, Dinner: $_dinnerStatus',
      );
    });
  }

  void completeMeal(String mealTime) {
    print('Completing meal: $mealTime'); // Debug log

    if (mealTime == 'breakfast') {
      _breakfastStatus = ActivityStatus.success;
    } else if (mealTime == 'lunch') {
      _lunchStatus = ActivityStatus.success;
    } else if (mealTime == 'dinner') {
      _dinnerStatus = ActivityStatus.success;
    }

    // Always save and notify after changes
    _saveStatus();
    notifyListeners();

    // Add additional debug to help trace the issue
    print(
      'Status after completion - Breakfast: $_breakfastStatus, Lunch: $_lunchStatus, Dinner: $_dinnerStatus',
    );
  }

  // To force reset
  void _resetAllMeals() {
    _breakfastStatus = ActivityStatus.inactive;
    _lunchStatus = ActivityStatus.inactive;
    _dinnerStatus = ActivityStatus.inactive;
    _saveStatus();
  }

  // Debug
  Future<void> manualResetForDebug() async {
    if (_prefs == null) return;

    // Reset semua status ke inactive dulu
    _breakfastStatus = ActivityStatus.inactive;
    _lunchStatus = ActivityStatus.inactive;
    _dinnerStatus = ActivityStatus.inactive;

    // Simpan ke SharedPreferences
    await _prefs!.setInt('breakfastStatus', _breakfastStatus.index);
    await _prefs!.setInt('lunchStatus', _lunchStatus.index);
    await _prefs!.setInt('dinnerStatus', _dinnerStatus.index);

    // Update tanggal reset
    final now = DateTime.now();
    await _prefs!.setString(
      _lastResetDateKey,
      "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
    );

    // Update status sesuai waktu sekarang
    updateMealStatuses(); // <-- ini dia kuncinya bro

    notifyListeners();
    print(
      'DEBUG: Meal statuses manually reset and updated based on current time',
    );
  }

  Future<void> debugDateReset() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }

    final String? lastResetDateStr = _prefs!.getString(_lastResetDateKey);
    final DateTime now = DateTime.now();
    final String todayDateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    print('DEBUG - Last reset: $lastResetDateStr, Today: $todayDateStr');
    print('Would reset? ${lastResetDateStr != todayDateStr}');

    // Also print all meal statuses
    print(
      'Breakfast: $_breakfastStatus (${_prefs!.getInt('breakfastStatus')})',
    );
    print('Lunch: $_lunchStatus (${_prefs!.getInt('lunchStatus')})');
    print('Dinner: $_dinnerStatus (${_prefs!.getInt('dinnerStatus')})');
  }

  // Method untuk debug - print semua info status
  void printDebugInfo() {
    if (_prefs == null) {
      print('DEBUG ERROR: SharedPreferences not initialized');
      return;
    }

    final String? lastResetDate = _prefs!.getString(_lastResetDateKey);
    final String? firstLaunchDate = _prefs!.getString(_firstLaunchDateKey);
    final int? breakfastVal = _prefs!.getInt('breakfastStatus');
    final int? lunchVal = _prefs!.getInt('lunchStatus');
    final int? dinnerVal = _prefs!.getInt('dinnerStatus');

    print('DEBUG INFO - Meal Activity:');
    print('First Launch Date: $firstLaunchDate');
    print('Last Reset Date: $lastResetDate');
    print('Is Day Changed: $_isDayChanged');
    print('Breakfast Status: $_breakfastStatus (stored value: $breakfastVal)');
    print('Lunch Status: $_lunchStatus (stored value: $lunchVal)');
    print('Dinner Status: $_dinnerStatus (stored value: $dinnerVal)');
    print('Is Initialized: $_initialized');
  }

  // Update first launch date to match reset date
  // Call this after showing the daily form
  Future<void> markDailyFormShown() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }

    final String? lastResetDate = _prefs!.getString(_lastResetDateKey);
    if (lastResetDate != null) {
      await _prefs!.setString(_firstLaunchDateKey, lastResetDate);
    }
  }
    Future<void> debugDateAndResetInfo() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }

    final String? lastResetDateStr = _prefs!.getString(_lastResetDateKey);
    final DateTime now = DateTime.now();
    final String todayDateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    print('DEBUG - Last reset: $lastResetDateStr, Today: $todayDateStr');
    print('Would reset? ${lastResetDateStr != todayDateStr}');

    // Also print all meal statuses
    print(
      'Breakfast: $_breakfastStatus (${_prefs!.getInt('breakfastStatus')})',
    );
    print('Lunch: $_lunchStatus (${_prefs!.getInt('lunchStatus')})');
    print('Dinner: $_dinnerStatus (${_prefs!.getInt('dinnerStatus')})');
  }
}
