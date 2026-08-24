import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../models/recipe_model.dart';
import '../../providers/branding_provider.dart';
import '../../services/pdf_service.dart';
import '../widgets/role_guard.dart';
import 'recipe_form_screen.dart';

class RecipeDetailScreen extends StatelessWidget {
  final RecipeModel recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  void _printRecipePdf(BuildContext context) async {
    final branding = Provider.of<BrandingProvider>(context, listen: false).branding;
    final pdfData = await PdfService.generateRecipePdf(recipe: recipe, branding: branding);

    await Printing.layoutPdf(
      onLayout: (format) async => pdfData,
      name: 'Recipe_${recipe.title.replaceAll(' ', '_')}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final branding = Provider.of<BrandingProvider>(context).branding;
    final currencyFormat = NumberFormat.currency(symbol: branding.currencySymbol, decimalDigits: 2);
    final primaryColor = branding.primaryColor;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(recipe.title),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.print_rounded),
              tooltip: "Print Recipe Sheet PDF",
              onPressed: () => _printRecipePdf(context),
            ),
            RoleGuard(
              canAccess: (auth) => auth.permissions.canEditRecipes,
              child: IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: "Edit Recipe",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RecipeFormScreen(recipeToEdit: recipe)),
                  );
                },
              ),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.shopping_basket_rounded), text: "Ingredients & Cost"),
              Tab(icon: Icon(Icons.format_list_numbered_rounded), text: "Method"),
              Tab(icon: Icon(Icons.health_and_safety_rounded), text: "Nutrition & Allergens"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Ingredients & Costing
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe Overview Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                      child: Row(
                        children: [
                          Expanded(child: _buildDetailMetric("Category", recipe.category, Icons.category_rounded, primaryColor)),
                          Expanded(child: _buildDetailMetric("Servings", "${recipe.yieldServings} pcs", Icons.pie_chart_rounded, primaryColor)),
                          Expanded(child: _buildDetailMetric("Prep / Bake", "${recipe.prepTimeMins}m / ${recipe.bakeTimeMins}m", Icons.timer_rounded, primaryColor)),
                          Expanded(child: _buildDetailMetric("Bake Temp", "${recipe.bakingTempC}°C", Icons.thermostat_rounded, Colors.deepOrange)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Financial Cost Summary Box (Owner / Manager permission check)
                  RoleGuard(
                    canAccess: (auth) => auth.permissions.canViewFinancials,
                    child: Card(
                      color: Colors.brown.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Total Batch Cost:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                Text(currencyFormat.format(recipe.totalBatchCost), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Cost per Portion:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                Text(
                                  currencyFormat.format(recipe.costPerServing),
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                ),
                              ],
                            ),
                            if (recipe.sellingPrice > 0) ...[
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Retail Price / Margin:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text(
                                    "${currencyFormat.format(recipe.sellingPrice)} (${recipe.grossProfitMargin.toStringAsFixed(1)}% margin)",
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigo),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text("Ingredients List (UK Units)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recipe.ingredients.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final ing = recipe.ingredients[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(ing.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text("Quantity: ${ing.quantity} ${ing.unit}"),
                        trailing: RoleGuard(
                          canAccess: (auth) => auth.permissions.canViewFinancials,
                          child: Text(
                            currencyFormat.format(ing.itemTotalCost),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Tab 2: Method & Instructions
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Step-by-Step Baking Method", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...recipe.instructions.asMap().entries.map((entry) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: primaryColor,
                              child: Text(
                                "${entry.key + 1}",
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 14, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (recipe.notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.amber.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.sticky_note_2_rounded, color: Colors.amber.shade900),
                                const SizedBox(width: 8),
                                Text(
                                  "Baker's Notes:",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(recipe.notes, style: TextStyle(color: Colors.amber.shade900)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Tab 3: Nutrition & Allergens
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Allergen Warnings Section
                  const Text("Allergen Information (UK Standard)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (recipe.allergens.isEmpty)
                    const Text("No major allergens flagged for this recipe.", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: recipe.allergens.map((allergen) {
                        return Chip(
                          avatar: const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.white),
                          label: Text(allergen, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.red.shade700,
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),

                  // Nutritional Table Section
                  const Text("Nutritional Information (Per Portion)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildNutritionalRow("Energy (Calories)", "${recipe.nutritionalInfo.calories} kcal", Colors.orange),
                          const Divider(),
                          _buildNutritionalRow("Protein", "${recipe.nutritionalInfo.protein} g", Colors.blue),
                          const Divider(),
                          _buildNutritionalRow("Carbohydrates", "${recipe.nutritionalInfo.carbohydrates} g", Colors.amber),
                          const Divider(),
                          _buildNutritionalRow("Fat", "${recipe.nutritionalInfo.fat} g", Colors.purple),
                          const Divider(),
                          _buildNutritionalRow("Sugar", "${recipe.nutritionalInfo.sugar} g", Colors.pink),
                          const Divider(),
                          _buildNutritionalRow("Salt", "${recipe.nutritionalInfo.salt} g", Colors.grey),
                          const Divider(),
                          _buildNutritionalRow("Fibre", "${recipe.nutritionalInfo.fibre} g", Colors.green),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailMetric(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildNutritionalRow(String label, String value, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
