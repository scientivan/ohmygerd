import 'package:flutter/material.dart';
import 'package:OhMyGERD/presentation/components/alert_notification.dart';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import '../../../data/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:OhMyGERD/presentation/components/custom_buttons.dart';
import 'package:OhMyGERD/presentation/components/custom_fields.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // tambahin ini

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? emailError;
  String? passwordError;
  String alertDescription = "";
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();

  bool isGoogleLoading = false;
  bool isLoading = false;
  bool isErrorVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral.shade0,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 43.w, vertical: 32.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AlertNotification(
                  description: alertDescription,
                  visible: isErrorVisible,
                ),
                Image.asset(
                  'assets/images/registration_mascot.png',
                  height: 180.h,
                  width: 180.w,
                ),
                SizedBox(height: 16.h),
                Text("Masuk", style: AppFonts.semiBold(20.sp)),
                SizedBox(height: 32.h),
                CustomTextField(
                  title: "Email",
                  hintText: "Masukkan emailmu",
                  controller: _emailController,
                  errorText: emailError,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16.h),
                CustomPasswordField(
                  title: "Password",
                  hintText: "Masukkan passwordmu",
                  controller: _passwordController,
                  errorText: passwordError,
                ),
                SizedBox(height: 32.h),
                MainButton(
                  text: "Masuk",
                  onPressed: () async {
                    if (!mounted) return;
                    setState(() {
                      passwordError = null;
                      emailError = null;
                      isErrorVisible = false;
                      alertDescription = "";
                      isLoading = true;
                    });
                    String email = _emailController.text;
                    if (email.isEmpty ||
                        !RegExp(
                          r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
                        ).hasMatch(email)) {
                      setState(() {
                        emailError = 'Email tidak valid';
                      });
                    }
                    String password = _passwordController.text;
                    if (password.isEmpty || password.length < 6) {
                      setState(() {
                        passwordError = 'Password harus lebih dari 6 karakter';
                      });
                    }
                    if (emailError == null && passwordError == null) {
                      final userCredential = await _auth.loginWithoutGoogle(
                        _emailController.text,
                        _passwordController.text,
                        context,
                      );
                      if (mounted) {
                        setState(() {
                          isLoading = false;
                        });
                        print(userCredential);
                        if (userCredential != null) {
                          User? user = userCredential.user;
                          if (user != null) {
                            final redirectTo = await _auth
                                .checkUserDataFromBackend(
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
                          }
                        } else {
                          setState(() {
                            isErrorVisible = true;
                            alertDescription = "Email belum terdaftar";
                            isLoading = false;
                          });
                        }
                      } else {
                        setState(() {
                          isErrorVisible = true;
                          alertDescription =
                              "Mohon isi kolom teks dengan sesuai";
                          isLoading = false;
                        });
                      }
                    }
                  },
                  isLoading: isLoading,
                ),
                SizedBox(height: 16.h),
                GoogleButton(
                  isLoading: isGoogleLoading,
                  onPressed: () async {
                    if (!mounted) return;
                    setState(() {
                      isGoogleLoading = true;
                      isErrorVisible = false;
                    });
                    final dataCredential =
                        await _auth.handleRegisterLoginWithGoogle();
                    if (dataCredential?["userCredential"] != null) {
                      print(dataCredential);
                      if (dataCredential?["route"] == "home") {
                        context.go(AppRoutes.home);
                      } else if (dataCredential?["route"] == "biodata") {
                        context.push(AppRoutes.biodata);
                      }
                    } else {
                      isErrorVisible = true;
                      alertDescription = "Login gagal, mohon coba kembali";
                    }
                  },
                ),
                SizedBox(height: 64.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 2.5.w),
                    Text(
                      "Belum punya akun?",
                      style: AppFonts.regular(
                        12.sp,
                      ).copyWith(color: AppColors.neutral.shade900),
                    ),
                    SizedBox(width: 4.w),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.register),
                      child: Text(
                        "Daftar",
                        style: AppFonts.regular(12.sp).copyWith(
                          color: const Color(0xFF3E9295),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
