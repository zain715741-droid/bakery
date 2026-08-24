import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // --- Hybrid Cloud & Local Data Methods ---

  Future<void> saveDocument(String collectionName, String docId, Map<String, dynamic> data) async {
    // 1. Save locally (SQLite)
    try {
      final db = await database;
      if (db != null) {
        await db.insert(
          collectionName,
          {'id': docId, 'data': jsonEncode(data)},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint("Local SQLite save note: $e");
    }

    // 2. Save locally (SharedPreferences key-value store for Web / Offline persistence)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sp_${collectionName}_$docId', jsonEncode(data));
      final ids = prefs.getStringList('sp_ids_$collectionName') ?? [];
      if (!ids.contains(docId)) {
        ids.add(docId);
        await prefs.setStringList('sp_ids_$collectionName', ids);
      }
    } catch (e) {
      debugPrint("Local SharedPreferences save note: $e");
    }

    // 3. Sync live to Firebase Cloud Firestore
    try {
      await _firestore.collection(collectionName).doc(docId).set(data, SetOptions(merge: true));
      debugPrint("Synced document $docId to Firebase Firestore collection '$collectionName'");
    } catch (e) {
      debugPrint("Firebase sync note (queued offline): $e");
      await _queueForSync(collectionName, 'SAVE', docId, data);
    }
  }

  Future<void> deleteDocument(String collectionName, String docId) async {
    // 1. Delete from SQLite
    try {
      final db = await database;
      if (db != null) {
        await db.delete(collectionName, where: 'id = ?', whereArgs: [docId]);
      }
    } catch (e) {
      debugPrint("Local delete note: $e");
    }

    // 2. Delete from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sp_${collectionName}_$docId');
      final ids = prefs.getStringList('sp_ids_$collectionName') ?? [];
      ids.remove(docId);
      await prefs.setStringList('sp_ids_$collectionName', ids);
    } catch (e) {
      debugPrint("Local SharedPreferences delete note: $e");
    }

    // 3. Delete from Firebase Firestore
    try {
      await _firestore.collection(collectionName).doc(docId).delete();
    } catch (e) {
      await _queueForSync(collectionName, 'DELETE', docId, {});
    }
  }

  Future<void> _queueForSync(String collectionName, String action, String docId, Map<String, dynamic> payload) async {
    try {
      final db = await database;
      if (db != null) {
        await db.insert('sync_queue', {
          'collection': collectionName,
          'action': action,
          'documentId': docId,
          'payload': jsonEncode(payload),
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint("Queue sync error: $e");
    }
  }

  Future<void> syncPendingQueueToFirebase() async {
    try {
      final db = await database;
      if (db == null) return;

      final pendingRows = await db.query('sync_queue', orderBy: 'id ASC');
      for (final row in pendingRows) {
        final id = row['id'] as int;
        final collection = row['collection'] as String;
        final action = row['action'] as String;
        final docId = row['documentId'] as String;
        final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;

        try {
          if (action == 'SAVE') {
            await _firestore.collection(collection).doc(docId).set(payload, SetOptions(merge: true));
          } else if (action == 'DELETE') {
            await _firestore.collection(collection).doc(docId).delete();
          }
          await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
        } catch (e) {
          debugPrint("Failed to sync item $id to Firebase: $e");
          break;
        }
      }
    } catch (e) {
      debugPrint("Error syncing queue to Firebase: $e");
    }
  }

  // --- Seed Initial Bakery Demo Data (Cloud First, Local Storage, No Fake Staff) ---
  Future<void> seedInitialDataIfEmpty({
    required Function(BrandingModel) onBrandingLoaded,
    required Function(List<IngredientModel>) onIngredientsLoaded,
    required Function(List<RecipeModel>) onRecipesLoaded,
    required Function(List<CustomerModel>) onCustomersLoaded,
    required Function(List<OrderModel>) onOrdersLoaded,
    required Function(List<UserModel>) onUsersLoaded,
  }) async {
    await database;

    bool loadedFromCloud = false;

    // 1. Attempt fetching live data from Firebase Cloud Firestore first
    try {
      final usersSnap = await _firestore.collection('users').get().timeout(const Duration(seconds: 3));
      if (usersSnap.docs.isNotEmpty) {
        final users = usersSnap.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
        onUsersLoaded(users);
        loadedFromCloud = true;
      }

      final brandingSnap = await _firestore.collection('branding').get().timeout(const Duration(seconds: 3));
      if (brandingSnap.docs.isNotEmpty) {
        final branding = BrandingModel.fromMap(brandingSnap.docs.first.data());
        onBrandingLoaded(branding);
      }

      final ingSnap = await _firestore.collection('ingredients').get().timeout(const Duration(seconds: 3));
      if (ingSnap.docs.isNotEmpty) {
        final ingredients = ingSnap.docs.map((doc) => IngredientModel.fromMap(doc.data())).toList();
        onIngredientsLoaded(ingredients);
      }

      final recipeSnap = await _firestore.collection('recipes').get().timeout(const Duration(seconds: 3));
      if (recipeSnap.docs.isNotEmpty) {
        final recipes = recipeSnap.docs.map((doc) => RecipeModel.fromMap(doc.data())).toList();
        onRecipesLoaded(recipes);
      }

      final custSnap = await _firestore.collection('customers').get().timeout(const Duration(seconds: 3));
      if (custSnap.docs.isNotEmpty) {
        final customers = custSnap.docs.map((doc) => CustomerModel.fromMap(doc.data())).toList();
        onCustomersLoaded(customers);
      }

      final orderSnap = await _firestore.collection('orders').get().timeout(const Duration(seconds: 3));
      if (orderSnap.docs.isNotEmpty) {
        final orders = orderSnap.docs.map((doc) => OrderModel.fromMap(doc.data())).toList();
        onOrdersLoaded(orders);
      }
    } catch (e) {
      debugPrint("Firebase cloud initial load note (checking local persistence): $e");
    }

    if (loadedFromCloud) return;

    // 2. Sample Datasets for fallback & initial fresh launch
    final now = DateTime.now();

    final sampleUsers = [
      UserModel(
        id: 'u_owner_1',
        email: 'owner@bakery.co.uk',
        password: 'owner',
        name: 'Bakery Owner',
        role: UserRole.owner,
        isApproved: true,
        createdAt: now,
      ),
    ];

    final sampleBranding = BrandingModel(
      businessName: "Honey & Flour Artisanal Bakery",
      ownerName: "Eleanor Vance",
      welcomeMessage: "Freshly Baked Artisan Breads & Delicate Pastries",
      primaryColorValue: 0xFF2C1810,
      accentColorValue: 0xFFD4AF37,
      currencySymbol: "£",
      vatRate: 0.20,
    );

    final sampleIngredients = [
      IngredientModel(
        id: 'ing_1',
        name: 'Organic UK Plain Flour',
        category: 'Flour & Grains',
        currentStock: 25000,
        unit: 'g',
        purchasePrice: 16.50,
        purchaseQuantity: 15000,
        supplierName: 'Wessex Mill Wholesalers',
        supplierContact: '+44 1234 567890',
        lowStockThreshold: 5000,
      ),
      IngredientModel(
        id: 'ing_2',
        name: 'French Strong Bread Flour (T65)',
        category: 'Flour & Grains',
        currentStock: 30000,
        unit: 'g',
        purchasePrice: 22.00,
        purchaseQuantity: 20000,
        supplierName: 'Moulins Viron Imports',
        supplierContact: '+44 1234 567899',
        lowStockThreshold: 6000,
      ),
      IngredientModel(
        id: 'ing_3',
        name: 'Unsalted British Butter (82% Fat)',
        category: 'Dairy',
        currentStock: 8500,
        unit: 'g',
        purchasePrice: 32.00,
        purchaseQuantity: 5000,
        supplierName: 'Somerset Dairy Supplies',
        supplierContact: '+44 1234 999888',
        lowStockThreshold: 2000,
      ),
      IngredientModel(
        id: 'ing_4',
        name: 'Caster Sugar',
        category: 'Sugars & Sweeteners',
        currentStock: 12000,
        unit: 'g',
        purchasePrice: 11.50,
        purchaseQuantity: 8000,
        supplierName: 'British Sugar Co',
        lowStockThreshold: 3000,
      ),
      IngredientModel(
        id: 'ing_5',
        name: 'Soft Light Brown Sugar',
        category: 'Sugars & Sweeteners',
        currentStock: 6000,
        unit: 'g',
        purchasePrice: 8.00,
        purchaseQuantity: 5000,
        supplierName: 'British Sugar Co',
        lowStockThreshold: 1500,
      ),
      IngredientModel(
        id: 'ing_6',
        name: 'Free-Range Eggs (Large)',
        category: 'Dairy & Eggs',
        currentStock: 180,
        unit: 'pcs',
        purchasePrice: 22.00,
        purchaseQuantity: 90,
        supplierName: 'Cotswold Farm Eggs',
        supplierContact: '+44 1452 778899',
        lowStockThreshold: 36,
      ),
      IngredientModel(
        id: 'ing_7',
        name: 'Belgian Dark Chocolate 70%',
        category: 'Chocolate & Cocoa',
        currentStock: 5000,
        unit: 'g',
        purchasePrice: 36.00,
        purchaseQuantity: 3000,
        supplierName: 'Callebaut Imports UK',
        lowStockThreshold: 1200,
      ),
      IngredientModel(
        id: 'ing_8',
        name: 'Madagascan Vanilla Extract',
        category: 'Flavourings',
        currentStock: 800,
        unit: 'ml',
        purchasePrice: 42.00,
        purchaseQuantity: 750,
        supplierName: 'BakeCraft Essentials',
        lowStockThreshold: 150,
      ),
      IngredientModel(
        id: 'ing_9',
        name: 'Active Dry Baker\'s Yeast',
        category: 'Leaveners',
        currentStock: 1500,
        unit: 'g',
        purchasePrice: 9.50,
        purchaseQuantity: 1000,
        supplierName: 'DCL Yeast Ltd',
        lowStockThreshold: 300,
      ),
      IngredientModel(
        id: 'ing_10',
        name: 'Cornish Fine Sea Salt',
        category: 'Seasonings',
        currentStock: 4000,
        unit: 'g',
        purchasePrice: 6.50,
        purchaseQuantity: 3000,
        supplierName: 'Cornish Sea Salt Co',
        lowStockThreshold: 800,
      ),
      IngredientModel(
        id: 'ing_11',
        name: 'Ceylon Ground Cinnamon',
        category: 'Spices',
        currentStock: 750,
        unit: 'g',
        purchasePrice: 14.00,
        purchaseQuantity: 500,
        supplierName: 'Spice Gourmet UK',
        lowStockThreshold: 150,
      ),
      IngredientModel(
        id: 'ing_12',
        name: 'Fresh Whole Farm Milk',
        category: 'Dairy',
        currentStock: 12000,
        unit: 'ml',
        purchasePrice: 10.00,
        purchaseQuantity: 10000,
        supplierName: 'Somerset Dairy Supplies',
        lowStockThreshold: 3000,
      ),
    ];

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
          RecipeIngredientItem(ingredientId: 'ing_7', name: 'Belgian Dark Chocolate 70%', quantity: 300, unit: 'g', unitCost: 0.012),
          RecipeIngredientItem(ingredientId: 'ing_3', name: 'Unsalted British Butter (82% Fat)', quantity: 200, unit: 'g', unitCost: 0.0064),
          RecipeIngredientItem(ingredientId: 'ing_4', name: 'Caster Sugar', quantity: 250, unit: 'g', unitCost: 0.0014),
          RecipeIngredientItem(ingredientId: 'ing_5', name: 'Soft Light Brown Sugar', quantity: 100, unit: 'g', unitCost: 0.0016),
          RecipeIngredientItem(ingredientId: 'ing_6', name: 'Free-Range Eggs (Large)', quantity: 4, unit: 'pcs', unitCost: 0.24),
          RecipeIngredientItem(ingredientId: 'ing_1', name: 'Organic UK Plain Flour', quantity: 120, unit: 'g', unitCost: 0.0011),
          RecipeIngredientItem(ingredientId: 'ing_8', name: 'Madagascan Vanilla Extract', quantity: 5, unit: 'ml', unitCost: 0.056),
          RecipeIngredientItem(ingredientId: 'ing_10', name: 'Cornish Fine Sea Salt', quantity: 3, unit: 'g', unitCost: 0.0021),
        ],
        instructions: [
          'Preheat convection oven to 175°C and line a 20x30cm baking tin.',
          'Melt Belgian dark chocolate and unsalted butter together in a bain-marie.',
          'Whisk eggs, caster sugar, and brown sugar until thick, pale, and doubled in volume.',
          'Gently fold melted chocolate mixture into the whipped eggs.',
          'Sift in plain flour and sea salt; fold with spatula until just combined.',
          'Pour into tin and bake for 30-35 minutes until papery crust forms with fudgy center.',
        ],
        notes: 'Best served warmed with clotted cream. Shelf life: 5 days at room temperature.',
        allergens: ['Milk', 'Eggs', 'Wheat', 'Gluten', 'Soya'],
        nutritionalInfo: const NutritionalInfo(calories: 380, protein: 4.5, carbohydrates: 45.0, fat: 21.0, sugar: 34.0, salt: 0.3, fibre: 2.1),
      ),
      RecipeModel(
        id: 'rec_2',
        title: 'Classic Victoria Sponge Cake',
        category: 'Cakes',
        prepTimeMins: 25,
        bakeTimeMins: 25,
        bakingTempC: 180,
        yieldServings: 8,
        sellingPrice: 24.00,
        ingredients: [
          RecipeIngredientItem(ingredientId: 'ing_3', name: 'Unsalted British Butter (82% Fat)', quantity: 225, unit: 'g', unitCost: 0.0064),
          RecipeIngredientItem(ingredientId: 'ing_4', name: 'Caster Sugar', quantity: 225, unit: 'g', unitCost: 0.0014),
          RecipeIngredientItem(ingredientId: 'ing_6', name: 'Free-Range Eggs (Large)', quantity: 4, unit: 'pcs', unitCost: 0.24),
          RecipeIngredientItem(ingredientId: 'ing_1', name: 'Organic UK Plain Flour', quantity: 225, unit: 'g', unitCost: 0.0011),
          RecipeIngredientItem(ingredientId: 'ing_8', name: 'Madagascan Vanilla Extract', quantity: 5, unit: 'ml', unitCost: 0.056),
        ],
        instructions: [
          'Preheat oven to 180°C and grease two 20cm round sandwich tins.',
          'Cream softened butter and caster sugar together until pale and fluffy.',
          'Gradually incorporate eggs one by one with a dash of flour.',
          'Fold in the remaining flour and vanilla extract gently.',
          'Divide batter equally into prepared tins and bake for 22-25 minutes until golden springy.',
          'Fill center with artisan strawberry jam and Chantilly cream. Dust top with powdered sugar.',
        ],
        notes: 'Quintessential British afternoon tea center-piece.',
        allergens: ['Milk', 'Eggs', 'Wheat', 'Gluten'],
        nutritionalInfo: const NutritionalInfo(calories: 410, protein: 5.2, carbohydrates: 48.0, fat: 22.0, sugar: 31.0, salt: 0.4, fibre: 1.2),
      ),
      RecipeModel(
        id: 'rec_3',
        title: 'Artisan Sourdough Country Loaf',
        category: 'Artisan Breads',
        prepTimeMins: 45,
        bakeTimeMins: 40,
        bakingTempC: 230,
        yieldServings: 1,
        sellingPrice: 4.80,
        ingredients: [
          RecipeIngredientItem(ingredientId: 'ing_2', name: 'French Strong Bread Flour (T65)', quantity: 450, unit: 'g', unitCost: 0.0011),
          RecipeIngredientItem(ingredientId: 'ing_1', name: 'Organic UK Plain Flour', quantity: 50, unit: 'g', unitCost: 0.0011),
          RecipeIngredientItem(ingredientId: 'ing_10', name: 'Cornish Fine Sea Salt', quantity: 10, unit: 'g', unitCost: 0.0021),
        ],
        instructions: [
          'Autolyse flour and water for 60 minutes.',
          'Incorporate mature sourdough starter and Cornish sea salt.',
          'Perform 4 sets of stretch and folds over 2.5 hours.',
          'Shape boule and cold ferment overnight at 4°C in proofing banneton.',
          'Score top and bake inside a preheated Dutch oven at 230°C for 20 mins lid on, 20 mins lid off for deep blistered crust.',
        ],
        notes: '36-hour slow fermentation provides exceptional open crumb and deep sourdough aroma.',
        allergens: ['Wheat', 'Gluten'],
        nutritionalInfo: const NutritionalInfo(calories: 215, protein: 7.8, carbohydrates: 42.0, fat: 1.1, sugar: 0.8, salt: 1.1, fibre: 2.9),
      ),
      RecipeModel(
        id: 'rec_4',
        title: 'French Butter Croissants (Pack of 4)',
        category: 'Pastries & Viennoiserie',
        prepTimeMins: 60,
        bakeTimeMins: 20,
        bakingTempC: 195,
        yieldServings: 4,
        sellingPrice: 8.50,
        ingredients: [
          RecipeIngredientItem(ingredientId: 'ing_2', name: 'French Strong Bread Flour (T65)', quantity: 300, unit: 'g', unitCost: 0.0011),
          RecipeIngredientItem(ingredientId: 'ing_3', name: 'Unsalted British Butter (82% Fat)', quantity: 180, unit: 'g', unitCost: 0.0064),
          RecipeIngredientItem(ingredientId: 'ing_4', name: 'Caster Sugar', quantity: 30, unit: 'g', unitCost: 0.0014),
          RecipeIngredientItem(ingredientId: 'ing_9', name: 'Active Dry Baker\'s Yeast', quantity: 7, unit: 'g', unitCost: 0.0063),
          RecipeIngredientItem(ingredientId: 'ing_12', name: 'Fresh Whole Farm Milk', quantity: 140, unit: 'ml', unitCost: 0.001),
          RecipeIngredientItem(ingredientId: 'ing_10', name: 'Cornish Fine Sea Salt', quantity: 6, unit: 'g', unitCost: 0.0021),
        ],
        instructions: [
          'Knead dough détrempe and chill for 4 hours.',
          'Encase butter block and perform 1 double turn and 1 single turn with 30 min chill intervals.',
          'Roll to 4mm thickness, cut triangles, and gently shape into croissants.',
          'Proof at 26°C for 2 hours until aerated and jiggly.',
          'Egg wash and bake at 195°C for 18-20 minutes until honeycomb golden crisp.',
        ],
        notes: '27 distinct laminated butter layers delivering ultra flaky texture.',
        allergens: ['Milk', 'Wheat', 'Gluten', 'Eggs'],
        nutritionalInfo: const NutritionalInfo(calories: 290, protein: 4.8, carbohydrates: 29.0, fat: 17.5, sugar: 4.5, salt: 0.6, fibre: 1.4),
      ),
    ];

    final sampleCustomers = [
      CustomerModel(
        id: 'cust_1',
        name: 'The Royal Crescent Cafe',
        email: 'orders@royalcrescentcafe.co.uk',
        phone: '+44 1225 443322',
        address: '14 Royal Crescent, Bath',
        postcode: 'BA1 2LS',
        totalOrders: 18,
        totalSpent: 940.50,
      ),
      CustomerModel(
        id: 'cust_2',
        name: 'James Sterling',
        email: 'james.sterling@gmail.com',
        phone: '+44 7911 123456',
        address: '88 High Street, Bristol',
        postcode: 'BS1 4HA',
        totalOrders: 6,
        totalSpent: 168.00,
      ),
      CustomerModel(
        id: 'cust_3',
        name: 'Clifton Artisan Deli',
        email: 'supplies@cliftondeli.co.uk',
        phone: '+44 117 9223344',
        address: '42 Princess Victoria St, Clifton',
        postcode: 'BS8 4BX',
        totalOrders: 12,
        totalSpent: 720.00,
      ),
    ];

    final sampleOrders = [
      OrderModel(
        id: 'ord_101',
        invoiceNumber: 'INV-2026-001',
        customerId: 'cust_1',
        customerName: 'The Royal Crescent Cafe',
        customerPhone: '+44 1225 443322',
        customerAddress: '14 Royal Crescent, Bath',
        customerPostcode: 'BA1 2LS',
        items: [
          OrderItem(recipeId: 'rec_2', recipeName: 'Classic Victoria Sponge Cake', quantity: 2, unitPrice: 24.00),
          OrderItem(recipeId: 'rec_1', recipeName: 'Signature Dark Chocolate Brownie', quantity: 12, unitPrice: 3.50),
        ],
        status: OrderStatus.completed,
        fulfillment: FulfillmentType.delivery,
        paymentStatus: PaymentStatus.paid,
        vatRate: 0.20,
        createdAt: now.subtract(const Duration(days: 4)),
        targetDate: now.subtract(const Duration(days: 4)),
        notes: 'Morning delivery before 10:00 AM.',
      ),
      OrderModel(
        id: 'ord_102',
        invoiceNumber: 'INV-2026-002',
        customerId: 'cust_3',
        customerName: 'Clifton Artisan Deli',
        customerPhone: '+44 117 9223344',
        customerAddress: '42 Princess Victoria St, Clifton',
        customerPostcode: 'BS8 4BX',
        items: [
          OrderItem(recipeId: 'rec_3', recipeName: 'Artisan Sourdough Country Loaf', quantity: 15, unitPrice: 4.80),
          OrderItem(recipeId: 'rec_4', recipeName: 'French Butter Croissants (Pack of 4)', quantity: 8, unitPrice: 8.50),
        ],
        status: OrderStatus.completed,
        fulfillment: FulfillmentType.delivery,
        paymentStatus: PaymentStatus.paid,
        vatRate: 0.20,
        createdAt: now.subtract(const Duration(days: 2)),
        targetDate: now.subtract(const Duration(days: 2)),
        notes: 'Wholesale delivery to deli counter.',
      ),
      OrderModel(
        id: 'ord_103',
        invoiceNumber: 'INV-2026-003',
        customerId: 'cust_2',
        customerName: 'James Sterling',
        customerPhone: '+44 7911 123456',
        customerAddress: '88 High Street, Bristol',
        customerPostcode: 'BS1 4HA',
        items: [
          OrderItem(recipeId: 'rec_1', recipeName: 'Signature Dark Chocolate Brownie', quantity: 6, unitPrice: 3.50),
          OrderItem(recipeId: 'rec_4', recipeName: 'French Butter Croissants (Pack of 4)', quantity: 2, unitPrice: 8.50),
        ],
        status: OrderStatus.completed,
        fulfillment: FulfillmentType.collection,
        paymentStatus: PaymentStatus.paid,
        vatRate: 0.20,
        createdAt: now.subtract(const Duration(days: 1)),
        targetDate: now.subtract(const Duration(days: 1)),
        notes: 'Customer collection at 4:30 PM.',
      ),
      OrderModel(
        id: 'ord_104',
        invoiceNumber: 'INV-2026-004',
        customerId: 'cust_1',
        customerName: 'The Royal Crescent Cafe',
        customerPhone: '+44 1225 443322',
        customerAddress: '14 Royal Crescent, Bath',
        customerPostcode: 'BA1 2LS',
        items: [
          OrderItem(recipeId: 'rec_2', recipeName: 'Classic Victoria Sponge Cake', quantity: 1, unitPrice: 24.00),
          OrderItem(recipeId: 'rec_3', recipeName: 'Artisan Sourdough Country Loaf', quantity: 10, unitPrice: 4.80),
          OrderItem(recipeId: 'rec_4', recipeName: 'French Butter Croissants (Pack of 4)', quantity: 6, unitPrice: 8.50),
        ],
        status: OrderStatus.baking,
        fulfillment: FulfillmentType.delivery,
        paymentStatus: PaymentStatus.paid,
        vatRate: 0.20,
        createdAt: now,
        targetDate: now.add(const Duration(hours: 3)),
        notes: 'Today\'s priority baking run.',
      ),
    ];

    // 3. Check Local Persistence for each collection independently
    final prefs = await SharedPreferences.getInstance();

    // 3a. Users
    final savedUserIds = prefs.getStringList('sp_ids_users') ?? [];
    final List<UserModel> localUsers = [];
    for (final id in savedUserIds) {
      final raw = prefs.getString('sp_users_$id');
      if (raw != null) localUsers.add(UserModel.fromMap(jsonDecode(raw)));
    }
    if (localUsers.isNotEmpty) {
      onUsersLoaded(localUsers);
    } else {
      onUsersLoaded(sampleUsers);
      for (final u in sampleUsers) {
        saveDocument('users', u.id, u.toMap());
      }
    }

    // 3b. Branding
    final savedBrandingIds = prefs.getStringList('sp_ids_branding') ?? [];
    BrandingModel? localBranding;
    if (savedBrandingIds.isNotEmpty) {
      final rawB = prefs.getString('sp_branding_${savedBrandingIds.first}');
      if (rawB != null) localBranding = BrandingModel.fromMap(jsonDecode(rawB));
    }
    if (localBranding != null) {
      onBrandingLoaded(localBranding);
    } else {
      onBrandingLoaded(sampleBranding);
      saveDocument('branding', 'main_branding', sampleBranding.toMap());
    }

    // 3c. Ingredients
    final savedIngIds = prefs.getStringList('sp_ids_ingredients') ?? [];
    final List<IngredientModel> localIngs = [];
    for (final id in savedIngIds) {
      final raw = prefs.getString('sp_ingredients_$id');
      if (raw != null) localIngs.add(IngredientModel.fromMap(jsonDecode(raw)));
    }
    if (localIngs.isNotEmpty) {
      onIngredientsLoaded(localIngs);
    } else {
      onIngredientsLoaded(sampleIngredients);
      for (final ing in sampleIngredients) {
        saveDocument('ingredients', ing.id, ing.toMap());
      }
    }

    // 3d. Recipes
    final savedRecIds = prefs.getStringList('sp_ids_recipes') ?? [];
    final List<RecipeModel> localRecs = [];
    for (final id in savedRecIds) {
      final raw = prefs.getString('sp_recipes_$id');
      if (raw != null) localRecs.add(RecipeModel.fromMap(jsonDecode(raw)));
    }
    if (localRecs.isNotEmpty) {
      onRecipesLoaded(localRecs);
    } else {
      onRecipesLoaded(sampleRecipes);
      for (final rec in sampleRecipes) {
        saveDocument('recipes', rec.id, rec.toMap());
      }
    }

    // 3e. Customers
    final savedCustIds = prefs.getStringList('sp_ids_customers') ?? [];
    final List<CustomerModel> localCusts = [];
    for (final id in savedCustIds) {
      final raw = prefs.getString('sp_customers_$id');
      if (raw != null) localCusts.add(CustomerModel.fromMap(jsonDecode(raw)));
    }
    if (localCusts.isNotEmpty) {
      onCustomersLoaded(localCusts);
    } else {
      onCustomersLoaded(sampleCustomers);
      for (final c in sampleCustomers) {
        saveDocument('customers', c.id, c.toMap());
      }
    }

    // 3f. Orders
    final savedOrderIds = prefs.getStringList('sp_ids_orders') ?? [];
    final List<OrderModel> localOrders = [];
    for (final id in savedOrderIds) {
      final raw = prefs.getString('sp_orders_$id');
      if (raw != null) localOrders.add(OrderModel.fromMap(jsonDecode(raw)));
    }
    if (localOrders.isNotEmpty) {
      onOrdersLoaded(localOrders);
    } else {
      onOrdersLoaded(sampleOrders);
      for (final o in sampleOrders) {
        saveDocument('orders', o.id, o.toMap());
      }
    }

    // Background cloud sync
    _syncInitialSeedToFirebase(
      sampleUsers,
      sampleBranding,
      sampleIngredients,
      sampleRecipes,
      sampleCustomers,
      sampleOrders,
    );
  }

  Future<void> _syncInitialSeedToFirebase(
    List<UserModel> users,
    BrandingModel branding,
    List<IngredientModel> ingredients,
    List<RecipeModel> recipes,
    List<CustomerModel> customers,
    List<OrderModel> orders,
  ) async {
    try {
      for (final u in users) {
        await _firestore.collection('users').doc(u.id).set(u.toMap(), SetOptions(merge: true));
      }
      await _firestore.collection('branding').doc('default').set(branding.toMap(), SetOptions(merge: true));
      for (final ing in ingredients) {
        await _firestore.collection('ingredients').doc(ing.id).set(ing.toMap(), SetOptions(merge: true));
      }
      for (final r in recipes) {
        await _firestore.collection('recipes').doc(r.id).set(r.toMap(), SetOptions(merge: true));
      }
      for (final c in customers) {
        await _firestore.collection('customers').doc(c.id).set(c.toMap(), SetOptions(merge: true));
      }
      for (final o in orders) {
        await _firestore.collection('orders').doc(o.id).set(o.toMap(), SetOptions(merge: true));
      }
      debugPrint("Initial seed data successfully synced to Firebase Firestore!");
    } catch (e) {
      debugPrint("Background Firebase initial seed sync note: $e");
    }
  }
}
