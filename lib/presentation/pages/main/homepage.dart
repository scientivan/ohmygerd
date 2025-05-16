import 'dart:convert';
import 'dart:io';
import 'package:OhMyGERD/presentation/components/shimmer_loading_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:OhMyGERD/data/models/meal_model.dart';
import 'package:OhMyGERD/presentation/components/activity_card.dart';
import 'package:OhMyGERD/presentation/components/custom_buttons.dart';
import 'package:OhMyGERD/presentation/components/custom_fields.dart';
import 'package:OhMyGERD/presentation/components/meal_recommendation_card.dart';
import 'package:OhMyGERD/presentation/components/shimmer_loading_card.dart';
import 'package:OhMyGERD/presentation/providers/meal_activity_provider.dart';
import 'package:OhMyGERD/presentation/providers/water_activity_provider.dart';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/be_service.dart';
import '../../../data/services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  final _auth = FirebaseAuth.instance;
  final user = FirebaseAuth.instance.currentUser;
  final authService = AuthService();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final mealProvider = Provider.of<MealActivityProvider>(
        context,
        listen: false,
      );

      await mealProvider.checkForDayReset();

      mealProvider.updateMealStatuses();

      mealProvider.printDebugInfo();
      await mealProvider.debugDateAndResetInfo();

      final isFirstLaunch = await mealProvider.isFirstLaunchOfDay();
      if (isFirstLaunch) {
        _showDailyFormDialog();
      }
    });
  }

  List<Map<String, dynamic>> mealRecommendations = [];
  bool isLoading = true; // Start with loading state true
  bool isLoadingRecommendations =
      true; // Loading state for meal recommendations
  final backendService = BackendService();
  ActivityStatus _mealStatus = ActivityStatus.active;
  int currentStreak = 0;
  String? currentStreakString, username;
  String? imageLink;

  List? makananTidakAman = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (username == null || imageLink == null) {
      _initProfile();
    }

    _loadMealRecommendation();

    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final message = args?['message'] ?? 'No message';
    if (message == 'success') {
      if (!mounted) return;
      setState(() {
        _mealStatus = ActivityStatus.success;
      });
    }
  }

  Future<void> _refreshHomePage() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      isLoadingRecommendations = true;
    });

    await _initProfile();

    await _loadMealRecommendation();

    Provider.of<MealActivityProvider>(
      context,
      listen: false,
    ).updateMealStatuses();

    await Provider.of<MealActivityProvider>(
      context,
      listen: false,
    ).checkForDayReset();
  }

  Future<void> _initProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (user != null) {
        final profile = await authService.getProfileData(user!);

        if (!mounted) return;
        if (profile != null) {
          setState(() {
            currentStreak = profile['currentStreak'] ?? 0;
            currentStreakString = currentStreak.toString();
            imageLink = profile['profilePicture'];
            username = profile["name"];
            print(
              "Profile data set: username=$username, imageLink=$imageLink, currentStreak=$currentStreak",
            );
          });
        } else {
          print("Profile data is null or empty");
        }
      } else {
        print("User is null, cannot fetch profile");
      }
    } catch (e) {
      print("Error fetching profile data: $e");
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMealRecommendation() async {
    setState(() {
      isLoadingRecommendations = true;
    });

    try {
      if (user != null) {
        final result = await backendService.getMealRecommendation(user!);

        if (!mounted) return;
        setState(() {
          if (result != null) {
            mealRecommendations = List<Map<String, dynamic>>.from(result);
          }
          isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      print("Error fetching meal recommendations: $e");
      if (mounted) {
        setState(() {
          isLoadingRecommendations = false;
        });
      }
    }
  }

  String? selectedOption;
  String? gerdOccured;
  void _showDailyFormDialog() {
    String? dialogErrorText;
    bool hasGERD = false;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              void validateAndSubmit() async {
                if (selectedOption == null) {
                  setDialogState(
                    () =>
                        dialogErrorText =
                            "Silakan pilih apakah Anda mengalami GERD.",
                  );

                  return;
                }
                print(selectedOption);
                if (selectedOption == "Ya" && gerdOccured == null) {
                  setDialogState(
                    () =>
                        dialogErrorText =
                            "Silakan pilih berapa kali mengalami GERD.",
                  );
                  return;
                }

                // Store the GERD status before async operations
                hasGERD = selectedOption == "Ya";

                final now = DateTime.now();
                final date = now.toUtc().toIso8601String();
                int gerdCount = hasGERD ? int.parse(gerdOccured!) : 0;

                final response = await backendService.sendDailyGerdReport(
                  user!,
                  date,
                  gerdCount,
                );
                print(response);

                Provider.of<MealActivityProvider>(
                  context,
                  listen: false,
                ).markDailyFormShown();

                Navigator.of(dialogContext).pop(hasGERD);
              }

              return AlertDialog(
                backgroundColor: AppColors.neutral.shade0,
                title: Text(
                  "Daily Report",
                  style: AppFonts.bold(18),
                  textAlign: TextAlign.center,
                ),
                content: SingleChildScrollView(
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dialogErrorText != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.danger.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.danger.shade300,
                              ),
                            ),
                            child: Text(
                              dialogErrorText!,
                              style: AppFonts.medium(
                                12,
                              ).copyWith(color: AppColors.danger.shade500),
                            ),
                          ),
                        CustomDropDownField(
                          title: "Apakah anda mengalami GERD?",
                          hintText: "",
                          items: ["Ya", "Tidak"],
                          selectedItem: selectedOption,
                          onChanged: (val) {
                            setDialogState(() {
                              selectedOption = val;
                              dialogErrorText = null;
                              if (val != "Ya") gerdOccured = null;
                            });
                          },
                        ),
                        if (selectedOption == "Ya") ...[
                          SizedBox(height: 8),
                          CustomDropDownField(
                            title: "Berapa kali?",
                            hintText: "",
                            items: ["1", "2", "3", "4", "5"],
                            selectedItem: gerdOccured,
                            onChanged: (val) {
                              setDialogState(() {
                                gerdOccured = val;
                                dialogErrorText = null;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  MainButton(text: "Kirim", onPressed: validateAndSubmit),
                ],
              );
            },
          ),
    ).then((hasGERD) {
      if (hasGERD == true) {
        _showGerdTriggerInfoDialog().then((_) {
          if (mounted) {
            _showThankYouDialog(context);
          }
        });
      } else if (mounted) {
        _showThankYouDialog(context);
      }
    });
  }

  Future<void> _showGerdTriggerInfoDialog() async {
    late List<dynamic> selectedComponents;
    final now = DateTime.now();
    final year_month_date = DateFormat('yyyy-MM-dd').format(now);
    final result = await backendService.sendGerdTriggerInformation(
      user!,
      year_month_date,
    );

    try {
      bool hasUnsafeFood = false;
      bool hasReportedFood = false;

      if (result != null) {
        final decoded =
            result is String
                ? json.decode(result as String)
                : result as Map<String, dynamic>;

        print("Decoded response: $decoded");

        if (decoded.containsKey('foodComponent') &&
            decoded['foodComponent'] != null) {
          final breakfast =
              decoded['foodComponent']['breakfast'] is List
                  ? decoded['foodComponent']['breakfast'] as List
                  : <dynamic>[];

          final lunch =
              decoded['foodComponent']['lunch'] is List
                  ? decoded['foodComponent']['lunch'] as List
                  : <dynamic>[];

          final dinner =
              decoded['foodComponent']['dinner'] is List
                  ? decoded['foodComponent']['dinner'] as List
                  : <dynamic>[];

          hasReportedFood =
              breakfast.isNotEmpty || lunch.isNotEmpty || dinner.isNotEmpty;

          List<dynamic> allComponents = [...breakfast, ...lunch, ...dinner];

          selectedComponents =
              allComponents
                  .where(
                    (item) =>
                        item['status'].toString().toLowerCase() == 'tidak aman',
                  )
                  .toList();

          hasUnsafeFood = selectedComponents.isNotEmpty;

          if (!hasReportedFood) {
            // Case 3: User didn't report any food
            selectedComponents = [
              {
                'nama': 'Anda belum melaporkan makanan apapun',
                'status': 'Tidak Aman',
              },
            ];
          } else if (!hasUnsafeFood) {
            // Case 2: All reported food components are safe
            selectedComponents = [
              {'nama': 'Semua makanan anda aman dikonsumsi', 'status': 'Aman'},
            ];
          }
          // Case 1: User has reported food and some components are unsafe
          // This is handled by default since selectedComponents already contains unsafe food items
        }
        // else dari kalok gaada foodcomponent
        else {
          print("Response doesn't contain 'foodComponent' or it's null");
          selectedComponents = [
            {
              'nama': 'Data komponen makanan tidak tersedia',
              'status': 'Tidak Aman',
            },
          ];
        }
      }
      // else dari result != null
      else {
        print("API result is null");
        selectedComponents = [
          {'nama': 'Gagal memuat data', 'status': 'Tidak Aman'},
        ];
      }
    } catch (e) {
      print("Error processing food component data: $e");
      selectedComponents = [
        {
          'nama': 'Terjadi kesalahan saat memproses data',
          'status': 'Tidak Aman',
        },
      ];
    }
    // Pastikan komponen makanan diambil dari field foodComponent

    if (!mounted) return;

    return showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.neutral.shade0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.r),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.report_rounded,
                  color: AppColors.secondary.shade300,
                  size: 60.w,
                ),
                SizedBox(height: 16.h),
                Center(
                  child: Text(
                    "List makanan tidak aman yang anda makan kemarin",
                    style: AppFonts.semiBold(16.sp),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 16.h),
                // TABEL STATUS
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: 16.h),
                            Container(
                              padding: EdgeInsets.all(12.r),
                              width: double.infinity,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // KASUS 1: List makanan tidak aman
                                  if (selectedComponents.isNotEmpty &&
                                      selectedComponents[0]['nama'] !=
                                          'Semua makanan anda aman dikonsumsi' &&
                                      selectedComponents[0]['nama'] !=
                                          'Anda belum melaporkan makanan apapun' &&
                                      selectedComponents[0]['nama'] !=
                                          'Data komponen makanan tidak tersedia' &&
                                      selectedComponents[0]['nama'] !=
                                          'Gagal memuat data' &&
                                      selectedComponents[0]['nama'] !=
                                          'Terjadi kesalahan saat memproses data')
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.center,
                                      children:
                                          selectedComponents.map<Widget>((
                                            item,
                                          ) {
                                            return Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12.w,
                                                vertical: 8.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    AppColors.danger.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                                border: Border.all(
                                                  color:
                                                      AppColors
                                                          .neutral
                                                          .shade900,
                                                ),
                                              ),
                                              child: Text(
                                                item['nama'],
                                                style: AppFonts.semiBold(12.sp),
                                                textAlign: TextAlign.center,
                                              ),
                                            );
                                          }).toList(),
                                    )
                                  // KASUS 2: Semua makanan aman
                                  else if (selectedComponents.isNotEmpty &&
                                      selectedComponents[0]['nama'] ==
                                          'Semua makanan anda aman dikonsumsi')
                                    Text(
                                      "Dari catatan makanan kemarin, tidak terlihat ada pemicu GERD. Bisa jadi faktor lain seperti stres atau kurang tidur yang berperan. Yuk, coba istirahat cukup dan kelola stres dengan baik 😊",
                                      style: AppFonts.medium(16).copyWith(
                                        color: AppColors.neutral.shade400,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                  // KASUS 3: Belum melaporkan makanan
                                  else if (selectedComponents.isNotEmpty &&
                                      selectedComponents[0]['nama'] ==
                                          'Data komponen makanan tidak tersedia')
                                    Column(
                                      children: [
                                        Text(
                                          "Kemarin belum ada laporan makanan nih. Yuk, mulai konsisten lagi dari sekarang!",
                                          style: AppFonts.medium(16).copyWith(
                                            color: AppColors.neutral.shade400,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 12),
                                        Icon(
                                          CupertinoIcons.smiley,
                                          color: AppColors.neutral.shade400,
                                          size: 32,
                                        ),
                                      ],
                                    )
                                  // Kasus error lainnya
                                  else
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        selectedComponents[0]['nama'],
                                        style: AppFonts.semiBold(12),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
            ),
            actions: [
              RedMainButton(
                text: "Tutup",
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
    );
  }

  void _showThankYouDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.neutral.shade0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset("assets/images/biodata_mascot.png"),
                SizedBox(height: 16),
                Text(
                  "Laporan harian Anda telah berhasil disimpan.",
                  style: AppFonts.regular(
                    14,
                  ).copyWith(color: AppColors.neutral.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              RedMainButton(
                text: "Tutup",
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
    );
  }

  Future<void> _takePictureAndProcess(
    BuildContext context,
    String mealType,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      await context.push(AppRoutes.foodComponent, extra: File(pickedFile.path));

      final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
      final message = args?['message'] ?? 'No message';

      if (message == 'success') {
        Provider.of<MealActivityProvider>(
          context,
          listen: false,
        ).completeMeal(mealType);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealActivityProvider>().updateMealStatuses();
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshHomePage,
          color: AppColors.secondary.shade600,
          backgroundColor: AppColors.secondary.shade0,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 12.h, left: 28.w, right: 28.w),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: AppColors.neutral.shade0,
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                "assets/icons/fire_icon.png",
                                height: 21.h,
                                width: 21.w,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                currentStreakString ?? "0",
                                style: AppFonts.medium(14.sp),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Profile Section
                          isLoading
                              ? ProfileShimmer()
                              : Expanded(
                                child: Row(
                                  children: [
                                    ClipOval(
                                      child:
                                          (imageLink != null &&
                                                  imageLink!.isNotEmpty)
                                              ? Image.network(
                                                imageLink!,
                                                width: 46.w,
                                                height: 46.h,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Center(
                                                    child: CircularProgressIndicator(
                                                      value:
                                                          loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  loadingProgress
                                                                      .expectedTotalBytes!
                                                              : null,
                                                      color:
                                                          AppColors
                                                              .neutral
                                                              .shade400,
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Image.asset(
                                                    'assets/images/photo_profile_placeholder.png',
                                                    width: 46.w,
                                                    height: 46.h,
                                                  );
                                                },
                                              )
                                              : Image.asset(
                                                'assets/images/photo_profile_placeholder.png',
                                                width: 46.w,
                                                height: 46.h,
                                              ),
                                    ),
                                    SizedBox(width: 8.w),

                                    // Username and Streak Text
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Hi, ${username ?? 'user'}",
                                            style: AppFonts.semiBold(18.sp),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            "Semangat kejar streak hari ini ! 💪",
                                            style: AppFonts.medium(12.sp),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                          // Notification Icon
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.notification),
                            child: Image.asset(
                              'assets/icons/notification_icon.png',
                              width: 50.w,
                              height: 50.h,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30.h),

                      // SOS Slider
                      ConfirmationSlider(
                        onConfirmation: () {
                          String emergencyMessage =
                              "Apa pertolongan pertama saat terkena GERD dan nomor darurat yang dapat dihubungi";
                          context.push(
                            AppRoutes.chatbot,
                            extra: {
                              'useRootNavigator': true,
                              'emergencyMessage': emergencyMessage,
                            },
                          );
                        },

                        height: 40.h,
                        width: 0.92.sw,
                        backgroundColor: AppColors.danger.shade200,
                        foregroundColor: AppColors.danger.shade300,
                        iconColor: AppColors.danger.shade300,
                        text: "Geser kanan untuk SOS",
                        textStyle: AppFonts.semiBold(
                          16.sp,
                        ).copyWith(color: AppColors.danger.shade300),
                        shadow: BoxShadow(color: Colors.transparent),
                        backgroundColorEnd: AppColors.danger.shade300,
                        sliderButtonContent: Icon(
                          Icons.alarm,
                          color: AppColors.danger.shade300,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Consumer<MealActivityProvider>(
                        builder: (context, provider, child) {
                          return Column(
                            children: [
                              // Makan Pagi
                              MealActivityCard(
                                title: "Makan Pagi",
                                description: "Jangan lupa foto ya",
                                activityStatus: provider.breakfastStatus,
                                activeImage:
                                    "assets/icons/breakfast_active.png",
                                inActiveImage:
                                    "assets/icons/breakfast_inactive.png",
                                onClick:
                                    provider.breakfastStatus ==
                                            ActivityStatus.active
                                        ? () async {
                                          if (user != null) {
                                            await _takePictureAndProcess(
                                              context,
                                              "breakfast",
                                            );
                                          }
                                          provider.updateMealStatuses();
                                        }
                                        : null,
                              ),

                              // Makan Siang
                              MealActivityCard(
                                title: "Makan Siang",
                                description: "Jangan lupa foto ya",
                                activityStatus: provider.lunchStatus,
                                activeImage: "assets/icons/lunch_active.png",
                                inActiveImage:
                                    "assets/icons/lunch_inactive.png",
                                onClick:
                                    provider.lunchStatus ==
                                            ActivityStatus.active
                                        ? () async {
                                          if (user != null) {
                                            await _takePictureAndProcess(
                                              context,
                                              "lunch",
                                            );
                                          }
                                          provider.updateMealStatuses();
                                          setState(() {});
                                        }
                                        : null,
                              ),

                              // Makan Malem
                              MealActivityCard(
                                title: "Makan Malam",
                                description: "Jangan lupa foto ya",
                                activityStatus: provider.dinnerStatus,
                                activeImage: "assets/icons/dinner_active.png",
                                inActiveImage:
                                    "assets/icons/dinner_inactive.png",
                                onClick:
                                    provider.dinnerStatus ==
                                            ActivityStatus.active
                                        ? () async {
                                          if (user != null) {
                                            await _takePictureAndProcess(
                                              context,
                                              "dinner",
                                            );
                                          }
                                          provider.updateMealStatuses();
                                        }
                                        : null,
                              ),

                              // Water Activity Card
                              WaterActivityCard(),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Rekomendasi Makanan",
                          style: AppFonts.semiBold(16),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ),
                SizedBox(
                  height: 162.h,
                  child:
                      isLoadingRecommendations
                          ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.only(left: 28.w, right: 16.r),
                            itemCount: 5, // Show 3 shimmer cards
                            itemBuilder: (context, index) {
                              return MealRecommendationShimmer();
                            },
                          )
                          : mealRecommendations.isNotEmpty
                          ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.only(left: 28, right: 16),
                            itemCount: mealRecommendations.length,
                            itemBuilder: (context, index) {
                              final meal = mealRecommendations[index];
                              return Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: MealRecommendationCard(
                                  imagePath:
                                      meal['imagePath'] ??
                                      "https://drive.google.com/uc?export=download&id=1lxsvBUKFtd8E3XG4RRAF9vLrdGqKPMDl",
                                  mealName: meal['nama'] ?? "",
                                  onTap: () {
                                    final mealItem =
                                        MealModel.mealCatalog[meal['nama']];
                                    if (mealItem != null) {
                                      context.push(
                                        AppRoutes.mealDetails,
                                        extra: mealItem,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Detail for ${meal['nama']} not available',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          )
                          : Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Tidak ada rekomendasi makanan saat ini',
                                    style: AppFonts.medium(14).copyWith(
                                      color: AppColors.neutral.shade500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Icon(
                                    Icons.no_meals,
                                    color: AppColors.neutral.shade400,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),
                ),
                SizedBox(height: 20.h),
                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
