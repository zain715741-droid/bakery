// ignore_for_file: curly_braces_in_flow_control_structures, unused_local_variable, unused_field

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      debugPrint("Local save note: $e");
    }

    // 2. Sync live to Firebase Cloud Firestore
    try {
      await _firestore.collection(collectionName).doc(docId).set(data, SetOptions(merge: true));
      debugPrint("Synced document $docId to Firebase Firestore collection '$collectionName'");
    } catch (e) {
      debugPrint("Firebase sync note (queued offline): $e");
      await _queueForSync(collectionName, 'SAVE', docId, data);
    }
  }

  Future<void> deleteDocument(String collectionName, String docId) async {
    try {
      final db = await database;
      if (db != null) {
        await db.delete(collectionName, where: 'id = ?', whereArgs: [docId]);
      }
    } catch (e) {
      debugPrint("Local delete note: $e");
    }

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

  // --- Seed Initial Bakery Demo Data (Cloud First, Local Fallback) ---
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
      final usersSnap = await _firestore.collection('users').get().timeout(const Duration(seconds: 4));
      if (usersSnap.docs.isNotEmpty) {
        final users = usersSnap.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
        onUsersLoaded(users);
        loadedFromCloud = true;
      }

      final brandingSnap = await _firestore.collection('branding').get().timeout(const Duration(seconds: 4));
      if (brandingSnap.docs.isNotEmpty) {
        final branding = BrandingModel.fromMap(brandingSnap.docs.first.data());
        onBrandingLoaded(branding);
      }

      final ingSnap = await _firestore.collection('ingredients').get().timeout(const Duration(seconds: 4));
      if (ingSnap.docs.isNotEmpty) {
        final ingredients = ingSnap.docs.map((doc) => IngredientModel.fromMap(doc.data())).toList();
        onIngredientsLoaded(ingredients);
      }

      final recipeSnap = await _firestore.collection('recipes').get().timeout(const Duration(seconds: 4));
      if (recipeSnap.docs.isNotEmpty) {
        final recipes = recipeSnap.docs.map((doc) => RecipeModel.fromMap(doc.data())).toList();
        onRecipesLoaded(recipes);
      }

      final custSnap = await _firestore.collection('customers').get().timeout(const Duration(seconds: 4));
      if (custSnap.docs.isNotEmpty) {
        final customers = custSnap.docs.map((doc) => CustomerModel.fromMap(doc.data())).toList();
        onCustomersLoaded(customers);
      }

      final orderSnap = await _firestore.collection('orders').get().timeout(const Duration(seconds: 4));
      if (orderSnap.docs.isNotEmpty) {
        final orders = orderSnap.docs.map((doc) => OrderModel.fromMap(doc.data())).toList();
        onOrdersLoaded(orders);
      }
    } catch (e) {
      debugPrint("Firebase cloud initial load note (falling back to local seed): $e");
    }

    if (loadedFromCloud) return;

    // Fallback: Seed local sample data & push initial seed to Firebase Firestore
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
          'Preheat oven to 175°C and grease a 9x13 inch baking pan.',
          'Melt dark chocolate and unsalted butter together in a heatproof bowl over simmering water.',
          'Whisk sugar and eggs together in a separate bowl until pale and fluffy.',
          'Fold melted chocolate mixture into the egg mixture gently.',
          'Sift in the organic plain flour and fold until just combined.',
          'Pour into lined pan and bake for 30-35 minutes until fudgy in the center.',
          'Allow to cool completely before slicing into 12 squares.',
        ],
        notes: 'Best served warm with a scoop of vanilla bean ice cream.',
        allergens: ['Milk', 'Eggs', 'Wheat', 'Gluten', 'Soy'],
        nutritionalInfo: const NutritionalInfo(
          calories: 340,
          protein: 4.5,
          carbohydrates: 38.0,
          fat: 19.5,
          sugar: 26.0,
          salt: 0.2,
          fibre: 2.1,
        ),
      ),
      RecipeModel(
        id: 'rec_2',
        title: 'Classic Victoria Sponge Cake',
        category: 'Cakes',
        prepTimeMins: 25,
        bakeTimeMins: 25,
        bakingTempC: 180,
        yieldServings: 8,
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
          'Preheat oven to 180°C and line two 20cm sandwich tins.',
          'Cream together butter and caster sugar until soft and pale.',
          'Beat in eggs one at a time, adding a spoon of flour if it curdles.',
          'Fold in remaining flour and vanilla extract.',
          'Divide evenly between tins and bake for 20-25 minutes.',
          'Sandwich with raspberry jam and whipped cream. Dust top with icing sugar.',
        ],
        notes: 'Quintessential British afternoon tea center-piece.',
        allergens: ['Milk', 'Eggs', 'Wheat', 'Gluten'],
        nutritionalInfo: const NutritionalInfo(
          calories: 410,
          protein: 5.2,
          carbohydrates: 48.0,
          fat: 22.0,
          sugar: 31.0,
          salt: 0.4,
          fibre: 1.2,
        ),
      ),
    ];
    onRecipesLoaded(sampleRecipes);

    final sampleCustomers = [
      CustomerModel(
        id: 'cust_1',
        name: 'The Georgian Tea Rooms',
        email: 'orders@georgiantearooms.co.uk',
        phone: '+44 1225 443322',
        address: '14 Royal Crescent, Bath',
        postcode: 'BA1 2LS',
        totalOrders: 14,
        totalSpent: 620.50,
      ),
      CustomerModel(
        id: 'cust_2',
        name: 'James Sterling',
        email: 'james.sterling@gmail.com',
        phone: '+44 7911 123456',
        address: '88 High Street, Bristol',
        postcode: 'BS1 4HA',
        totalOrders: 3,
        totalSpent: 84.00,
      ),
    ];
    onCustomersLoaded(sampleCustomers);

    final sampleOrders = [
      OrderModel(
        id: 'ord_101',
        invoiceNumber: 'INV-2026-001',
        customerId: 'cust_1',
        customerName: 'The Georgian Tea Rooms',
        customerPhone: '+44 1225 443322',
        customerAddress: '14 Royal Crescent, Bath',
        customerPostcode: 'BA1 2LS',
        items: [
          OrderItem(
            recipeId: 'rec_2',
            recipeName: 'Classic Victoria Sponge Cake',
            quantity: 2,
            unitPrice: 22.00,
          ),
          OrderItem(
            recipeId: 'rec_1',
            recipeName: 'Signature Dark Chocolate Brownie',
            quantity: 6,
            unitPrice: 3.50,
          ),
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
          OrderItem(
            recipeId: 'rec_1',
            recipeName: 'Signature Dark Chocolate Brownie',
            quantity: 24,
            unitPrice: 3.00,
          ),
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

    // Sync seed data to Firebase Cloud Firestore in background
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
