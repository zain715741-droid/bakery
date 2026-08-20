import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branding_provider.dart';
import '../widgets/role_guard.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  void _showAddUserModal(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    UserRole selectedRole = UserRole.staff;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Add New Staff Member Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: "Email / Username", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: "Assigned System Role", border: OutlineInputBorder()),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text("${role.displayName} Role"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final email = emailController.text.trim();
                        if (name.isEmpty || email.isEmpty) return;

                        final newUser = UserModel(
                          id: 'u_${DateTime.now().millisecondsSinceEpoch}',
                          email: email,
                          name: name,
                          role: selectedRole,
                        );

                        auth.addUser(newUser);
                        Navigator.pop(ctx);
                      },
                      child: const Text("Create User Account"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final branding = Provider.of<BrandingProvider>(context).branding;
    final primaryColor = branding.primaryColor;

    return RoleGuard(
      canAccess: (a) => a.permissions.canManageUsers,
      fallback: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "User Management Access Restricted",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "Only the Bakery Owner account can add, edit, or manage user roles.",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFBF7),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              color: primaryColor.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded, color: Colors.brown, size: 36),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Owner Control Center", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 2),
                          Text("Manage staff accounts, assign roles, and grant permissions.", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Staff & Team Accounts", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...auth.allUsers.map((user) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primaryColor,
                    child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${user.email} • Role: ${user.role.displayName}"),
                  trailing: DropdownButton<UserRole>(
                    value: user.role,
                    onChanged: (newRole) {
                      if (newRole != null) {
                        auth.updateUserRole(user.id, newRole);
                      }
                    },
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.displayName),
                      );
                    }).toList(),
                  ),
                ),
              );
            }),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          onPressed: () => _showAddUserModal(context),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text("Add Staff User"),
        ),
      ),
    );
  }
}
