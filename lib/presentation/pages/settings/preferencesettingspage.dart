import 'package:OhMyGERD/data/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:OhMyGERD/presentation/components/custom_appbar.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/presentation/components/custom_buttons.dart';
import 'package:OhMyGERD/presentation/components/custom_fields.dart';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';
import 'package:OhMyGERD/presentation/components/alert_notification.dart';
import '../../../data/services/be_service.dart';

class PreferenceSettingsPage extends StatefulWidget {
  const PreferenceSettingsPage({super.key});

  @override
  State<PreferenceSettingsPage> createState() => _PreferenceSettingsPageState();
}

class _PreferenceSettingsPageState extends State<PreferenceSettingsPage> {
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
  final backendService = BackendService();
  final authService = AuthService();
  final user = FirebaseAuth.instance.currentUser;
  int? snackIntensity;
  bool isLoading = false;
  String alertDescription = "";
  bool isErrorVisible = false;
  double? time_range;

  // Error flags
  bool isBreakfastError = false;
  bool isLunchError = false;
  bool isDinnerError = false;
  bool isSnackIntensityError = false;
  bool isMaxTimeError = false;
  bool isStartTimeError = false;
  bool isSnackIntensityTooHighError = false;

  String? breakfastTime,
      lunchTime,
      dinnerTime,
      snackIntensityString,
      reminderInterval,
      maxSnackTime,
      startSnackTime;

  @override
  void initState() {
    super.initState();
    _loadUserPreference();
  }

  Future<void> _loadUserPreference() async {
    if (user != null) {
      final preference = await authService.getUserMealAndSnackTime(user!);
      if (!mounted) return;
      setState(() {
        if (preference != null) {
          breakfastTime = preference["breakfastTime"];
          lunchTime = preference["lunchTime"];
          dinnerTime = preference["dinnerTime"];

          snackIntensity = preference["snackIntensity"];
          snackIntensityString = snackIntensity.toString();

          maxSnackTime = preference["maxSnackTime"];
          startSnackTime = preference["startSnackTime"];
        }
      });
    }
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

    // Check if fields have been changed or they're using existing values
    bool isBreakfastEmpty = _breakfastTime == null && breakfastTime == null;
    bool isLunchEmpty = _lunchTime == null && lunchTime == null;
    bool isDinnerEmpty = _dinnerTime == null && dinnerTime == null;

    // For snack fields, we only validate if there's an attempt to change them
    bool isSnackChanged =
        _snackIntensityController.text.trim().isNotEmpty ||
        _maxTime != null ||
        _startTime != null;

    bool isMaxTimeEmpty =
        isSnackChanged && (_maxTime == null && maxSnackTime == null);
    bool isStartTimeEmpty =
        isSnackChanged && (_startTime == null && startSnackTime == null);
    bool isSnackIntensityEmpty =
        isSnackChanged &&
        _snackIntensityController.text.trim().isEmpty &&
        snackIntensityString == null;

    bool isSnackIntensityTooHigh = false;
    bool isStartTimeGreaterThanMaxTime = false;
    bool isTimeRangeTooSmall = false;

    // Check snack time validation if any snack field is being changed
    if (isSnackChanged &&
        !isSnackIntensityEmpty &&
        !isMaxTimeEmpty &&
        !isStartTimeEmpty) {
      int? snackIntensityValue =
          int.tryParse(_snackIntensityController.text.trim()) ?? snackIntensity;

      // Get current or new times for validation
      TimeOfDay startTimeValue =
          _startTime ?? _parseTimeString(startSnackTime ?? "00:00");
      TimeOfDay maxTimeValue =
          _maxTime ?? _parseTimeString(maxSnackTime ?? "00:00");

      // Convert times to minutes since midnight for easier comparison
      int startTimeInMinutes = startTimeValue.hour * 60 + startTimeValue.minute;
      int maxTimeInMinutes = maxTimeValue.hour * 60 + maxTimeValue.minute;

      // Check if max time is earlier in the day than start time (indicating a wrap around midnight)
      if (maxTimeInMinutes < startTimeInMinutes) {
        isStartTimeGreaterThanMaxTime = true;
        alertDescription =
            "Waktu mulai makan harus lebih dahulu daripada waktu maksimal makan pada hari yang sama";
        isErrorVisible = true;
      } else if (snackIntensityValue != null && snackIntensityValue > 0) {
        // Calculate time range in hours
        double timeRangeInHours =
            (maxTimeInMinutes - startTimeInMinutes) / 60.0;
        time_range = timeRangeInHours;

        // Check if there's enough time between notifications
        if (timeRangeInHours / snackIntensityValue < 3) {
          isTimeRangeTooSmall = true;
          alertDescription =
              "Jarak waktu antar notifikasi terlalu pendek (minimal 3 jam)";
          isErrorVisible = true;
        }
      }

      if (snackIntensityValue != null && snackIntensityValue > 8) {
        isSnackIntensityTooHigh = true;
        if (!isErrorVisible) {
          alertDescription = "Intensitas snack tidak boleh lebih dari 8";
          isErrorVisible = true;
        }
      }
    }

    if (isBreakfastEmpty) isBreakfastError = true;
    if (isLunchEmpty) isLunchError = true;
    if (isDinnerEmpty) isDinnerError = true;

    if (isSnackChanged && isMaxTimeEmpty) isMaxTimeError = true;
    if (isSnackChanged && isStartTimeEmpty) isStartTimeError = true;
    if (isSnackChanged && isSnackIntensityEmpty) {
      isSnackIntensityError = true;
    }

    final isBigMealError = isBreakfastEmpty || isLunchEmpty || isDinnerEmpty;
    final isSnackError =
        (isSnackChanged &&
            (isMaxTimeEmpty ||
                isStartTimeEmpty ||
                isSnackIntensityEmpty ||
                isSnackIntensityTooHigh ||
                isStartTimeGreaterThanMaxTime ||
                isTimeRangeTooSmall));

    // Set appropriate error message if there are validation errors
    if (isBigMealError && isSnackError) {
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
    } else if (isSnackError) {
      if (!isErrorVisible) {
        alertDescription = "Tolong isi waktu makan snack dengan benar";
        isErrorVisible = true;
      }
    }

    // Force UI update to show the correct error message
    setState(() {});

    return !(isBigMealError || isSnackError);
  }

  // Helper function to parse time string into TimeOfDay
  TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return TimeOfDay(hour: 0, minute: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.neutral.shade0,
      appBar: InvisibleAppbar(title: "Preferensi"),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(top: 16, bottom: 93, left: 30, right: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AlertNotification(
                  description: alertDescription,
                  visible: isErrorVisible,
                ),
                Text("Makan Besar", style: AppFonts.medium(16)),
                SizedBox(height: 16),
                Text(
                  "Rekomendasi Makanan",
                  style: AppFonts.medium(
                    14,
                  ).copyWith(color: AppColors.neutral.shade600),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMealTimeCard("Makan Pagi", "07.30 - 09.30"),
                    _buildMealTimeCard("Makan Siang", "12.30 - 14.30"),
                    _buildMealTimeCard("Makan Malam", "16.30 - 18.30"),
                  ],
                ),
                SizedBox(height: 16),
                CustomTimePickerField(
                  title: "Makan Pagi",
                  hintText: breakfastTime ?? "Isi waktu",
                  controller: _breakfastController,
                  onTimePicked: (picked) {
                    setState(() {
                      _breakfastTime = picked;
                      isBreakfastError = false;
                      isErrorVisible = false;
                      alertDescription = "";
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
                SizedBox(height: 16),
                CustomTimePickerField(
                  title: "Makan Siang",
                  hintText: lunchTime ?? "Isi waktu",
                  controller: _lunchController,
                  onTimePicked: (picked) {
                    setState(() {
                      _lunchTime = picked;
                      isLunchError = false;
                      isErrorVisible = false;
                      alertDescription = "";
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
                SizedBox(height: 16),
                CustomTimePickerField(
                  title: "Makan Malam",
                  hintText: dinnerTime ?? "Isi waktu",
                  controller: _dinnerController,
                  onTimePicked: (picked) {
                    setState(() {
                      _dinnerTime = picked;
                      isDinnerError = false;
                      isErrorVisible = false;
                      alertDescription = "";
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
                SizedBox(height: 24),
                Text("Makan Snack", style: AppFonts.medium(16)),
                SizedBox(height: 16),
                Text(
                  "Rekomendasi Makanan",
                  style: AppFonts.medium(
                    14,
                  ).copyWith(color: AppColors.neutral.shade600),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMealTimeCard("Jumlah Makan\n Snack", "3x"),
                    _buildMealTimeCard("Maksimal waktu\n makan", "21.00"),
                  ],
                ),
                SizedBox(height: 16),
                CustomTextField(
                  title: "Berapa banyak makan (satuan kali)",
                  hintText:
                      snackIntensityString ?? "Masukkan intensitas snack Anda",
                  controller: _snackIntensityController,
                  iconAssetPath: 'assets/icons/drink_icon.png',
                  keyboardType: TextInputType.number,
                  errorText:
                      isSnackIntensityError
                          ? "Mohon isi intensitas snack"
                          : isSnackIntensityTooHighError
                          ? "Intensitas snack tidak boleh lebih dari 8"
                          : null,
                ),
                SizedBox(height: 16),
                CustomTimePickerField(
                  title: "Mulai waktu makan",
                  hintText: startSnackTime ?? "Isi disini",
                  controller: _startTimeController,
                  onTimePicked: (picked) {
                    setState(() {
                      _startTime = picked;
                      isStartTimeError = false;
                      isErrorVisible = false;
                      alertDescription = "";
                    });
                  },
                  timeRange: TimeRange.morning(),
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
                SizedBox(height: 16),
                CustomTimePickerField(
                  title: "Maksimal waktu makan",
                  hintText: maxSnackTime ?? "Isi waktu",
                  controller: _maxTimeController,
                  onTimePicked: (picked) {
                    setState(() {
                      _maxTime = picked;
                      isMaxTimeError = false;
                      isErrorVisible = false;
                      alertDescription = "";
                    });
                  },
                  timeRange: TimeRange.evening(),
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
                SizedBox(height: 24),
                MainButton(
                  text: "Simpan",
                  onPressed: () async {
                    if (!validateAndSubmit()) {
                      return;
                    }

                    setState(() {
                      isLoading = true;
                    });

                    Map<String, dynamic> updatedFields = {};

                    if (_breakfastTime != null &&
                        _breakfastTime!.format(context) != breakfastTime) {
                      updatedFields["breakfastTime"] = _breakfastTime!.format(
                        context,
                      );
                    }

                    if (_lunchTime != null &&
                        _lunchTime!.format(context) != lunchTime) {
                      updatedFields["lunchTime"] = _lunchTime!.format(context);
                    }

                    if (_dinnerTime != null &&
                        _dinnerTime!.format(context) != dinnerTime) {
                      updatedFields["dinnerTime"] = _dinnerTime!.format(
                        context,
                      );
                    }

                    if (_maxTime != null &&
                        _maxTime!.format(context) != maxSnackTime) {
                      updatedFields["maxSnackTime"] = _maxTime!.format(context);
                    }

                    if (_startTime != null &&
                        _startTime!.format(context) != startSnackTime) {
                      updatedFields["startSnackTime"] = _startTime!.format(
                        context,
                      );
                    }

                    final snackIntensityInput = int.tryParse(
                      _snackIntensityController.text.trim(),
                    );
                    if (snackIntensityInput != null &&
                        snackIntensityInput != snackIntensity) {
                      updatedFields["snackIntensity"] = snackIntensityInput;

                      int reminderInterval = (24 / snackIntensityInput).floor();
                      if (reminderInterval < 3) reminderInterval = 3;
                      updatedFields["reminderInterval"] = reminderInterval;
                    }

                    if (updatedFields.isEmpty) {
                      setState(() {
                        isLoading = false;
                        alertDescription = "Tidak ada perubahan yang disimpan.";
                        isErrorVisible = true;
                      });
                      return;
                    }

                    final result = await authService.updateUserMealAndSnackTime(
                      user!,
                      updatedFields,
                    );

                    setState(() {
                      isLoading = false;
                    });

                    if (result != null) {
                      context.go(AppRoutes.profile);
                    } else {
                      setState(() {
                        alertDescription = "Gagal menyimpan perubahan.";
                        isErrorVisible = true;
                      });
                    }
                  },
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ),
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
                12.sp,
              ).copyWith(color: AppColors.neutral.shade600),
              textAlign: TextAlign.center,
            ),
            Text(description, style: AppFonts.semiBold(12.sp)),
          ],
        ),
      ),
    );
  }
}
