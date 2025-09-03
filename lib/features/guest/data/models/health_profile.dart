class HealthProfile {
  final int? id;
  final int userId;
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final String? activityLevel;
  final List<String>? healthGoals;
  final List<String>? dietaryRestrictions;
  final List<String>? foodAllergies;
  final List<String>? dislikedFoods;
  final List<String>? preferredCuisines;
  final double? targetCalories;
  final double? targetProteinG;
  final double? targetCarbsG;
  final double? targetFatG;
  final double? targetFiberG;
  final double? targetSodiumMg;
  final bool? hasDiabetes;
  final bool? hasHypertension;
  final bool? hasHeartDisease;
  final bool? hasKidneyDisease;
  final String? otherConditions;
  final bool? myfitnesspalConnected;
  final String? myfitnesspalUsername;
  final bool? googleFitConnected;
  final bool? appleHealthConnected;
  final bool? shareHealthData;
  final bool? allowRecommendations;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HealthProfile({
    this.id,
    required this.userId,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.activityLevel,
    this.healthGoals,
    this.dietaryRestrictions,
    this.foodAllergies,
    this.dislikedFoods,
    this.preferredCuisines,
    this.targetCalories,
    this.targetProteinG,
    this.targetCarbsG,
    this.targetFatG,
    this.targetFiberG,
    this.targetSodiumMg,
    this.hasDiabetes,
    this.hasHypertension,
    this.hasHeartDisease,
    this.hasKidneyDisease,
    this.otherConditions,
    this.myfitnesspalConnected,
    this.myfitnesspalUsername,
    this.googleFitConnected,
    this.appleHealthConnected,
    this.shareHealthData,
    this.allowRecommendations,
    this.createdAt,
    this.updatedAt,
  });

  factory HealthProfile.fromJson(Map<String, dynamic> json) {
    return HealthProfile(
      id: json['id'],
      userId: json['user_id'],
      age: json['age'],
      gender: json['gender'],
      heightCm: json['height_cm']?.toDouble(),
      weightKg: json['weight_kg']?.toDouble(),
      activityLevel: json['activity_level'],
      healthGoals: json['health_goals']?.cast<String>(),
      dietaryRestrictions: json['dietary_restrictions']?.cast<String>(),
      foodAllergies: json['food_allergies']?.cast<String>(),
      dislikedFoods: json['disliked_foods']?.cast<String>(),
      preferredCuisines: json['preferred_cuisines']?.cast<String>(),
      targetCalories: json['target_calories']?.toDouble(),
      targetProteinG: json['target_protein_g']?.toDouble(),
      targetCarbsG: json['target_carbs_g']?.toDouble(),
      targetFatG: json['target_fat_g']?.toDouble(),
      targetFiberG: json['target_fiber_g']?.toDouble(),
      targetSodiumMg: json['target_sodium_mg']?.toDouble(),
      hasDiabetes: json['has_diabetes'],
      hasHypertension: json['has_hypertension'],
      hasHeartDisease: json['has_heart_disease'],
      hasKidneyDisease: json['has_kidney_disease'],
      otherConditions: json['other_conditions'],
      myfitnesspalConnected: json['myfitnesspal_connected'],
      myfitnesspalUsername: json['myfitnesspal_username'],
      googleFitConnected: json['google_fit_connected'],
      appleHealthConnected: json['apple_health_connected'],
      shareHealthData: json['share_health_data'],
      allowRecommendations: json['allow_recommendations'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (healthGoals != null) 'health_goals': healthGoals,
      if (dietaryRestrictions != null)
        'dietary_restrictions': dietaryRestrictions,
      if (foodAllergies != null) 'food_allergies': foodAllergies,
      if (dislikedFoods != null) 'disliked_foods': dislikedFoods,
      if (preferredCuisines != null) 'preferred_cuisines': preferredCuisines,
      if (targetCalories != null) 'target_calories': targetCalories,
      if (targetProteinG != null) 'target_protein_g': targetProteinG,
      if (targetCarbsG != null) 'target_carbs_g': targetCarbsG,
      if (targetFatG != null) 'target_fat_g': targetFatG,
      if (targetFiberG != null) 'target_fiber_g': targetFiberG,
      if (targetSodiumMg != null) 'target_sodium_mg': targetSodiumMg,
      if (hasDiabetes != null) 'has_diabetes': hasDiabetes,
      if (hasHypertension != null) 'has_hypertension': hasHypertension,
      if (hasHeartDisease != null) 'has_heart_disease': hasHeartDisease,
      if (hasKidneyDisease != null) 'has_kidney_disease': hasKidneyDisease,
      if (otherConditions != null) 'other_conditions': otherConditions,
      if (myfitnesspalConnected != null)
        'myfitnesspal_connected': myfitnesspalConnected,
      if (myfitnesspalUsername != null)
        'myfitnesspal_username': myfitnesspalUsername,
      if (googleFitConnected != null)
        'google_fit_connected': googleFitConnected,
      if (appleHealthConnected != null)
        'apple_health_connected': appleHealthConnected,
      if (shareHealthData != null) 'share_health_data': shareHealthData,
      if (allowRecommendations != null)
        'allow_recommendations': allowRecommendations,
    };
  }

  HealthProfile copyWith({
    int? id,
    int? userId,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    List<String>? healthGoals,
    List<String>? dietaryRestrictions,
    List<String>? foodAllergies,
    List<String>? dislikedFoods,
    List<String>? preferredCuisines,
    double? targetCalories,
    double? targetProteinG,
    double? targetCarbsG,
    double? targetFatG,
    double? targetFiberG,
    double? targetSodiumMg,
    bool? hasDiabetes,
    bool? hasHypertension,
    bool? hasHeartDisease,
    bool? hasKidneyDisease,
    String? otherConditions,
    bool? myfitnesspalConnected,
    String? myfitnesspalUsername,
    bool? googleFitConnected,
    bool? appleHealthConnected,
    bool? shareHealthData,
    bool? allowRecommendations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      healthGoals: healthGoals ?? this.healthGoals,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      foodAllergies: foodAllergies ?? this.foodAllergies,
      dislikedFoods: dislikedFoods ?? this.dislikedFoods,
      preferredCuisines: preferredCuisines ?? this.preferredCuisines,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProteinG: targetProteinG ?? this.targetProteinG,
      targetCarbsG: targetCarbsG ?? this.targetCarbsG,
      targetFatG: targetFatG ?? this.targetFatG,
      targetFiberG: targetFiberG ?? this.targetFiberG,
      targetSodiumMg: targetSodiumMg ?? this.targetSodiumMg,
      hasDiabetes: hasDiabetes ?? this.hasDiabetes,
      hasHypertension: hasHypertension ?? this.hasHypertension,
      hasHeartDisease: hasHeartDisease ?? this.hasHeartDisease,
      hasKidneyDisease: hasKidneyDisease ?? this.hasKidneyDisease,
      otherConditions: otherConditions ?? this.otherConditions,
      myfitnesspalConnected:
          myfitnesspalConnected ?? this.myfitnesspalConnected,
      myfitnesspalUsername: myfitnesspalUsername ?? this.myfitnesspalUsername,
      googleFitConnected: googleFitConnected ?? this.googleFitConnected,
      appleHealthConnected: appleHealthConnected ?? this.appleHealthConnected,
      shareHealthData: shareHealthData ?? this.shareHealthData,
      allowRecommendations: allowRecommendations ?? this.allowRecommendations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Health calculations
  double? get bmi {
    if (heightCm == null || weightKg == null) return null;
    final heightM = heightCm! / 100;
    return weightKg! / (heightM * heightM);
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Onbekend';
    if (bmiValue < 18.5) return 'Ondergewicht';
    if (bmiValue < 25) return 'Normaal gewicht';
    if (bmiValue < 30) return 'Overgewicht';
    return 'Obesitas';
  }

  double? get bmr {
    if (age == null || heightCm == null || weightKg == null || gender == null) {
      return null;
    }

    // Mifflin-St Jeor Equation
    if (gender!.toLowerCase() == 'male' || gender!.toLowerCase() == 'man') {
      return (10 * weightKg!) + (6.25 * heightCm!) - (5 * age!) + 5;
    } else {
      return (10 * weightKg!) + (6.25 * heightCm!) - (5 * age!) - 161;
    }
  }

  double? get tdee {
    final bmrValue = bmr;
    if (bmrValue == null || activityLevel == null) return null;

    final multipliers = {
      'sedentary': 1.2,
      'lightly_active': 1.375,
      'moderately_active': 1.55,
      'very_active': 1.725,
      'extremely_active': 1.9,
    };

    return bmrValue * (multipliers[activityLevel] ?? 1.2);
  }
}
