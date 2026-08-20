import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  List<UserModel> _allUsers = [];

  UserModel? get currentUser => _currentUser;
  List<UserModel> get allUsers => List.unmodifiable(_allUsers);

  bool get isAuthenticated => _currentUser != null;

  UserRole get currentRole => _currentUser?.role ?? UserRole.staff;
  UserPermissions get permissions => _currentUser?.permissions ?? UserPermissions.forRole(UserRole.staff);

  bool get isOwner => currentRole == UserRole.owner;
  bool get isManager => currentRole == UserRole.manager;
  bool get isStaff => currentRole == UserRole.staff;

  void setUsers(List<UserModel> users) {
    _allUsers = users;
    if (_currentUser == null && _allUsers.isNotEmpty) {
      _currentUser = _allUsers.firstWhere(
        (u) => u.role == UserRole.owner,
        orElse: () => _allUsers.first,
      );
    }
    notifyListeners();
  }

  void switchRole(UserRole role) {
    final matchingUser = _allUsers.firstWhere(
      (u) => u.role == role,
      orElse: () => UserModel(
        id: 'u_${role.name}',
        email: '${role.name}@bakery.co.uk',
        name: '${role.displayName} User',
        role: role,
      ),
    );
    _currentUser = matchingUser;
    notifyListeners();
  }

  void loginAsUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void addUser(UserModel user) {
    _allUsers.add(user);
    notifyListeners();
  }

  void updateUserRole(String userId, UserRole newRole) {
    final idx = _allUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      _allUsers[idx] = UserModel(
        id: _allUsers[idx].id,
        email: _allUsers[idx].email,
        name: _allUsers[idx].name,
        role: newRole,
        permissions: UserPermissions.forRole(newRole),
        avatarUrl: _allUsers[idx].avatarUrl,
      );
      if (_currentUser?.id == userId) {
        _currentUser = _allUsers[idx];
      }
      notifyListeners();
    }
  }
}
