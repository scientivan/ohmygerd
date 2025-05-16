import 'dart:io';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/presentation/providers/meal_activity_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';
import 'package:OhMyGERD/presentation/layouts/custom_navigation_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:shimmer/shimmer.dart';

class NavigationWrapper extends StatelessWidget {
  final Widget child;

  NavigationWrapper({required this.child});

  final List<String> _routes = [
    AppRoutes.home,
    AppRoutes.calendar,
    AppRoutes.photo,
    AppRoutes.chatbot,
    AppRoutes.profile,
  ];

  int _getSelectedIndex(String location) {
    final index = _routes.indexWhere((route) => location.startsWith(route));
    return index < 0 ? 0 : index;
  }

  void _handleScanTap(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      await context.push(AppRoutes.mealScan, extra: File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouter.of(context).location;
    final selectedIndex = _getSelectedIndex(location);

    return Scaffold(
      backgroundColor: AppColors.neutral.shade0,
      body: child,
      floatingActionButton: SizedBox(
        height: 60.h,
        width: 60.w,
        child: FloatingActionButton(
          shape: CircleBorder(),
          backgroundColor: AppColors.secondary.shade200,

          elevation: 4,
          onPressed: () => _handleScanTap(context),
          child: Shimmer.fromColors(
            baseColor: AppColors.neutral.shade400,
            highlightColor: AppColors.secondary.shade300,
            period: Duration(seconds: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/scan_inactive_alt.png',
                  width: 24.w,
                  height: 24.h,
                ),
                SizedBox(height: 4.h),
                Text(
                  "Scan",
                  style: AppFonts.medium(12.sp).copyWith(
                    color:
                        AppColors
                            .neutral
                            .shade400, // penting: biar shimmer kelihatan
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomNavigationBar(
        selectedIndex: selectedIndex,
        onTap: (index) {
          if (index != selectedIndex) {
            if (index == 3) {
              context.push(_routes[index]);
            } else {
              context.go(_routes[index]);
            }
          }
        },
      ),
    );
  }
}
