import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';

class MealHistoryCard extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String components;
  final String time;
  final String mealTime;
  const MealHistoryCard({
    required this.imageAsset,
    required this.title,
    required this.components,
    required this.time,
    required this.mealTime,
    Key? key,
  });

  @override
  Widget build(BuildContext context) {
    return time != ""
        ? Container(
          padding: EdgeInsets.all(8.r),
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            color: AppColors.secondary.shade200,
            border: Border.all(color: AppColors.neutral.shade900),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle),
                width: 65.w,
                height: 65.h,
                child: ClipOval(
                  child:
                      imageAsset.isNotEmpty
                          ? Image.network(
                            imageAsset,
                            width: 65.w,
                            height: 65.h,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/placeholder_meal_log.png',
                                width: 65.w,
                                height: 65.h,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                          : Image.asset(
                            'assets/images/placeholder_meal_log.png',
                            width: 65.w,
                            height: 65.h,
                            fit: BoxFit.cover,
                          ),
                ),
              ),

              SizedBox(width: 10.w),
              Expanded(
                child: Container(
                  height: 85.h,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppFonts.medium(16.sp),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      Text(components, style: AppFonts.medium(10.sp)),
                      Text(
                        time,
                        style: AppFonts.medium(
                          12.sp,
                        ).copyWith(color: AppColors.neutral.shade500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        : Text(
          "• Yah, anda tidak makan ${mealTime.toLowerCase()}!",
          style: AppFonts.medium(
            14,
          ).copyWith(color: AppColors.neutral.shade600),
        );
  }
}
