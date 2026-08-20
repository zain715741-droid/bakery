import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/branding_provider.dart';
import 'widgets/sync_banner.dart';
import 'dashboard/dashboard_screen.dart';
import 'recipes/recipes_screen.dart';
import 'inventory/inventory_screen.dart';
import 'orders/orders_screen.dart';
import 'customers/customers_screen.dart';
import 'users/user_management_screen.dart';
import 'branding/branding_screen.dart';
import 'reports/reports_screen.dart';
import 'auth/login_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _currentIndex = 0;
  bool _isOnline = true;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final branding = Provider.of<BrandingProvider>(context).branding;
    final auth = Provider.of<AuthProvider>(context);
    final primaryColor = branding.primaryColor;

    final List<Widget> pages = [
      DashboardScreen(onNavigateToTab: _onTabSelected),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        if (isDesktop) {
          // Desktop / Web Responsive Layout with NavigationRail
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  const Icon(Icons.bakery_dining_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    branding.businessName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text("• ${pageTitles[_currentIndex]}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal)),
                ],
              ),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: Icon(_isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded),
                  tooltip: _isOnline ? "Connected to Cloud Firestore" : "Offline Storage Mode",
                  onPressed: () {
                    setState(() => _isOnline = !_isOnline);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_isOnline ? "Connected to Cloud Firestore" : "Switched to 100% Offline SQLite Storage Mode"),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.account_circle_rounded, size: 28),
                  onSelected: (val) {
                    if (val == 'branding') {
                      setState(() => _currentIndex = 7);
                    } else if (val == 'users') {
                      setState(() => _currentIndex = 6);
                    } else if (val == 'reports') {
                      setState(() => _currentIndex = 5);
                    } else if (val == 'logout') {
                      auth.logout();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(auth.currentUser?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("Role: ${auth.currentRole.displayName}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const Divider(),
                        ],
                      ),
                    ),
                    if (auth.permissions.canViewFinancials)
                      const PopupMenuItem(
                        value: 'reports',
                        child: Row(children: [Icon(Icons.bar_chart, size: 18), SizedBox(width: 8), Text("Financial Reports")]),
                      ),
                    if (auth.permissions.canManageUsers)
                      const PopupMenuItem(
                        value: 'users',
                        child: Row(children: [Icon(Icons.people_alt, size: 18), SizedBox(width: 8), Text("User Management")]),
                      ),
                    if (auth.permissions.canEditBranding)
                      const PopupMenuItem(
                        value: 'branding',
                        child: Row(children: [Icon(Icons.brush_rounded, size: 18), SizedBox(width: 8), Text("Branding Settings")]),
                      ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(children: [Icon(Icons.logout, color: Colors.red, size: 18), SizedBox(width: 8), Text("Sign Out", style: TextStyle(color: Colors.red))]),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
              ],
            ),
            body: Column(
              children: [
                SyncBanner(
                  isOnline: _isOnline,
                  onSyncPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Cloud Firestore sync completed! All data is synced."), backgroundColor: Colors.green),
                    );
                  },
                ),
                Expanded(
                  child: Row(
                    children: [
                      NavigationRail(
                        selectedIndex: _currentIndex,
                        onDestinationSelected: _onTabSelected,
                        labelType: NavigationRailLabelType.all,
                        selectedIconTheme: IconThemeData(color: primaryColor),
                        selectedLabelTextStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                        unselectedIconTheme: const IconThemeData(color: Colors.grey),
                        unselectedLabelTextStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                        destinations: const [
                          NavigationRailDestination(icon: Icon(Icons.dashboard_rounded), label: Text("Dashboard")),
                          NavigationRailDestination(icon: Icon(Icons.menu_book_rounded), label: Text("Recipes")),
                          NavigationRailDestination(icon: Icon(Icons.inventory_2_rounded), label: Text("Inventory")),
                          NavigationRailDestination(icon: Icon(Icons.receipt_long_rounded), label: Text("Orders")),
                          NavigationRailDestination(icon: Icon(Icons.contacts_rounded), label: Text("Customers")),
                          NavigationRailDestination(icon: Icon(Icons.bar_chart_rounded), label: Text("Reports")),
                          NavigationRailDestination(icon: Icon(Icons.people_alt_rounded), label: Text("Users")),
                          NavigationRailDestination(icon: Icon(Icons.brush_rounded), label: Text("Branding")),
                        ],
                      ),
                      const VerticalDivider(thickness: 1, width: 1),
                      Expanded(child: pages[_currentIndex]),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile Layout with BottomNavigationBar & Drawer
        return Scaffold(
          appBar: AppBar(
            title: Text(
              pageTitles[_currentIndex],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(_isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded),
                tooltip: _isOnline ? "Connected to Cloud Firestore" : "Offline Storage Mode",
                onPressed: () {
                  setState(() => _isOnline = !_isOnline);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isOnline ? "Connected to Cloud Firestore" : "Switched to 100% Offline SQLite Storage Mode"),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: primaryColor),
                  accountName: Text(auth.currentUser?.name ?? branding.ownerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  accountEmail: Text(auth.currentUser?.email ?? 'owner@bakery.co.uk'),
                  currentAccountPicture: const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.bakery_dining_rounded, color: Colors.white, size: 36),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard_rounded),
                  title: const Text("Dashboard"),
                  selected: _currentIndex == 0,
                  onTap: () {
                    _onTabSelected(0);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book_rounded),
                  title: const Text("Recipes"),
                  selected: _currentIndex == 1,
                  onTap: () {
                    _onTabSelected(1);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.inventory_2_rounded),
                  title: const Text("Inventory"),
                  selected: _currentIndex == 2,
                  onTap: () {
                    _onTabSelected(2);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long_rounded),
                  title: const Text("Orders"),
                  selected: _currentIndex == 3,
                  onTap: () {
                    _onTabSelected(3);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.contacts_rounded),
                  title: const Text("Customers"),
                  selected: _currentIndex == 4,
                  onTap: () {
                    _onTabSelected(4);
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                if (auth.permissions.canViewFinancials)
                  ListTile(
                    leading: const Icon(Icons.bar_chart_rounded),
                    title: const Text("Financial Reports"),
                    selected: _currentIndex == 5,
                    onTap: () {
                      _onTabSelected(5);
                      Navigator.pop(context);
                    },
                  ),
                if (auth.permissions.canManageUsers)
                  ListTile(
                    leading: const Icon(Icons.people_alt_rounded),
                    title: const Text("User Management"),
                    selected: _currentIndex == 6,
                    onTap: () {
                      _onTabSelected(6);
                      Navigator.pop(context);
                    },
                  ),
                if (auth.permissions.canEditBranding)
                  ListTile(
                    leading: const Icon(Icons.brush_rounded),
                    title: const Text("Branding Studio"),
                    selected: _currentIndex == 7,
                    onTap: () {
                      _onTabSelected(7);
                      Navigator.pop(context);
                    },
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Sign Out", style: TextStyle(color: Colors.red)),
                  onTap: () {
                    auth.logout();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              SyncBanner(
                isOnline: _isOnline,
                onSyncPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cloud Firestore sync completed! All data is synced."), backgroundColor: Colors.green),
                  );
                },
              ),
              Expanded(child: pages[_currentIndex]),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex > 4 ? 0 : _currentIndex,
            onTap: _onTabSelected,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey.shade600,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
              BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: "Recipes"),
              BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: "Inventory"),
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: "Orders"),
              BottomNavigationBarItem(icon: Icon(Icons.contacts_rounded), label: "Customers"),
            ],
          ),
        );
      },
    );
  }
}
