import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:OhMyGERD/presentation/components/alert_notification.dart';
import 'package:OhMyGERD/presentation/components/custom_buttons.dart';
import 'package:OhMyGERD/presentation/components/custom_fields.dart';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import '../../../data/services/auth_service.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  String? usernameError;
  String? emailError;
  String? passwordError;
  String? passwordValidationError;
  String alertDescription = "";

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = AuthService();
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool isErrorVisible = false;

  bool validateInputs() {
    setState(() {
      usernameError =
          _nameController.text.isEmpty ? 'Nama tidak boleh kosong' : null;
      emailError =
          _emailController.text.isEmpty ||
                  !RegExp(
                    r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
                  ).hasMatch(_emailController.text)
              ? 'Email tidak valid'
              : null;
      passwordError =
          _passwordController.text.length < 6
              ? 'Password harus lebih dari 6 karakter'
              : null;
      passwordValidationError =
          _confirmPasswordController.text != _passwordController.text
              ? 'Konfirmasi password tidak cocok'
              : null;
    });

    return usernameError == null &&
        emailError == null &&
        passwordError == null &&
        passwordValidationError == null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral.shade0,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            right: 43.w,
            left: 43.w,
            top: 78.h,
            bottom: 44.h + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AlertNotification(
                description: alertDescription,
                visible: isErrorVisible,
              ),
              Center(
                child: Column(
                  children: [
                    Image.asset('assets/images/registration_mascot.png'),
                    SizedBox(height: 16.h),
                    Text("Daftar", style: AppFonts.semiBold(20.sp)),
                    SizedBox(height: 4.h),
                    Text(
                      "Isikan nama, email, dan password",
                      style: AppFonts.regular(14.sp),
                    ),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
              CustomTextField(
                title: "Nama",
                hintText: "Masukkan namamu",
                controller: _nameController,
                errorText: usernameError,
              ),
              SizedBox(height: 16.h),
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
              SizedBox(height: 16.h),
              CustomPasswordField(
                title: "Konfirmasi Password",
                hintText: "Masukkan konfirmasi passwordmu",
                controller: _confirmPasswordController,
                errorText: passwordValidationError,
              ),

              SizedBox(height: 32.h),
              MainButton(
                text: "Selanjutnya",
                onPressed: () async {
                  if (!mounted) return;
                  setState(() {
                    usernameError = null;
                    emailError = null;
                    passwordError = null;
                    passwordValidationError = null;
                    isLoading = true;
                    isErrorVisible = false;
                  });

                  if (validateInputs()) {
                    final userCredential = await _auth.registerWithoutGoogle(
                      _nameController.text,
                      _emailController.text,
                      _passwordController.text,
                    );
                    if (mounted) {
                      setState(() {
                        isLoading = false;
                      });
                      if (userCredential != null) {
                        context.push(AppRoutes.biodata);
                      } else {
                        setState(() {
                          isErrorVisible = true;
                          alertDescription = "Email sudah terdaftar";
                          isLoading = false;
                        });
                      }
                    }
                  } else {
                    setState(() {
                      isErrorVisible = true;
                      alertDescription = "Mohon isi kolom teks dengan sesuai";
                      isLoading = false;
                    });
                  }
                },
                isLoading: isLoading,
              ),
              SizedBox(height: 16.h),
              GoogleButton(
                isLoading: false,
                onPressed: () async {
                  if (!mounted) return;
                  setState(() {
                    isGoogleLoading = isGoogleLoading;
                    isErrorVisible = false;
                  });
                  //masih belum aman untuk orang yang login di halaman register
                  final dataCredential =
                      await _auth.handleRegisterLoginWithGoogle();
                  if (mounted) {
                    setState(() {
                      isGoogleLoading = false;
                    });
                    if (dataCredential?["userCredential"] != null) {
                      print(dataCredential);
                      if (dataCredential?["route"] == "home") {
                        context.go(AppRoutes.home);
                      } else if (dataCredential?["route"] == "biodata") {
                        context.push(AppRoutes.biodata);
                      }
                    } else {
                      isErrorVisible = true;
                      alertDescription = "Registrasi gagal, mohon coba kembali";
                      isGoogleLoading = false;
                    }
                  }
                },
              ),

              SizedBox(height: 53.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Sudah punya akun?",
                    style: AppFonts.regular(
                      12.sp,
                    ).copyWith(color: AppColors.neutral.shade900),
                  ),
                  SizedBox(width: 4.w),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.login),
                    child: Text(
                      "Masuk",
                      style: AppFonts.regular(12.sp).copyWith(
                        color: Color(0xFF3E9295),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
