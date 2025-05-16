import 'dart:io';
import 'package:OhMyGERD/presentation/layouts/meal_result_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:OhMyGERD/data/services/be_service.dart';
import 'package:OhMyGERD/presentation/components/custom_appbar.dart';
import 'package:OhMyGERD/presentation/components/custom_buttons.dart';
import 'package:OhMyGERD/presentation/layouts/navigation_wrapper.dart';
import 'package:OhMyGERD/presentation/providers/meal_activity_provider.dart';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';
import 'package:provider/provider.dart';

class FoodResultPage extends StatefulWidget {
  const FoodResultPage({super.key});

  @override
  State<FoodResultPage> createState() => _FoodResultPageState();
}

class _FoodResultPageState extends State<FoodResultPage> {
  final backendService = BackendService();
  late List<dynamic> selectedComponents;
  late File imageFile;
  final user = FirebaseAuth.instance.currentUser;
  bool _mealCompleted =
      false; // Track if we've already marked the meal complete

  // This method handles detecting current meal type based on the current time
  String _getCurrentMealType() {
    final now = DateTime.now();
    final hour = now.hour;

    print('Current hour: $hour'); // Debug print

    if (hour >= 5 && hour < 9) {
      return 'breakfast';
    } else if (hour >= 11 && hour < 15) {
      return 'lunch';
    } else if (hour >= 17 && hour < 21) {
      return 'dinner';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    // Mark meal as completed immediately when this page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_mealCompleted) {
        _markMealComplete();
      }
    });
  }

  void _markMealComplete() {
    if (_mealCompleted) return; // Prevent double execution

    // Get provider from context
    final mealProvider = Provider.of<MealActivityProvider>(
      context,
      listen: false,
    );

    // Determine active meal type
    final currentMeal = _getCurrentMealType();

    // Update meal status to success
    if (currentMeal.isNotEmpty) {
      mealProvider.completeMeal(currentMeal);
      print('Meal marked as completed: $currentMeal');
      _mealCompleted = true; // Mark as already handled
    } else {
      print('Could not determine current meal type. Hour outside meal ranges.');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get data passed through extra in context
    final args = GoRouterState.of(context).extra as Map<String, dynamic>;
    selectedComponents = args['selectedComponents'];
    imageFile = args['imageFile'];
  }

  @override
  Widget build(BuildContext context) {
    // Kategorikan makanan berdasarkan status
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
      appBar: InvisibleAppbar(title: "Hasil Scan Makanan"),
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
            Padding(
              padding: EdgeInsets.all(16.r),
              child: MainButton(
                text: "Kembali ke Home",
                onPressed: () async {
                  if (_mealCompleted) {
                    int hour = DateTime.now().hour;
                    String? mealTime;
                    if (hour >= 6 && hour < 10) {
                      mealTime = 'breakfast';
                    } else if (hour >= 11 && hour < 16) {
                      mealTime = 'lunch';
                    } else if (hour >= 18 && hour < 23) {
                      mealTime = 'dinner';
                    }

                    if (mealTime != null) {
                      // Tampilkan loading dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            content: Row(
                              children: [
                                CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.neutral.shade900,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text("Sedang menyimpan data"),
                              ],
                            ),
                          );
                        },
                      );

                      // Tambahkan sedikit delay agar dialog bisa tampil dulu
                      await Future.delayed(Duration(milliseconds: 300));

                      // Lakukan proses upload
                      await backendService.uploadPhotoAndFoodComponent(
                        user!,
                        mealTime,
                        selectedComponents,
                        imageFile,
                      );

                      // Tutup dialog setelah selesai
                      Navigator.of(context).pop();
                    }

                    _markMealComplete();
                  }

                  // Kembali ke Home
                  context.go(AppRoutes.home, extra: {'message': 'success'});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
