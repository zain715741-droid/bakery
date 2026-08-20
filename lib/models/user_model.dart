enum UserRole { owner, manager, staff }

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.manager:
        return 'Manager';
      case UserRole.staff:
        return 'Staff';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'manager':
        return UserRole.manager;
      case 'staff':
      default:
        return UserRole.staff;
    }
  }
}

class UserPermissions {
  final bool canManageUsers;
  final bool canEditRecipes;
  final bool canViewFinancials;
  final bool canEditInventory;
  final bool canCreateOrders;
  final bool canEditBranding;

  const UserPermissions({
    required this.canManageUsers,
    required this.canEditRecipes,
    required this.canViewFinancials,
    required this.canEditInventory,
    required this.canCreateOrders,
    required this.canEditBranding,
  });

  factory UserPermissions.forRole(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return const UserPermissions(
          canManageUsers: true,
          canEditRecipes: true,
          canViewFinancials: true,
          canEditInventory: true,
          canCreateOrders: true,
          canEditBranding: true,
        );
      case UserRole.manager:
        return const UserPermissions(
          canManageUsers: false,
          canEditRecipes: true,
          canViewFinancials: true,
          canEditInventory: true,
          canCreateOrders: true,
          canEditBranding: false,
        );
      case UserRole.staff:
        return const UserPermissions(
          canManageUsers: false,
          canEditRecipes: false,
          canViewFinancials: false,
          canEditInventory: false,
          canCreateOrders: true,
          canEditBranding: false,
        );
    }
  }

  Map<String, dynamic> toJson() => {
        'canManageUsers': canManageUsers,
        'canEditRecipes': canEditRecipes,
        'canViewFinancials': canViewFinancials,
        'canEditInventory': canEditInventory,
        'canCreateOrders': canCreateOrders,
        'canEditBranding': canEditBranding,
      };

  factory UserPermissions.fromJson(Map<String, dynamic> json) => UserPermissions(
        canManageUsers: json['canManageUsers'] ?? false,
        canEditRecipes: json['canEditRecipes'] ?? false,
        canViewFinancials: json['canViewFinancials'] ?? false,
        canEditInventory: json['canEditInventory'] ?? false,
        canCreateOrders: json['canCreateOrders'] ?? true,
        canEditBranding: json['canEditBranding'] ?? false,
      );
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final UserPermissions permissions;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    UserPermissions? permissions,
    this.avatarUrl,
  }) : permissions = permissions ?? UserPermissions.forRole(role);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'avatarUrl': avatarUrl,
      'permissions': permissions.toJson(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final role = UserRoleExtension.fromString(map['role'] ?? 'staff');
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: role,
      avatarUrl: map['avatarUrl'],
      permissions: map['permissions'] != null
          ? (map['permissions'] is Map
              ? UserPermissions.fromJson(Map<String, dynamic>.from(map['permissions']))
              : UserPermissions.forRole(role))
          : UserPermissions.forRole(role),
    );
  }
}
