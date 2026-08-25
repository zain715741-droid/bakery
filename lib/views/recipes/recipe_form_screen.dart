import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recipe_model.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/branding_provider.dart';

class RecipeFormScreen extends StatefulWidget {
  final RecipeModel? recipeToEdit;

  const RecipeFormScreen({super.key, this.recipeToEdit});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _categoryController;
  late TextEditingController _prepTimeController;
  late TextEditingController _bakeTimeController;
  late TextEditingController _tempController;
  late TextEditingController _servingsController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _notesController;

  // Nutrition controllers
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _sugarController;
  late TextEditingController _saltController;
  late TextEditingController _fibreController;

  List<RecipeIngredientItem> _selectedIngredients = [];
  List<TextEditingController> _instructionControllers = [];

  final List<String> _ukAllergensList = [
    'Milk',
    'Eggs',
    'Nuts',
    'Peanuts',
    'Wheat',
    'Gluten',
    'Soy',
    'Sesame',
    'Mustard',
    'Celery',
    'Lupin',
    'Molluscs',
    'Crustaceans',
    'Sulphites',
  ];

  Set<String> _selectedAllergens = {};

  @override
  void initState() {
    super.initState();
    final r = widget.recipeToEdit;

    _titleController = TextEditingController(text: r?.title ?? '');
    _categoryController = TextEditingController(text: r?.category ?? 'Cakes');
    _prepTimeController = TextEditingController(text: r != null ? r.prepTimeMins.toString() : '20');
    _bakeTimeController = TextEditingController(text: r != null ? r.bakeTimeMins.toString() : '30');
    _tempController = TextEditingController(text: r != null ? r.bakingTempC.toString() : '180');
    _servingsController = TextEditingController(text: r != null ? r.yieldServings.toString() : '12');
    _sellingPriceController = TextEditingController(text: r != null ? r.sellingPrice.toString() : '3.50');
    _notesController = TextEditingController(text: r?.notes ?? '');

    _caloriesController = TextEditingController(text: r != null ? r.nutritionalInfo.calories.toString() : '300');
    _proteinController = TextEditingController(text: r != null ? r.nutritionalInfo.protein.toString() : '5.0');
    _carbsController = TextEditingController(text: r != null ? r.nutritionalInfo.carbohydrates.toString() : '40.0');
    _fatController = TextEditingController(text: r != null ? r.nutritionalInfo.fat.toString() : '15.0');
    _sugarController = TextEditingController(text: r != null ? r.nutritionalInfo.sugar.toString() : '20.0');
    _saltController = TextEditingController(text: r != null ? r.nutritionalInfo.salt.toString() : '0.2');
    _fibreController = TextEditingController(text: r != null ? r.nutritionalInfo.fibre.toString() : '2.0');

    if (r != null) {
      _selectedIngredients = List.from(r.ingredients);
      _selectedAllergens = Set.from(r.allergens);
      _instructionControllers = r.instructions.map((step) => TextEditingController(text: step)).toList();
    }

    if (_instructionControllers.isEmpty) {
      _instructionControllers.add(TextEditingController(text: 'Preheat oven and prepare baking tin.'));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _prepTimeController.dispose();
    _bakeTimeController.dispose();
    _tempController.dispose();
    _servingsController.dispose();
    _sellingPriceController.dispose();
    _notesController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _sugarController.dispose();
    _saltController.dispose();
    _fibreController.dispose();
    for (final c in _instructionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addIngredientDialog() async {
    final inventory = Provider.of<InventoryProvider>(context, listen: false);
    final item = await showDialog<RecipeIngredientItem>(
      context: context,
      builder: (ctx) => AddRecipeIngredientDialog(ingredients: inventory.ingredients),
    );
    if (item != null) {
      setState(() {
        _selectedIngredients.add(item);
      });
    }
  }

  void _saveRecipe() {
    if (!_formKey.currentState!.validate()) return;

    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);

    final instructions = _instructionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

    final newRecipe = RecipeModel(
      id: widget.recipeToEdit?.id ?? 'rec_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      prepTimeMins: int.tryParse(_prepTimeController.text) ?? 20,
      bakeTimeMins: int.tryParse(_bakeTimeController.text) ?? 30,
      bakingTempC: int.tryParse(_tempController.text) ?? 180,
      yieldServings: int.tryParse(_servingsController.text) ?? 12,
      sellingPrice: double.tryParse(_sellingPriceController.text) ?? 3.50,
      ingredients: _selectedIngredients,
      instructions: instructions,
      notes: _notesController.text.trim(),
      allergens: _selectedAllergens.toList(),
      nutritionalInfo: NutritionalInfo(
        calories: double.tryParse(_caloriesController.text) ?? 0,
        protein: double.tryParse(_proteinController.text) ?? 0,
        carbohydrates: double.tryParse(_carbsController.text) ?? 0,
        fat: double.tryParse(_fatController.text) ?? 0,
        sugar: double.tryParse(_sugarController.text) ?? 0,
        salt: double.tryParse(_saltController.text) ?? 0,
        fibre: double.tryParse(_fibreController.text) ?? 0,
      ),
    );

    if (widget.recipeToEdit != null) {
      recipeProvider.updateRecipe(newRecipe);
    } else {
      recipeProvider.addRecipe(newRecipe);
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text("Recipe '${newRecipe.title}' saved successfully!"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Provider.of<BrandingProvider>(context).branding.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipeToEdit == null ? "Create New Recipe" : "Edit Recipe"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Details Card
              const Text("Recipe Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Recipe Title *", border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? "Title is required" : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Retail Price (£)", border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prepTimeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Prep (Mins)", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _bakeTimeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Bake (Mins)", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _tempController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Temp (°C)", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _servingsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Yield Servings", border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Ingredients Picker Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Ingredients & Quantities", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: _addIngredientDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Add Ingredient"),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_selectedIngredients.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text("No ingredients added yet. Tap 'Add Ingredient' to select from stock.")),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedIngredients.length,
                  itemBuilder: (context, idx) {
                    final item = _selectedIngredients[idx];
                    return Card(
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text("${item.quantity} ${item.unit}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            setState(() => _selectedIngredients.removeAt(idx));
                          },
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),

              // Baking Steps Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Baking Instructions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.brown),
                    onPressed: () {
                      setState(() => _instructionControllers.add(TextEditingController()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._instructionControllers.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 12, backgroundColor: primaryColor, child: Text("${entry.key + 1}", style: const TextStyle(color: Colors.white, fontSize: 10))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: entry.value,
                          decoration: InputDecoration(hintText: "Step ${entry.key + 1} method...", border: const OutlineInputBorder()),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () {
                          if (_instructionControllers.length > 1) {
                            setState(() => _instructionControllers.removeAt(entry.key));
                          }
                        },
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Allergen Selector Checkboxes (14 UK Allergens)
              const Text("UK Allergen Warnings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _ukAllergensList.map((allergen) {
                  final isSelected = _selectedAllergens.contains(allergen);
                  return FilterChip(
                    label: Text(allergen),
                    selected: isSelected,
                    selectedColor: Colors.red.shade100,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAllergens.add(allergen);
                        } else {
                          _selectedAllergens.remove(allergen);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Nutrition Fields
              const Text("Nutritional Information (per portion)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _caloriesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Calories (kcal)", border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _proteinController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Protein (g)", border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _carbsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Carbs (g)", border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _fatController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Fat (g)", border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _sugarController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Sugar (g)", border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _saltController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Salt (g)", border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveRecipe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Save Recipe to Catalog", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddRecipeIngredientDialog extends StatefulWidget {
  final List<dynamic> ingredients;

  const AddRecipeIngredientDialog({super.key, required this.ingredients});

  @override
  State<AddRecipeIngredientDialog> createState() => _AddRecipeIngredientDialogState();
}

class _AddRecipeIngredientDialogState extends State<AddRecipeIngredientDialog> {
  late bool _isCustom;
  String? _selectedIngId;
  late final TextEditingController _customNameController;
  late final TextEditingController _customUnitController;
  late final TextEditingController _customCostController;
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _isCustom = widget.ingredients.isEmpty;
    _selectedIngId = widget.ingredients.isNotEmpty ? widget.ingredients.first.id : null;
    _customNameController = TextEditingController();
    _customUnitController = TextEditingController(text: 'g');
    _customCostController = TextEditingController(text: '0.01');
    _qtyController = TextEditingController(text: '100');
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _customUnitController.dispose();
    _customCostController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _submit() {
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    if (qty <= 0) return;

    if (!_isCustom && widget.ingredients.isNotEmpty && _selectedIngId != null) {
      final ing = widget.ingredients.firstWhere((i) => i.id == _selectedIngId, orElse: () => widget.ingredients.first);
      Navigator.pop(
        context,
        RecipeIngredientItem(
          ingredientId: ing.id,
          name: ing.name,
          quantity: qty,
          unit: ing.unit,
          unitCost: ing.costPerUnit,
        ),
      );
    } else {
      final name = _customNameController.text.trim();
      if (name.isEmpty) return;
      final unit = _customUnitController.text.trim().isEmpty ? 'g' : _customUnitController.text.trim();
      final cost = double.tryParse(_customCostController.text) ?? 0.01;

      Navigator.pop(
        context,
        RecipeIngredientItem(
          ingredientId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          quantity: qty,
          unit: unit,
          unitCost: cost,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasStock = widget.ingredients.isNotEmpty;

    return AlertDialog(
      title: const Text("Add Recipe Ingredient"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasStock) ...[
              Row(
                children: [
                  ChoiceChip(
                    label: const Text("From Stock"),
                    selected: !_isCustom,
                    onSelected: (val) => setState(() => _isCustom = !val),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text("Custom Item"),
                    selected: _isCustom,
                    onSelected: (val) => setState(() => _isCustom = val),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            if (!_isCustom && hasStock) ...[
              DropdownButtonFormField<String>(
                key: const ValueKey('ingredient_dropdown'),
                initialValue: _selectedIngId,
                decoration: const InputDecoration(labelText: "Select Ingredient", border: OutlineInputBorder()),
                items: widget.ingredients.map((ing) {
                  return DropdownMenuItem<String>(
                    value: ing.id as String,
                    child: Text("${ing.name} (${ing.unit})"),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedIngId = val);
                },
              ),
              const SizedBox(height: 12),
            ] else ...[
              TextField(
                key: const ValueKey('custom_ing_name'),
                controller: _customNameController,
                decoration: const InputDecoration(labelText: "Ingredient Name *", hintText: "e.g. Flour", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('custom_ing_unit'),
                      controller: _customUnitController,
                      decoration: const InputDecoration(labelText: "Unit (g, ml, pcs)", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('custom_ing_cost'),
                      controller: _customCostController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Cost (£/unit)", border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantity", border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: _submit, child: const Text("Add Ingredient")),
      ],
    );
  }
}
