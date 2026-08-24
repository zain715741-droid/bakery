import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../providers/auth_provider.dart';
import '../theme/luxury_theme.dart';
import '../views/auth/login_screen.dart';

class ShellController extends GetxController {
  final currentIndex = 0.obs;
  final isOnline = true.obs;

  void selectTab(int index) => currentIndex.value = index;

  void toggleOnline() {
    isOnline.toggle();
    Get.snackbar(
      isOnline.value ? "Cloud Online" : "Offline Storage Mode",
      isOnline.value ? "Connected to live Cloud Firestore." : "Switched to local SQLite storage mode.",
      backgroundColor: LuxuryColors.espresso,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  void logout() {
    Get.find<AuthProvider>().logout();
    Get.offAll(() => const LoginScreen());
  }
}
