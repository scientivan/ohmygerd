import 'package:OhMyGERD/data/services/be_service.dart';
import 'package:OhMyGERD/presentation/components/meal_location_card.dart';
import 'package:OhMyGERD/presentation/components/shimmer_loading_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:OhMyGERD/presentation/components/custom_appbar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:OhMyGERD/data/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class MealDetailLayout extends StatefulWidget {
  final String imagePath;
  final String mealName;
  final List<String> ingredients;
  final List<String> tools;
  final List<String> steps;

  const MealDetailLayout({
    super.key,
    required this.imagePath,
    required this.mealName,
    required this.ingredients,
    required this.tools,
    required this.steps,
  });

  @override
  State<MealDetailLayout> createState() => _MealDetailLayoutState();
}

class _MealDetailLayoutState extends State<MealDetailLayout>
    with SingleTickerProviderStateMixin {
  final backendService = BackendService();
  final user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  String? restaurantCount;
  bool _isLoadingRestaurants = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNearbyRestaurant();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> restaurantData = [];

  Future<void> _loadNearbyRestaurant() async {
    setState(() {
      _isLoadingRestaurants = true;
    });

    try {
      UserLocation userLocation = UserLocation();
      Position? currentPosition = await userLocation.getCurrentLocation();

      if (currentPosition != null && user != null) {
        String sementara = "-7.740148, 110.380716";
        // String positionString =
        //     "${currentPosition.latitude}, ${currentPosition.longitude}";
        String firstTwoWords = widget.mealName.split(" ").take(2).join(" ");
        final response = await backendService.loadNearbyRestaurant(
          user!,
          firstTwoWords,
          sementara,
        );

        if (mounted) {
          setState(() {
            if (response != null) {
              restaurantData = response;
            }
            restaurantCount = restaurantData.length.toString();
            _isLoadingRestaurants = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingRestaurants = false;
          });
        }
      }
    } catch (e) {
      print("Error loading nearby restaurants: $e");
      if (mounted) {
        setState(() {
          _isLoadingRestaurants = false;
        });
      }
    }
  }

  Widget _buildShimmerLocationCards() {
    return SizedBox(
      height: 90.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        padding: EdgeInsets.only(right: 16.w),
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: ShimmerLoadingCard(height: 90.h, width: 200.w),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.neutral.shade0,
      appBar: const InvisibleAppbar(),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 200.h,
            decoration:
                widget.imagePath.isNotEmpty
                    ? BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(widget.imagePath),
                        fit: BoxFit.cover,
                      ),
                    )
                    : null,
            child:
                widget.imagePath.isEmpty
                    ? ShimmerLoadingCard(
                      height: 200,
                      width: double.infinity,
                      borderRadius: 0,
                    )
                    : null,
          ),

          // Recipe name and time
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.mealName,
                    style: AppFonts.semiBold(24),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  _isLoadingRestaurants
                      ? ShimmerLoadingCard(height: 16, width: 80)
                      : Text(
                        restaurantCount != null
                            ? "$restaurantCount toko"
                            : "0 toko",
                        style: AppFonts.regular(14.r),
                      ),
                ],
              ),
            ),
          ),

          // Location recommendations
          Padding(
            padding: EdgeInsets.only(
              left: 16.0.w,
              right: 16.0.w,
              bottom: 16.0.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Rekomendasi Tempat Makan", style: AppFonts.semiBold(18)),
                SizedBox(height: 8.h),
                _isLoadingRestaurants
                    ? _buildShimmerLocationCards()
                    : SizedBox(
                      height: 90.h,
                      child:
                          restaurantData.isEmpty
                              ? Center(
                                child: Text(
                                  "Tidak ada rekomendasi tempat makan",
                                  style: AppFonts.regular(14.sp),
                                ),
                              )
                              : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: restaurantData.length,
                                padding: EdgeInsets.only(right: 16.w),
                                itemBuilder: (context, index) {
                                  final item = restaurantData[index];
                                  return Padding(
                                    padding: EdgeInsets.only(right: 12.w),
                                    child: MealLocationCard(
                                      imagePath:
                                          item['photo'] ??
                                          'assets/images/meal_placeholder.png',
                                      title: item['name'] ?? 'Unknown',
                                      time: item['estimatedTime'] ?? '?? menit',
                                      distance:
                                          item['distance']?['text'] ?? '?? km',
                                      rating:
                                          item['rating']?.toString() ?? 'N/A',
                                    ),
                                  );
                                },
                              ),
                    ),
              ],
            ),
          ),

          // Tabs
          Container(
            decoration: BoxDecoration(color: AppColors.neutral.shade0),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.neutral.shade900,
              unselectedLabelColor: Colors.grey,
              indicator: BoxDecoration(
                color: AppColors.secondary.shade200,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              indicatorPadding: EdgeInsets.symmetric(horizontal: -60.w),
              tabs: const [
                Tab(text: "Bahan & Alat"),
                Tab(text: "Langkah-langkah"),
              ],
            ),
          ),

          // TabBarView with Expanded
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Bahan & Alat
                Container(
                  color: AppColors.secondary.shade200,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Bahan", style: AppFonts.bold(20.sp)),
                        SizedBox(height: 8.h),
                        ...widget.ingredients.map(
                          (ingredient) => Padding(
                            padding: EdgeInsets.only(bottom: 16.r),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("• ", style: AppFonts.regular(14.sp)),
                                Text(
                                  ingredient,
                                  style: AppFonts.regular(14.sp),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text("Alat", style: AppFonts.bold(20.sp)),
                        SizedBox(height: 8.h),
                        ...widget.tools.map(
                          (tool) => Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("• ", style: AppFonts.regular(14.sp)),
                                Expanded(
                                  child: Text(
                                    tool,
                                    style: AppFonts.regular(14.sp),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),

                // Tab 2: Langkah-langkah
                Container(
                  color: AppColors.secondary.shade200,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Langkah-langkah", style: AppFonts.bold(20.sp)),
                        SizedBox(height: 8.h),
                        ...List.generate(
                          widget.steps.length,
                          (index) => Container(
                            margin: EdgeInsets.only(bottom: 16.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${index + 1}. ",
                                  style: AppFonts.semiBold(14.sp),
                                ),
                                Expanded(
                                  child: Text(
                                    widget.steps[index],
                                    style: AppFonts.regular(14.sp),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
