import 'dart:io';

import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:OhMyGERD/data/services/be_service.dart';
import 'package:OhMyGERD/presentation/components/custom_appbar.dart';
import 'package:OhMyGERD/presentation/components/custom_buttons.dart';
import 'package:OhMyGERD/presentation/layouts/meal_result_layout.dart';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class MealResult extends StatefulWidget {
  const MealResult({super.key});

  @override
  State<MealResult> createState() => _MealResultState();
}

class _MealResultState extends State<MealResult> {
  final backendService = BackendService();
  late List<dynamic> selectedComponents;
  late File imageFile;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get data passed through extra in context
    final args = GoRouterState.of(context).extra as Map<String, dynamic>;
    selectedComponents = args['selectedComponents'];
    imageFile = args['imageFile'];
    print(selectedComponents);
  }

  @override
  Widget build(BuildContext context) {
    // Kategorikan makanan berdasarkan status
    print("darisini $selectedComponents");
    final tidakAmanMeals =
        selectedComponents
            .where(
              (item) => item['status'].toString().toLowerCase() == 'tidak aman',
            )
            .toList();
    final masihAmanMeals =
        selectedComponents
            .where(
              (item) => item['status'].toString().toLowerCase() == 'masih aman',
            )
            .toList();
    final sangatAmanMeals =
        selectedComponents
            .where(
              (item) =>
                  item['status'].toString().toLowerCase() == 'sangat aman',
            )
            .toList();

    return Scaffold(
      backgroundColor: AppColors.neutral.shade0,
      appBar: InvisibleAppbar(
        title: "Hasil Scan Makanan",
        isBackButtonVisible: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tampilkan gambar makanan yang di-scan di bagian atas
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 30.w),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 30.w),
                decoration: BoxDecoration(
                  color: AppColors.secondary.shade200,
                  border: Border.all(color: AppColors.neutral.shade900),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.neutral.shade900,
                      width: 2.w,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                      width: 120.w,
                      height: 120.h,
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Text(
                "Hindari penggunaan saus sambal dan saus kecap yang memicu gerd kamu",
                style: AppFonts.medium(
                  14.sp,
                ).copyWith(color: AppColors.danger.shade300),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 8.w),

            // Gunakan MealResultsLayout untuk menampilkan hasil dalam bentuk tab
            Expanded(
              child: MealResultsLayout(
                tidakAmanMeals: tidakAmanMeals,
                masihAmanMeals: masihAmanMeals,
                sangatAmanMeals: sangatAmanMeals,
              ),
            ),

            // Tombol untuk kembali ke home
            Container(
              padding: EdgeInsets.all(10.r),
              margin: EdgeInsets.only(bottom: 8.h),
              child: MainButton(
                text: "Kembali ke Home",
                onPressed: () {
                  context.go(AppRoutes.home);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Perbaikan pada MealResultsLayout
