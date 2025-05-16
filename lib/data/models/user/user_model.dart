import 'package:OhMyGERD/data/models/user/submodels/biodata_model.dart';
import 'package:OhMyGERD/data/models/user/submodels/mealstreak_model.dart';
import 'package:OhMyGERD/data/models/user/submodels/preference_model.dart';

class UserModel {
  String? uid;
  String? name;
  String? email;
  String? password;
  String? providerId;
  String? profilePicture;
  BioData? bio;
  MealPreference? mealPref;
  MealStreak? mealStreak;

  UserModel({
    this.uid,
    this.name,
    this.email,
    this.password,
    this.profilePicture,
    this.providerId,
    this.bio,
    this.mealPref,
    this.mealStreak,
  });

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? password,
    String? providerId,
    String? profilePicture,
    BioData? bio,
    MealPreference? mealPref,
    MealStreak? mealStreak,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      providerId: providerId ?? this.providerId,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      mealPref: mealPref ?? this.mealPref,
      mealStreak: mealStreak ?? this.mealStreak,
    );
  }
}
