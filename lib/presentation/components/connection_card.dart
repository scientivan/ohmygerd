import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';

class ConnectionCard extends StatelessWidget {
  final String mail;
  final VoidCallback onTap;

  const ConnectionCard({super.key, required this.mail, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(mail), // Unique key buat Slidable
      endActionPane: ActionPane(
        motion: ScrollMotion(), // Animasi gesernya
        children: [
          SlidableAction(
            onPressed: (context) => onTap(),
            backgroundColor: AppColors.danger.shade300,
            foregroundColor: AppColors.neutral.shade0,
            icon: Icons.delete,
            label: 'Hapus',
            borderRadius: BorderRadius.circular(9.r),
            
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 16.w),
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: AppColors.secondary.shade100,
          border: Border.all(color: AppColors.neutral.shade900),
          borderRadius: BorderRadius.circular(9.r)
        ),
        child: Row(
          children: [
            Icon(Icons.mail),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                mail,
                style: AppFonts.medium(
                  16,
                ).copyWith(color: AppColors.neutral.shade800),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
