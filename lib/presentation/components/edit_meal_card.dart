import 'package:flutter/material.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';

class MealHistoryCard extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String components;
  final String time;
  const MealHistoryCard({
    required this.imageAsset,
    required this.title,
    required this.components,
    required this.time,
    Key? key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.secondary.shade200,
        border: Border.all(color: AppColors.neutral.shade900),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(shape: BoxShape.circle),
            width: 65,
            height: 65,
            child: ClipOval(
              child:
                  imageAsset.isNotEmpty
                      ? Image.network(
                        imageAsset,
                        width: 65,
                        height: 65,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/placeholder_meal_log.png',
                            width: 65,
                            height: 65,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                      : Image.asset(
                        'assets/images/placeholder_meal_log.png',
                        width: 65,
                        height: 65,
                        fit: BoxFit.cover,
                      ),
            ),
          ),

          SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 85,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppFonts.medium(16)),
                  Text(components, style: AppFonts.medium(10)),
                  Text(
                    time,
                    style: AppFonts.medium(
                      12,
                    ).copyWith(color: AppColors.neutral.shade500),
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
