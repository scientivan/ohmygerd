import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class MealRecommendationCard extends StatelessWidget {
  final String imagePath;
  final String mealName;
  final VoidCallback? onTap;

  const MealRecommendationCard({
    Key? key,
    required this.imagePath,
    required this.mealName,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100.w, // Set a fixed width for the card
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral.shade900),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with loading state
            SizedBox(
              height: 80.h,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: imagePath,
                fit: BoxFit.contain,
                placeholder:
                    (context, url) => Shimmer.fromColors(
                      baseColor: AppColors.neutral.shade200,
                      highlightColor: AppColors.neutral.shade100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.neutral.shade400,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Image Error",
                            style: AppFonts.regular(
                              10,
                            ).copyWith(color: AppColors.neutral.shade400),
                          ),
                        ],
                      ),
                    ),
              ),
            ),

            const SizedBox(height: 8),

            // Meal name
            Text(
              mealName,
              style: AppFonts.semiBold(12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
            ),
          ],
        ),
      ),
    );
  }
}
