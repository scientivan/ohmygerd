import 'dart:async';

import 'package:geolocator/geolocator.dart';

class UserLocation {
  /// Mendapatkan lokasi saat ini dengan penanganan izin dan error yang komprehensif
  Future<Position?> getCurrentLocation() async {
    try {
      // Cek apakah layanan lokasi aktif
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showLocationServiceAlert();
        return null;
      }

      // Cek dan minta izin lokasi
      LocationPermission permission = await _checkAndRequestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // Ambil posisi dengan timeout dan akurasi tinggi
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print(
        'Lokasi berhasil didapatkan: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } catch (e) {
      _handleLocationError(e);
      return null;
    }
  }

  /// Memeriksa dan meminta izin lokasi
  Future<LocationPermission> _checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        print('Izin lokasi ditolak.');
        return LocationPermission.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Izin lokasi ditolak permanen.');
      return LocationPermission.deniedForever;
    }

    return permission;
  }

  /// Menampilkan pesan alert untuk mengaktifkan layanan lokasi
  Future<void> _showLocationServiceAlert() async {
    print(
      'Layanan lokasi tidak aktif. Silakan aktifkan di pengaturan perangkat.',
    );
    // Anda bisa mengimplementasikan dialog atau navigasi ke pengaturan sistem di sini
    // Contoh menggunakan app_settings package:
    // await AppSettings.openLocationSettings();
  }

  /// Menangani error yang terkait dengan lokasi
  void _handleLocationError(dynamic error) {
    if (error is PermissionDeniedException) {
      print('Izin lokasi ditolak: ${error.message}');
    } else if (error is LocationServiceDisabledException) {
      print('Layanan lokasi dinonaktifkan');
    } else if (error is TimeoutException) {
      print('Timeout saat mendapatkan lokasi');
    } else {
      print('Error tidak dikenal saat mendapatkan lokasi: $error');
    }
  }
}

// Contoh penggunaan
void main() async {
  UserLocation userLocation = UserLocation();

  Position? currentPosition = await userLocation.getCurrentLocation();

  if (currentPosition != null) {
    print('Latitude: ${currentPosition.latitude}');
    print('Longitude: ${currentPosition.longitude}');
    print('Akurasi: ${currentPosition.accuracy}');
    print('Ketinggian: ${currentPosition.altitude}');
  }
}
