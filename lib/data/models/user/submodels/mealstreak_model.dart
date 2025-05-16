class MealStreak {
  bool isBreakfastDone;
  bool isLunchDone;
  bool isDinnerDone;
  bool isDrinkDone;
  int streak;
  DateTime lastUpdatedDate;

  MealStreak({
    this.isBreakfastDone = false,
    this.isLunchDone = false,
    this.isDinnerDone = false,
    this.isDrinkDone = false,
    this.streak = 0,
    DateTime? lastUpdatedDate,
  }) : lastUpdatedDate = lastUpdatedDate ?? DateTime.now();
}
