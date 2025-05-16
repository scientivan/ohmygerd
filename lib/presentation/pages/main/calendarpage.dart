import 'package:OhMyGERD/presentation/components/shimmer_loading_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:OhMyGERD/data/services/be_service.dart';
import 'package:OhMyGERD/data/services/convertGoogleDriveLink.dart';
import 'package:OhMyGERD/presentation/components/meal_history_card.dart';
import '../../../data/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shimmer/shimmer.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  Map<DateTime, int> calendarData = {};

  bool _isLoading = false;
  DateTime? selectedDate, selectedMonth;
  final List<String> mealTimes = ["Pagi", "Siang", "Malam"];
  final backendService = BackendService();
  final user = FirebaseAuth.instance.currentUser;
  int? currentStreak, currentMonthReport, currentMonthGerdCount, dailyGerdCount;
  String? currentStreakString,
      currentMonthReportString,
      currentMonthGerdCountString,
      dailyGerdCountString,
      breakfastLink,
      breakfastTime,
      breakfastComponentString,
      lunchComponentString,
      dinnerComponentString,
      lunchLink,
      lunchTime,
      dinnerLink,
      dinnerTime;

  // ScrollController to handle refresh behavior
  final ScrollController _scrollController = ScrollController();

  String? getMealTime(String mealTime) {
    switch (mealTime) {
      case 'Pagi':
        return breakfastTime;
      case 'Siang':
        return lunchTime;
      case 'Malam':
        return dinnerTime;
      default:
        return null;
    }
  }

  String? getMealComponentBasedOnMealTime(String mealTime) {
    print(
      "Getting component for $mealTime: ${_getMealComponentDebug(mealTime)}",
    );
    switch (mealTime) {
      case 'Pagi':
        return breakfastComponentString;
      case 'Siang':
        return lunchComponentString;
      case 'Malam':
        return dinnerComponentString;
      default:
        return null;
    }
  }

  // Debug helper to print component values
  String _getMealComponentDebug(String mealTime) {
    switch (mealTime) {
      case 'Pagi':
        return "breakfast: $breakfastComponentString";
      case 'Siang':
        return "lunch: $lunchComponentString";
      case 'Malam':
        return "dinner: $dinnerComponentString";
      default:
        return "unknown mealtime";
    }
  }

  String? getMealLink(String mealTime) {
    switch (mealTime) {
      case 'Pagi':
        return breakfastLink;
      case 'Siang':
        return lunchLink;
      case 'Malam':
        return dinnerLink;
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _loadCalendarData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Helper function to safely process food components
  String _processFoodComponents(List<dynamic>? components) {
    if (components == null || components.isEmpty) return "";

    try {
      return components
          .map((item) {
            // Try to get the name, using null-safe access
            String? name = item is Map ? item["nama"]?.toString() : null;
            return name ?? "";
          })
          .where((name) => name.isNotEmpty)
          .join(", ");
    } catch (e) {
      print("Error processing food components: $e");
      return "";
    }
  }

  Future<Map<String, dynamic>?> _loadMonthData(String year_month) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final resultMonth = await backendService.getDataOnSpecificMonth(
        user!,
        year_month,
      );

      if (resultMonth != null) {
        setState(() {
          currentStreak = resultMonth["currentStreak"];
          currentStreakString = currentStreak?.toString() ?? "0";

          currentMonthReport = resultMonth["monthlyReport"];
          currentMonthReportString = currentMonthReport?.toString() ?? "0";

          currentMonthGerdCount = resultMonth["monthlyGerdCount"];
          currentMonthGerdCountString =
              currentMonthGerdCount?.toString() ?? "0";

          final monthlyGerdCountDetail =
              resultMonth["monthlyGerdCountDetail"] as Map<String, dynamic>?;

          if (monthlyGerdCountDetail != null) {
            _processMonthlyGerdData(
              monthlyGerdCountDetail,
              int.parse(year_month.split('-')[0]), // year
              int.parse(year_month.split('-')[1]), // month
            );
          }
        });
      }

      return resultMonth;
    } catch (e) {
      print("Error loading month data: $e");
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDateData(String year_month_date) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final resultDate = await backendService.getDataOnSpecificDate(
        user!,
        year_month_date,
      );

      if (resultDate != null) {
        print("Loaded data for date: $year_month_date");
        print("Raw food component data: ${resultDate["foodComponent"]}");

        setState(() {
          // Process GERD data
          dailyGerdCount = resultDate["dailyGerdCount"];
          dailyGerdCountString = dailyGerdCount?.toString() ?? "0";

          // Process meal links and times
          breakfastLink = resultDate["breakfastLink"] ?? "";
          breakfastTime = resultDate["breakfastTime"] ?? "";

          lunchLink = resultDate["lunchLink"] ?? "";
          lunchTime = resultDate["lunchTime"] ?? "";

          dinnerLink = resultDate["dinnerLink"] ?? "";
          dinnerTime = resultDate["dinnerTime"] ?? "";

          // Process food components
          final foodComponent = resultDate["foodComponent"];

          if (foodComponent != null) {
            final breakfast = foodComponent["breakfast"];
            final lunch = foodComponent["lunch"];
            final dinner = foodComponent["dinner"];

            print("Breakfast raw: $breakfast");
            print("Lunch raw: $lunch");
            print("Dinner raw: $dinner");

            // Process components with robust error handling
            breakfastComponentString = _processFoodComponents(
              breakfast as List<dynamic>?,
            );
            lunchComponentString = _processFoodComponents(
              lunch as List<dynamic>?,
            );
            dinnerComponentString = _processFoodComponents(
              dinner as List<dynamic>?,
            );

            print("Processed breakfast: $breakfastComponentString");
            print("Processed lunch: $lunchComponentString");
            print("Processed dinner: $dinnerComponentString");
          } else {
            // Reset component strings if no food data
            breakfastComponentString = "";
            lunchComponentString = "";
            dinnerComponentString = "";
            print("No food component data found for date: $year_month_date");
          }
        });
      } else {
        setState(() {
          // Reset all values if no data found
          dailyGerdCount = 0;
          dailyGerdCountString = "0";
          breakfastLink = "";
          breakfastTime = "";
          lunchLink = "";
          lunchTime = "";
          dinnerLink = "";
          dinnerTime = "";
          breakfastComponentString = "";
          lunchComponentString = "";
          dinnerComponentString = "";
          print("No data found for date: $year_month_date");
        });
      }
    } catch (e) {
      print("Error loading date data for $year_month_date: $e");
      setState(() {
        // Reset on error
        breakfastComponentString = "";
        lunchComponentString = "";
        dinnerComponentString = "";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi untuk mengkonversi monthlyGerdCountDetail ke Map<DateTime, int>
  void _processMonthlyGerdData(
    Map<String, dynamic> monthlyGerdCountDetail,
    int year,
    int month,
  ) {
    calendarData.clear(); // Reset data kalender sebelum mengisi yang baru

    monthlyGerdCountDetail.forEach((dayString, gerdCount) {
      // Konversi key string (hari) ke integer
      final day = int.tryParse(dayString);
      if (day != null) {
        // Buat DateTime object untuk tanggal ini
        final date = DateTime(year, month, day);
        // Simpan jumlah GERD untuk tanggal tersebut
        if (gerdCount is int) {
          calendarData[date] = gerdCount;
        } else if (gerdCount is String) {
          calendarData[date] = int.tryParse(gerdCount) ?? 0;
        } else {
          calendarData[date] = 0;
        }
      }
    });

    print("Calendar GERD data updated: $calendarData");
  }

  Future<void> _loadCalendarData() async {
    setState(() {
      _isLoading = true;
    });

    if (user != null) {
      final now = DateTime.now();
      final year_month_date = DateFormat('yyyy-MM-dd').format(now);
      final year_month = DateFormat('yyyy-MM').format(now);

      try {
        final resultMonth = await _loadMonthData(year_month);
        await _loadDateData(year_month_date);
      } catch (e) {
        print("Error in _loadCalendarData: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    print("Refreshing calendar data...");
    await _loadCalendarData();
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Kalender"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading ? _buildShimmerContent() : _buildRefreshableContent(),
      ),
    );
  }

  // Implement the refreshable content with proper setup
  Widget _buildRefreshableContent() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.secondary.shade600,
      backgroundColor: AppColors.secondary.shade0,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section - Streak
            _buildStreakHeader(),

            // Motivation Text
            _buildMotivationBox(),

            // Calendar
            _buildCalendar(),

            // Stats Row (GERD + Streak)
            Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: _buildStatsRow(),
            ),

            // Alert Message
            _buildAlertMessage(),

            // Section Title
            Padding(
              padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
              child: Text("Riwayat Makan", style: AppFonts.semiBold(16.sp)),
            ),

            // Meal History List
            ..._buildMealHistoryList(),

            // Bottom Padding
            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }

  // Shimmer loading content
  Widget _buildShimmerContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: CalendarShimmer(),
    );
  }

  // Generate meal history list as a regular list of widgets
  List<Widget> _buildMealHistoryList() {
    return List.generate(mealTimes.length, (index) {
      final String mealTime = mealTimes[index];
      final String? mealTimeString = getMealTime(mealTime);
      final String? mealLinkString = getMealLink(mealTime);
      final String? components = getMealComponentBasedOnMealTime(mealTime);

      // Debug print
      print(
        "Building meal card for $mealTime - Time: $mealTimeString, Components: $components",
      );

      var imageLink = convertGoogleDriveLink(mealLinkString ?? "");
      return Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: MealHistoryCard(
          imageAsset: imageLink,
          title: "Makan $mealTime",
          components: components ?? "",
          mealTime: mealTime,
          time: mealTimeString ?? "",
        ),
      );
    });
  }

  Widget _buildStreakHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/icons/fire_icon.png', width: 40.w, height: 40.h),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(currentStreakString ?? "0", style: AppFonts.medium(44.sp)),
              Text('Hari streak', style: AppFonts.medium(12.sp)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationBox() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      margin: EdgeInsets.symmetric(horizontal: 25.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.secondary.shade200,
        border: Border.all(color: AppColors.neutral.shade900),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              "Makan tepat waktu adalah kunci meredakan gejala GERD. Terus jaga streakmu, demi hidup yang lebih nyaman.",
              style: AppFonts.regular(12.sp),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      pageJumpingEnabled: false,
      pageAnimationEnabled: false,
      availableGestures: AvailableGestures.none,
      focusedDay: selectedDate ?? DateTime.now(),
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      enabledDayPredicate: (day) {
        final today = DateTime.now();
        return !day.isAfter(DateTime(today.year, today.month, today.day + 1));
      },
      onPageChanged: (focusedDay) async {
        final bulan = focusedDay.month.toString().padLeft(2, '0');
        final tahun = focusedDay.year.toString();
        final yearMonth = '$tahun-$bulan';

        // Determine which date to select in the new month
        DateTime newSelectedDate;
        if (selectedDate != null &&
            selectedDate!.year == focusedDay.year &&
            selectedDate!.month == focusedDay.month) {
          newSelectedDate =
              selectedDate!; // Keep the same day if we're in the same month
        } else {
          newSelectedDate = DateTime(focusedDay.year, focusedDay.month, 1);
        }

        final newDateString = DateFormat('yyyy-MM-dd').format(newSelectedDate);

        setState(() {
          selectedMonth = focusedDay;
          selectedDate = newSelectedDate;
          _isLoading = true;
        });

        // Load both month and date data in sequence
        try {
          await _loadMonthData(yearMonth);
          await _loadDateData(newDateString);
        } catch (e) {
          print("Error in onPageChanged: $e");
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },

      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: AppColors.secondary.shade500,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.neutral.shade0,
          border: Border.all(color: AppColors.neutral.shade900),
        ),
        outsideDaysVisible: false,
        selectedTextStyle: TextStyle(color: AppColors.neutral.shade900),
        // Adjust text sizes for calendar
        defaultTextStyle: TextStyle(fontSize: 14.sp),
        weekendTextStyle: TextStyle(fontSize: 14.sp),
        todayTextStyle: TextStyle(
          fontSize: 14.sp,
          color: AppColors.neutral.shade0,
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(fontSize: 16.sp),
        leftChevronIcon: Icon(Icons.chevron_left, size: 24.r),
        rightChevronIcon: Icon(Icons.chevron_right, size: 24.r),
      ),
      selectedDayPredicate: (day) {
        return isSameDay(selectedDate, day);
      },
      onDaySelected: (selectedDay, focusedDay) async {
        print("Day selected: ${DateFormat('yyyy-MM-dd').format(selectedDay)}");
        setState(() {
          selectedDate = selectedDay;
          _isLoading = true;
        });

        final selectedDateString = DateFormat('yyyy-MM-dd').format(selectedDay);
        try {
          await _loadDateData(selectedDateString);
        } catch (e) {
          print("Error in onDaySelected: $e");
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },

      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, _) {
          int gerdLevel = _getGerdLevelForDate(date);
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${date.day}', style: TextStyle(fontSize: 14.sp)),
              if (gerdLevel > 0)
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Container(
                    width: 10.w,
                    height: 10.h,
                    decoration: BoxDecoration(
                      color: _getColorByGerdLevel(gerdLevel),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  int _getGerdLevelForDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return calendarData[normalized] ?? 0;
  }

  Color _getColorByGerdLevel(int level) {
    switch (level) {
      case 1:
        return AppColors.danger.shade100;
      case 2:
        return AppColors.danger.shade200;
      case >= 3:
        return AppColors.danger.shade600;
      default:
        return AppColors.neutral.shade0;
    }
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            color: AppColors.danger.shade200,
            iconPath: 'assets/icons/stomach_icon.png',
            value: currentMonthGerdCountString ?? "0",
            label: 'GERD Bulanan',
          ),
        ),

        SizedBox(width: 12.w),

        Expanded(
          child: _buildStatCard(
            color: AppColors.secondary.shade200,
            iconPath: 'assets/icons/fire_yellow.png',
            value: currentMonthReportString ?? "0",
            label: 'Days Report',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required Color color,
    required String iconPath,
    required String value,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.neutral.shade900),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 24.w, height: 24.h),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppFonts.medium(16.sp)),
              Text(label, style: AppFonts.medium(10.sp)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertMessage() {
    final int gerdCount = dailyGerdCount ?? 0;
    final bool isGerdFree = gerdCount == 0;

    // Determine colors and text based on GERD status
    final Color borderColor =
        isGerdFree
            ? AppColors
                .success
                .shade300 // Green border for GERD-free
            : AppColors.danger.shade300; // Red border for GERD occurrences

    final Color textColor =
        isGerdFree
            ? AppColors
                .success
                .shade300 // Green text for GERD-free
            : AppColors.danger.shade300; // Red text for GERD occurrences

    final String messageText =
        isGerdFree
            ? "Hore! Kamu tidak mengalami GERD hari ini. Tetap jaga pola makanmu ya!"
            : "Yah, kamu telah mengalami GERD sebanyak $gerdCount kali di hari ini";

    final String iconPath =
        'assets/icons/mascot_icon.png'; // Default mascot icon

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      margin: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.neutral.shade0,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Image.asset(iconPath, width: 40.w, height: 40.h),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              messageText,
              style: AppFonts.medium(12.sp).copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
