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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.bakery_dining_rounded, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                pageTitles[_currentIndex],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded),
            tooltip: _isOnline ? "Simulate Offline Mode" : "Simulate Online Mode",
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
        ],
      ),
      body: Column(
        children: [
          SyncBanner(
            isOnline: _isOnline,
            onSyncPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Cloud Firestore sync completed! All local data is up to date."), backgroundColor: Colors.green),
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
  }
}
