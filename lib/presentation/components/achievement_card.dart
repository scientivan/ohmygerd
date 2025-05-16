import 'package:OhMyGERD/core/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:OhMyGERD/core/colors.dart';

class AchievementCard extends StatelessWidget {
  final String imagePath;
  final bool isActive;
  final double? width;
  final double? height;

  const AchievementCard({
    super.key,
    required this.imagePath,
    this.isActive = true,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Use context-based sizing or provided size with fallbacks
    final cardWidth = width ?? 100.0;
    final cardHeight = height ?? 120.0;
    final imageSize = cardWidth; // Make image 70% of card width

    return Container(
      width: cardWidth,
      height: cardHeight,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:
            isActive
                ? AppColors.secondary.shade100
                : AppColors.neutral.shade100,
        border: Border.all(
          color:
              isActive
                  ? AppColors.secondary.shade300
                  : AppColors.neutral.shade700,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Opacity(
        opacity: isActive ? 1.0 : 0.5,
        child: Center(
          child:
              isActive
                  ? Image.asset(
                    imagePath,
                    width: imageSize,
                    height: imageSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $imagePath - $error');
                      return Container(
                        width: imageSize,
                        height: imageSize,
                        color: Colors.grey.shade300,
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  )
                  : Container(
                    width: imageSize,
                    height: imageSize,
                    child: Icon(Icons.lock),
                  ),
        ),
      ),
    );
  }
}
