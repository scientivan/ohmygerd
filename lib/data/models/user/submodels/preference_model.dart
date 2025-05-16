import 'package:flutter/material.dart';

class MealPreference {
  final TimeOfDay? breakfastTime;
  final TimeOfDay? lunchTime;
  final TimeOfDay? dinnerTime;

  final bool wantsSnack;
  final int? snackIntensityPerDay;
  final TimeOfDay? snackCutoffTime;

  MealPreference({
    this.breakfastTime,
    this.lunchTime,
    this.dinnerTime,
    this.wantsSnack = false,
    this.snackIntensityPerDay,
    this.snackCutoffTime,
  });
}
