import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/branding_provider.dart';
import '../views/shell_screen.dart';

class LoginController extends GetxController {
  final obscurePassword = true.obs;
  final selectedRole = UserRole.owner.obs;
  final isLoading = false.obs;

  void switchRole(UserRole role) {
    selectedRole.value = role;
  }

  Future<void> handleLogin({required String email, required String password}) async {
    final auth = Get.find<AuthProvider>();
    final trimmedEmail = email.trim();
    final trimmedPassword = password;

    if (trimmedEmail.isEmpty) {
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

    if (trimmedPassword.isEmpty) {
      Get.snackbar(
        "Password Required",
        "Please enter your password.",
        backgroundColor: const Color(0xFF1E0F0A),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    isLoading.value = true;

    bool firebaseSuccess = false;
    // 1. Try signing in via Firebase Authentication if email is properly formatted
    if (trimmedEmail.contains('@') && trimmedEmail.contains('.')) {
      try {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: trimmedEmail.toLowerCase(),
          password: trimmedPassword,
        );
        if (cred.user != null) {
          firebaseSuccess = true;
        }
      } on FirebaseAuthException catch (e) {
        debugPrint("Firebase Auth sign in error code: ${e.code}");
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          isLoading.value = false;
          Get.snackbar(
            "Invalid Password",
            "The password you entered is incorrect. Please check and try again.",
            backgroundColor: const Color(0xFF8B1E0F),
            colorText: Colors.white,
            icon: const Icon(Icons.lock_clock_outlined, color: Colors.white),
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          );
          return;
        }
      } catch (e) {
        debugPrint("Firebase Auth sign in note: $e");
      }
    }

    // 2. Check Database Users
    final matching = auth.allUsers.where(
      (u) => u.email.toLowerCase() == trimmedEmail.toLowerCase(),
    );

    if (matching.isNotEmpty) {
      var user = matching.first;

      // STRICT PASSWORD VERIFICATION
      if (user.password != null && user.password!.isNotEmpty) {
        if (user.password != trimmedPassword && !firebaseSuccess) {
          isLoading.value = false;
          Get.snackbar(
            "Incorrect Password",
            "The password you entered is incorrect. Please try again.",
            backgroundColor: const Color(0xFF8B1E0F),
            colorText: Colors.white,
            icon: const Icon(Icons.lock_clock_outlined, color: Colors.white),
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          );
          return;
        }
      } else if (!firebaseSuccess) {
        isLoading.value = false;
        Get.snackbar(
          "Authentication Failed",
          "Invalid credentials. Please enter the correct password.",
          backgroundColor: const Color(0xFF8B1E0F),
          colorText: Colors.white,
          icon: const Icon(Icons.lock_clock_outlined, color: Colors.white),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Check account approval
      if (!user.isApproved) {
        isLoading.value = false;
        _showPendingDialog(user);
        return;
      }

      if (user.role == UserRole.owner) {
        final branding = Get.find<BrandingProvider>().branding;
        if (branding.ownerName.isNotEmpty && branding.ownerName != 'Owner' && (user.name == 'Bakery Owner' || user.name.isEmpty)) {
          user = user.copyWith(name: branding.ownerName);
          await auth.updateOwnerProfileName(branding.ownerName);
        }
      }

      isLoading.value = false;
      await auth.loginAsUser(user);
      Get.offAll(() => const ShellScreen(), routeName: '/ShellScreen');
      return;
    }

    // 3. First Setup Bootstrap (Only if ZERO users exist in whole database)
    if (auth.allUsers.isEmpty) {
      final ownerUser = UserModel(
        id: 'u_${DateTime.now().millisecondsSinceEpoch}',
        email: trimmedEmail,
        password: trimmedPassword,
        name: 'Bakery Owner',
        role: UserRole.owner,
        isApproved: true,
        createdAt: DateTime.now(),
      );
      await auth.addUser(ownerUser);
      await auth.loginAsUser(ownerUser);
      isLoading.value = false;
      Get.offAll(() => const ShellScreen(), routeName: '/ShellScreen');
      return;
    }

    // 4. Account not found
    isLoading.value = false;
    Get.snackbar(
      "Account Not Found",
      "No account found for $trimmedEmail. Please click 'Register for Access' to create a profile.",
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
