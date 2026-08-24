import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/ingredient_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/branding_provider.dart';
import '../widgets/role_guard.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  void _showIngredientModal(BuildContext context, {IngredientModel? ingredientToEdit}) {
    final inventory = Provider.of<InventoryProvider>(context, listen: false);
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);

    final nameController = TextEditingController(text: ingredientToEdit?.name ?? '');
    final categoryController = TextEditingController(text: ingredientToEdit?.category ?? 'Flour & Grains');
    final stockController = TextEditingController(text: ingredientToEdit?.currentStock.toString() ?? '5000');
    final unitController = TextEditingController(text: ingredientToEdit?.unit ?? 'g');
    final priceController = TextEditingController(text: ingredientToEdit?.purchasePrice.toString() ?? '10.00');
    final qtyController = TextEditingController(text: ingredientToEdit?.purchaseQuantity.toString() ?? '5000');
    final supplierController = TextEditingController(text: ingredientToEdit?.supplierName ?? 'Local Bakery Wholesaler');
    final contactController = TextEditingController(text: ingredientToEdit?.supplierContact ?? '');
    final alertController = TextEditingController(text: ingredientToEdit?.lowStockThreshold.toString() ?? '1000');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredientToEdit == null ? "Add New Ingredient" : "Edit Ingredient Stock",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Ingredient Name", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(labelText: "Unit (g, kg, ml, pcs)", border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Current Stock Level", border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: alertController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Low Stock Alert Threshold", border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Purchase Price (£)", border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Batch Purchase Quantity", border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: supplierController,
                  decoration: const InputDecoration(labelText: "Supplier Name", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(labelText: "Supplier Contact Phone / Email", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;

                      final newIng = IngredientModel(
                        id: ingredientToEdit?.id ?? 'ing_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        category: categoryController.text.trim(),
                        currentStock: double.tryParse(stockController.text) ?? 0.0,
                        unit: unitController.text.trim(),
                        purchasePrice: double.tryParse(priceController.text) ?? 0.0,
                        purchaseQuantity: double.tryParse(qtyController.text) ?? 1.0,
                        supplierName: supplierController.text.trim(),
                        supplierContact: contactController.text.trim(),
                        lowStockThreshold: double.tryParse(alertController.text) ?? 500.0,
                      );

                      if (ingredientToEdit != null) {
                        inventory.updateIngredient(newIng);
                      } else {
                        inventory.addIngredient(newIng);
                      }

                      // Recalculate recipe costs dynamically
                      recipeProvider.syncRecipeCostsWithIngredients(inventory.ingredients);

                      Navigator.pop(ctx);
                    },
                    child: const Text("Save Ingredient"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final branding = Provider.of<BrandingProvider>(context).branding;
    final primaryColor = branding.primaryColor;
    final currencyFormat = NumberFormat.currency(symbol: branding.currencySymbol, decimalDigits: 2);

    final items = inventory.filteredIngredients;
    final categories = inventory.categories;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: Column(
        children: [
          // 1. Search Bar & Category Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (val) => inventory.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: "Search ingredients or suppliers...",
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: inventory.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => inventory.setSearchQuery(''),
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
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = inventory.selectedCategory == cat;
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
                      if (selected) inventory.setCategory(cat);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // 2. Inventory Items List
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text("No stock items found", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final ing = items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
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
                                      ing.name,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ing.isLowStock ? Colors.red.shade100 : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          ing.isLowStock ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                          size: 14,
                                          color: ing.isLowStock ? Colors.red.shade900 : Colors.green.shade900,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          ing.isLowStock ? "LOW STOCK" : "IN STOCK",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: ing.isLowStock ? Colors.red.shade900 : Colors.green.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Stock: ${ing.currentStock.toStringAsFixed(0)} ${ing.unit}",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: ing.isLowStock ? Colors.red.shade700 : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          "Supplier: ${ing.supplierName}",
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  RoleGuard(
                                    canAccess: (auth) => auth.permissions.canEditInventory,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.brown, size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => inventory.adjustStock(ing.id, -100),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, color: Colors.brown, size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => inventory.adjustStock(ing.id, 100),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _showIngredientModal(context, ingredientToEdit: ing),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              RoleGuard(
                                canAccess: (auth) => auth.permissions.canViewFinancials,
                                child: Text(
                                  "Purchase Price: ${currencyFormat.format(ing.purchasePrice)} per ${ing.purchaseQuantity.toStringAsFixed(0)} ${ing.unit}",
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: RoleGuard(
        canAccess: (auth) => auth.permissions.canEditInventory,
        child: FloatingActionButton.extended(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          onPressed: () => _showIngredientModal(context),
          icon: const Icon(Icons.add),
          label: const Text("New Stock Item"),
        ),
      ),
    );
  }
}
