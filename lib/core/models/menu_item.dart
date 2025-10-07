// lib/core/models/menu_item.dart

class MenuItem {
  // --- Definitive English fields ---
  final int id;
  final int menuId;
  final int? recipeId;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final int? categoryId; // ✅ Added support for category_id
  final bool available;
  final int order;
  final List<String> labels;
  final NutritionInfo? nutrition;
  final String? image;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MenuItem({
    required this.id,
    required this.menuId,
    this.recipeId,
    required this.name,
    this.description,
    required this.price,
    this.category,
    this.categoryId,
    this.available = true,
    this.order = 0,
    this.labels = const [],
    this.nutrition,
    this.image,
    this.createdAt,
    this.updatedAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as int,
      menuId: json['menu_id'] as int,
      recipeId: json['recipe_id'] as int?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      // ✅ Accept both category and category_id
      category:
          json['category'] as String? ?? (json['category_name'] as String?),
      categoryId: json['category_id'] as int?,
      available: json['available'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
      labels: (json['labels'] is List)
          ? List<String>.from(json['labels'] as List)
          : const [],
      nutrition: (json['nutrition'] is Map)
          ? NutritionInfo.fromJson(json['nutrition'] as Map<String, dynamic>)
          : null,
      image: json['image'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menu_id': menuId,
      'recipe_id': recipeId,
      'name': name,
      'description': description,
      'price': price,
      // ✅ Include both for backend compatibility
      'category': category,
      'category_id': categoryId,
      'available': available,
      'order': order,
      'labels': labels,
      'nutrition': nutrition?.toJson(),
      'image': image,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ---------- Convenience ----------
  String get priceDisplay => '€${price.toStringAsFixed(2)}';

  bool get isVeganLabel => labels.contains('vegan');
  bool get isVegetarianLabel => labels.contains('vegetarian');
  bool get isGlutenFree => labels.contains('gluten-free');
  bool get isDairyFree => labels.contains('dairy-free');
  bool get isNutFree => labels.contains('nut-free');

  double? get calories => nutrition?.calories;

  List<String> get allergens => const [];

  bool get isVegetarian => isVegetarianLabel;
  bool get isVegan => isVeganLabel;

  double? get priceNullable => price;

  MenuItem copyWith({
    int? id,
    int? menuId,
    int? recipeId,
    String? name,
    String? description,
    double? price,
    String? category,
    int? categoryId,
    bool? available,
    int? order,
    List<String>? labels,
    NutritionInfo? nutrition,
    String? image,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      menuId: menuId ?? this.menuId,
      recipeId: recipeId ?? this.recipeId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      available: available ?? this.available,
      order: order ?? this.order,
      labels: labels ?? this.labels,
      nutrition: nutrition ?? this.nutrition,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'MenuItem(id: $id, name: $name, price: $price, categoryId: $categoryId, available: $available)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MenuItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

// ================= NutritionInfo =================

class NutritionInfo {
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;
  final double? sodium;
  final double? sugar;
  final String? calorieMargin;
  final String? calorieNote;

  const NutritionInfo({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.sodium,
    this.sugar,
    this.calorieMargin,
    this.calorieNote,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: (json['energy_kcal'] as num?)?.toDouble() ??
          (json['calories'] as num?)?.toDouble(),
      protein: (json['protein_g'] as num?)?.toDouble() ??
          (json['protein'] as num?)?.toDouble(),
      carbs: (json['carbs_g'] as num?)?.toDouble() ??
          (json['carbs'] as num?)?.toDouble(),
      fat: (json['fat_g'] as num?)?.toDouble() ??
          (json['fat'] as num?)?.toDouble(),
      fiber: (json['fiber_g'] as num?)?.toDouble() ??
          (json['fiber'] as num?)?.toDouble(),
      sodium: (json['sodium_mg'] as num?)?.toDouble() ??
          (json['sodium'] as num?)?.toDouble(),
      sugar: (json['sugars_g'] as num?)?.toDouble() ??
          (json['sugar'] as num?)?.toDouble(),
      calorieMargin: json['calorie_margin'] as String?,
      calorieNote: json['calorie_note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sodium': sodium,
      'sugar': sugar,
      'calorie_margin': calorieMargin,
      'calorie_note': calorieNote,
    };
  }

  String get caloriesDisplay =>
      (calories != null) ? '${calories!.round()} kcal' : 'Calories unknown';

  String get macrosDisplay {
    final parts = <String>[];
    if (protein != null) parts.add('${protein!.round()}g protein');
    if (carbs != null) parts.add('${carbs!.round()}g carbs');
    if (fat != null) parts.add('${fat!.round()}g fat');
    return parts.join(' • ');
  }

  CalorieMarginLevel get marginLevel {
    switch (calorieMargin) {
      case '0-5':
        return CalorieMarginLevel.low;
      case '5-10':
        return CalorieMarginLevel.medium;
      case '10-15':
        return CalorieMarginLevel.high;
      case '>15':
        return CalorieMarginLevel.veryHigh;
      default:
        return CalorieMarginLevel.unknown;
    }
  }
}

enum CalorieMarginLevel { low, medium, high, veryHigh, unknown }
