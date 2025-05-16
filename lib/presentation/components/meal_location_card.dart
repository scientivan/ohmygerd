import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MealLocationCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String distance;
  final String time;
  final String rating;

  const MealLocationCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.time,
    required this.distance,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    // Tetapkan lebar tetap untuk card
    return Container(
      width: 280.w, // Tambahkan lebar tetap untuk card
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral.shade900),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Gunakan MainAxisSize.min, bukan max
        children: [
          // Tetap gunakan lebar tetap untuk gambar
          SizedBox(
            width: 100.w,
            height: 100.w,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(7.r),
                bottomLeft: Radius.circular(7.r),
              ),
              child: Image.network(
                imagePath,
                fit: BoxFit.cover, // Gunakan BoxFit.cover alih-alih fill
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  } else {
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                        color: AppColors.neutral.shade400,
                      ),
                    );
                  }
                },
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/meal_placeholder.png',
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ),

          // Gunakan Flexible dengan loose fit, bukan Expanded
          Flexible(
            fit: FlexFit.loose,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 12.5.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$distance • $time",
                    style: AppFonts.regular(
                      10.sp,
                    ).copyWith(color: AppColors.neutral.shade400),
                  ),
                  Text(
                    title,
                    style: AppFonts.semiBold(14.sp),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1, // Batasi maksimal 2 baris
                  ),
                  Text(
                    "⭐ $rating",
                    style: AppFonts.regular(
                      10,
                    ).copyWith(color: AppColors.neutral.shade400),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
