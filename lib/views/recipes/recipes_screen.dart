import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/branding_provider.dart';
import 'package:get/get.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/customer_provider.dart';
import '../../data/initial_bakery_data.dart';
import '../widgets/role_guard.dart';
import 'recipe_detail_screen.dart';
import 'recipe_form_screen.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final branding = Provider.of<BrandingProvider>(context).branding;
    final primaryColor = branding.primaryColor;
    final accentColor = branding.accentColor;
    final currencyFormat = NumberFormat.currency(symbol: branding.currencySymbol, decimalDigits: 2);

    final recipes = recipeProvider.filteredRecipes;
    final categories = recipeProvider.categories;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: Column(
        children: [
          // 1. Search Bar & Category Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (val) => recipeProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: "Search recipes or ingredients...",
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: recipeProvider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => recipeProvider.setSearchQuery(''),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = recipeProvider.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: primaryColor,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) recipeProvider.setCategory(cat);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // 2. Recipe Catalog Grid / List
          Expanded(
            child: recipes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cake_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          "No recipes found in catalog",
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Add your custom recipe or load the handcrafted artisanal menu.",
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: () {
                            final defaultRecs = InitialBakeryData.defaultRecipes;
                            final defaultIngs = InitialBakeryData.defaultIngredients;
                            final defaultCusts = InitialBakeryData.defaultCustomers;
                            for (final rec in defaultRecs) {
                              recipeProvider.addRecipe(rec);
                            }
                            for (final ing in defaultIngs) {
                              inventoryProvider.addIngredient(ing);
                            }
                            for (final cust in defaultCusts) {
                              customerProvider.addCustomer(cust);
                            }
                            Get.snackbar(
                              "Artisanal Menu Loaded",
                              "${defaultRecs.length} Recipes & ${defaultIngs.length} Ingredients populated successfully!",
                              backgroundColor: primaryColor,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                              margin: const EdgeInsets.all(16),
                            );
                          },
                          icon: Icon(Icons.auto_awesome_rounded, color: accentColor),
                          label: const Text("Load 8 Handcrafted Bakery Recipes"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        recipe.title,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        recipe.category,
                                        style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold),
                                      ),
                                      backgroundColor: primaryColor.withValues(alpha: 0.1),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.timer_outlined, size: 16, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text("${recipe.prepTimeMins + recipe.bakeTimeMins} mins total", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.pie_chart_outline_rounded, size: 16, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text("Yield: ${recipe.yieldServings} pcs", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Costing & Allergens Row
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  alignment: WrapAlignment.spaceBetween,
                                  children: [
                                    RoleGuard(
                                      canAccess: (auth) => auth.permissions.canViewFinancials,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "Cost: ${currencyFormat.format(recipe.costPerServing)}/serving",
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                        ),
                                      ),
                                    ),
                                    if (recipe.allergens.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red.shade700),
                                          const SizedBox(width: 2),
                                          Text(
                                            "${recipe.allergens.length} allergen(s)",
                                            style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecipeFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("New Recipe"),
      ),
    );
  }
}
