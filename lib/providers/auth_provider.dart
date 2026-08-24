import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  UserRole get currentRole => _currentUser?.role ?? UserRole.staff;
  UserPermissions get permissions => _currentUser?.permissions ?? UserPermissions.forRole(UserRole.staff);

  bool get isOwner => currentRole == UserRole.owner;
  bool get isManager => currentRole == UserRole.manager;
  bool get isStaff => currentRole == UserRole.staff;

  void setUsers(List<UserModel> users) {
    _allUsers = users;
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
      }
    } catch (e) {
      debugPrint("Error restoring session: $e");
    }
  }

  void switchRole(UserRole role) {
    final matchingUser = _allUsers.firstWhere(
      (u) => u.role == role && u.isApproved,
      orElse: () => UserModel(
        id: 'u_${role.name}',
        email: '${role.name}@bakery.co.uk',
        name: '${role.displayName} User',
        role: role,
        isApproved: true,
      ),
    );
    loginAsUser(matchingUser);
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
}
