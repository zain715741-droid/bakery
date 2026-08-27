import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../models/user_model.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  static const String _sessionKey = 'logged_in_user_id';

  UserModel? _currentUser;
  List<UserModel> _allUsers = [];

  UserModel? get currentUser => _currentUser;
  List<UserModel> get allUsers => List.unmodifiable(_allUsers);

  List<UserModel> get approvedUsers => _allUsers.where((u) => u.isApproved).toList();
  List<UserModel> get pendingUsers => _allUsers.where((u) => !u.isApproved).toList();
  int get pendingCount => pendingUsers.length;

  bool get isAuthenticated => _currentUser != null;

  UserRole get currentRole => _currentUser?.role ?? UserRole.owner;
  UserPermissions get permissions => _currentUser?.permissions ?? UserPermissions.forRole(UserRole.owner);

  bool get isOwner => currentRole == UserRole.owner;
  bool get isManager => currentRole == UserRole.manager;
  bool get isStaff => currentRole == UserRole.staff;

  void setUsers(List<UserModel> users) {
    _allUsers = users;
    notifyListeners();
  }

  void addOrUpdateUserLocally(UserModel user) {
    final idx = _allUsers.indexWhere((u) => u.id == user.id || u.email.toLowerCase() == user.email.toLowerCase());
    if (idx != -1) {
      _allUsers[idx] = user;
    } else {
      _allUsers.add(user);
    }
    notifyListeners();
  }

  Future<void> restoreSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString(_sessionKey);
      if (savedUserId != null && savedUserId.isNotEmpty) {
        final matching = _allUsers.where((u) => u.id == savedUserId && u.isApproved);
        if (matching.isNotEmpty) {
          _currentUser = matching.first;
          notifyListeners();
          return;
        }

        // Fallback: check directly from Firestore
        final cloudUser = await DatabaseService.instance.fetchUserById(savedUserId);
        if (cloudUser != null && cloudUser.isApproved) {
          _currentUser = cloudUser;
          addOrUpdateUserLocally(cloudUser);
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint("Error restoring session: $e");
    }
  }

  void switchRole(UserRole role) {
    final matchingUsers = _allUsers.where((u) => u.role == role && u.isApproved).toList();
    if (matchingUsers.isNotEmpty) {
      loginAsUser(matchingUsers.first);
    }
  }

  Future<void> loginAsUser(UserModel user) async {
    _currentUser = user;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, user.id);
    } catch (e) {
      debugPrint("Error saving session: $e");
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } catch (e) {
      debugPrint("Error clearing session: $e");
    }
  }

  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    required UserRole requestedRole,
    String? note,
  }) async {
    // 1. Create in Firebase Authentication Console
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      if (cred.user != null) {
        await cred.user!.updateDisplayName(name.trim());
      }
    } catch (e) {
      debugPrint("Firebase Auth registration note: $e");
    }

    final newUser = UserModel(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim().toLowerCase(),
      password: password,
      role: requestedRole,
      isApproved: false, // Must be approved by owner
      createdAt: DateTime.now(),
      note: note?.trim(),
    );

    _allUsers.add(newUser);
    notifyListeners();

    await DatabaseService.instance.saveDocument('users', newUser.id, newUser.toMap());
  }

  Future<void> approveUser(String userId, {UserRole? assignedRole}) async {
    final index = _allUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final updatedUser = _allUsers[index].copyWith(
        isApproved: true,
        role: assignedRole ?? _allUsers[index].role,
      );
      _allUsers[index] = updatedUser;
      notifyListeners();

      await DatabaseService.instance.saveDocument('users', updatedUser.id, updatedUser.toMap());
    }
  }

  Future<void> rejectUser(String userId) async {
    _allUsers.removeWhere((u) => u.id == userId);
    notifyListeners();

    await DatabaseService.instance.deleteDocument('users', userId);
  }

  Future<void> addUser(UserModel user) async {
    // 1. Create in Firebase Authentication Console
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: user.email.trim().toLowerCase(),
        password: user.password ?? 'bakery123',
      );
      if (cred.user != null) {
        await cred.user!.updateDisplayName(user.name.trim());
      }
    } catch (e) {
      debugPrint("Firebase Auth user creation note: $e");
    }

    _allUsers.add(user);
    notifyListeners();

    await DatabaseService.instance.saveDocument('users', user.id, user.toMap());
  }

  Future<void> updateUserRole(String userId, UserRole newRole) async {
    final index = _allUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _allUsers[index] = _allUsers[index].copyWith(role: newRole);
      if (_currentUser?.id == userId) {
        _currentUser = _allUsers[index];
      }
      notifyListeners();

      await DatabaseService.instance.saveDocument('users', _allUsers[index].id, _allUsers[index].toMap());
    }
  }

  Future<void> updateOwnerProfileName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    if (_currentUser != null && _currentUser!.role == UserRole.owner) {
      _currentUser = _currentUser!.copyWith(name: trimmed);
    }

    for (int i = 0; i < _allUsers.length; i++) {
      if (_allUsers[i].role == UserRole.owner) {
        _allUsers[i] = _allUsers[i].copyWith(name: trimmed);
        await DatabaseService.instance.saveDocument('users', _allUsers[i].id, _allUsers[i].toMap());
      }
    }

    notifyListeners();

    try {
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.currentUser!.updateDisplayName(trimmed);
      }
    } catch (e) {
      debugPrint("Firebase Auth display name update note: $e");
    }
  }

  Future<void> updateUserName(String userId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final index = _allUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _allUsers[index] = _allUsers[index].copyWith(name: trimmed);
      if (_currentUser?.id == userId) {
        _currentUser = _allUsers[index];
      }
      notifyListeners();
      await DatabaseService.instance.saveDocument('users', _allUsers[index].id, _allUsers[index].toMap());
    }
  }

  Future<void> deleteUser(String userId) async {
    _allUsers.removeWhere((u) => u.id == userId);
    if (_currentUser?.id == userId) {
      _currentUser = null;
    }
    notifyListeners();
    await DatabaseService.instance.deleteDocument('users', userId);
  }

  Future<void> syncUsersFromCloud() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').get().timeout(const Duration(seconds: 4));
      final List<UserModel> cloudUsers = [];
      for (final doc in snap.docs) {
        cloudUsers.add(UserModel.fromMap(doc.data()));
      }

      if (cloudUsers.isNotEmpty) {
        _allUsers = cloudUsers;
        notifyListeners();

        // Update local SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final currentLocalIds = prefs.getStringList('sp_ids_users') ?? [];
        for (final oldId in currentLocalIds) {
          await prefs.remove('sp_users_$oldId');
        }
        final newIds = cloudUsers.map((u) => u.id).toList();
        await prefs.setStringList('sp_ids_users', newIds);
        for (final u in cloudUsers) {
          await prefs.setString('sp_users_${u.id}', jsonEncode(u.toMap()));
        }
      }
    } catch (e) {
      debugPrint("Error syncing users from cloud: $e");
    }
  }
}
