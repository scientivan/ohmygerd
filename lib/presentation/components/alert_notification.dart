import 'package:flutter/material.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';

class AlertNotification extends StatelessWidget {
  final String? description;
  final bool visible;

  const AlertNotification({
    required this.description,
    this.visible = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: Column(
        children: [
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.danger.shade200,
                border: Border.all(color: AppColors.danger.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 8),
                  Image.asset("assets/icons/alarm_icon.png"),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(description!, style: AppFonts.regular(14)),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
