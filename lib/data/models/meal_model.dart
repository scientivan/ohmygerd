import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class MealModel {
  final String imagePath;
  final String mealName;

  final List<String> ingredients;
  final List<String> steps;
  final List<String> tools;

  const MealModel({
    required this.imagePath,
    required this.mealName,

    required this.ingredients,
    required this.steps,
    required this.tools,
  });

  static Map<String, MealModel> mealCatalog = {};

  static Future<void> loadMealsFromJson() async {
    final String jsonString = await rootBundle.loadString(
      'assets/data/foodRecommendation.json',
    );
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    for (final kombinasi in jsonData['kombinasi_gerd_penyakit']) {
      for (final meal in kombinasi['daftar_makanan']) {
        final String nama = meal['nama'];
        final String imagePath =
            meal['imagePath'] ?? 'assets/images/placeholder_meal_log.png';

        if (!mealCatalog.containsKey(nama)) {
          mealCatalog[nama] = MealModel(
            imagePath: imagePath,
            mealName: nama,
            ingredients: List<String>.from(meal['bahan'] ?? []),
            steps: List<String>.from(meal['langkah'] ?? []),
            tools: List<String>.from(meal['alat'] ?? []),
          );
        }
      }
    }
  }
}
