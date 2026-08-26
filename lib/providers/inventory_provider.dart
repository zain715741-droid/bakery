import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/ingredient_model.dart';
import '../services/database_service.dart';

class InventoryProvider extends ChangeNotifier {
  List<IngredientModel> _ingredients = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  StreamSubscription<List<IngredientModel>>? _ingredientsSubscription;

  InventoryProvider() {
    _initLiveStream();
  }

  void _initLiveStream() {
    _ingredientsSubscription = DatabaseService.instance.ingredientsStream.listen(
      (liveIngredients) {
        if (liveIngredients.isNotEmpty) {
          _ingredients = liveIngredients;
          notifyListeners();
        }
      },
      onError: (err) {
        debugPrint("Error in live ingredients stream: $err");
      },
    );
  }

  @override
  void dispose() {
    _ingredientsSubscription?.cancel();
    super.dispose();
  }

  List<IngredientModel> get ingredients => List.unmodifiable(_ingredients);
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<IngredientModel> get lowStockIngredients =>
      _ingredients.where((item) => item.isLowStock).toList();

  List<String> get categories {
    final cats = {'All', ..._ingredients.map((item) => item.category)};
    return cats.toList();
  }

  List<IngredientModel> get filteredIngredients {
    return _ingredients.where((item) {
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.supplierName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void setIngredients(List<IngredientModel> list) {
    _ingredients = list;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void addIngredient(IngredientModel ingredient) {
    _ingredients.add(ingredient);
    notifyListeners();
    DatabaseService.instance.saveDocument('ingredients', ingredient.id, ingredient.toMap());
  }

  void updateIngredient(IngredientModel ingredient) {
    final index = _ingredients.indexWhere((i) => i.id == ingredient.id);
    if (index != -1) {
      _ingredients[index] = ingredient;
      notifyListeners();
      DatabaseService.instance.saveDocument('ingredients', ingredient.id, ingredient.toMap());
    }
  }

  void deleteIngredient(String id) {
    _ingredients.removeWhere((i) => i.id == id);
    notifyListeners();
    DatabaseService.instance.deleteDocument('ingredients', id);
  }

  void adjustStock(String id, double deltaQuantity) {
    final index = _ingredients.indexWhere((i) => i.id == id);
    if (index != -1) {
      final current = _ingredients[index];
      final newStock = (current.currentStock + deltaQuantity).clamp(
        0.0,
        999999.0,
      );
      final updated = current.copyWith(currentStock: newStock);
      _ingredients[index] = updated;
      notifyListeners();
      DatabaseService.instance.saveDocument('ingredients', updated.id, updated.toMap());
    }
  }

  /// Deduct stock according to recipe requirements * batch multiplier
  bool deductRecipeStock(Map<String, double> deductions) {
    for (final entry in deductions.entries) {
      final index = _ingredients.indexWhere((i) => i.id == entry.key);
      if (index != -1) {
        final current = _ingredients[index];
        final updatedStock = (current.currentStock - entry.value).clamp(
          0.0,
          999999.0,
        );
        final updated = current.copyWith(currentStock: updatedStock);
        _ingredients[index] = updated;
        DatabaseService.instance.saveDocument('ingredients', updated.id, updated.toMap());
      }
    }
    notifyListeners();
    return true;
  }
}
