import 'package:OhMyGERD/data/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:OhMyGERD/presentation/components/alert_notification.dart';
import 'package:OhMyGERD/presentation/components/custom_appbar.dart';
import 'package:OhMyGERD/presentation/components/custom_buttons.dart';
import 'package:OhMyGERD/presentation/components/custom_fields.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/be_service.dart';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';
import 'dart:math';

class PreferencePage extends StatefulWidget {
  const PreferencePage({super.key});

  @override
  State<PreferencePage> createState() => _PreferencePageState();
}

class _PreferencePageState extends State<PreferencePage>
    with TickerProviderStateMixin {
  final _breakfastController = TextEditingController();
  final _lunchController = TextEditingController();
  final _dinnerController = TextEditingController();
  final _snackIntensityController = TextEditingController();
  final _maxTimeController = TextEditingController();
  final _startTimeController = TextEditingController();
  TimeOfDay? _breakfastTime;
  TimeOfDay? _lunchTime;
  TimeOfDay? _dinnerTime;
  TimeOfDay? _maxTime;
  TimeOfDay? _startTime;
  bool isLoading = false;
  final backendService = BackendService();
  final authService = AuthService();

  bool _isSnackSectionVisible = false;
  bool isSnackIntensityError = false;
  bool isMaxTimeError = false;
  bool isStartTimeError = false;
  bool isBreakfastError = false;
  bool isLunchError = false;
  bool isDinnerError = false;
  bool isSnackIntensityTooHighError = false;
  String alertDescription = "";
  bool isErrorVisible = false;
  double? time_range;
  @override
  void dispose() {
    _breakfastController.dispose();
    _lunchController.dispose();
    _dinnerController.dispose();
    _snackIntensityController.dispose();
    _maxTimeController.dispose();
    _startTimeController.dispose();
    super.dispose();
  }

  bool validateAndSubmit() {
    // Clear all error states first
    isBreakfastError = false;
    isLunchError = false;
    isDinnerError = false;
    isSnackIntensityError = false;
    isMaxTimeError = false;
    isStartTimeError = false;
    isSnackIntensityTooHighError = false;

    // Always reset error visibility and description at the start
    alertDescription = "";
    isErrorVisible = false;

    bool isBreakfastEmpty = _breakfastTime == null;
    bool isLunchEmpty = _lunchTime == null;
    bool isDinnerEmpty = _dinnerTime == null;
    bool isMaxTimeEmpty = _maxTime == null;
    bool isStartTimeEmpty = _startTime == null;
    bool isSnackIntensityEmpty = _snackIntensityController.text.trim().isEmpty;

    bool isSnackIntensityTooHigh = false;
    bool isStartTimeGreaterThanMaxTime = false;
    bool isTimeRangeTooSmall = false;

    if (_isSnackSectionVisible &&
        !isSnackIntensityEmpty &&
        !isMaxTimeEmpty &&
        !isStartTimeEmpty) {
      int? snackIntensity = int.tryParse(_snackIntensityController.text.trim());

      // Compare TimeOfDay objects properly
      if (_startTime != null && _maxTime != null) {
        // Convert times to minutes since midnight for easier comparison
        int startTimeInMinutes = _startTime!.hour * 60 + _startTime!.minute;
        int maxTimeInMinutes = _maxTime!.hour * 60 + _maxTime!.minute;

        // Check if max time is earlier in the day than start time (indicating a wrap around midnight)
        if (maxTimeInMinutes < startTimeInMinutes) {
          isStartTimeGreaterThanMaxTime = true;
          alertDescription =
              "Waktu mulai makan harus lebih dahulu daripada waktu maksimal makan pada hari yang sama";
          isErrorVisible = true;
        } else if (snackIntensity != null && snackIntensity > 0) {
          // Calculate time range in hours
          double timeRangeInHours =
              (maxTimeInMinutes - startTimeInMinutes) / 60.0;
          time_range = timeRangeInHours;

          // Check if there's enough time between notifications
          if (timeRangeInHours / snackIntensity < 3) {
            log(timeRangeInHours / snackIntensity);
            isTimeRangeTooSmall = true;
            alertDescription =
                "Jarak antar notifikasi makan terlalu rapat. Coba kurangi intensitas makanan atau perpanjang durasi waktu makan.";
            isErrorVisible = true;
          }
        }
      }

      if (snackIntensity != null && snackIntensity > 8) {
        isSnackIntensityTooHigh = true;
      }
    }

    if (isBreakfastEmpty) isBreakfastError = true;
    if (isLunchEmpty) isLunchError = true;
    if (isDinnerEmpty) isDinnerError = true;

    if (_isSnackSectionVisible && isMaxTimeEmpty) isMaxTimeError = true;
    if (_isSnackSectionVisible && isStartTimeEmpty) isStartTimeError = true;
    if (_isSnackSectionVisible && isSnackIntensityEmpty) {
      isSnackIntensityError = true;
    }
    if (_isSnackSectionVisible && isSnackIntensityTooHigh) {
      isSnackIntensityTooHighError = true;
    }

    final isBigMealError = isBreakfastEmpty || isLunchEmpty || isDinnerEmpty;
    final isSnackError =
        isMaxTimeEmpty ||
        isStartTimeEmpty ||
        isSnackIntensityEmpty ||
        isSnackIntensityTooHigh ||
        isStartTimeGreaterThanMaxTime ||
        isTimeRangeTooSmall;

    // Set appropriate error message if there are validation errors
    if (isBigMealError && _isSnackSectionVisible && isSnackError) {
      if (!isErrorVisible) {
        // Only set if no specific error is already set
        alertDescription =
            "Tolong isi waktu makan besar dan snack dengan benar";
        isErrorVisible = true;
      }
    } else if (isBigMealError) {
      if (!isErrorVisible) {
        alertDescription = "Tolong isi waktu makan besar";
        isErrorVisible = true;
      }
    } else if (_isSnackSectionVisible && isSnackError) {
      if (!isErrorVisible) {
        alertDescription = "Tolong isi waktu makan snack dengan benar";
        isErrorVisible = true;
      }
    }

    // Force UI update to show the correct error message
    setState(() {});

    return !(isBigMealError || (_isSnackSectionVisible && isSnackError));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.neutral.shade0,
      appBar: InvisibleAppbar(isBackButtonVisible: false),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double horizontalPadding = constraints.maxWidth * 0.08;
          return Container(
            margin: EdgeInsets.only(
              right: 30.w,
              left: 30.w,
              bottom: 36.h,
              top: 79.h,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  AlertNotification(
                    description: alertDescription,
                    visible: isErrorVisible,
                  ),
                  Center(
                    child: Column(
                      children: [
                        Image.asset('assets/images/preference_mascot.png'),
                        SizedBox(height: 16.h),
                        Text(
                          "Rekomendasi Makanan",
                          style: AppFonts.semiBold(20.sp),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "Isikan preferensi waktu pengingat makanmu di bawah ini",
                          style: AppFonts.regular(14.sp),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 32.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.shade200,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            "Makan Besar",
                            style: AppFonts.semiBold(16.sp),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          "Rekomendasi Waktu Makan",
                          style: AppFonts.medium(
                            14.sp,
                          ).copyWith(color: AppColors.neutral.shade600),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMealTimeCard("Makan Pagi", "05.00 - 09.00"),
                            _buildMealTimeCard("Makan Siang", "11.00 - 15.00"),
                            _buildMealTimeCard("Makan Malam", "17.00 - 21.00"),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        CustomTimePickerField(
                          title: "Makan Pagi",
                          hintText: "Isi waktu",
                          controller: _breakfastController,
                          onTimePicked: (picked) {
                            setState(() {
                              _breakfastTime = picked;
                            });
                          },
                          timeRange: TimeRange.morning(),
                        ),
                        if (isBreakfastError)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Text(
                              "Waktu sarapan wajib diisi",
                              style: TextStyle(
                                color: AppColors.danger.shade300,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        SizedBox(height: 16.h),
                        CustomTimePickerField(
                          title: "Makan Siang",
                          hintText: "Isi waktu",
                          controller: _lunchController,
                          onTimePicked: (picked) {
                            setState(() {
                              _lunchTime = picked;
                            });
                          },
                          timeRange: TimeRange.afternoon(),
                        ),
                        if (isLunchError)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Text(
                              "Waktu makan siang wajib diisi",
                              style: TextStyle(
                                color: AppColors.danger.shade300,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        SizedBox(height: 16.h),
                        CustomTimePickerField(
                          title: "Makan Malam",
                          hintText: "Isi waktu",
                          controller: _dinnerController,
                          onTimePicked: (picked) {
                            setState(() {
                              _dinnerTime = picked;
                            });
                          },
                          timeRange: TimeRange.evening(),
                        ),
                        if (isDinnerError)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Text(
                              "Waktu makan malam wajib diisi",
                              style: TextStyle(
                                color: AppColors.danger.shade300,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Visibility(
                    visible: !_isSnackSectionVisible,
                    child: DashedMainButton(
                      text: "Tambah Jadwal Makan Snack",
                      icon: 'assets/icons/plus_icon.png',
                      onPressed: () {
                        setState(() {
                          _isSnackSectionVisible = true;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 16.h),
                  AnimatedSize(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child:
                        _isSnackSectionVisible
                            ? Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 32.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.shade200,
                                border: Border.all(
                                  color: AppColors.neutral.shade900,
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      Center(
                                        child: Text(
                                          "Makan Snack",
                                          style: AppFonts.semiBold(16.sp),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0.w,
                                        top: -15.h,
                                        child: IconButton(
                                          icon: Icon(Icons.close),
                                          onPressed: () {
                                            setState(() {
                                              _isSnackSectionVisible = false;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    "Rekomendasi Waktu Makan",
                                    style: AppFonts.medium(14.sp).copyWith(
                                      color: AppColors.neutral.shade600,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildMealTimeCard(
                                        "Jumlah Makan\n Snack",
                                        "3x",
                                      ),
                                      _buildMealTimeCard(
                                        "Maksimal waktu\n makan",
                                        "21.00",
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16.h),
                                  CustomTextField(
                                    title: "Berapa banyak makan (maksimal 8x)",
                                    hintText: "Masukkan intensitas snack Anda",
                                    controller: _snackIntensityController,
                                    iconAssetPath:
                                        'assets/icons/drink_icon.png',
                                    errorText:
                                        isSnackIntensityError
                                            ? "Mohon isi intensitas snack"
                                            : isSnackIntensityTooHighError
                                            ? "Intensitas snack tidak boleh lebih dari 8"
                                            : null,
                                    keyboardType: TextInputType.number,
                                  ),
                                  SizedBox(height: 16.h),
                                  CustomTimePickerField(
                                    title: "Mulai waktu makan",
                                    hintText: "Isi disini",
                                    controller: _startTimeController,
                                    onTimePicked: (picked) {
                                      setState(() {
                                        _startTime = picked;
                                      });
                                    },
                                  ),
                                  if (isStartTimeError)
                                    Padding(
                                      padding: EdgeInsets.only(top: 4.h),
                                      child: Text(
                                        "Waktu mulai makan wajib diisi",
                                        style: TextStyle(
                                          color: AppColors.danger.shade300,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ),
                                  SizedBox(height: 16.h),
                                  CustomTimePickerField(
                                    title: "Maksimal waktu makan",
                                    hintText: "Isi waktu",
                                    controller: _maxTimeController,
                                    onTimePicked: (picked) {
                                      setState(() {
                                        _maxTime = picked;
                                      });
                                    },
                                  ),
                                  if (isMaxTimeError)
                                    Padding(
                                      padding: EdgeInsets.only(top: 4.h),
                                      child: Text(
                                        "Waktu maksimal makan wajib diisi",
                                        style: TextStyle(
                                          color: AppColors.danger.shade300,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )
                            : SizedBox(),
                  ),
                  SizedBox(height: 16.h),
                  MainButton(
                    text: "Selanjutnya",
                    onPressed: () async {
                      final isValid = validateAndSubmit();
                      if (!isValid) return;

                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        setState(() {
                          alertDescription = "User tidak ditemukan.";
                          isErrorVisible = true;
                        });
                        return;
                      }

                      final breakfastTimeString = _breakfastTime!.format(
                        context,
                      );
                      final lunchTimeString = _lunchTime!.format(context);
                      final dinnerTimeString = _dinnerTime!.format(context);
                      final maxSnackTime = _maxTime?.format(context) ?? "00:00";
                      final startSnackTime =
                          _startTime?.format(context) ?? "00:00";
                      final snackIntensity =
                          int.tryParse(_snackIntensityController.text) ?? 0;
                      int reminderInterval;
                      if (snackIntensity != 0) {
                        reminderInterval = (24 / snackIntensity).floor();
                        // set maksimal reminder dalam sehari adalah 8 kali (setiap 3 jam) biar gaboros fcm hehe
                        if (reminderInterval < 3) {
                          reminderInterval = 3;
                        }
                      } else {
                        reminderInterval = 0;
                      }

                      setState(() {
                        isLoading = true;
                        alertDescription = "";
                        isErrorVisible = false;
                      });

                      final response = await authService
                          .sendUserMealAndSnackTime(
                            user,
                            breakfastTimeString,
                            lunchTimeString,
                            dinnerTimeString,
                            snackIntensity,
                            reminderInterval,
                            maxSnackTime,
                            startSnackTime,
                          );

                      if (mounted) {
                        setState(() {
                          isLoading = false;
                        });
                        if (response != null) {
                          context.push(AppRoutes.connections);
                        } else {
                          setState(() {
                            alertDescription =
                                "Gagal mengirim waktu makan & snack!";
                            isErrorVisible = true;
                          });
                        }
                      }
                    },
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealTimeCard(String label, String description) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(8.r),
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: AppColors.secondary.shade100,
          border: Border.all(color: AppColors.secondary.shade800),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppFonts.medium(
                10.sp,
              ).copyWith(color: AppColors.neutral.shade600),
              textAlign: TextAlign.center,
            ),
            Text(
              description,
              style: AppFonts.semiBold(12.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
