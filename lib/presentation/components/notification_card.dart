import 'package:flutter/material.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';

class NotificationCard extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final String date;
  const NotificationCard({
    Key? key,
    required this.title,
    required this.description,
    required this.time,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 9.5),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral.shade900),
        color: AppColors.secondary.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/notification_mascot.png',
            width: 56,
            height: 61,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$date, $time",
                  style: AppFonts.regular(
                    10,
                  ).copyWith(color: AppColors.neutral.shade600),
                ),
                SizedBox(height: 4),
                Text(
                  title,
                  style: AppFonts.medium(
                    12,
                  ).copyWith(color: AppColors.neutral.shade900),
                ),
                Text(
                  description,
                  style: AppFonts.regular(
                    10,
                  ).copyWith(color: AppColors.neutral.shade900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
