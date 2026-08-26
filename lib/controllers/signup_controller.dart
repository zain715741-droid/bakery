import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../views/auth/login_screen.dart';

class SignUpController extends GetxController {
  final selectedRole = UserRole.staff.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final isLoading = false.obs;

  Future<void> handleSignUp({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? note,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    final trimmedNote = note?.trim();

    if (trimmedName.isEmpty) {
      Get.snackbar("Validation Error", "Please enter your full name.", backgroundColor: const Color(0xFF3E1D19), colorText: Colors.white);
      return;
    }

    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      Get.snackbar("Validation Error", "Please enter a valid email address.", backgroundColor: const Color(0xFF3E1D19), colorText: Colors.white);
      return;
    }

    if (password.length < 6) {
      Get.snackbar("Validation Error", "Password must be at least 6 characters.", backgroundColor: const Color(0xFF3E1D19), colorText: Colors.white);
      return;
    }

    if (password != confirmPassword) {
      Get.snackbar("Validation Error", "Passwords do not match.", backgroundColor: const Color(0xFF3E1D19), colorText: Colors.white);
      return;
    }

    final auth = Get.find<AuthProvider>();
    if (auth.allUsers.any((u) => u.email.toLowerCase() == trimmedEmail.toLowerCase())) {
      Get.snackbar("Account Exists", "This email address is already registered.", backgroundColor: const Color(0xFF3E1D19), colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    try {
      await auth.registerUser(
        name: trimmedName,
        email: trimmedEmail,
        password: password,
        requestedRole: selectedRole.value,
        note: trimmedNote != null && trimmedNote.isNotEmpty ? trimmedNote : null,
      );
      isLoading.value = false;
      _showSuccessDialog(trimmedName, selectedRole.value);
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Registration Failed", e.toString(), backgroundColor: const Color(0xFF3E1D19), colorText: Colors.white);
    }
  }

  void _showSuccessDialog(String name, UserRole role) {
    Get.dialog(
      barrierDismissible: false,
      AlertDialog(
        backgroundColor: const Color(0xFF1E0F0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFFFFE39A), Color(0xFFD4AF37), Color(0xFFA67C1E)]),
              ),
              child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF1E0F0A), size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              "Registration Submitted!",
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Account for $name registered as ${role.displayName}.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: const Color(0xFFF3E5AB), fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
              child: Text(
                "Status: Pending Approval by the Bakery Owner. You can log in once approved.",
                style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.offAll(() => const LoginScreen());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF1E0F0A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Back to Sign In", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
