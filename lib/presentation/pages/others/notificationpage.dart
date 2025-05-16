import 'package:OhMyGERD/data/services/be_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:OhMyGERD/data/models/notification_data.dart';
import 'package:OhMyGERD/presentation/components/custom_appbar.dart';
import 'package:OhMyGERD/presentation/components/notification_card.dart';
import 'package:OhMyGERD/presentation/providers/notification_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final backendService = BackendService();
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndSaveNotifications();
  }

  /// Fungsi untuk memuat notifikasi dari API dan menyimpannya ke provider
  Future<void> _loadAndSaveNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (user != null) {
        // Mendapatkan data notifikasi dari API
        final result = await backendService.loadNotificationInApps(user!);
        if (result != null && mounted) {
          // Akses provider untuk menyimpan notifikasi
          final notifProvider = Provider.of<NotificationProvider>(
            context,
            listen: false,
          );

          // Hapus notifikasi lama jika ada
          notifProvider.clearNotifications();

          // Konversi hasil API menjadi NotificationData dan simpan ke provider
          List<NotificationData> notificationsList = [];

          for (var item in result) {
            print(item);
            // Pastikan item adalah Map<String, dynamic>
            if (item is Map<String, dynamic>) {
              try {
                final timeString = item['time'] ?? '';
                final dateString = item['date'] ?? '';

                DateTime timeDateTime = DateTime.now();
                DateTime dateDateTime = DateTime.now();

                try {
                  timeDateTime = DateFormat("HH-mm-ss").parse(timeString);
                } catch (_) {
                  print("Gagal parsing time: $timeString");
                }

                try {
                  dateDateTime = DateFormat("dd-MM-yyyy").parse(dateString);
                } catch (_) {
                  print("Gagal parsing date: $dateString");
                }

                final notifData = NotificationData(
                  title: item['title'] ?? 'Notifikasi',
                  description: item['desc'] ?? 'Tidak ada deskripsi',
                  time: timeDateTime,
                  date: dateDateTime,
                );

                // Tambahkan ke list sementara
                notificationsList.add(notifData);
              } catch (e) {
                print('Error parsing notification item: $e');
              }
            }
          }

          // Tambahkan semua notifikasi sekaligus ke provider untuk menghindari banyak rebuild
          if (notificationsList.isNotEmpty) {
            notifProvider.addNotifications(notificationsList);
          }
        }
      }
    } catch (e) {
      print('Error loading notifications: $e');
      // Menampilkan pesan error jika gagal memuat notifikasi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat notifikasi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Akhiri loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.neutral.shade0,
      appBar: InvisibleAppbar(title: "Notifikasi"),
      body: SafeArea(
        child: _isLoading ? _buildLoadingView() : _buildNotificationView(),
      ),
    );
  }

  /// Widget untuk menampilkan loading indicator
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.neutral.shade900,
            ),
          ),
          SizedBox(height: 16),
          Text('Memuat notifikasi...', style: AppFonts.medium(16)),
        ],
      ),
    );
  }

  /// Widget untuk menampilkan daftar notifikasi
  Widget _buildNotificationView() {
    return RefreshIndicator(
      onRefresh: _loadAndSaveNotifications,
      color: AppColors.secondary.shade600,
      backgroundColor: AppColors.secondary.shade0,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tombol untuk menambahkan notifikasi test
              SizedBox(height: 24),
              _buildNotificationList(),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget untuk menampilkan daftar notifikasi dari provider
  Widget _buildNotificationList() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.notifications.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: AppColors.neutral.shade300,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: AppFonts.medium(20),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Notifikasi akan muncul di sini saat ada pembaruan penting',
                    style: AppFonts.regular(
                      14,
                    ).copyWith(color: AppColors.neutral.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: provider.notifications.length,
          itemBuilder: (context, index) {
            final reversedIndex = provider.notifications.length - 1 - index;
            final notif = provider.notifications[reversedIndex];
            String formattedTime =
                '${notif.time.hour.toString().padLeft(2, '0')}:${notif.time.minute.toString().padLeft(2, '0')}:${notif.time.second.toString().padLeft(2, '0')}';
            String formattedDate = DateFormat('dd-MM-yyyy').format(notif.date);

            return NotificationCard(
              title: notif.title,
              description: notif.description,
              time: formattedTime,
              date: formattedDate,
            );
          },
        );
      },
    );
  }
}
