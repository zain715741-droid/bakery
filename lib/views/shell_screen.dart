import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/shell_controller.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/branding_provider.dart';
import '../theme/luxury_theme.dart';
import 'widgets/sync_banner.dart';
import 'storefront/storefront_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'recipes/recipes_screen.dart';
import 'inventory/inventory_screen.dart';
import 'orders/orders_screen.dart';
import 'customers/customers_screen.dart';
import 'users/user_management_screen.dart';
import 'branding/branding_screen.dart';
import 'reports/reports_screen.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ShellController());

    final List<Widget> pages = [
      DashboardScreen(onNavigateToTab: controller.selectTab),
      const RecipesScreen(),
      const InventoryScreen(),
      const OrdersScreen(),
      const CustomersScreen(),
      const ReportsScreen(),
      const UserManagementScreen(),
      const BrandingScreen(),
    ];

    final List<String> pageTitles = [
      "Bakery Dashboard",
      "Recipe Catalog",
      "Stock & Inventory",
      "Orders & Invoices",
      "Customer CRM",
      "Financial Reports",
      "User Management",
      "Branding Studio",
    ];

    return Consumer2<BrandingProvider, AuthProvider>(
      builder: (context, brandingProvider, auth, _) {
        final branding = brandingProvider.branding;
        final primaryColor = branding.primaryColor;
        final accentColor = branding.accentColor;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;

            if (isDesktop) {
              // Desktop Layout
              return Scaffold(
            backgroundColor: LuxuryColors.cream,
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor, width: 1.5),
                    ),
                    child: Icon(Icons.bakery_dining_rounded, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      branding.businessName,
                      style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Obx(() => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          pageTitles[controller.currentIndex.value],
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.95)),
                        ),
                      )),
                ],
              ),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              actions: [
                OutlinedButton.icon(
                  onPressed: () => Get.to(() => const StorefrontScreen()),
                  icon: const Icon(Icons.storefront_rounded, size: 16, color: Colors.white),
                  label: Text('Customer Storefront', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 10),
                _buildOnlineBadge(controller),
                const SizedBox(width: 14),
                _buildProfileMenu(auth, controller, accentColor),
                const SizedBox(width: 16),
              ],
            ),
            body: Column(
              children: [
                Obx(() => SyncBanner(
                      isOnline: controller.isOnline.value,
                      onSyncPressed: () {
                        Get.snackbar("Sync Complete", "Cloud Firestore sync completed!", backgroundColor: LuxuryColors.espresso, colorText: Colors.white);
                      },
                    )),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 92,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(right: BorderSide(color: Colors.brown.shade100, width: 1)),
                          boxShadow: LuxuryShadows.soft,
                        ),
                        child: LayoutBuilder(
                          builder: (context, railConstraints) {
                            return SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: railConstraints.maxHeight),
                                child: IntrinsicHeight(
                                  child: Obx(() => NavigationRail(
                                        minWidth: 92,
                                        backgroundColor: Colors.transparent,
                                        selectedIndex: controller.currentIndex.value,
                                        onDestinationSelected: controller.selectTab,
                                        labelType: NavigationRailLabelType.all,
                                        indicatorColor: accentColor.withValues(alpha: 0.2),
                                        selectedIconTheme: IconThemeData(color: primaryColor, size: 24),
                                        selectedLabelTextStyle: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                                        unselectedIconTheme: IconThemeData(color: Colors.brown.shade300, size: 21),
                                        unselectedLabelTextStyle: GoogleFonts.outfit(color: Colors.brown.shade400, fontSize: 10.5),
                                        destinations: [
                                          const NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: Text("Dashboard")),
                                          const NavigationRailDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: Text("Recipes")),
                                          const NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2_rounded), label: Text("Inventory")),
                                          const NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: Text("Orders")),
                                          const NavigationRailDestination(icon: Icon(Icons.contacts_outlined), selectedIcon: Icon(Icons.contacts_rounded), label: Text("Customers")),
                                          const NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: Text("Reports")),
                                          NavigationRailDestination(
                                            icon: auth.pendingCount > 0
                                                ? Badge.count(count: auth.pendingCount, backgroundColor: Colors.orange.shade800, child: const Icon(Icons.people_alt_outlined))
                                                : const Icon(Icons.people_alt_outlined),
                                            selectedIcon: auth.pendingCount > 0
                                                ? Badge.count(count: auth.pendingCount, backgroundColor: Colors.orange.shade800, child: const Icon(Icons.people_alt_rounded))
                                                : const Icon(Icons.people_alt_rounded),
                                            label: const Text("Users"),
                                          ),
                                          const NavigationRailDestination(icon: Icon(Icons.brush_outlined), selectedIcon: Icon(Icons.brush_rounded), label: Text("Branding")),
                                        ],
                                      )),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: Obx(
                          () => pages[controller.currentIndex.value],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile Layout
        return Scaffold(
          backgroundColor: LuxuryColors.cream,
          appBar: AppBar(
            title: Obx(() => Text(
                  pageTitles[controller.currentIndex.value],
                  style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 18),
                )),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Obx(() => Icon(
                      controller.isOnline.value ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      color: controller.isOnline.value ? Colors.greenAccent : Colors.orangeAccent,
                    )),
                onPressed: controller.toggleOnline,
              ),
            ],
          ),
          drawer: _buildDrawer(auth, branding, controller, primaryColor, accentColor),
          body: Column(
            children: [
              Obx(() => SyncBanner(
                    isOnline: controller.isOnline.value,
                    onSyncPressed: () {
                      Get.snackbar("Sync Complete", "Cloud Firestore sync completed!", backgroundColor: LuxuryColors.espresso, colorText: Colors.white);
                    },
                  )),
              Expanded(
                child: Obx(
                  () => pages[controller.currentIndex.value],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Obx(() => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.brown.shade100, width: 1)),
                ),
                child: BottomNavigationBar(
                  currentIndex: controller.currentIndex.value > 4 ? 0 : controller.currentIndex.value,
                  onTap: controller.selectTab,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.white,
                  selectedItemColor: primaryColor,
                  unselectedItemColor: Colors.brown.shade300,
                  selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
                  unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 11),
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
                    BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book_rounded), label: "Recipes"),
                    BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2_rounded), label: "Inventory"),
                    BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long_rounded), label: "Orders"),
                    BottomNavigationBarItem(icon: Icon(Icons.contacts_outlined), activeIcon: Icon(Icons.contacts_rounded), label: "Customers"),
                  ],
                ),
              )),
        );
      },
    );
  },
);
  }

  Widget _buildOnlineBadge(ShellController controller) {
    return Obx(() => Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: controller.isOnline.value ? const Color(0xFF2E7D32).withValues(alpha: 0.25) : Colors.orange.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: controller.isOnline.value ? Colors.greenAccent : Colors.orangeAccent),
          ),
          child: InkWell(
            onTap: controller.toggleOnline,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(controller.isOnline.value ? Icons.cloud_done_rounded : Icons.cloud_off_rounded, size: 15, color: controller.isOnline.value ? Colors.greenAccent : Colors.orangeAccent),
                const SizedBox(width: 6),
                Text(controller.isOnline.value ? "Cloud Online" : "Offline SQLite", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
        ));
  }

  Widget _buildProfileMenu(AuthProvider auth, ShellController controller, Color accentColor) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accentColor, width: 1.5)),
        child: const Icon(Icons.person_rounded, size: 22, color: Colors.white),
      ),
      onSelected: (val) {
        if (val == 'storefront') Get.to(() => const StorefrontScreen());
        if (val == 'branding') controller.selectTab(7);
        if (val == 'users') controller.selectTab(6);
        if (val == 'reports') controller.selectTab(5);
        if (val == 'logout') controller.logout();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(auth.currentUser?.name ?? 'Artisan User', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: LuxuryColors.textPrimary)),
              Text("Role: ${auth.currentRole.displayName}", style: GoogleFonts.outfit(fontSize: 12, color: accentColor, fontWeight: FontWeight.w600)),
              const Divider(),
            ],
          ),
        ),
        if (auth.permissions.canViewFinancials)
          PopupMenuItem(value: 'reports', child: Row(children: [const Icon(Icons.bar_chart, size: 18), const SizedBox(width: 8), Text("Financial Reports", style: GoogleFonts.outfit())])),
        if (auth.permissions.canManageUsers)
          PopupMenuItem(
            value: 'users',
            child: Row(
              children: [
                const Icon(Icons.people_alt, size: 18),
                const SizedBox(width: 8),
                Text("User Management", style: GoogleFonts.outfit()),
                if (auth.pendingCount > 0) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: Colors.orange.shade800, borderRadius: BorderRadius.circular(10)),
                    child: Text("${auth.pendingCount}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),
        if (auth.permissions.canEditBranding)
          PopupMenuItem(value: 'branding', child: Row(children: [const Icon(Icons.brush_rounded, size: 18), const SizedBox(width: 8), Text("Branding Studio", style: GoogleFonts.outfit())])),
        PopupMenuItem(
          value: 'storefront',
          child: Row(
            children: [
              const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF6B4423)),
              const SizedBox(width: 8),
              Text("View Storefront", style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        PopupMenuItem(value: 'logout', child: Row(children: [const Icon(Icons.logout, color: Colors.red, size: 18), const SizedBox(width: 8), Text("Sign Out", style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w600))])),
      ],
    );
  }

  Widget _buildDrawer(AuthProvider auth, dynamic branding, ShellController controller, Color primaryColor, Color accentColor) {
    return Drawer(
      backgroundColor: LuxuryColors.cream,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryColor, Color.alphaBlend(Colors.black38, primaryColor)]),
              border: Border(bottom: BorderSide(color: accentColor.withValues(alpha: 0.4), width: 1.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Icon(Icons.bakery_dining_rounded, color: Colors.white, size: 32)),
                const SizedBox(height: 14),
                Text(auth.currentUser?.name ?? branding.ownerName, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(auth.currentUser?.email ?? 'owner@bakery.co.uk', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
              ],
            ),
          ),
          _buildDrawerTile(Icons.dashboard_rounded, "Dashboard", 0, controller, primaryColor, accentColor),
          _buildDrawerTile(Icons.menu_book_rounded, "Recipes", 1, controller, primaryColor, accentColor),
          _buildDrawerTile(Icons.inventory_2_rounded, "Inventory", 2, controller, primaryColor, accentColor),
          _buildDrawerTile(Icons.receipt_long_rounded, "Orders", 3, controller, primaryColor, accentColor),
          _buildDrawerTile(Icons.contacts_rounded, "Customers", 4, controller, primaryColor, accentColor),
          const Divider(),
          if (auth.permissions.canViewFinancials) _buildDrawerTile(Icons.bar_chart_rounded, "Financial Reports", 5, controller, primaryColor, accentColor),
          if (auth.permissions.canManageUsers) _buildDrawerTile(Icons.people_alt_rounded, "User Management", 6, controller, primaryColor, accentColor, badgeCount: auth.pendingCount),
          if (auth.permissions.canEditBranding) _buildDrawerTile(Icons.brush_rounded, "Branding Studio", 7, controller, primaryColor, accentColor),
          const Divider(),
          ListTile(
            leading: Icon(Icons.storefront_rounded, color: primaryColor),
            title: Text("Customer Storefront", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: primaryColor)),
            onTap: () {
              Get.back();
              Get.to(() => const StorefrontScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: Text("Sign Out", style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: controller.logout,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, int index, ShellController controller, Color primaryColor, Color accentColor, {int badgeCount = 0}) {
    return Obx(() {
      final isSelected = controller.currentIndex.value == index;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: accentColor.withValues(alpha: 0.5)) : null,
        ),
        child: ListTile(
          leading: badgeCount > 0
              ? Badge.count(count: badgeCount, backgroundColor: Colors.orange.shade800, child: Icon(icon, color: isSelected ? primaryColor : Colors.brown.shade400))
              : Icon(icon, color: isSelected ? primaryColor : Colors.brown.shade400),
          title: Text(title, style: GoogleFonts.outfit(color: isSelected ? primaryColor : LuxuryColors.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
          trailing: badgeCount > 0 ? Text("$badgeCount pending", style: GoogleFonts.outfit(color: Colors.orange.shade800, fontSize: 11, fontWeight: FontWeight.bold)) : null,
          onTap: () {
            controller.selectTab(index);
            Get.back(); // close drawer
          },
        ),
      );
    });
  }
}
