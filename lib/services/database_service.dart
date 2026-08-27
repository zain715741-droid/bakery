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

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint("Firebase Firestore not yet initialized or error: $e");
      return null;
    }
  }

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
      final fs = _firestore;
      if (fs != null) {
        await fs.collection(collectionName).doc(docId).set(data, SetOptions(merge: true));
        debugPrint("Synced document $docId to Firebase Firestore collection '$collectionName'");
      }
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
      final fs = _firestore;
      if (fs != null) {
        await fs.collection(collectionName).doc(docId).delete();
      }
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
      final fs = _firestore;
      if (db == null || fs == null) return;

      final pendingRows = await db.query('sync_queue', orderBy: 'id ASC');
      for (final row in pendingRows) {
        final id = row['id'] as int;
        final collection = row['collection'] as String;
        final action = row['action'] as String;
        final docId = row['documentId'] as String;
        final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;

        try {
          if (action == 'SAVE') {
            await fs.collection(collection).doc(docId).set(payload, SetOptions(merge: true));
          } else if (action == 'DELETE') {
            await fs.collection(collection).doc(docId).delete();
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

  Future<UserModel?> fetchUserByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final fs = _firestore;
    if (fs != null) {
      try {
        final querySnap = await fs.collection('users').get().timeout(const Duration(seconds: 6));
        for (final doc in querySnap.docs) {
          final data = doc.data();
          if ((data['email'] as String?)?.toLowerCase() == cleanEmail) {
            return UserModel.fromMap(data);
          }
        }
      } catch (e) {
        debugPrint("fetchUserByEmail error: $e");
      }
    }
    return null;
  }

  Future<UserModel?> fetchUserById(String docId) async {
    final fs = _firestore;
    if (fs != null) {
      try {
        final docSnap = await fs.collection('users').doc(docId).get().timeout(const Duration(seconds: 6));
        if (docSnap.exists && docSnap.data() != null) {
          return UserModel.fromMap(docSnap.data()!);
        }
      } catch (e) {
        debugPrint("fetchUserById error: $e");
      }
    }
    return null;
  }

  // --- Real-time Live Firestore Streams ---

  Stream<List<UserModel>> get usersStream {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    try {
      return fs.collection('users').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
      }).handleError((e) {
        debugPrint("Error in usersStream: $e");
      });
    } catch (e) {
      return const Stream.empty();
    }
  }

  Stream<List<RecipeModel>> get recipesStream {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    try {
      return fs.collection('recipes').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => RecipeModel.fromMap(doc.data())).toList();
      }).handleError((e) {
        debugPrint("Error in recipesStream: $e");
      });
    } catch (e) {
      return const Stream.empty();
    }
  }

  Stream<List<OrderModel>> get ordersStream {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    try {
      return fs.collection('orders').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => OrderModel.fromMap(doc.data())).toList();
      }).handleError((e) {
        debugPrint("Error in ordersStream: $e");
      });
    } catch (e) {
      return const Stream.empty();
    }
  }

  Stream<List<IngredientModel>> get ingredientsStream {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    try {
      return fs.collection('ingredients').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => IngredientModel.fromMap(doc.data())).toList();
      }).handleError((e) {
        debugPrint("Error in ingredientsStream: $e");
      });
    } catch (e) {
      return const Stream.empty();
    }
  }

  Stream<List<CustomerModel>> get customersStream {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    try {
      return fs.collection('customers').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => CustomerModel.fromMap(doc.data())).toList();
      }).handleError((e) {
        debugPrint("Error in customersStream: $e");
      });
    } catch (e) {
      return const Stream.empty();
    }
  }

  Stream<BrandingModel?> get brandingStream {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    try {
      return fs.collection('branding').snapshots().map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          return BrandingModel.fromMap(snapshot.docs.first.data());
        }
        return null;
      }).handleError((e) {
        debugPrint("Error in brandingStream: $e");
      });
    } catch (e) {
      return const Stream.empty();
    }
  }

  // --- Clean Real Data Initialization (Pure Database Driven) ---
  Future<void> seedInitialDataIfEmpty({
    required Function(BrandingModel) onBrandingLoaded,
    required Function(List<IngredientModel>) onIngredientsLoaded,
    required Function(List<RecipeModel>) onRecipesLoaded,
    required Function(List<CustomerModel>) onCustomersLoaded,
    required Function(List<OrderModel>) onOrdersLoaded,
    required Function(List<UserModel>) onUsersLoaded,
  }) async {
    await database;

    bool usersLoaded = false;
    bool brandingLoaded = false;
    bool ingredientsLoaded = false;
    bool recipesLoaded = false;
    bool customersLoaded = false;
    bool ordersLoaded = false;

    // 1. Attempt fetching live data from Firebase Cloud Firestore
    final fs = _firestore;
    if (fs != null) {
      try {
        final usersSnap = await fs.collection('users').get().timeout(const Duration(seconds: 4));
        if (usersSnap.docs.isNotEmpty) {
          final users = usersSnap.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList();
          if (users.isNotEmpty) {
            onUsersLoaded(users);
            usersLoaded = true;
          }
        }

        final brandingSnap = await fs.collection('branding').get().timeout(const Duration(seconds: 4));
        if (brandingSnap.docs.isNotEmpty) {
          final branding = BrandingModel.fromMap(brandingSnap.docs.first.data());
          onBrandingLoaded(branding);
          brandingLoaded = true;
        }

        final ingSnap = await fs.collection('ingredients').get().timeout(const Duration(seconds: 4));
        if (ingSnap.docs.isNotEmpty) {
          final ingredients = ingSnap.docs
              .map((doc) => IngredientModel.fromMap(doc.data()))
              .toList();
          onIngredientsLoaded(ingredients);
          ingredientsLoaded = true;
        } else {
          // If Firestore collection is empty, seed initial ingredients to Firestore
          final defaultIngs = InitialBakeryData.defaultIngredients;
          onIngredientsLoaded(defaultIngs);
          ingredientsLoaded = true;
          for (final ing in defaultIngs) {
            await saveDocument('ingredients', ing.id, ing.toMap());
          }
        }

        final recipeSnap = await fs.collection('recipes').get().timeout(const Duration(seconds: 4));
        if (recipeSnap.docs.isNotEmpty) {
          final recipes = recipeSnap.docs
              .map((doc) => RecipeModel.fromMap(doc.data()))
              .toList();
          onRecipesLoaded(recipes);
          recipesLoaded = true;
        } else {
          // If Firestore collection is empty, seed initial recipes to Firestore
          final defaultRecs = InitialBakeryData.defaultRecipes;
          onRecipesLoaded(defaultRecs);
          recipesLoaded = true;
          for (final rec in defaultRecs) {
            await saveDocument('recipes', rec.id, rec.toMap());
          }
        }

        final custSnap = await fs.collection('customers').get().timeout(const Duration(seconds: 4));
        if (custSnap.docs.isNotEmpty) {
          final customers = custSnap.docs
              .map((doc) => CustomerModel.fromMap(doc.data()))
              .toList();
          onCustomersLoaded(customers);
          customersLoaded = true;
        } else {
          final defaultCusts = InitialBakeryData.defaultCustomers;
          onCustomersLoaded(defaultCusts);
          customersLoaded = true;
          for (final cust in defaultCusts) {
            await saveDocument('customers', cust.id, cust.toMap());
          }
        }

        final orderSnap = await fs.collection('orders').get().timeout(const Duration(seconds: 4));
        if (orderSnap.docs.isNotEmpty) {
          final orders = orderSnap.docs
              .map((doc) => OrderModel.fromMap(doc.data()))
              .toList();
          onOrdersLoaded(orders);
          ordersLoaded = true;
        }
      } catch (e) {
        debugPrint("Firebase cloud load note: $e");
      }
    }

    // 2. Fallback to Local Storage only if completely offline / Firestore failed
    final prefs = await SharedPreferences.getInstance();

    if (!usersLoaded) {
      final savedUserIds = prefs.getStringList('sp_ids_users') ?? [];
      final List<UserModel> localUsers = [];
      for (final id in savedUserIds) {
        final raw = prefs.getString('sp_users_$id');
        if (raw != null) localUsers.add(UserModel.fromMap(jsonDecode(raw)));
      }
      onUsersLoaded(localUsers);
    }

    if (!brandingLoaded) {
      final savedBrandingIds = prefs.getStringList('sp_ids_branding') ?? [];
      BrandingModel? localBranding;
      if (savedBrandingIds.isNotEmpty) {
        final rawB = prefs.getString('sp_branding_${savedBrandingIds.first}');
        if (rawB != null) localBranding = BrandingModel.fromMap(jsonDecode(rawB));
      }
      onBrandingLoaded(localBranding ?? BrandingModel());
    }

    if (!ingredientsLoaded) {
      final savedIngIds = prefs.getStringList('sp_ids_ingredients') ?? [];
      final List<IngredientModel> localIngs = [];
      for (final id in savedIngIds) {
        final raw = prefs.getString('sp_ingredients_$id');
        if (raw != null) localIngs.add(IngredientModel.fromMap(jsonDecode(raw)));
      }
      onIngredientsLoaded(localIngs);
    }

    if (!recipesLoaded) {
      final savedRecIds = prefs.getStringList('sp_ids_recipes') ?? [];
      final List<RecipeModel> localRecs = [];
      for (final id in savedRecIds) {
        final raw = prefs.getString('sp_recipes_$id');
        if (raw != null) localRecs.add(RecipeModel.fromMap(jsonDecode(raw)));
      }
      onRecipesLoaded(localRecs);
    }

    if (!customersLoaded) {
      final savedCustIds = prefs.getStringList('sp_ids_customers') ?? [];
      final List<CustomerModel> localCusts = [];
      for (final id in savedCustIds) {
        final raw = prefs.getString('sp_customers_$id');
        if (raw != null) localCusts.add(CustomerModel.fromMap(jsonDecode(raw)));
      }
      onCustomersLoaded(localCusts);
    }

    if (!ordersLoaded) {
      final savedOrderIds = prefs.getStringList('sp_ids_orders') ?? [];
      final List<OrderModel> localOrders = [];
      for (final id in savedOrderIds) {
        final raw = prefs.getString('sp_orders_$id');
        if (raw != null) localOrders.add(OrderModel.fromMap(jsonDecode(raw)));
      }
      onOrdersLoaded(localOrders);
    }
  }
}
