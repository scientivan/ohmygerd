import 'dart:io';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/presentation/providers/meal_activity_provider.dart';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';
import 'package:provider/provider.dart';

class CustomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  bool _isWithinMealTimeRange() {
    final now = DateTime.now();
    final hour = now.hour;

    // Check if current time is within any meal time range
    return (hour >= 6 && hour < 10) || // Breakfast
        (hour >= 11 && hour < 16) || // Lunch
        (hour >= 18 && hour < 23); // Dinner
  }

  void _handleScanTap(BuildContext context) async {
    if (_isWithinMealTimeRange()) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        // Navigate to food component page with the image
        await context.push(
          AppRoutes.foodComponent,
          extra: File(pickedFile.path),
        );

        // Force update meal statuses after returning
        Provider.of<MealActivityProvider>(
          context,
          listen: false,
        ).updateMealStatuses();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isScanTime = _isWithinMealTimeRange();

    return Container(
      height: 80.h, // Fixed height to make bottom bar more compact
      child: BottomAppBar(
        padding: EdgeInsets.symmetric(
          horizontal: 10.w,
          vertical: 5.h,
        ), // Add padding to control internal space
        notchMargin: 9,
        shape: const CircularNotchedRectangle(),
        color: AppColors.secondary.shade200,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(
              'assets/icons/home_active_alt.png',
              'assets/icons/home_inactive_alt.png',
              0,
              "Beranda",
            ),
            navItem(
              'assets/icons/calendar_active_alt.png',
              'assets/icons/calendar_inactive_alt.png',
              1,
              "Kalendar",
            ),
            Container(width: 50.w),
            navItem(
              'assets/icons/chat_active_alt.png',
              'assets/icons/chat_inactive_alt.png',
              3,
              "Gerdian",
            ),
            navItem(
              'assets/icons/profile_active_alt.png',
              'assets/icons/profile_inactive_alt.png',
              4,
              "Profil",
            ),
          ],
        ),
      ),
    );
  }

  Widget navItem(
    String activeAsset,
    String inActiveAsset,
    int index,
    String text,
  ) {
    final bool isActive = selectedIndex == index;
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: isActive ? AppColors.danger.shade200 : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              isActive ? activeAsset : inActiveAsset,
              width: 22.w, // Fixed width for icons
              height: 22.h, // Fixed height for icons
            ),
            SizedBox(height: 3.h), // Reduced space between icon and text
            Text(
              text,
              style: AppFonts.medium(10.sp).copyWith(
                // Smaller text
                color:
                    isActive
                        ? AppColors.neutral.shade900
                        : AppColors.neutral.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
