import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/branding_controller.dart';
import '../../providers/branding_provider.dart';
import '../../theme/luxury_theme.dart';
import '../widgets/role_guard.dart';

class BrandingScreen extends StatelessWidget {
  const BrandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BrandingScreenController());

    return Consumer<BrandingProvider>(
      builder: (context, brandingProvider, _) {
        final branding = brandingProvider.branding;
        final primaryColor = branding.primaryColor;
        final accentColor = branding.accentColor;

        return RoleGuard(
          canAccess: (auth) => auth.permissions.canEditBranding,

      // ============================================================
      // ACCESS DENIED
      // ============================================================
      fallback: Scaffold(
        backgroundColor: LuxuryColors.cream,
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(35),
            constraints: const BoxConstraints(maxWidth: 460),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .06),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: .08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 38,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  "Branding Settings Restricted",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: LuxuryColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Only the Bakery Owner can edit business branding.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    height: 1.6,
                    color: LuxuryColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ============================================================
      // MAIN SCREEN
      // ============================================================
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F5EF),

        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1000;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 42 : 18,
                  vertical: 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 1250,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==================================================
                        // PAGE HEADER
                        // ==================================================
                        _pageHeader(accentColor),

                        const SizedBox(height: 25),

                        // ==================================================
                        // LIVE PREVIEW
                        // ==================================================
                        _livePreview(
                          branding.businessName,
                          branding.ownerName,
                          branding.welcomeMessage,
                          primaryColor,
                          accentColor,
                        ),

                        const SizedBox(height: 28),

                        // ==================================================
                        // MAIN CONTENT
                        // ==================================================
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _identitySection(
                                  controller,
                                  primaryColor,
                                  accentColor,
                                ),
                              ),
                              const SizedBox(width: 22),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    _paletteSection(
                                      controller,
                                      brandingProvider,
                                      accentColor,
                                    ),
                                    const SizedBox(height: 22),
                                    _businessSettingsSection(controller),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _identitySection(
                                controller,
                                primaryColor,
                                accentColor,
                              ),
                              const SizedBox(height: 22),
                              _paletteSection(
                                controller,
                                brandingProvider,
                                accentColor,
                              ),
                              const SizedBox(height: 22),
                              _businessSettingsSection(controller),
                            ],
                          ),

                        const SizedBox(height: 25),

                        // ==================================================
                        // SAVE
                        // ==================================================
                        _saveButton(
                          controller,
                          primaryColor,
                          accentColor,
                        ),

                        const SizedBox(height: 20),

                        // ==================================================
                        // FOOTER
                        // ==================================================
                        _footer(accentColor),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  },
);
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _pageHeader(Color accentColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withValues(alpha: .25),
                accentColor.withValues(alpha: .08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: .35),
            ),
          ),
          child: Icon(
            Icons.palette_outlined,
            color: accentColor,
            size: 26,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Branding & Identity',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: LuxuryColors.espresso,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Customize your bakery identity, colors and business details.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: LuxuryColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LIVE PREVIEW
  // ============================================================

  Widget _livePreview(
    String businessName,
    String ownerName,
    String welcomeMessage,
    Color primaryColor,
    Color accentColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            Color.alphaBlend(
              Colors.black.withValues(alpha: .32),
              primaryColor,
            ),
            Color.alphaBlend(
              Colors.black.withValues(alpha: .50),
              primaryColor,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: accentColor.withValues(alpha: .30),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: .18),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative glow
          Positioned(
            right: -70,
            top: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: .08),
              ),
            ),
          ),

          Row(
            children: [
              // Logo
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      accentColor,
                      Color.alphaBlend(
                        Colors.black.withValues(alpha: .18),
                        accentColor,
                      ),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: .25),
                      blurRadius: 22,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: .35),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .20),
                    ),
                  ),
                  child: Icon(
                    Icons.bakery_dining_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 2,
                          color: accentColor,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'LIVE PREVIEW',
                          style: GoogleFonts.outfit(
                            color: accentColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.7,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      businessName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Master Artisan: $ownerName',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: .82),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '“$welcomeMessage”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: .62),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IDENTITY SECTION
  // ============================================================

  Widget _identitySection(
    BrandingScreenController controller,
    Color primaryColor,
    Color accentColor,
  ) {
    return _sectionCard(
      icon: Icons.storefront_outlined,
      title: 'Identity Details',
      subtitle: 'Define how your bakery appears throughout the system.',
      accentColor: accentColor,
      child: Column(
        children: [
          _customField(
            controller: controller.businessNameController,
            label: 'Bakery Business Name',
            hint: 'Enter your bakery name',
            icon: Icons.storefront_rounded,
            accentColor: accentColor,
          ),

          const SizedBox(height: 16),

          _customField(
            controller: controller.ownerNameController,
            label: 'Owner / Head Chef Name',
            hint: 'Enter owner name',
            icon: Icons.person_outline_rounded,
            accentColor: accentColor,
          ),

          const SizedBox(height: 16),

          _customField(
            controller: controller.welcomeController,
            label: 'Welcome Tagline / Motto',
            hint: 'Your bakery motto or tagline',
            icon: Icons.format_quote_rounded,
            accentColor: accentColor,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PALETTE SECTION
  // ============================================================

  Widget _paletteSection(
    BrandingScreenController controller,
    BrandingProvider brandingProvider,
    Color accentColor,
  ) {
    final branding = brandingProvider.branding;
    return _sectionCard(
      icon: Icons.color_lens_outlined,
      title: 'Luxury Theme',
      subtitle: 'Choose a color palette for your bakery.',
      accentColor: accentColor,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: controller.themePalettes.map<Widget>((p) {
          final isSelected =
              branding.primaryColorValue == p['primary'];

          final pPrimary = Color(p['primary'] as int);
          final pAccent = Color(p['accent'] as int);

          return GestureDetector(
            onTap: () {
              brandingProvider.updateColors(
                primaryColor: p['primary'] as int,
                accentColor: p['accent'] as int,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          pPrimary,
                          Color.alphaBlend(
                            Colors.black.withValues(alpha: .20),
                            pPrimary,
                          ),
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? pAccent
                      : Colors.grey.shade200,
                  width: isSelected ? 1.8 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: pPrimary.withValues(alpha: .15),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          pPrimary,
                          pAccent,
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    p['name'] as String,
                    style: GoogleFonts.outfit(
                      color: isSelected
                          ? Colors.white
                          : LuxuryColors.textPrimary,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 7),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // BUSINESS SETTINGS
  // ============================================================

  Widget _businessSettingsSection(
    BrandingScreenController controller,
  ) {
    return _sectionCard(
      icon: Icons.settings_outlined,
      title: 'Business Settings',
      subtitle: 'Configure currency and tax information.',
      accentColor: LuxuryColors.gold,
      child: Column(
        children: [
          _customField(
            controller: controller.currencyController,
            label: 'Currency Symbol',
            hint: '£',
            icon: Icons.payments_outlined,
            accentColor: LuxuryColors.gold,
          ),

          const SizedBox(height: 16),

          _customField(
            controller: controller.vatController,
            label: 'VAT / Tax (%)',
            hint: '20',
            icon: Icons.percent_rounded,
            accentColor: LuxuryColors.gold,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withValues(alpha: .055),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .045),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: LuxuryColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: LuxuryColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // CUSTOM TEXT FIELD
  // ============================================================

  Widget _customField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color accentColor,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.outfit(
        color: LuxuryColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.outfit(
          color: LuxuryColors.textSecondary,
          fontSize: 12,
        ),
        hintStyle: GoogleFonts.outfit(
          color: Colors.grey.shade400,
          fontSize: 12,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: 4,
            right: 4,
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: 20,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 52,
        ),
        filled: true,
        fillColor: const Color(0xFFFAF9F6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: accentColor,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _saveButton(
    BrandingScreenController controller,
    Color primaryColor,
    Color accentColor,
  ) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            primaryColor,
            Color.alphaBlend(
              Colors.black.withValues(alpha: .22),
              primaryColor,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: accentColor.withValues(alpha: .60),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: .20),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: controller.saveBranding,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.save_rounded,
              color: accentColor,
              size: 21,
            ),
            const SizedBox(width: 10),
            Text(
              "Save Branding Settings",
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: .3,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white.withValues(alpha: .75),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _footer(Color accentColor) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            color: accentColor,
            size: 14,
          ),
          const SizedBox(width: 7),
          Text(
            'SECURE ARTISAN BAKERY BRANDING',
            style: GoogleFonts.outfit(
              color: Colors.grey.shade500,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}