import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/database_service.dart';
import 'providers/auth_provider.dart';
import 'providers/branding_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/order_provider.dart';
import 'theme/luxury_theme.dart';
import 'views/shell_screen.dart';
import 'views/auth/login_screen.dart';

class BakeryApp extends StatefulWidget {
  const BakeryApp({super.key});

  @override
  State<BakeryApp> createState() => _BakeryAppState();
}

class _BakeryAppState extends State<BakeryApp> {
  late final AuthProvider _authProvider;
  late final BrandingProvider _brandingProvider;
  late final InventoryProvider _inventoryProvider;
  late final RecipeProvider _recipeProvider;
  late final CustomerProvider _customerProvider;
  late final OrderProvider _orderProvider;
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _authProvider = Get.put(AuthProvider());
    _brandingProvider = Get.put(BrandingProvider());
    _inventoryProvider = Get.put(InventoryProvider());
    _recipeProvider = Get.put(RecipeProvider());
    _customerProvider = Get.put(CustomerProvider());
    _orderProvider = Get.put(OrderProvider());
    _initFuture = _initData();
  }

  Future<void> _initData() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint("Firebase init note: $e");
    }

    await DatabaseService.instance.seedInitialDataIfEmpty(
      onUsersLoaded: _authProvider.setUsers,
      onBrandingLoaded: _brandingProvider.updateBranding,
      onIngredientsLoaded: _inventoryProvider.setIngredients,
      onRecipesLoaded: _recipeProvider.setRecipes,
      onCustomersLoaded: _customerProvider.setCustomers,
      onOrdersLoaded: _orderProvider.setOrders,
    );

    // Restore saved user login session
    await _authProvider.restoreSavedSession();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _brandingProvider),
        ChangeNotifierProvider.value(value: _inventoryProvider),
        ChangeNotifierProvider.value(value: _recipeProvider),
        ChangeNotifierProvider.value(value: _customerProvider),
        ChangeNotifierProvider.value(value: _orderProvider),
      ],
      child: Consumer<BrandingProvider>(
        builder: (context, brandingProvider, _) {
          final branding = brandingProvider.branding;
          return GetMaterialApp(
            title: branding.businessName,
            debugShowCheckedModeBanner: false,
            theme: createLuxuryTheme(branding.primaryColor, branding.accentColor),
            home: FutureBuilder<void>(
              future: _initFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(branding.primaryColor),
                      ),
                    ),
                  );
                }
                return _authProvider.isAuthenticated
                    ? const ShellScreen()
                    : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
