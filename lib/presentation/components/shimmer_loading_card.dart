import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:OhMyGERD/core/colors.dart';

extension SizeExtensions on double {
  double get w => this;
  double get h => this;
  double get r => this; // Untuk borderRadius, sama aja kayak size
}

class ShimmerLoadingCard extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;

  const ShimmerLoadingCard({
    Key? key,
    this.height = 80,
    this.width = 100.0,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.neutral.shade200,
      highlightColor: AppColors.neutral.shade100,
      child: Container(
        height: height.h,
        width: width.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius.r),
        ),
      ),
    );
  }
}

class MealRecommendationShimmer extends StatelessWidget {
  const MealRecommendationShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 120.w,
        child: Shimmer.fromColors(
          baseColor: AppColors.neutral.shade200,
          highlightColor: AppColors.neutral.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                height: 70.h,
                width: 160.w,
                decoration: BoxDecoration(
                  color: AppColors.neutral.shade200,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                height: 10.h,
                width: 80.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Profile image shimmer
        ShimmerLoadingCard(
          height: 46.h,
          width: 46.w,
          borderRadius: 23.r, // Make it circular
        ),
        SizedBox(width: 8.w),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name shimmer
            ShimmerLoadingCard(height: 20.h, width: 100.w),
            SizedBox(height: 4.h),
            // Text shimmer
            ShimmerLoadingCard(height: 12.h, width: 150.w),
          ],
        ),
      ],
    );
  }
}

class CalendarShimmer extends StatelessWidget {
  const CalendarShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShimmerLoadingCard(width: 40, height: 40, borderRadius: 10),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoadingCard(width: 60, height: 44),
                  SizedBox(height: 4),
                  ShimmerLoadingCard(width: 80, height: 12),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        Center(child: ShimmerLoadingCard(width: 300, height: 60)),
        SizedBox(height: 16),

        ShimmerLoadingCard(width: double.infinity, height: 300),
        SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: ShimmerLoadingCard(width: double.infinity, height: 60),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ShimmerLoadingCard(width: double.infinity, height: 60),
            ),
          ],
        ),
        SizedBox(height: 16),

        ShimmerLoadingCard(width: double.infinity, height: 70),
        SizedBox(height: 16),

        ShimmerLoadingCard(width: 120, height: 20),
        SizedBox(height: 16),

        // Meal History Shimmer
        for (int i = 0; i < 3; i++) ...[
          MealHistoryCardShimmer(),
          SizedBox(height: 12),
        ],
      ],
    );
  }
}

class MealHistoryCardShimmer extends StatelessWidget {
  const MealHistoryCardShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.neutral.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Image placeholder
          ShimmerLoadingCard(width: 64, height: 64),
          SizedBox(width: 12),

          // Content placeholders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoadingCard(width: 100, height: 16),
                SizedBox(height: 8),
                ShimmerLoadingCard(width: 150, height: 12),
                SizedBox(height: 8),
                ShimmerLoadingCard(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
