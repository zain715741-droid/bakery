import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../models/branding_model.dart';
import '../models/ingredient_model.dart';
import '../models/recipe_model.dart';
import '../models/customer_model.dart';
import '../models/order_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _db;

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_db != null) return _db!;
    try {
      _db = await _initDatabase();
      return _db;
    } catch (e) {
      debugPrint("SQLite initialization error fallback: $e");
      return null;
    }
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, 'bakery_database.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE branding (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE ingredients (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT,
            data TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE recipes (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            category TEXT,
            data TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE customers (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            postcode TEXT,
            data TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE orders (
            id TEXT PRIMARY KEY,
            invoiceNumber TEXT NOT NULL,
            status TEXT NOT NULL,
            data TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            email TEXT NOT NULL,
            role TEXT NOT NULL,
            data TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            collection TEXT NOT NULL,
            action TEXT NOT NULL,
            documentId TEXT NOT NULL,
            payload TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // --- Seed Initial Bakery Demo Data ---
  Future<void> seedInitialDataIfEmpty({
    required Function(BrandingModel) onBrandingLoaded,
    required Function(List<IngredientModel>) onIngredientsLoaded,
    required Function(List<RecipeModel>) onRecipesLoaded,
    required Function(List<CustomerModel>) onCustomersLoaded,
    required Function(List<OrderModel>) onOrdersLoaded,
    required Function(List<UserModel>) onUsersLoaded,
  }) async {
    await database;

    // 1. Users
    final sampleUsers = [
      UserModel(
        id: 'u_owner_1',
        email: 'owner@bakery.co.uk',
        name: 'Eleanor Vance (Owner)',
        role: UserRole.owner,
      ),
      UserModel(
        id: 'u_manager_1',
        email: 'manager@bakery.co.uk',
        name: 'Arthur Pendelton (Manager)',
        role: UserRole.manager,
      ),
      UserModel(
        id: 'u_staff_1',
        email: 'staff@bakery.co.uk',
        name: 'Chloe Bennett (Staff)',
        role: UserRole.staff,
      ),
    ];
    onUsersLoaded(sampleUsers);

    // 2. Branding
    final sampleBranding = BrandingModel(
      businessName: "Honey & Flour Artisanal Bakery",
      ownerName: "Eleanor Vance",
      welcomeMessage: "Freshly Baked Artisan Breads & Delicate Pastries",
      primaryColorValue: 0xFF8D6E63,
      accentColorValue: 0xFFD81B60,
      currencySymbol: "£",
      vatRate: 0.20,
    );
    onBrandingLoaded(sampleBranding);

    // 3. Ingredients (UK standard units and pricing)
    final sampleIngredients = [
      IngredientModel(
        id: 'ing_1',
        name: 'Organic UK Plain Flour',
        category: 'Flour & Grains',
        currentStock: 15000,
        unit: 'g',
        purchasePrice: 12.50,
        purchaseQuantity: 10000,
        supplierName: 'Wessex Mill Wholesalers',
        supplierContact: '+44 1234 567890',
        lowStockThreshold: 3000,
      ),
      IngredientModel(
        id: 'ing_2',
        name: 'Unsalted British Butter',
        category: 'Dairy',
        currentStock: 5000,
        unit: 'g',
        purchasePrice: 18.00,
        purchaseQuantity: 2500,
        supplierName: 'Somerset Dairy Supplies',
        supplierContact: '+44 1234 999888',
        lowStockThreshold: 1000,
      ),
      IngredientModel(
        id: 'ing_3',
        name: 'Caster Sugar',
        category: 'Sugars & Sweeteners',
        currentStock: 8000,
        unit: 'g',
        purchasePrice: 8.50,
        purchaseQuantity: 5000,
        supplierName: 'British Sugar Co',
        lowStockThreshold: 2000,
      ),
      IngredientModel(
        id: 'ing_4',
        name: 'Free-Range Eggs (Large)',
        category: 'Dairy & Eggs',
        currentStock: 120,
        unit: 'pcs',
        purchasePrice: 15.00,
        purchaseQuantity: 60,
        supplierName: 'Cotswold Farm Eggs',
        lowStockThreshold: 24,
      ),
      IngredientModel(
        id: 'ing_5',
        name: 'Belgian Dark Chocolate 70%',
        category: 'Chocolate & Cocoa',
        currentStock: 3500,
        unit: 'g',
        purchasePrice: 24.00,
        purchaseQuantity: 2000,
        supplierName: 'Callebaut Imports UK',
        lowStockThreshold: 800,
      ),
      IngredientModel(
        id: 'ing_6',
        name: 'Madagascan Vanilla Extract',
        category: 'Flavourings',
        currentStock: 500,
        unit: 'ml',
        purchasePrice: 28.00,
        purchaseQuantity: 500,
        supplierName: 'BakeCraft Essentials',
        lowStockThreshold: 100,
      ),
    ];
    onIngredientsLoaded(sampleIngredients);

    // 4. Recipes
    final sampleRecipes = [
      RecipeModel(
        id: 'rec_1',
        title: 'Signature Dark Chocolate Brownie',
        category: 'Brownies & Bars',
        prepTimeMins: 20,
        bakeTimeMins: 35,
        bakingTempC: 175,
        yieldServings: 12,
        sellingPrice: 3.50,
        ingredients: [
          RecipeIngredientItem(
            ingredientId: 'ing_5',
            name: 'Belgian Dark Chocolate 70%',
            quantity: 300,
            unit: 'g',
            unitCost: 0.012,
          ),
          RecipeIngredientItem(
            ingredientId: 'ing_2',
            name: 'Unsalted British Butter',
            quantity: 200,
            unit: 'g',
            unitCost: 0.0072,
          ),
          RecipeIngredientItem(
            ingredientId: 'ing_3',
            name: 'Caster Sugar',
            quantity: 250,
            unit: 'g',
            unitCost: 0.0017,
          ),
          RecipeIngredientItem(
            ingredientId: 'ing_4',
            name: 'Free-Range Eggs (Large)',
            quantity: 4,
            unit: 'pcs',
            unitCost: 0.25,
          ),
          RecipeIngredientItem(
            ingredientId: 'ing_1',
            name: 'Organic UK Plain Flour',
            quantity: 100,
            unit: 'g',
            unitCost: 0.00125,
          ),
        ],
        instructions: [
          'Preheat oven to 175°C and line a 9x9 inch baking pan with parchment paper.',
          'Melt Belgian dark chocolate and unsalted butter together in a heatproof bowl over simmering water.',
          'Whisk caster sugar and free-range eggs until pale, thick, and fluffy.',
          'Fold melted chocolate mixture into the egg mixture gently.',
          'Sift in the organic plain flour and fold until just combined.',
          'Pour into lined pan and bake for 30-35 minutes until fudgy in the center.',
          'Allow to cool completely before slicing into 12 squares.'
        ],
        notes: 'Best served warm with a scoop of vanilla bean ice cream.',
        allergens: ['Milk', 'Eggs', 'Wheat', 'Gluten', 'Soy'],
        nutritionalInfo: const NutritionalInfo(
          calories: 340,
          protein: 4.8,
          carbohydrates: 38.5,
          fat: 19.2,
          sugar: 28.0,
          salt: 0.15,
          fibre: 2.4,
        ),
      ),
      RecipeModel(
        id: 'rec_2',
        title: 'Classic Victoria Sponge Cake',
        category: 'Cakes',
        prepTimeMins: 25,
        bakeTimeMins: 25,
        bakingTempC: 180,
        yieldServings: 10,
        sellingPrice: 22.00,
        ingredients: [
          RecipeIngredientItem(
            ingredientId: 'ing_2',
            name: 'Unsalted British Butter',
            quantity: 225,
            unit: 'g',
            unitCost: 0.0072,
          ),
          RecipeIngredientItem(
            ingredientId: 'ing_3',
            name: 'Caster Sugar',
            quantity: 225,
            unit: 'g',
            unitCost: 0.0017,
          ),
          RecipeIngredientItem(
            ingredientId: 'ing_4',
            name: 'Free-Range Eggs (Large)',
            quantity: 4,
            unit: 'pcs',
            unitCost: 0.25,
          ),
          RecipeIngredientItem(
            ingredientId: 'ing_1',
            name: 'Organic UK Plain Flour',
            quantity: 225,
            unit: 'g',
            unitCost: 0.00125,
          ),
          RecipeIngredientItem(
            ingredientId: 'ing_6',
            name: 'Madagascan Vanilla Extract',
            quantity: 5,
            unit: 'ml',
            unitCost: 0.056,
          ),
        ],
        instructions: [
          'Preheat oven to 180°C and grease two 8-inch sandwich tins.',
          'Cream butter and caster sugar together until fluffy and pale.',
          'Beat in eggs one at a time, adding a spoon of flour if it curdles.',
          'Fold in remaining flour and vanilla extract.',
          'Divide evenly between tins and bake for 20-25 minutes.',
          'Sandwich with raspberry jam and whipped cream. Dust top with icing sugar.'
        ],
        notes: 'Quintessential British afternoon tea center-piece.',
        allergens: ['Milk', 'Eggs', 'Wheat', 'Gluten'],
        nutritionalInfo: const NutritionalInfo(
          calories: 385,
          protein: 5.2,
          carbohydrates: 44.0,
          fat: 21.0,
          sugar: 26.5,
          salt: 0.22,
          fibre: 1.1,
        ),
      ),
    ];
    onRecipesLoaded(sampleRecipes);

    // 5. Customers
    final sampleCustomers = [
      CustomerModel(
        id: 'cust_1',
        name: 'Lady Olivia Kensington',
        phone: '+44 7700 900123',
        email: 'olivia.k@kensington-estates.co.uk',
        address: '14 Royal Crescent, Bath',
        postcode: 'BA1 2LS',
        notes: 'Loves extra vanilla in Victoria sponge orders.',
        favoriteRecipeIds: ['rec_2'],
        totalOrders: 4,
        totalSpent: 145.50,
      ),
      CustomerModel(
        id: 'cust_2',
        name: 'James Sterling',
        phone: '+44 7911 123456',
        email: 'james@sterlingcafe.co.uk',
        address: '88 High Street, Bristol',
        postcode: 'BS1 4HA',
        notes: 'Weekly wholesale buyer for cafe.',
        favoriteRecipeIds: ['rec_1', 'rec_2'],
        totalOrders: 12,
        totalSpent: 480.00,
      ),
    ];
    onCustomersLoaded(sampleCustomers);

    // 6. Orders
    final sampleOrders = [
      OrderModel(
        id: 'ord_101',
        invoiceNumber: 'INV-2026-001',
        customerId: 'cust_1',
        customerName: 'Lady Olivia Kensington',
        customerPhone: '+44 7700 900123',
        customerAddress: '14 Royal Crescent, Bath',
        customerPostcode: 'BA1 2LS',
        items: [
          OrderItem(recipeId: 'rec_2', recipeName: 'Classic Victoria Sponge Cake', quantity: 2, unitPrice: 22.00),
          OrderItem(recipeId: 'rec_1', recipeName: 'Signature Dark Chocolate Brownie', quantity: 6, unitPrice: 3.50),
        ],
        status: OrderStatus.completed,
        fulfillment: FulfillmentType.delivery,
        paymentStatus: PaymentStatus.paid,
        vatRate: 0.20,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        targetDate: DateTime.now().subtract(const Duration(days: 1)),
        notes: 'Deliver before 11:00 AM for garden party.',
      ),
      OrderModel(
        id: 'ord_102',
        invoiceNumber: 'INV-2026-002',
        customerId: 'cust_2',
        customerName: 'James Sterling',
        customerPhone: '+44 7911 123456',
        customerAddress: '88 High Street, Bristol',
        customerPostcode: 'BS1 4HA',
        items: [
          OrderItem(recipeId: 'rec_1', recipeName: 'Signature Dark Chocolate Brownie', quantity: 24, unitPrice: 3.00),
        ],
        status: OrderStatus.baking,
        fulfillment: FulfillmentType.collection,
        paymentStatus: PaymentStatus.paid,
        vatRate: 0.20,
        createdAt: DateTime.now(),
        targetDate: DateTime.now().add(const Duration(hours: 4)),
        notes: 'Pack in 2 wholesale presentation boxes.',
      ),
    ];
    onOrdersLoaded(sampleOrders);
  }
}
