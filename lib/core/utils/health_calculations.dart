class HealthCalculations {
  /// Calculate BMI (Body Mass Index)
  /// Formula: weight_kg / (height_m²)
  static double calculateBMI(double weightKg, double heightCm) {
    if (weightKg <= 0 || heightCm <= 0) return 0.0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Calculate BMR (Basal Metabolic Rate) using Mifflin-St Jeor Equation
  /// Men: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) + 5
  /// Women: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) - 161
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) return 0.0;
    
    double bmr = 10 * weightKg + 6.25 * heightCm - 5 * age;
    
    if (gender.toLowerCase() == 'male' || gender.toLowerCase() == 'man') {
      bmr += 5;
    } else {
      bmr -= 161;
    }
    
    return bmr;
  }

  /// Calculate TDEE (Total Daily Energy Expenditure)
  /// TDEE = BMR × activity_factor
  static double calculateTDEE(double bmr, String activityLevel) {
    if (bmr <= 0) return 0.0;
    
    double activityFactor;
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
      case 'zittend':
        activityFactor = 1.2;
        break;
      case 'lightly_active':
      case 'licht_actief':
        activityFactor = 1.375;
        break;
      case 'moderately_active':
      case 'matig_actief':
        activityFactor = 1.55;
        break;
      case 'very_active':
      case 'zeer_actief':
        activityFactor = 1.725;
        break;
      case 'extremely_active':
      case 'extreem_actief':
        activityFactor = 1.9;
        break;
      default:
        activityFactor = 1.2; // Default to sedentary
    }
    
    return bmr * activityFactor;
  }

  /// Get BMI category
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Ondergewicht';
    if (bmi < 25) return 'Normaal gewicht';
    if (bmi < 30) return 'Overgewicht';
    return 'Obesitas';
  }

  /// Get BMI category color
  static String getBMICategoryColor(double bmi) {
    if (bmi < 18.5) return '#3B82F6'; // Blue
    if (bmi < 25) return '#10B981'; // Green
    if (bmi < 30) return '#F59E0B'; // Orange
    return '#EF4444'; // Red
  }

  /// Calculate daily calorie goal based on goal type
  static double calculateDailyCalorieGoal(double tdee, String goal) {
    switch (goal.toLowerCase()) {
      case 'lose_weight':
      case 'afvallen':
        return tdee - 500; // 500 calorie deficit for ~0.5kg/week loss
      case 'gain_weight':
      case 'aankomen':
        return tdee + 500; // 500 calorie surplus for ~0.5kg/week gain
      case 'maintain':
      case 'behouden':
      default:
        return tdee;
    }
  }

  /// Get calorie margin badge color based on percentage
  /// From blueprint: ≤5% = grijs, 5-10% = amber, 10-15% = oranje, >15% = rood
  static String getCalorieMarginColor(double marginPercentage) {
    if (marginPercentage <= 5) return '#B0BEC5'; // grijs
    if (marginPercentage <= 10) return '#FFCA28'; // amber
    if (marginPercentage <= 15) return '#FF7043'; // oranje
    return '#D32F2F'; // rood
  }

  /// Get calorie margin badge text
  static String getCalorieMarginText(double marginPercentage) {
    if (marginPercentage <= 5) return '≤5%';
    if (marginPercentage <= 10) return '5-10%';
    if (marginPercentage <= 15) return '10-15%';
    return '>15%';
  }

  /// Check if explanation is required for calorie margin (>15%)
  static bool requiresCalorieExplanation(double marginPercentage) {
    return marginPercentage > 15;
  }

  /// Check if warning is needed for calorie margin (>5% and goal is weight loss)
  static bool requiresCalorieWarning(double marginPercentage, String goal) {
    return marginPercentage > 5 && 
           (goal.toLowerCase() == 'lose_weight' || goal.toLowerCase() == 'afvallen');
  }

  /// Calculate macro percentages
  static Map<String, double> calculateMacroPercentages({
    required double protein,
    required double carbs,
    required double fat,
  }) {
    final totalCalories = (protein * 4) + (carbs * 4) + (fat * 9);
    
    if (totalCalories == 0) {
      return {'protein': 0, 'carbs': 0, 'fat': 0};
    }
    
    return {
      'protein': (protein * 4 / totalCalories) * 100,
      'carbs': (carbs * 4 / totalCalories) * 100,
      'fat': (fat * 9 / totalCalories) * 100,
    };
  }

  /// Generate MyFitnessPal deeplink
  static String generateMyFitnessPalDeeplink({
    required String dishName,
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
  }) {
    return 'myfitnesspal://addfood?name=${Uri.encodeComponent(dishName)}'
           '&calories=${calories.round()}'
           '&protein=${protein.round()}'
           '&fat=${fat.round()}'
           '&carbs=${carbs.round()}';
  }
}

