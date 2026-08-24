import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../providers/branding_provider.dart';
import '../theme/luxury_theme.dart';

class BrandingScreenController extends GetxController {
  late final TextEditingController businessNameController;
  late final TextEditingController ownerNameController;
  late final TextEditingController welcomeController;
  late final TextEditingController currencyController;
  late final TextEditingController vatController;

  final themePalettes = const [
    {'name': 'Espresso & Gold (Luxury)', 'primary': 0xFF2C1810, 'accent': 0xFFD4AF37},
    {'name': 'Royal Velvet & Champagne', 'primary': 0xFF3D1E24, 'accent': 0xFFE5B567},
    {'name': 'Warm Amber & Caramel', 'primary': 0xFF5D4037, 'accent': 0xFFE5A93C},
    {'name': 'Midnight Chocolate', 'primary': 0xFF1E140F, 'accent': 0xFFC5A059},
    {'name': 'Artisan Rose & Bronze', 'primary': 0xFF4A1525, 'accent': 0xFFCD7F32},
    {'name': 'Emerald Botanical', 'primary': 0xFF1B3B2B, 'accent': 0xFFD4AF37},
  ];

  @override
  void onInit() {
    super.onInit();
    final branding = Get.find<BrandingProvider>().branding;
    businessNameController = TextEditingController(text: branding.businessName);
    ownerNameController = TextEditingController(text: branding.ownerName);
    welcomeController = TextEditingController(text: branding.welcomeMessage);
    currencyController = TextEditingController(text: branding.currencySymbol);
    vatController = TextEditingController(text: (branding.vatRate * 100).toStringAsFixed(0));
  }

  @override
  void onClose() {
    businessNameController.dispose();
    ownerNameController.dispose();
    welcomeController.dispose();
    currencyController.dispose();
    vatController.dispose();
    super.dispose();
  }

  void saveBranding() {
    final provider = Get.find<BrandingProvider>();
    final vatPercent = double.tryParse(vatController.text) ?? 20.0;

    final updated = provider.branding.copyWith(
      businessName: businessNameController.text.trim(),
      ownerName: ownerNameController.text.trim(),
      welcomeMessage: welcomeController.text.trim(),
      currencySymbol: currencyController.text.trim(),
      vatRate: vatPercent / 100.0,
    );

    provider.updateBranding(updated);

    Get.snackbar(
      "Branding Saved",
      "Luxury branding settings updated globally across the app!",
      backgroundColor: LuxuryColors.espresso,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.check_circle_rounded, color: LuxuryColors.gold),
    );
  }
}
