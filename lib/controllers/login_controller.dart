import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../views/shell_screen.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController(text: 'owner@bakery.co.uk');
  final passwordController = TextEditingController(text: 'bakery123');
  final obscurePassword = true.obs;
  final selectedRole = UserRole.owner.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void switchRole(UserRole role) {
    selectedRole.value = role;
    final auth = Get.find<AuthProvider>();
    auth.switchRole(role);

    if (role == UserRole.owner) {
      emailController.text = 'owner@bakery.co.uk';
    } else if (role == UserRole.manager) {
      emailController.text = 'manager@bakery.co.uk';
    } else {
      emailController.text = 'staff@bakery.co.uk';
    }
  }

  Future<void> handleLogin() async {
    final auth = Get.find<AuthProvider>();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      Get.snackbar(
        "Email Required",
        "Please enter your registered email address.",
        backgroundColor: const Color(0xFF1E0F0A),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final matching = auth.allUsers.where(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );

    if (matching.isNotEmpty) {
      final user = matching.first;
      if (!user.isApproved) {
        _showPendingDialog(user);
        return;
      }
      await auth.loginAsUser(user);
      Get.offAll(() => const ShellScreen());
      return;
    }

    // Default Owner Bootstrap for fresh setups
    if (email.toLowerCase() == 'owner@bakery.co.uk' || auth.allUsers.isEmpty) {
      final ownerUser = UserModel(
        id: 'u_owner_1',
        email: email.isEmpty ? 'owner@bakery.co.uk' : email,
        password: password.isEmpty ? 'bakery123' : password,
        name: 'Bakery Owner',
        role: UserRole.owner,
        isApproved: true,
        createdAt: DateTime.now(),
      );
      await auth.addUser(ownerUser);
      await auth.loginAsUser(ownerUser);
      Get.offAll(() => const ShellScreen());
      return;
    }

    Get.snackbar(
      "Account Not Found",
      "No account found for $email. Please click 'Create New Account' to register your profile.",
      backgroundColor: const Color(0xFF1E0F0A),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    );
  }

  void _showPendingDialog(UserModel user) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E0F0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD4AF37), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Approval Pending",
                style: GoogleFonts.playfairDisplay(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Account: ${user.name} (${user.email})",
              style: GoogleFonts.outfit(color: const Color(0xFFF5D98A), fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              "Your registration for ${user.role.displayName} access is pending approval by the Bakery Owner.",
              style: GoogleFonts.outfit(color: const Color(0xFFFFF4DA).withValues(alpha: 0.85), fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: const Color(0xFF120A07),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Understood", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void showForgotPassword() {
    final resetEmail = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E0F0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
        ),
        title: Text("Password Recovery", style: GoogleFonts.playfairDisplay(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: resetEmail,
          style: GoogleFonts.outfit(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Enter your registered email",
            prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFD4AF37)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                "Reset Link Sent",
                "Password recovery instructions sent to ${resetEmail.text.isEmpty ? 'your email' : resetEmail.text}",
                backgroundColor: const Color(0xFF2C1810),
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
                margin: const EdgeInsets.all(16),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            child: const Text("Send Link"),
          ),
        ],
      ),
    );
  }
}
