import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'providers/auth_provider.dart';
import 'providers/branding_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/order_provider.dart';
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
    _authProvider = AuthProvider();
    _brandingProvider = BrandingProvider();
    _inventoryProvider = InventoryProvider();
    _recipeProvider = RecipeProvider();
    _customerProvider = CustomerProvider();
    _orderProvider = OrderProvider();
    _initFuture = _initData();
  }

  Future<void> _initData() async {
    await DatabaseService.instance.seedInitialDataIfEmpty(
      onUsersLoaded: _authProvider.setUsers,
      onBrandingLoaded: _brandingProvider.updateBranding,
      onIngredientsLoaded: _inventoryProvider.setIngredients,
      onRecipesLoaded: _recipeProvider.setRecipes,
      onCustomersLoaded: _customerProvider.setCustomers,
      onOrdersLoaded: _orderProvider.setOrders,
    );
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
          return MaterialApp(
            title: branding.businessName,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: branding.primaryColor,
                primary: branding.primaryColor,
                secondary: branding.accentColor,
                surface: const Color(0xFFFDFBF7),
              ),
              scaffoldBackgroundColor: const Color(0xFFFDFBF7),
              fontFamily: 'Roboto',
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: branding.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
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
                return const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
