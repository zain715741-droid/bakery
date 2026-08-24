import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/branding_controller.dart';
import '../../providers/branding_provider.dart';
import '../../theme/luxury_theme.dart';
import '../widgets/role_guard.dart';

class BrandingScreen extends StatelessWidget {
  const BrandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BrandingScreenController());
    final brandingProvider = Get.find<BrandingProvider>();
    final branding = brandingProvider.branding;
    final primaryColor = branding.primaryColor;
    final accentColor = branding.accentColor;

    return RoleGuard(
      canAccess: (auth) => auth.permissions.canEditBranding,
      fallback: Scaffold(
        backgroundColor: LuxuryColors.cream,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 60, color: Colors.grey),
              const SizedBox(height: 12),
              Text("Branding Settings Restricted", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("Only the Bakery Owner can edit business branding.", style: GoogleFonts.outfit(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: LuxuryColors.cream,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Preview Banner
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor, Color.alphaBlend(Colors.black38, primaryColor)]),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.5),
                  boxShadow: LuxuryShadows.elevated,
                ),
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor, width: 2),
                        color: accentColor.withValues(alpha: 0.2),
                      ),
                      child: Icon(Icons.bakery_dining_rounded, color: accentColor, size: 34),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(branding.businessName, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Master Artisan: ${branding.ownerName}", style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                          Text("“${branding.welcomeMessage}”", style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Inputs
              Text("Identity Details", style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: LuxuryColors.textPrimary)),
              const SizedBox(height: 10),
              TextField(controller: controller.businessNameController, decoration: const InputDecoration(labelText: "Bakery Business Name", prefixIcon: Icon(Icons.storefront_rounded))),
              const SizedBox(height: 12),
              TextField(controller: controller.ownerNameController, decoration: const InputDecoration(labelText: "Owner / Head Chef Name", prefixIcon: Icon(Icons.person_outline_rounded))),
              const SizedBox(height: 12),
              TextField(controller: controller.welcomeController, decoration: const InputDecoration(labelText: "Welcome Tagline / Motto", prefixIcon: Icon(Icons.format_quote_rounded))),
              const SizedBox(height: 24),

              // Palettes
              Text("Luxury Theme Color Palettes", style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: LuxuryColors.textPrimary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: controller.themePalettes.map((p) {
                  final isSelected = branding.primaryColorValue == p['primary'];
                  final pPrimary = Color(p['primary'] as int);
                  final pAccent = Color(p['accent'] as int);

                  return GestureDetector(
                    onTap: () {
                      brandingProvider.updateColors(primaryColor: p['primary'] as int, accentColor: p['accent'] as int);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? pPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? pAccent : Colors.grey.shade300, width: isSelected ? 2 : 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: pPrimary, shape: BoxShape.circle, border: Border.all(color: pAccent))),
                          const SizedBox(width: 8),
                          Text(p['name'] as String, style: GoogleFonts.outfit(color: isSelected ? Colors.white : LuxuryColors.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Currency & Tax
              Row(
                children: [
                  Expanded(child: TextField(controller: controller.currencyController, decoration: const InputDecoration(labelText: "Currency Symbol", prefixIcon: Icon(Icons.payments_outlined), hintText: "£"))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: controller.vatController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "VAT / Tax (%)", prefixIcon: Icon(Icons.percent_rounded), hintText: "20"))),
                ],
              ),
              const SizedBox(height: 28),

              // Save Button
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor, Color.alphaBlend(Colors.black26, primaryColor)]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentColor.withValues(alpha: 0.6)),
                ),
                child: ElevatedButton(
                  onPressed: controller.saveBranding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, color: accentColor, size: 20),
                      const SizedBox(width: 8),
                      Text("Save Branding Settings", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
