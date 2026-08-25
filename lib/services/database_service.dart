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
import '../data/initial_bakery_data.dart';

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

  // --- Clean Real Data Initialization (Zero Dummy Data, Pure Original) ---
  Future<void> seedInitialDataIfEmpty({
    required Function(BrandingModel) onBrandingLoaded,
    required Function(List<IngredientModel>) onIngredientsLoaded,
    required Function(List<RecipeModel>) onRecipesLoaded,
    required Function(List<CustomerModel>) onCustomersLoaded,
    required Function(List<OrderModel>) onOrdersLoaded,
    required Function(List<UserModel>) onUsersLoaded,
  }) async {
    await database;

    // Purge any previously seeded dummy items from local storage
    await _purgeLingeringDummyData();

    bool usersLoaded = false;
    bool brandingLoaded = false;
    bool ingredientsLoaded = false;
    bool recipesLoaded = false;
    bool customersLoaded = false;
    bool ordersLoaded = false;

    // 1. Attempt fetching live data from Firebase Cloud Firestore
    try {
      final usersSnap = await _firestore.collection('users').get().timeout(const Duration(seconds: 3));
      if (usersSnap.docs.isNotEmpty) {
        final users = usersSnap.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .where((u) => !_isDummyId(u.id))
            .toList();
        if (users.isNotEmpty) {
          onUsersLoaded(users);
          usersLoaded = true;
        }
      }

      final brandingSnap = await _firestore.collection('branding').get().timeout(const Duration(seconds: 3));
      if (brandingSnap.docs.isNotEmpty) {
        final branding = BrandingModel.fromMap(brandingSnap.docs.first.data());
        onBrandingLoaded(branding);
        brandingLoaded = true;
      }

      final ingSnap = await _firestore.collection('ingredients').get().timeout(const Duration(seconds: 3));
      if (ingSnap.docs.isNotEmpty) {
        final ingredients = ingSnap.docs
            .map((doc) => IngredientModel.fromMap(doc.data()))
            .where((i) => !_isDummyId(i.id))
            .toList();
        onIngredientsLoaded(ingredients);
        ingredientsLoaded = true;
      }

      final recipeSnap = await _firestore.collection('recipes').get().timeout(const Duration(seconds: 3));
      if (recipeSnap.docs.isNotEmpty) {
        final recipes = recipeSnap.docs
            .map((doc) => RecipeModel.fromMap(doc.data()))
            .where((r) => !_isDummyId(r.id))
            .toList();
        onRecipesLoaded(recipes);
        recipesLoaded = true;
      }

      final custSnap = await _firestore.collection('customers').get().timeout(const Duration(seconds: 3));
      if (custSnap.docs.isNotEmpty) {
        final customers = custSnap.docs
            .map((doc) => CustomerModel.fromMap(doc.data()))
            .where((c) => !_isDummyId(c.id))
            .toList();
        onCustomersLoaded(customers);
        customersLoaded = true;
      }

      final orderSnap = await _firestore.collection('orders').get().timeout(const Duration(seconds: 3));
      if (orderSnap.docs.isNotEmpty) {
        final orders = orderSnap.docs
            .map((doc) => OrderModel.fromMap(doc.data()))
            .where((o) => !_isDummyId(o.id))
            .toList();
        onOrdersLoaded(orders);
        ordersLoaded = true;
      }
    } catch (e) {
      debugPrint("Firebase cloud load note: $e");
    }

    // 2. Load from Local Persistence for any collections not loaded from Cloud
    final prefs = await SharedPreferences.getInstance();

    // 2a. Users
    if (!usersLoaded) {
      final savedUserIds = prefs.getStringList('sp_ids_users') ?? [];
      final List<UserModel> localUsers = [];
      for (final id in savedUserIds) {
        if (_isDummyId(id)) continue;
        final raw = prefs.getString('sp_users_$id');
        if (raw != null) localUsers.add(UserModel.fromMap(jsonDecode(raw)));
      }
      onUsersLoaded(localUsers);
    }

    // 2b. Branding
    if (!brandingLoaded) {
      final savedBrandingIds = prefs.getStringList('sp_ids_branding') ?? [];
      BrandingModel? localBranding;
      if (savedBrandingIds.isNotEmpty) {
        final rawB = prefs.getString('sp_branding_${savedBrandingIds.first}');
        if (rawB != null) localBranding = BrandingModel.fromMap(jsonDecode(rawB));
      }
      onBrandingLoaded(localBranding ?? BrandingModel());
    }

    // 2c. Ingredients
    final List<IngredientModel> localIngs = [];
    if (!ingredientsLoaded) {
      final savedIngIds = prefs.getStringList('sp_ids_ingredients') ?? [];
      for (final id in savedIngIds) {
        if (_isDummyId(id)) continue;
        final raw = prefs.getString('sp_ingredients_$id');
        if (raw != null) localIngs.add(IngredientModel.fromMap(jsonDecode(raw)));
      }
    }
    if (localIngs.isEmpty && !ingredientsLoaded) {
      final defaultIngs = InitialBakeryData.defaultIngredients;
      onIngredientsLoaded(defaultIngs);
      for (final ing in defaultIngs) {
        await saveDocument('ingredients', ing.id, ing.toMap());
      }
    } else if (!ingredientsLoaded) {
      onIngredientsLoaded(localIngs);
    }

    // 2d. Recipes / Menu Items
    final List<RecipeModel> localRecs = [];
    if (!recipesLoaded) {
      final savedRecIds = prefs.getStringList('sp_ids_recipes') ?? [];
      for (final id in savedRecIds) {
        if (_isDummyId(id)) continue;
        final raw = prefs.getString('sp_recipes_$id');
        if (raw != null) localRecs.add(RecipeModel.fromMap(jsonDecode(raw)));
      }
    }
    if (localRecs.isEmpty && !recipesLoaded) {
      final defaultRecs = InitialBakeryData.defaultRecipes;
      onRecipesLoaded(defaultRecs);
      for (final rec in defaultRecs) {
        await saveDocument('recipes', rec.id, rec.toMap());
      }
    } else if (!recipesLoaded) {
      onRecipesLoaded(localRecs);
    }

    // 2e. Customers
    final List<CustomerModel> localCusts = [];
    if (!customersLoaded) {
      final savedCustIds = prefs.getStringList('sp_ids_customers') ?? [];
      for (final id in savedCustIds) {
        if (_isDummyId(id)) continue;
        final raw = prefs.getString('sp_customers_$id');
        if (raw != null) localCusts.add(CustomerModel.fromMap(jsonDecode(raw)));
      }
    }
    if (localCusts.isEmpty && !customersLoaded) {
      final defaultCusts = InitialBakeryData.defaultCustomers;
      onCustomersLoaded(defaultCusts);
      for (final cust in defaultCusts) {
        await saveDocument('customers', cust.id, cust.toMap());
      }
    } else if (!customersLoaded) {
      onCustomersLoaded(localCusts);
    }

    // 2f. Orders
    if (!ordersLoaded) {
      final savedOrderIds = prefs.getStringList('sp_ids_orders') ?? [];
      final List<OrderModel> localOrders = [];
      for (final id in savedOrderIds) {
        if (_isDummyId(id)) continue;
        final raw = prefs.getString('sp_orders_$id');
        if (raw != null) localOrders.add(OrderModel.fromMap(jsonDecode(raw)));
      }
      onOrdersLoaded(localOrders);
    }
  }

  static const _dummyIdSet = {
    'cust_1', 'cust_2', 'cust_3',
    'ord_101', 'ord_102', 'ord_103', 'ord_104',
    'rec_1', 'rec_2', 'rec_3', 'rec_4',
    'ing_1', 'ing_2', 'ing_3', 'ing_4', 'ing_5', 'ing_6',
    'ing_7', 'ing_8', 'ing_9', 'ing_10', 'ing_11', 'ing_12',
  };

  bool _isDummyId(String id) {
    return _dummyIdSet.contains(id);
  }

  Future<void> _purgeLingeringDummyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const collections = ['users', 'ingredients', 'recipes', 'customers', 'orders'];

      for (final col in collections) {
        final ids = prefs.getStringList('sp_ids_$col') ?? [];
        final cleanedIds = <String>[];
        for (final id in ids) {
          if (_isDummyId(id)) {
            await prefs.remove('sp_${col}_$id');
          } else {
            cleanedIds.add(id);
          }
        }
        await prefs.setStringList('sp_ids_$col', cleanedIds);
      }

      final db = await database;
      if (db != null) {
        for (final dummyId in _dummyIdSet) {
          for (final col in ['ingredients', 'recipes', 'customers', 'orders']) {
            await db.delete(col, where: 'id = ?', whereArgs: [dummyId]);
          }
        }
      }
    } catch (e) {
      debugPrint("Dummy data purge note: $e");
    }
  }
}
