class NotificationData {
  final String title;
  final String description;
  final DateTime time;
  final DateTime date;

  NotificationData({
    required this.title,
    required this.description,
    required this.time,
    required this.date,
  });

  // Factory method untuk membuat objek NotificationData dari JSON API
  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      title: json['title'] ?? 'Notifikasi',
      description: json['desc'] ?? 'Tidak ada deskripsi',
      time:
          json['time'] != null ? DateTime.parse(json['time']) : DateTime.now(),
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }
}
