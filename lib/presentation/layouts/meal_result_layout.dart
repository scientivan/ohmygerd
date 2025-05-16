import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MealResultsLayout extends StatelessWidget {
  final List<dynamic> tidakAmanMeals;
  final List<dynamic> masihAmanMeals;
  final List<dynamic> sangatAmanMeals;

  const MealResultsLayout({
    Key? key,
    required this.tidakAmanMeals,
    required this.masihAmanMeals,
    required this.sangatAmanMeals,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.dangerous, color: AppColors.danger.shade300),
                text: "Tidak Aman (${tidakAmanMeals.length})",
              ),
              Tab(
                icon: Icon(Icons.warning, color: AppColors.warning.shade300),
                text: "Masih Aman (${masihAmanMeals.length})",
              ),
              Tab(
                icon: Icon(
                  Icons.check_circle,
                  color: AppColors.success.shade300,
                ),
                text: "Sangat Aman (${sangatAmanMeals.length})",
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Tidak Aman
                buildMealList(tidakAmanMeals),

                // Tab 2: Masih Aman
                buildMealList(masihAmanMeals),

                // Tab 3: Sangat Aman
                buildMealList(sangatAmanMeals),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMealList(List<dynamic> meals) {
    if (meals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_food, size: 64.w, color: AppColors.neutral.shade400),
            SizedBox(height: 16.h),
            Text(
              "Tidak ada makanan dalam kategori ini",
              style: AppFonts.medium(
                16.sp,
              ).copyWith(color: AppColors.neutral.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppColors.neutral.shade0,
      child: GridView.builder(
        padding: EdgeInsets.all(16.r),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: meals.length,
        itemBuilder: (context, index) {
          final meal = meals[index];
          return MealCard(meal: meal);
        },
      ),
    );
  }
}

// Sesuaikan MealCard agar menyesuaikan dengan data 'selectedComponents'
class MealCard extends StatelessWidget {
  final dynamic meal;

  const MealCard({Key? key, required this.meal}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = meal['status'].toString().toLowerCase();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: AppColors.neutral.shade900),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100.h,
            decoration: BoxDecoration(
              color: getStatusColor(status),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: Center(
              child: Icon(
                getStatusIcon(status),
                size: 40.w,
                color: AppColors.neutral.shade0,
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal['nama'] ?? 'Nama Komponen',
                  style: AppFonts.semiBold(16.sp),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Text(
                  meal['status'] ?? 'Status',
                  style: AppFonts.medium(
                    14.sp,
                  ).copyWith(color: AppColors.neutral.shade900),
                ),
                SizedBox(height: 8.h),
                if (meal['deskripsi'] != null)
                  Text(
                    meal['deskripsi'],
                    style: AppFonts.regular(12.sp),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'tidak aman':
        return AppColors.danger.shade300;
      case 'masih aman':
        return AppColors.secondary.shade300;
      case 'sangat aman':
        return AppColors.success.shade300;
      default:
        return AppColors.neutral.shade400;
    }
  }

  IconData getStatusIcon(String? status) {
    switch (status) {
      case 'tidak aman':
        return Icons.dangerous_sharp;
      case 'masih aman':
        return Icons.warning;
      case 'sangat aman':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }
}
