import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/branding_provider.dart';
import '../widgets/role_guard.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final branding = Provider.of<BrandingProvider>(context).branding;

    final currencyFormat = NumberFormat.currency(symbol: branding.currencySymbol, decimalDigits: 2);
    final primaryColor = branding.primaryColor;

    final todaySales = orderProvider.todaySalesTotal;
    final monthSales = orderProvider.monthSalesTotal;
    final annualSales = orderProvider.annualSalesTotal;

    // Calculate total ingredient stock value in inventory
    final totalInventoryValue = inventoryProvider.ingredients.fold(
      0.0,
      (sum, item) => sum + (item.currentStock * item.costPerUnit),
    );

    return RoleGuard(
      canAccess: (auth) => auth.permissions.canViewFinancials,
      fallback: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text("Financial Reports Restricted", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Financial analytics are hidden for Staff accounts.", style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFBF7),
        body: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            const Text("Financial & Business Reports", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Revenue Breakdown Cards
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Sales Revenue Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Icon(Icons.trending_up_rounded, color: primaryColor),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildReportLine("Daily Sales (Today)", currencyFormat.format(todaySales), Colors.teal),
                    const Divider(),
                    _buildReportLine("Monthly Sales (Current)", currencyFormat.format(monthSales), Colors.indigo),
                    const Divider(),
                    _buildReportLine("Annual Sales (2026)", currencyFormat.format(annualSales), primaryColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Inventory Asset & Profit Margin Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Inventory Asset Valuation", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildReportLine("Total Raw Stock Valuation", currencyFormat.format(totalInventoryValue), Colors.brown),
                    const Divider(),
                    _buildReportLine("Active Inventory Line Items", "${inventoryProvider.ingredients.length} items", Colors.black87),
                    const Divider(),
                    _buildReportLine("Low Stock Alert Items", "${inventoryProvider.lowStockIngredients.length} items", Colors.amber.shade900),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recipe Margin Analysis
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Recipe Profitability Analysis", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...recipeProvider.recipes.map((r) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text("Cost: ${currencyFormat.format(r.costPerServing)} | Price: ${currencyFormat.format(r.sellingPrice)}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                "${r.grossProfitMargin.toStringAsFixed(1)}% margin",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green.shade900),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportLine(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}
