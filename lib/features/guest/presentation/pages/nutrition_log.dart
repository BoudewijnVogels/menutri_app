class NutritionLog {
  final int? id;
  final int healthProfileId;
  final String mealType;
  final int? restaurantId;
  final int? menuItemId;
  final String? foodName;
  final String? brand;
  final double calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;
  final double? sodiumMg;
  final double? sugarG;
  final String? servingSize;
  final double? quantity;
  final String? externalApp;
  final String? externalId;
  final DateTime loggedAt;
  final DateTime mealDate;

  const NutritionLog({
    this.id,
    required this.healthProfileId,
    required this.mealType,
    this.restaurantId,
    this.menuItemId,
    this.foodName,
    this.brand,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.sodiumMg,
    this.sugarG,
    this.servingSize,
    this.quantity,
    this.externalApp,
    this.externalId,
    required this.loggedAt,
    required this.mealDate,
  });

  factory NutritionLog.fromJson(Map<String, dynamic> json) {
    return NutritionLog(
      id: json['id'],
      healthProfileId: json['health_profile_id'],
      mealType: json['meal_type'],
      restaurantId: json['restaurant_id'],
      menuItemId: json['menu_item_id'],
      foodName: json['food_name'],
      brand: json['brand'],
      calories: json['calories']?.toDouble() ?? 0.0,
      proteinG: json['protein_g']?.toDouble(),
      carbsG: json['carbs_g']?.toDouble(),
      fatG: json['fat_g']?.toDouble(),
      fiberG: json['fiber_g']?.toDouble(),
      sodiumMg: json['sodium_mg']?.toDouble(),
      sugarG: json['sugar_g']?.toDouble(),
      servingSize: json['serving_size'],
      quantity: json['quantity']?.toDouble(),
      externalApp: json['external_app'],
      externalId: json['external_id'],
      loggedAt: DateTime.parse(json['logged_at']),
      mealDate: DateTime.parse(json['meal_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'health_profile_id': healthProfileId,
      'meal_type': mealType,
      if (restaurantId != null) 'restaurant_id': restaurantId,
      if (menuItemId != null) 'menu_item_id': menuItemId,
      if (foodName != null) 'food_name': foodName,
      if (brand != null) 'brand': brand,
      'calories': calories,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (fiberG != null) 'fiber_g': fiberG,
      if (sodiumMg != null) 'sodium_mg': sodiumMg,
      if (sugarG != null) 'sugar_g': sugarG,
      if (servingSize != null) 'serving_size': servingSize,
      if (quantity != null) 'quantity': quantity,
      if (externalApp != null) 'external_app': externalApp,
      if (externalId != null) 'external_id': externalId,
      'logged_at': loggedAt.toIso8601String(),
      'meal_date': mealDate.toIso8601String(),
    };
  }

  NutritionLog copyWith({
    int? id,
    int? healthProfileId,
    String? mealType,
    int? restaurantId,
    int? menuItemId,
    String? foodName,
    String? brand,
    double? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? fiberG,
    double? sodiumMg,
    double? sugarG,
    String? servingSize,
    double? quantity,
    String? externalApp,
    String? externalId,
    DateTime? loggedAt,
    DateTime? mealDate,
  }) {
    return NutritionLog(
      id: id ?? this.id,
      healthProfileId: healthProfileId ?? this.healthProfileId,
      mealType: mealType ?? this.mealType,
      restaurantId: restaurantId ?? this.restaurantId,
      menuItemId: menuItemId ?? this.menuItemId,
      foodName: foodName ?? this.foodName,
      brand: brand ?? this.brand,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      fiberG: fiberG ?? this.fiberG,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      sugarG: sugarG ?? this.sugarG,
      servingSize: servingSize ?? this.servingSize,
      quantity: quantity ?? this.quantity,
      externalApp: externalApp ?? this.externalApp,
      externalId: externalId ?? this.externalId,
      loggedAt: loggedAt ?? this.loggedAt,
      mealDate: mealDate ?? this.mealDate,
    );
  }
}

class DailySummary {
  final DateTime date;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final double totalSodium;
  final List<NutritionLog> meals;

  const DailySummary({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
    required this.totalSodium,
    required this.meals,
  });

  factory DailySummary.fromLogs(DateTime date, List<NutritionLog> logs) {
    final dayLogs = logs.where((log) => 
      log.mealDate.year == date.year &&
      log.mealDate.month == date.month &&
      log.mealDate.day == date.day
    ).toList();

    return DailySummary(
      date: date,
      totalCalories: dayLogs.fold(0.0, (sum, log) => sum + log.calories),
      totalProtein: dayLogs.fold(0.0, (sum, log) => sum + (log.proteinG ?? 0)),
      totalCarbs: dayLogs.fold(0.0, (sum, log) => sum + (log.carbsG ?? 0)),
      totalFat: dayLogs.fold(0.0, (sum, log) => sum + (log.fatG ?? 0)),
      totalFiber: dayLogs.fold(0.0, (sum, log) => sum + (log.fiberG ?? 0)),
      totalSodium: dayLogs.fold(0.0, (sum, log) => sum + (log.sodiumMg ?? 0)),
      meals: dayLogs,
    );
  }

  Map<String, List<NutritionLog>> get mealsByType {
    final Map<String, List<NutritionLog>> grouped = {};
    for (final meal in meals) {
      grouped.putIfAbsent(meal.mealType, () => []).add(meal);
    }
    return grouped;
  }
}

