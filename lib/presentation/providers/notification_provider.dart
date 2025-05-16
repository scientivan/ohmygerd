import 'package:flutter/foundation.dart';
import 'package:OhMyGERD/data/models/notification_data.dart';

class NotificationProvider extends ChangeNotifier {
  final List<NotificationData> _notifications = [];

  List<NotificationData> get notifications => List.unmodifiable(_notifications);

  /// Menambahkan notifikasi baru ke daftar
  void addNotification(NotificationData notification) {
    _notifications.add(notification);
    notifyListeners();
  }

  /// Menghapus semua notifikasi yang ada
  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  /// Menghapus notifikasi pada indeks tertentu
  void removeNotificationAt(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications.removeAt(index);
      notifyListeners();
    }
  }

  /// Bulk add notifications without notifying on each add
  void addNotifications(List<NotificationData> notifications) {
    if (notifications.isEmpty) return;

    _notifications.addAll(notifications);
    notifyListeners();
  }
}
