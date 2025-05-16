import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:OhMyGERD/presentation/pages/auth/loginpage.dart';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _auth = AuthService();
  @override
  void initState() {
    super.initState();

    // Future.delayed(const Duration(seconds: 5), () {
    //   // TODO: Bisa tambahin cek kondisi di sini (misal udah login / pernah onboarding)
    //   context.push(AppRoutes.onboarding1);
    // });

    Future.delayed(const Duration(seconds: 2), () async {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User sudah login
        final redirectTo = await _auth.checkUserDataFromBackend(
          user: user,
          context: context,
        );
        if (redirectTo != null) {
          if (redirectTo == 'biodata') {
            context.push(AppRoutes.biodata);
          } else if (redirectTo == 'preference') {
            context.push(AppRoutes.preference);
          }
        } else {
          context.go(AppRoutes.home);
        }
      } else {
        context.go(AppRoutes.onboarding);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary.shade100,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/splash_screen_mascot.png',
              width: 223.w,
              height: 242.h,
            ),
            Text(
              "OhMyGERD",
              style: AppFonts.bold(
                36.sp,
              ).copyWith(color: AppColors.danger.shade300),
            ),
          ],
        ),
      ),
    );
  }
}
