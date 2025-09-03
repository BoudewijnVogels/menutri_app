// lib/core/models/menu_item.dart

class MenuItem {
  // --- Oorspronkelijke NL-velden ---
  final int id;
  final int menuId;
  final int? recipeId;
  final String naam;
  final String? beschrijving;
  final double price;
  final String? category;
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
    required this.naam,
    this.beschrijving,
    required this.price,
    this.category,
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
      naam: json['naam'] as String? ?? json['name'] as String? ?? '',
      beschrijving:
          json['beschrijving'] as String? ?? json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String?,
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
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menu_id': menuId,
      'recipe_id': recipeId,
      'naam': naam,
      'beschrijving': beschrijving,
      'price': price,
      'category': category,
      'available': available,
      'order': order,
      'labels': labels,
      'nutrition': nutrition?.toJson(),
      'image': image,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ---------- Convenience (NL) ----------
  String get priceDisplay => '€${price.toStringAsFixed(2)}';

  bool get isVeganLabel => labels.contains('vegan');
  bool get isVegetarianLabel => labels.contains('vegetarian');
  bool get isGlutenFree => labels.contains('gluten-free');
  bool get isDairyFree => labels.contains('dairy-free');
  bool get isNutFree => labels.contains('nut-free');

  // ---------- Compatibiliteits-getters (EN) ----------
  String get name => naam;
  String? get description => beschrijving;

  /// UI gebruikt `double? calories`
  double? get calories => nutrition?.calories;

  /// UI gebruikt `List<String> allergens` — niet aanwezig in jouw model.
  /// We leiden niets af; retourneer lege lijst (of map labels -> allergens als je wil).
  List<String> get allergens => const [];

  /// UI gebruikt booleans voor dieetlabels:
  bool get isVegetarian => isVegetarianLabel;
  bool get isVegan => isVeganLabel;

  /// UI gebruikt `double? price` (nullable). Wij hebben verplicht `price`.
  /// Getter blijft gewoon bestaan voor compatibiliteit.
  double? get priceNullable => price;

  MenuItem copyWith({
    int? id,
    int? menuId,
    int? recipeId,
    String? naam,
    String? beschrijving,
    double? price,
    String? category,
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
      naam: naam ?? this.naam,
      beschrijving: beschrijving ?? this.beschrijving,
      price: price ?? this.price,
      category: category ?? this.category,
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
      'MenuItem(id: $id, naam: $naam, price: $price, available: $available)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MenuItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

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
      calories: (json['energie_kcal'] as num?)?.toDouble() ??
          (json['calories'] as num?)?.toDouble(),
      protein: (json['eiwit_g'] as num?)?.toDouble() ??
          (json['protein'] as num?)?.toDouble(),
      carbs: (json['koolhydraten_g'] as num?)?.toDouble() ??
          (json['carbs'] as num?)?.toDouble(),
      fat: (json['vet_g'] as num?)?.toDouble() ??
          (json['fat'] as num?)?.toDouble(),
      fiber: (json['vezels_g'] as num?)?.toDouble() ??
          (json['fiber'] as num?)?.toDouble(),
      sodium: (json['natrium_mg'] as num?)?.toDouble() ??
          (json['sodium'] as num?)?.toDouble(),
      sugar: (json['suiker_g'] as num?)?.toDouble() ??
          (json['sugar'] as num?)?.toDouble(),
      calorieMargin:
          json['cal_margin'] as String? ?? json['calorie_margin'] as String?,
      calorieNote:
          json['cal_note'] as String? ?? json['calorie_note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'energie_kcal': calories,
      'eiwit_g': protein,
      'koolhydraten_g': carbs,
      'vet_g': fat,
      'vezels_g': fiber,
      'natrium_mg': sodium,
      'suiker_g': sugar,
      'cal_margin': calorieMargin,
      'cal_note': calorieNote,
    };
  }

  String get caloriesDisplay =>
      (calories != null) ? '${calories!.round()} kcal' : 'Calorieën onbekend';

  String get macrosDisplay {
    final parts = <String>[];
    if (protein != null) parts.add('${protein!.round()}g eiwit');
    if (carbs != null) parts.add('${carbs!.round()}g koolhydraten');
    if (fat != null) parts.add('${fat!.round()}g vet');
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
