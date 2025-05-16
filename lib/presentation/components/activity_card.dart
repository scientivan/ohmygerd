import 'dart:ffi';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:OhMyGERD/data/services/be_service.dart';
import 'package:OhMyGERD/presentation/providers/water_activity_provider.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/flutter_percent_indicator.dart';
import 'package:provider/provider.dart';

enum ActivityStatus { active, inactive, success }

class MealActivityCard extends StatelessWidget {
  final String title;
  final String description;
  final String activeImage;
  final String inActiveImage;
  final ActivityStatus activityStatus;
  final Function()? onClick;
  MealActivityCard({
    Key? key,
    required this.title,
    required this.description,
    required this.activeImage,
    required this.inActiveImage,
    required this.activityStatus,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            margin: EdgeInsets.only(top: 4, bottom: 4, right: 8),
            child: Image.asset(_getStatusImage()),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.medium(14).copyWith(color: _getTextColor()),
                ),
                Text(
                  description,
                  style: AppFonts.medium(
                    12,
                  ).copyWith(color: AppColors.neutral.shade500),
                ),
              ],
            ),
          ),
          if (activityStatus == ActivityStatus.active)
            GestureDetector(
              onTap: onClick,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.neutral.shade0,
                  border: Border.all(color: AppColors.neutral.shade900),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: 2.4,
                        bottom: 2.4,
                        right: 4.0,
                      ),
                      child: Image.asset("assets/icons/scan_alt.png"),
                    ),
                    Text(
                      "Scan",
                      style: AppFonts.semiBold(
                        14,
                      ).copyWith(color: AppColors.neutral.shade900),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (activityStatus) {
      case ActivityStatus.active:
        return AppColors.secondary.shade200;
      case ActivityStatus.inactive:
        return AppColors.neutral.shade100;
      case ActivityStatus.success:
        return AppColors.success.shade200;
    }
  }

  String _getStatusImage() {
    switch (activityStatus) {
      case ActivityStatus.active:
        return activeImage;
      case ActivityStatus.inactive:
        return inActiveImage;
      case ActivityStatus.success:
        return "assets/icons/success_icon.png";
    }
  }

  Color _getTextColor() {
    switch (activityStatus) {
      case ActivityStatus.active:
        return AppColors.neutral.shade900;
      case ActivityStatus.inactive:
        return AppColors.neutral.shade600;
      case ActivityStatus.success:
        return AppColors.success.shade400;
    }
  }
}

class WaterActivityCard extends StatefulWidget {
  const WaterActivityCard({Key? key}) : super(key: key);

  @override
  State<WaterActivityCard> createState() => _WaterActivityCardState();
}

class _WaterActivityCardState extends State<WaterActivityCard>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _onTapDown(_) {
    _controller.forward();
  }

  void _onTapUp(_) {
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waterProvider = Provider.of<WaterActivityProvider>(context);
    bool isIndicatorFull =
        waterProvider.currentVolume >= waterProvider.maxVolume &&
        waterProvider.currentVolume > 0;
    int waterVolumeInt = waterProvider.currentVolume.toInt();
    int maxVolumeInt = waterProvider.maxVolume.toInt();
    String waterVolumeText = "$waterVolumeInt/$maxVolumeInt mL";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color:
            isIndicatorFull
                ? AppColors.success.shade200
                : AppColors.secondary.shade200,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 4, right: 8),
            child:
                isIndicatorFull
                    ? Image.asset('assets/icons/success_icon.png')
                    : Image.asset('assets/icons/bottle_icon.png'),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Minum Air",
                  style: AppFonts.medium(14).copyWith(
                    color:
                        isIndicatorFull
                            ? AppColors.success.shade300
                            : AppColors.neutral.shade900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: LinearPercentIndicator(
                        lineHeight: 5,
                        percent: waterProvider.percent.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade300,
                        progressColor:
                            isIndicatorFull
                                ? AppColors.success.shade300
                                : AppColors.primary.shade400,
                        barRadius: const Radius.circular(20),
                        progressBorderColor: AppColors.neutral.shade900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      waterVolumeText,
                      style: AppFonts.medium(
                        10,
                      ).copyWith(color: AppColors.neutral.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isIndicatorFull)
            GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: (details) async {
                _onTapUp(details);
                waterProvider.addWater(100);
              },
              onTapCancel: () {
                setState(() {
                  _scale = 1.0;
                });
              },
              child: AnimatedScale(
                scale: _scale,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeInOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.neutral.shade0,
                    border: Border.all(color: AppColors.neutral.shade900),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 2.4,
                          bottom: 2.4,
                          right: 4.0,
                        ),
                        child: Image.asset("assets/icons/plus_alt.png"),
                      ),
                      Text(
                        "100 mL",
                        style: AppFonts.semiBold(
                          12,
                        ).copyWith(color: AppColors.neutral.shade900),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
