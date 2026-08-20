class NutritionalInfo {
  final double calories; // kcal
  final double protein; // g
  final double carbohydrates; // g
  final double fat; // g
  final double sugar; // g
  final double salt; // g
  final double fibre; // g

  const NutritionalInfo({
    this.calories = 0.0,
    this.protein = 0.0,
    this.carbohydrates = 0.0,
    this.fat = 0.0,
    this.sugar = 0.0,
    this.salt = 0.0,
    this.fibre = 0.0,
  });

  Map<String, dynamic> toMap() => {
        'calories': calories,
        'protein': protein,
        'carbohydrates': carbohydrates,
        'fat': fat,
        'sugar': sugar,
        'salt': salt,
        'fibre': fibre,
      };

  factory NutritionalInfo.fromMap(Map<String, dynamic> map) => NutritionalInfo(
        calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
        protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
        carbohydrates: (map['carbohydrates'] as num?)?.toDouble() ?? 0.0,
        fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
        sugar: (map['sugar'] as num?)?.toDouble() ?? 0.0,
        salt: (map['salt'] as num?)?.toDouble() ?? 0.0,
        fibre: (map['fibre'] as num?)?.toDouble() ?? 0.0,
      );
}

class RecipeIngredientItem {
  final String ingredientId;
  final String name;
  final double quantity;
  final String unit;
  final double unitCost; // cost per 1 base unit

  RecipeIngredientItem({
    required this.ingredientId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitCost,
  });

  double get itemTotalCost => quantity * unitCost;

  Map<String, dynamic> toMap() => {
        'ingredientId': ingredientId,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'unitCost': unitCost,
      };

  factory RecipeIngredientItem.fromMap(Map<String, dynamic> map) => RecipeIngredientItem(
        ingredientId: map['ingredientId'] ?? '',
        name: map['name'] ?? '',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
        unit: map['unit'] ?? 'g',
        unitCost: (map['unitCost'] as num?)?.toDouble() ?? 0.0,
      );
}

class RecipeModel {
  final String id;
  final String title;
  final String category;
  final String? photoUrl;
  final int prepTimeMins;
  final int bakeTimeMins;
  final int bakingTempC;
  final int yieldServings;
  final double sellingPrice; // Retail price per item or batch
  final List<RecipeIngredientItem> ingredients;
  final List<String> instructions;
  final String notes;
  final List<String> allergens;
  final NutritionalInfo nutritionalInfo;

  RecipeModel({
    required this.id,
    required this.title,
    required this.category,
    this.photoUrl,
    required this.prepTimeMins,
    required this.bakeTimeMins,
    required this.bakingTempC,
    required this.yieldServings,
    required this.sellingPrice,
    required this.ingredients,
    required this.instructions,
    required this.notes,
    required this.allergens,
    required this.nutritionalInfo,
  });

  /// Total cost of raw ingredients for the batch
  double get totalBatchCost {
    return ingredients.fold(0.0, (sum, item) => sum + item.itemTotalCost);
  }

  /// Cost per individual serving
  double get costPerServing {
    return yieldServings > 0 ? totalBatchCost / yieldServings : 0.0;
  }

  /// Estimated gross profit margin per serving
  double get grossProfitMargin {
    final revenue = sellingPrice;
    if (revenue <= 0) return 0.0;
    return ((revenue - costPerServing) / revenue) * 100;
  }

  RecipeModel copyWith({
    String? id,
    String? title,
    String? category,
    String? photoUrl,
    int? prepTimeMins,
    int? bakeTimeMins,
    int? bakingTempC,
    int? yieldServings,
    double? sellingPrice,
    List<RecipeIngredientItem>? ingredients,
    List<String>? instructions,
    String? notes,
    List<String>? allergens,
    NutritionalInfo? nutritionalInfo,
  }) {
    return RecipeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      photoUrl: photoUrl ?? this.photoUrl,
      prepTimeMins: prepTimeMins ?? this.prepTimeMins,
      bakeTimeMins: bakeTimeMins ?? this.bakeTimeMins,
      bakingTempC: bakingTempC ?? this.bakingTempC,
      yieldServings: yieldServings ?? this.yieldServings,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      notes: notes ?? this.notes,
      allergens: allergens ?? this.allergens,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'category': category,
        'photoUrl': photoUrl,
        'prepTimeMins': prepTimeMins,
        'bakeTimeMins': bakeTimeMins,
        'bakingTempC': bakingTempC,
        'yieldServings': yieldServings,
        'sellingPrice': sellingPrice,
        'ingredients': ingredients.map((i) => i.toMap()).toList(),
        'instructions': instructions,
        'notes': notes,
        'allergens': allergens,
        'nutritionalInfo': nutritionalInfo.toMap(),
      };

  factory RecipeModel.fromMap(Map<String, dynamic> map) {
    return RecipeModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? 'Cakes',
      photoUrl: map['photoUrl'],
      prepTimeMins: map['prepTimeMins'] ?? 20,
      bakeTimeMins: map['bakeTimeMins'] ?? 30,
      bakingTempC: map['bakingTempC'] ?? 180,
      yieldServings: map['yieldServings'] ?? 12,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      ingredients: (map['ingredients'] as List<dynamic>?)
              ?.map((i) => RecipeIngredientItem.fromMap(Map<String, dynamic>.from(i)))
              .toList() ??
          [],
      instructions: (map['instructions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      notes: map['notes'] ?? '',
      allergens: (map['allergens'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      nutritionalInfo: map['nutritionalInfo'] != null
          ? NutritionalInfo.fromMap(Map<String, dynamic>.from(map['nutritionalInfo']))
          : const NutritionalInfo(),
    );
  }
}
