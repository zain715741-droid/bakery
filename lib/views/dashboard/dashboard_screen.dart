import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branding_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/recipe_provider.dart';
import '../widgets/role_guard.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int index) onNavigateToTab;

  const DashboardScreen({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final branding = Provider.of<BrandingProvider>(context).branding;
    final auth = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final customerProvider = Provider.of<CustomerProvider>(context);
    final recipeProvider = Provider.of<RecipeProvider>(context);

    final currencyFormat = NumberFormat.currency(symbol: branding.currencySymbol, decimalDigits: 2);
    final primaryColor = branding.primaryColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Welcome & Branding Banner
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back, ${auth.currentUser?.name ?? branding.ownerName}!",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${branding.businessName} • ${auth.currentRole.displayName} Access",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    avatar: Icon(
                      auth.isOwner ? Icons.workspace_premium : (auth.isManager ? Icons.manage_accounts : Icons.badge),
                      size: 16,
                      color: primaryColor,
                    ),
                    label: Text(
                      auth.currentRole.displayName.toUpperCase(),
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Alert Bar if Low Stock Exists
          if (inventoryProvider.lowStockIngredients.isNotEmpty) ...[
            GestureDetector(
              onTap: () => onNavigateToTab(2), // Navigate to Inventory tab
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  border: Border.all(color: Colors.amber.shade800),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Low Stock Alert: ${inventoryProvider.lowStockIngredients.length} ingredient(s) below re-order threshold!",
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.amber.shade900),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 3. Financial KPI Stat Cards (Owner & Manager View)
          RoleGuard(
            canAccess: (auth) => auth.permissions.canViewFinancials,
            fallback: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "🔒 Financial summaries hidden for Staff accounts.",
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sales & Operations Overview",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      title: "Today's Sales",
                      value: currencyFormat.format(orderProvider.todaySalesTotal),
                      icon: Icons.today_rounded,
                      color: Colors.teal,
                    ),
                    _buildStatCard(
                      title: "Monthly Sales",
                      value: currencyFormat.format(orderProvider.monthSalesTotal),
                      icon: Icons.calendar_month_rounded,
                      color: Colors.indigo,
                    ),
                    _buildStatCard(
                      title: "Annual Sales",
                      value: currencyFormat.format(orderProvider.annualSalesTotal),
                      icon: Icons.insights_rounded,
                      color: Colors.deepPurple,
                    ),
                    _buildStatCard(
                      title: "Pending Orders",
                      value: orderProvider.pendingOrdersCount.toString(),
                      icon: Icons.soup_kitchen_rounded,
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sales Trend Visualizer Chart
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Weekly Revenue Trend (£)",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Icon(Icons.show_chart_rounded, color: primaryColor),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 180,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (val, meta) {
                                      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                      if (val.toInt() >= 0 && val.toInt() < days.length) {
                                        return Text(days[val.toInt()], style: const TextStyle(fontSize: 10));
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: const [
                                    FlSpot(0, 120),
                                    FlSpot(1, 240),
                                    FlSpot(2, 180),
                                    FlSpot(3, 310),
                                    FlSpot(4, 290),
                                    FlSpot(5, 450),
                                    FlSpot(6, 520),
                                  ],
                                  isCurved: true,
                                  color: primaryColor,
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: primaryColor.withValues(alpha: 0.15),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // 4. Quick Operational Shortcuts
          const Text(
            "Quick Actions",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  label: "New Order",
                  icon: Icons.add_shopping_cart_rounded,
                  color: Colors.deepOrange,
                  onTap: () => onNavigateToTab(3), // Orders tab
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  context,
                  label: "Browse Recipes",
                  icon: Icons.menu_book_rounded,
                  color: Colors.brown,
                  onTap: () => onNavigateToTab(1), // Recipes tab
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  context,
                  label: "Customers",
                  icon: Icons.people_outline_rounded,
                  color: Colors.teal,
                  onTap: () => onNavigateToTab(4), // Customers tab
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 5. Bakery Metrics Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                  title: "Total Recipes",
                  value: recipeProvider.recipes.length.toString(),
                  subtitle: "Active catalog",
                  icon: Icons.cake_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryTile(
                  title: "Registered Customers",
                  value: customerProvider.customers.length.toString(),
                  subtitle: "CRM directory",
                  icon: Icons.groups_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                Icon(icon, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: Icon(icon, color: Colors.brown),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
