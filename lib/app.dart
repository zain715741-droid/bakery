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
import 'controllers/storefront_controller.dart';
import 'views/storefront/storefront_screen.dart';
import 'views/shell_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/signup_screen.dart';
import 'views/orders/order_form_screen.dart';
import 'views/recipes/recipe_form_screen.dart';

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
    Get.put(StorefrontController(), permanent: true);
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
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFFFAF8F5),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2C1810),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bakery_dining_rounded, color: Color(0xFFD4AF37), size: 40),
                    ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C1810)),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Loading Artisan Bakery...',
                      style: TextStyle(
                        color: Color(0xFF2C1810),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

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
                initialRoute: '/',
                getPages: [
                  GetPage(name: '/', page: () => const StorefrontScreen()),
                  GetPage(name: '/StorefrontScreen', page: () => const StorefrontScreen()),
                  GetPage(name: '/ShellScreen', page: () => const ShellScreen()),
                  GetPage(name: '/LoginScreen', page: () => const LoginScreen()),
                  GetPage(name: '/SignUpScreen', page: () => const SignUpScreen()),
                  GetPage(name: '/OrderFormScreen', page: () => const OrderFormScreen()),
                  GetPage(name: '/RecipeFormScreen', page: () => const RecipeFormScreen()),
                ],
                unknownRoute: GetPage(name: '/notfound', page: () => const StorefrontScreen()),
              );
            },
          ),
        );
      },
    );
  }
}
