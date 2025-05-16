import 'package:OhMyGERD/presentation/components/alert_notification.dart';
import 'package:OhMyGERD/presentation/components/shimmer_loading_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:OhMyGERD/presentation/components/connection_card.dart';
import 'package:OhMyGERD/presentation/components/custom_buttons.dart';
import 'package:OhMyGERD/presentation/components/custom_fields.dart';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import '../../../data/services/be_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  final backendService = BackendService();
  // Initialize as false instead of true
  bool isLoading = false;
  bool isErrorVisible = false;
  String alertDescription = "";

  final user = FirebaseAuth.instance.currentUser;
  Future<void> _handleAddConnection() async {
    setState(() {
      isLoading = true;
    });
    final emailInput = _connectionsController.text.trim();
    if (user == null || emailInput.isEmpty) {
      isErrorVisible = true;
      alertDescription = "Email yang dimasukkan kosong";
      print('User tidak login atau email kosong');
      setState(() => isLoading = false);
      return;
    }

    final connectionSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('connection')
            .get();

    if (connectionSnapshot.docs.length >= 3) {
      isErrorVisible = true;
      alertDescription = "Anda sudah mencapai jumlah maksimal koneksi";
      setState(() => isLoading = false);
      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(emailInput)) {
      isErrorVisible = true;
      alertDescription = "Format email tidak valid";
      print('Format email tidak valid');
      setState(() => isLoading = false);
      return;
    }

    try {
      await backendService.sendConnectionAddedNotification(user!, emailInput);
      isErrorVisible = true;
      alertDescription = "Berhasil menambahkan koneksi";
    } catch (e) {
      isErrorVisible = true;
      alertDescription = "Galat dalam menambahkan koneksi";
      print("Error sending connection: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = false;
    });
  }

  final _connectionsController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral.shade0,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              right: 30.w,
              left: 30.w,
              top: 82.h,
              bottom: 384.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DashedMainButton(
                  text: "DEBUGGGG",
                  onPressed: () {
                    context.push(AppRoutes.preference);
                  },
                ),
                AlertNotification(
                  description: alertDescription,
                  visible: isErrorVisible,
                ),
                Image.asset(
                  "assets/images/connections_mascot.png",
                  height: 200.h,
                  width: 200.w,
                ),
                SizedBox(height: 16.h),
                Text("Tambahkan Koneksi", style: AppFonts.semiBold(20.sp)),
                SizedBox(height: 4.h),
                Text(
                  "Isikan alamat email...",
                  style: AppFonts.regular(14.sp),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                CustomTextField(
                  title: "Koneksi",
                  hintText: "Tambahkan email koneksi kamu",
                  controller: _connectionsController,
                ),
                SizedBox(height: 10.h),
                DashedMainButton(
                  isLoading: isLoading,
                  icon: 'assets/icons/plus_icon.png',
                  text: "Tambahkan Koneksi",
                  onPressed: _handleAddConnection,
                ),
                Visibility(
                  visible: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 24.h),
                      Text("Koneksi Kamu", style: AppFonts.semiBold(16.sp)),
                      SizedBox(height: 16.h),
                      _buildConnectionList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .collection('connection')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: List.generate(
              3,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: const ShimmerLoadingCard(
                  height: 80,
                  width: double.infinity,
                  borderRadius: 12,
                ),
              ),
            ),
          );
        }

        // Cek kalau data koneksi kosong
        final connections = snapshot.data?.docs ?? [];

        // Kalo belum ada koneksi
        if (connections.isEmpty) {
          return Column(
            children: [
              Center(
                child: Text(
                  "Belum ada koneksi",
                  style: AppFonts.regular(14.sp),
                ),
              ),
              SizedBox(height: 32.h),
              MainButton(
                text: "Skip", // Tombol Skip
                onPressed: () {
                  context.go(AppRoutes.home);
                },
              ),
            ],
          );
        }

        // Kalau sudah ada koneksi
        return Column(
          children: [
            ...connections.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: ConnectionCard(
                  mail: data['to'],
                  onTap: () async {
                    await doc.reference.delete();
                    if (user != null) {
                      await backendService.sendDeletedConnection(
                        user!,
                        data['to'],
                      );
                    }
                  },
                ),
              );
            }).toList(),
            SizedBox(height: 32.h),
            MainButton(
              text: "Simpan", // Tombol Simpan
              onPressed: () {
                context.go(AppRoutes.home);
              },
            ),
          ],
        );
      },
    );
  }
}
