import 'package:OhMyGERD/presentation/components/alert_notification.dart';
import 'package:OhMyGERD/presentation/components/shimmer_loading_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:OhMyGERD/data/services/be_service.dart';
import 'package:OhMyGERD/presentation/components/connection_card.dart';
import 'package:OhMyGERD/presentation/components/custom_appbar.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/presentation/components/custom_buttons.dart';
import 'package:OhMyGERD/presentation/components/custom_fields.dart';

class ConnectionsSettingsPage extends StatefulWidget {
  const ConnectionsSettingsPage({super.key});

  @override
  State<ConnectionsSettingsPage> createState() =>
      _ConnectionsSettingsPageState();
}

class _ConnectionsSettingsPageState extends State<ConnectionsSettingsPage> {
  final _connectionsController = TextEditingController();
  final backendService = BackendService();
  final user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> connections = [];
  bool isLoading = false;
  bool isErrorVisible = false;
  String alertDescription = "";

  @override
  void initState() {
    super.initState();
    _loadListOfConnection();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadListOfConnection() async {
    if (user != null) {
      final result = await backendService.getListOfConnection(user!);
      if (!mounted) return;
      setState(() {
        connections = result ?? [];
      });
      print(connections);
    }
  }

  Future<void> _handleAddConnection() async {
    setState(() {
      isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    final emailInput = _connectionsController.text.trim();
    if (user == null || emailInput.isEmpty) {
      // Tampilkan pesan error ke pengguna
      isErrorVisible = true;
      alertDescription = "Email yang dimasukkan kosong";
      print('Email yang dimasukkan kosong');
      setState(() {
        isLoading = false;
      });
      return;
    }
    if (connections.length >= 3) {
      print(connections.length);
      isErrorVisible = true;
      alertDescription = "Anda sudah mencapai jumlah maksimal koneksi";
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Validasi format email
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(emailInput)) {
      isErrorVisible = true;
      alertDescription = "Format email tidak valid";
      print('Format email tidak valid');
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Lanjut kirim ke backend
    try {
      final response = await backendService.sendConnectionAddedNotification(
        user,
        emailInput,
      );
      if (!mounted) return;
      isErrorVisible = true;
      alertDescription = "Berhasil menambahkan koneksi";
      // Bersihkan input field setelah berhasil
      _connectionsController.clear();
    } catch (e) {
      isErrorVisible = true;
      alertDescription = "Galat dalam menambahkan koneksi";
      print('Error adding connection: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.neutral.shade0,
      appBar: InvisibleAppbar(title: "Koneksi"),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: 16.h,
              bottom: 93.h,
              left: 30.w,
              right: 30.w,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AlertNotification(
                  description: alertDescription,
                  visible: isErrorVisible,
                ),
                CustomTextField(
                  title: "Koneksi",
                  hintText: "Tambahkan email koneksi kamu",
                  controller: _connectionsController,
                ),

                SizedBox(height: 24.h),
                DashedMainButton(
                  icon: 'assets/icons/plus_icon.png',
                  text: "Tambahkan Koneksi",
                  onPressed: _handleAddConnection,
                  isLoading: isLoading, // Pass the state to the button
                ),
                SizedBox(height: 24.h),
                Text(
                  "Koneksi Kamu",
                  style: AppFonts.semiBold(16.sp),
                  textAlign: TextAlign.left,
                ),
                SizedBox(height: 16.h),
                _buildConnectionList(),

                SizedBox(height: 16.h),
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
                child: ShimmerLoadingCard(
                  height: 80.h,
                  width: double.infinity,
                  borderRadius: 12.r,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text("Belum ada koneksi", style: AppFonts.regular(14.sp)),
          );
        }

        final connections = snapshot.data!.docs;

        return Column(
          children:
              connections.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: ConnectionCard(
                    mail: data['to'],
                    onTap: () async {
                      await doc.reference.delete();
                      if (user != null) {
                        backendService.sendDeletedConnection(user!, data['to']);
                      }
                    },
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}
