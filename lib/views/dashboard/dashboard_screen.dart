import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

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

    final currencyFormat = NumberFormat.currency(
      symbol: branding.currencySymbol,
      decimalDigits: 2,
    );
    final primaryColor = branding.primaryColor;
    final accentColor = branding.accentColor;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        // =====================================================
        // AMBIENT BACKGROUND GLOWS
        // =====================================================
        Positioned(
          top: -120,
          right: -100,
          child: _backgroundGlow(350, accentColor, .08),
        ),
        Positioned(
          top: 400,
          left: -120,
          child: _backgroundGlow(380, const Color(0xFFD9B98C), .12),
        ),

        // =====================================================
        // MAIN SCROLLABLE CONTENT
        // =====================================================
        Positioned.fill(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 24.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Luxury Welcome & Branding Hero Card
              _buildHeroHeader(
                context,
                auth,
                branding,
                primaryColor,
                accentColor,
              ),
              const SizedBox(height: 20),

              // 2. Pending User Approvals Alert for Owner
              if (auth.isOwner && auth.pendingCount > 0) ...[
                _buildActionBanner(
                  onTap: () => onNavigateToTab(6),
                  icon: Icons.person_add_rounded,
                  accentIconBg: const Color(0xFFFFE0B2),
                  iconColor: const Color(0xFFE65100),
                  borderColor: const Color(0xFFFF9800),
                  bgColor: const Color(0xFFFFF8F0),
                  title:
                      "${auth.pendingCount} New Staff Registration(s) Pending Review",
                  subtitle: "Tap to review, assign roles, and approve access.",
                ),
                const SizedBox(height: 18),
              ],

              // 3. Alert Bar if Low Stock Exists
              if (inventoryProvider.lowStockIngredients.isNotEmpty) ...[
                _buildActionBanner(
                  onTap: () => onNavigateToTab(2),
                  icon: Icons.warning_amber_rounded,
                  accentIconBg: const Color(0xFFFFE082),
                  iconColor: const Color(0xFFE65100),
                  borderColor: const Color(0xFFFFB300),
                  bgColor: const Color(0xFFFFFDF5),
                  title:
                      "Low Stock Alert: ${inventoryProvider.lowStockIngredients.length} ingredient(s) below threshold!",
                  subtitle: "Tap to view inventory and re-order supplies.",
                ),
                const SizedBox(height: 20),
              ],

              // 4. Financial KPI Stat Cards (Owner & Manager View)
              RoleGuard(
                canAccess: (auth) => auth.permissions.canViewFinancials,
                fallback: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "🔒 Financial summaries restricted to management roles.",
                    style: GoogleFonts.outfit(
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF806F63),
                      fontSize: 13,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "EXECUTIVE OVERVIEW",
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFA67C1E),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Financial Performance",
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2C1810),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EEE4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE3D6C6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: Color(0xFFA67C1E),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat("dd MMMM yyyy")
                                    .format(DateTime.now()),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: const Color(0xFF2C1810),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 600 ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.50 : 1.20,
                      children: [
                        _buildLuxuryStatCard(
                          title: "Today's Sales",
                          value: currencyFormat
                              .format(orderProvider.todaySalesTotal),
                          icon: Icons.today_rounded,
                          accentColor: accentColor,
                          primaryColor: primaryColor,
                        ),
                        _buildLuxuryStatCard(
                          title: "Monthly Sales",
                          value: currencyFormat
                              .format(orderProvider.monthSalesTotal),
                          icon: Icons.calendar_month_rounded,
                          accentColor: accentColor,
                          primaryColor: primaryColor,
                        ),
                        _buildLuxuryStatCard(
                          title: "Annual Sales",
                          value: currencyFormat
                              .format(orderProvider.annualSalesTotal),
                          icon: Icons.insights_rounded,
                          accentColor: accentColor,
                          primaryColor: primaryColor,
                        ),
                        _buildLuxuryStatCard(
                          title: "Pending Orders",
                          value: orderProvider.pendingOrdersCount.toString(),
                          icon: Icons.soup_kitchen_rounded,
                          accentColor: accentColor,
                          primaryColor: primaryColor,
                          isPending: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Sales Trend Visualizer Chart Card
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFCF7),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFE2D3BF),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF6B4B32).withValues(alpha: .06),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(22.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Weekly Revenue Trends",
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2C1810),
                                    ),
                                  ),
                                  Text(
                                    "Live order revenue distribution (${branding.currencySymbol})",
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: const Color(0xFF806F63),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      accentColor.withValues(alpha: 0.22),
                                      accentColor.withValues(alpha: 0.08),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Icon(
                                  Icons.show_chart_rounded,
                                  color: const Color(0xFFA67C1E),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Builder(builder: (context) {
                            final weeklyTrend = orderProvider.weeklySalesTrend;
                            final maxSale = weeklyTrend
                                .map((e) => (e['amount'] as double))
                                .fold(0.0, (a, b) => a > b ? a : b);
                            final double maxY = maxSale > 0 ? (maxSale * 1.3) : 100.0;
                            final List<FlSpot> spots = [];
                            for (int i = 0; i < weeklyTrend.length; i++) {
                              spots.add(FlSpot(i.toDouble(), weeklyTrend[i]['amount'] as double));
                            }

                            return SizedBox(
                              height: 190,
                              child: LineChart(
                                LineChartData(
                                  minY: 0,
                                  maxY: maxY,
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: maxY > 0 ? (maxY / 4) : 25,
                                    getDrawingHorizontalLine: (val) => FlLine(
                                      color: const Color(0xFFEDE3D5),
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (val, meta) {
                                          final index = val.toInt();
                                          if (index >= 0 && index < weeklyTrend.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(
                                                weeklyTrend[index]['day'] as String,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF806F63),
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox();
                                        },
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: true,
                                      curveSmoothness: 0.35,
                                      color: const Color(0xFFA67C1E),
                                      barWidth: 3.5,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData, index) =>
                                            FlDotCirclePainter(
                                          radius: 4.5,
                                          color: accentColor,
                                          strokeWidth: 2,
                                          strokeColor: Colors.white,
                                        ),
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            accentColor.withValues(alpha: 0.30),
                                            accentColor.withValues(alpha: 0.0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // 5. Quick Operations
              Text(
                "QUICK OPERATIONS",
                style: GoogleFonts.outfit(
                  color: const Color(0xFFA67C1E),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Direct Actions",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C1810),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildLuxuryActionButton(
                      context,
                      label: "New Order",
                      icon: Icons.add_shopping_cart_rounded,
                      primaryColor: primaryColor,
                      accentColor: accentColor,
                      onTap: () => onNavigateToTab(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLuxuryActionButton(
                      context,
                      label: "Recipes",
                      icon: Icons.menu_book_rounded,
                      primaryColor: primaryColor,
                      accentColor: accentColor,
                      onTap: () => onNavigateToTab(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLuxuryActionButton(
                      context,
                      label: "Customers",
                      icon: Icons.people_outline_rounded,
                      primaryColor: primaryColor,
                      accentColor: accentColor,
                      onTap: () => onNavigateToTab(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 6. Bakery Metrics Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildLuxurySummaryTile(
                      title: "Artisanal Recipes",
                      value: recipeProvider.recipes.length.toString(),
                      subtitle: "Active Catalog",
                      icon: Icons.cake_rounded,
                      accentColor: accentColor,
                      primaryColor: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildLuxurySummaryTile(
                      title: "Registered CRM",
                      value: customerProvider.customers.length.toString(),
                      subtitle: "Customer Database",
                      icon: Icons.groups_rounded,
                      accentColor: accentColor,
                      primaryColor: primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ],
    );
  }

  // ============================================================
  // HERO HEADER
  // ============================================================
  Widget _buildHeroHeader(
    BuildContext context,
    AuthProvider auth,
    dynamic branding,
    Color primaryColor,
    Color accentColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2C1810),
            Color.alphaBlend(Colors.black38, const Color(0xFF2C1810)),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C1810).withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 460;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFF6D77A),
                          accentColor,
                          Color.alphaBlend(Colors.black12, accentColor),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2C1810),
                      ),
                      child: const Icon(
                        Icons.bakery_dining_rounded,
                        color: Color(0xFFD4AF37),
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back,",
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFD9B98C),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          auth.currentUser?.name ?? branding.ownerName,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isNarrow) ...[
                    const SizedBox(width: 12),
                    _buildRoleBadge(auth, accentColor),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${branding.businessName} • Artisan Bakery Portal",
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isNarrow) ...[
                    const SizedBox(width: 8),
                    _buildRoleBadge(auth, accentColor),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleBadge(AuthProvider auth, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.7),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            auth.isOwner
                ? Icons.workspace_premium
                : (auth.isManager
                    ? Icons.manage_accounts
                    : Icons.badge),
            size: 14,
            color: accentColor,
          ),
          const SizedBox(width: 5),
          Text(
            auth.currentRole.displayName.toUpperCase(),
            style: GoogleFonts.outfit(
              color: accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 10.5,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================
  Widget _buildLuxuryStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required Color primaryColor,
    bool isPending = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending
              ? Colors.orange.withValues(alpha: 0.4)
              : const Color(0xFFE2D3BF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4B32).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF806F63),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (isPending ? Colors.orange : accentColor)
                          .withValues(alpha: 0.22),
                      (isPending ? Colors.orange : accentColor)
                          .withValues(alpha: 0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: isPending
                      ? const Color(0xFFE65100)
                      : const Color(0xFFA67C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isPending
                    ? const Color(0xFFE65100)
                    : const Color(0xFF2C1810),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================
  Widget _buildLuxuryActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color primaryColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE2D3BF),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B4B32).withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF0CE72),
                    accentColor,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: const Color(0xFF2C1810), size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C1810),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY TILE
  // ============================================================
  Widget _buildLuxurySummaryTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color primaryColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2D3BF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4B32).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5EEE4),
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Icon(icon, color: const Color(0xFFA67C1E), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2C1810),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C1810),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: const Color(0xFF806F63),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BANNER
  // ============================================================
  Widget _buildActionBanner({
    required VoidCallback onTap,
    required IconData icon,
    required Color accentIconBg,
    required Color iconColor,
    required Color borderColor,
    required Color bgColor,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accentIconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFBF360C),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFE65100),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFFE65100),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BACKGROUND GLOW HELPER
  // ============================================================
  Widget _backgroundGlow(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: 130,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}