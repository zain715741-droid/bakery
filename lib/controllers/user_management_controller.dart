// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/branding_provider.dart';
import '../theme/luxury_theme.dart';

class UserManagementController extends GetxController {
  final selectedTab = 0.obs;

  void selectTab(int index) => selectedTab.value = index;

  void showAddUserModal() {
    final auth = Get.find<AuthProvider>();
    final branding = Get.find<BrandingProvider>().branding;
    final primaryColor = branding.primaryColor;

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController(text: 'bakery123');
    final selectedRole = UserRole.staff.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: LuxuryColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Add Pre-Approved Staff", style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("Directly create an active account without approval waiting.", style: GoogleFonts.outfit(fontSize: 12, color: LuxuryColors.textSecondary)),
              const SizedBox(height: 16),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person_outline_rounded))),
              const SizedBox(height: 10),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email Address", prefixIcon: Icon(Icons.email_outlined))),
              const SizedBox(height: 10),
              TextField(controller: passwordController, decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock_outline_rounded))),
              const SizedBox(height: 12),
              Obx(() => DropdownButtonFormField<UserRole>(
                    value: selectedRole.value,
                    decoration: const InputDecoration(labelText: "Role"),
                    items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text("${r.displayName} Role"))).toList(),
                    onChanged: (val) {
                      if (val != null) selectedRole.value = val;
                    },
                  )),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    if (name.isEmpty || email.isEmpty) {
                      Get.snackbar("Missing Information", "Please enter both name and email.", backgroundColor: Colors.red.shade900, colorText: Colors.white);
                      return;
                    }

                    final newUser = UserModel(
                      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
                      email: email,
                      name: name,
                      password: passwordController.text,
                      role: selectedRole.value,
                      isApproved: true,
                      createdAt: DateTime.now(),
                    );

                    await auth.addUser(newUser);
                    Get.back(); // close bottomsheet
                    Get.snackbar("Staff Created", "User '$name' created and active!", backgroundColor: primaryColor, colorText: Colors.white);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                  child: const Text("Create Active Account"),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void showApproveDialog(UserModel user) {
    final auth = Get.find<AuthProvider>();
    final assignedRole = user.role.obs;

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(Icons.verified_user_rounded, color: Colors.green.shade700, size: 24),
            const SizedBox(width: 8),
            Text("Approve User", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Approve access for ${user.name} (${user.email})?", style: GoogleFonts.outfit(fontSize: 14)),
            if (user.note != null && user.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text("“${user.note}”", style: GoogleFonts.outfit(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.brown)),
            ],
            const SizedBox(height: 14),
            Obx(() => DropdownButtonFormField<UserRole>(
                  value: assignedRole.value,
                  decoration: const InputDecoration(labelText: "Assigned Role"),
                  items: [UserRole.staff, UserRole.manager, UserRole.owner].map((r) => DropdownMenuItem(value: r, child: Text(r.displayName))).toList(),
                  onChanged: (val) {
                    if (val != null) assignedRole.value = val;
                  },
                )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await auth.approveUser(user.id, assignedRole: assignedRole.value);
              Get.back();
              Get.snackbar("User Approved", "'${user.name}' is now active as ${assignedRole.value.displayName}!", backgroundColor: Colors.green.shade800, colorText: Colors.white);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            child: const Text("Confirm & Approve"),
          ),
        ],
      ),
    );
  }

  void showRejectDialog(UserModel user) {
    final auth = Get.find<AuthProvider>();

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("Reject Registration"),
        content: Text("Are you sure you want to reject registration for '${user.name}'?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await auth.rejectUser(user.id);
              Get.back();
              Get.snackbar("Request Rejected", "Registration for '${user.name}' removed.", backgroundColor: Colors.red.shade900, colorText: Colors.white);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            child: const Text("Reject & Delete"),
          ),
        ],
      ),
    );
  }
}
