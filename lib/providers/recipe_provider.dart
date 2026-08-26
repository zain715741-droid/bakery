import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/recipe_model.dart';
import '../models/ingredient_model.dart';
import '../services/database_service.dart';

class RecipeProvider extends ChangeNotifier {
  List<RecipeModel> _recipes = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  StreamSubscription<List<RecipeModel>>? _recipesSubscription;

  RecipeProvider() {
    _initLiveStream();
  }

  void _initLiveStream() {
    _recipesSubscription = DatabaseService.instance.recipesStream.listen(
      (liveRecipes) {
        if (liveRecipes.isNotEmpty) {
          _recipes = liveRecipes;
          notifyListeners();
        }
      },
      onError: (err) {
        debugPrint("Error in live recipes stream: $err");
      },
    );
  }

  @override
  void dispose() {
    _recipesSubscription?.cancel();
    super.dispose();
  }

  List<RecipeModel> get recipes => List.unmodifiable(_recipes);
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<String> get categories {
    final cats = {'All', ..._recipes.map((r) => r.category)};
    return cats.toList();
  }

  List<RecipeModel> get filteredRecipes {
    return _recipes.where((r) {
      final matchesSearch = r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.ingredients.any((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesCategory = _selectedCategory == 'All' || r.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void setRecipes(List<RecipeModel> list) {
    _recipes = list;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  void addRecipe(RecipeModel recipe) {
    _recipes.add(recipe);
    notifyListeners();
    DatabaseService.instance.saveDocument('recipes', recipe.id, recipe.toMap());
  }

  void updateRecipe(RecipeModel recipe) {
    final idx = _recipes.indexWhere((r) => r.id == recipe.id);
    if (idx != -1) {
      _recipes[idx] = recipe;
      notifyListeners();
      DatabaseService.instance.saveDocument('recipes', recipe.id, recipe.toMap());
    }
  }

  void deleteRecipe(String id) {
    _recipes.removeWhere((r) => r.id == id);
    notifyListeners();
    DatabaseService.instance.deleteDocument('recipes', id);
  }

  /// Recalculate recipe costs when ingredient purchase price changes
  void syncRecipeCostsWithIngredients(List<IngredientModel> ingredients) {
    bool updated = false;
    for (int i = 0; i < _recipes.length; i++) {
      final recipe = _recipes[i];
      final updatedIngredients = recipe.ingredients.map((item) {
        final found = ingredients.firstWhere(
          (ing) => ing.id == item.ingredientId,
          orElse: () => IngredientModel(
            id: '',
            name: item.name,
            category: '',
            currentStock: 0,
            unit: item.unit,
            purchasePrice: item.unitCost,
            purchaseQuantity: 1,
            supplierName: '',
            lowStockThreshold: 0,
          ),
        );

        final newUnitCost = found.costPerUnit > 0 ? found.costPerUnit : item.unitCost;
        if (newUnitCost != item.unitCost) {
          updated = true;
          return RecipeIngredientItem(
            ingredientId: item.ingredientId,
            name: item.name,
            quantity: item.quantity,
            unit: item.unit,
            unitCost: newUnitCost,
          );
        }
        return item;
      }).toList();

      if (updated) {
        _recipes[i] = recipe.copyWith(ingredients: updatedIngredients);
      }
    }
    if (updated) {
      notifyListeners();
    }
  }
}
