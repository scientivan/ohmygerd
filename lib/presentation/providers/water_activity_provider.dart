import 'dart:async';
import 'package:OhMyGERD/data/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../data/services/be_service.dart';

class WaterActivityProvider extends ChangeNotifier {
  double _weight = 60;
  String _gender = "Laki-Laki";
  double _currentVolume = 0;
  double _maxVolume = 0;
  bool _isLoading = true;

  double get weight => _weight;
  String get gender => _gender;
  double get currentVolume => _currentVolume;
  double get maxVolume => _maxVolume;
  double get percent => _maxVolume == 0 ? 0 : _currentVolume / _maxVolume;
  bool get isLoading => _isLoading;

  Timer? _resetTimer;
  late SharedPreferences _prefs;
  static const String _lastResetDateKey = 'lastResetDate';
  static const String _maxVolumeKey = 'maxVolume';
  static const String _weightKey = 'weight';
  static const String _genderKey = 'gender';
  static const String _currentVolumeKey = 'currentVolume';

  final _auth = FirebaseAuth.instance;
  final backendService = BackendService();
  final authService = AuthService();

  // Constructor untuk memuat data
  WaterActivityProvider() {
    _initializeData();
  }

  // Inisialisasi data dengan async-await
  Future<void> _initializeData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Inisialisasi SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // Load data dari Firebase jika user sudah login
      await _loadUserDataFromFirebase();

      // Cek apakah perlu reset berdasarkan tanggal
      await _checkAndResetIfNewDay();

      // Mulai timer untuk reset harian
      _startDailyResetTimer();
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load data user dari Firebase
  Future<void> _loadUserDataFromFirebase() async {
    final user = _auth.currentUser;

    if (user != null) {
      try {
        // Ambil data profil dari Firebase melalui AuthService
        final userData = await authService.getProfileData(user);

        if (userData != null) {
          // Update nilai weight dan gender dari Firebase
          _weight = userData['weight']?.toDouble() ?? 60.0;
          _gender = userData['gender'] ?? "Laki-Laki";

          // Simpan ke SharedPreferences untuk backup
          await _prefs.setDouble(_weightKey, _weight);
          await _prefs.setString(_genderKey, _gender);

          print(
            'Data loaded from Firebase - Weight: $_weight, Gender: $_gender',
          );
        } else {
          // Jika tidak ada data di Firebase, load dari SharedPreferences
          _loadFromSharedPreferences();
        }
      } catch (e) {
        print('Error loading data from Firebase: $e');
        // Fallback ke SharedPreferences jika gagal load dari Firebase
        _loadFromSharedPreferences();
      }
    } else {
      // Jika user belum login, load dari SharedPreferences
      _loadFromSharedPreferences();
    }

    // Hitung max volume berdasarkan data yang telah diload
    _calculateMaxVolume();

    // Load current volume
    final storedVolume = _prefs.get(_currentVolumeKey);
    if (storedVolume is double) {
      _currentVolume = storedVolume;
    } else {
      _currentVolume = 0.0;
    }
  }

  // Load data dari SharedPreferences sebagai fallback
  void _loadFromSharedPreferences() {
    _weight = _prefs.getDouble(_weightKey) ?? 60.0;
    _gender = _prefs.getString(_genderKey) ?? "Laki-Laki";
    print(
      'Data loaded from SharedPreferences - Weight: $_weight, Gender: $_gender',
    );
  }

  // Menghitung konsumsi air maksimum berdasarkan weight dan gender
  void _calculateMaxVolume() {
    if (_gender == "Laki-Laki") {
      _maxVolume = 35 * _weight;
    } else {
      _maxVolume = 31 * _weight;
    }

    // Simpan max volume ke SharedPreferences
    _prefs.setDouble(_maxVolumeKey, _maxVolume);
    print('Max volume calculated: $_maxVolume ml');
  }

  // Method untuk mengupdate data dari UI (jika diperlukan)
  Future<void> updateUserData(double weight, String gender) async {
    _weight = weight;
    _gender = gender;

    // Simpan ke SharedPreferences
    await _prefs.setDouble(_weightKey, weight);
    await _prefs.setString(_genderKey, gender);

    // Hitung ulang max volume
    _calculateMaxVolume();

    // Jika user login, update ke Firebase juga
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Asumsikan ada method updateProfileData di AuthService
        await authService.updateProfileData(user, {
          'weight': weight,
          'gender': gender,
        });
        print('User data updated in Firebase');
      } catch (e) {
        print('Error updating data in Firebase: $e');
      }
    }

    notifyListeners();
  }

  // Refresh data dari Firebase (bisa dipanggil setelah login atau update profil)
  Future<void> refreshUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUserDataFromFirebase();
      notifyListeners();
    }
  }

  // Cek jika hari ini sudah reset atau belum
  Future<bool> _checkAndResetIfNewDay() async {
    final String? lastResetDateStr = _prefs.getString(_lastResetDateKey);
    final DateTime now = DateTime.now();
    final String todayDateStr = "${now.year}-${now.month}-${now.day}";

    // Jika tidak ada tanggal reset atau tanggal reset berbeda dengan hari ini
    if (lastResetDateStr == null || lastResetDateStr != todayDateStr) {
      // Reset volume air
      _currentVolume = 0;
      await _prefs.setDouble(_currentVolumeKey, 0.0);

      // Update tanggal reset terakhir
      await _prefs.setString(_lastResetDateKey, todayDateStr);
      return true;
    }
    return false;
  }

  // Menambahkan air ke volume saat ini
  Future<void> addWater(double amount) async {
    _currentVolume += amount;

    // Cek apakah sudah mencapai target
    if (_currentVolume >= _maxVolume) {
      final user = _auth.currentUser;
      if (user != null) {
        final now = DateTime.now();
        final date = DateFormat('yyyy-MM-dd').format(now);
        await backendService.sendIsDrinkStatusIsTrue(user, date);
        print('Daily water goal achieved! Status updated in backend.');
      }
    }

    // Save data setelah perubahan volume
    await _prefs.setDouble(_currentVolumeKey, _currentVolume);
    notifyListeners();
  }

  // Timer reset volume setiap hari pada tengah malam
  void _startDailyResetTimer() {
    // Hitung waktu hingga tengah malam
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    // Cancel timer sebelumnya dan buat timer baru
    _resetTimer?.cancel();
    _resetTimer = Timer(timeUntilMidnight, () {
      _resetVolume();
      // Simpan tanggal reset setelah reset volume
      _prefs.setString(
        _lastResetDateKey,
        "${tomorrow.year}-${tomorrow.month}-${tomorrow.day}",
      );
    });
  }

  // Reset volume air
  void _resetVolume() {
    _currentVolume = 0;
    _prefs.setDouble(_currentVolumeKey, 0.0);
    notifyListeners();
    _startDailyResetTimer(); // Setel timer untuk besok
  }

  // Method untuk reset manual, bisa dipanggil dari UI
  Future<void> manualResetForDebug() async {
    _currentVolume = 0;
    await _prefs.setDouble(_currentVolumeKey, 0.0);

    // Reset tanggal juga
    final now = DateTime.now();
    await _prefs.setString(
      _lastResetDateKey,
      "${now.year}-${now.month}-${now.day}",
    );

    notifyListeners();
    print('DEBUG: Water volume manually reset to 0');
  }

  // Debug - print informasi status saat ini
  void printDebugInfo() {
    final String? lastResetDate = _prefs.getString(_lastResetDateKey);
    print('DEBUG INFO - Water Activity:');
    print('Weight: $_weight, Gender: $_gender');
    print('Current Volume: $_currentVolume / $_maxVolume');
    print('Percent: ${percent * 100}%');
    print('Last Reset Date: $lastResetDate');
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }
}
