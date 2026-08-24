import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/login_controller.dart';
import '../../models/user_model.dart';
import '../../providers/branding_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    final branding = Get.find<BrandingProvider>().branding;

    final primaryColor = branding.primaryColor;
    final accentColor = branding.accentColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: Stack(
        children: [

          // =====================================================
          // BACKGROUND
          // =====================================================

          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFCF7),
                  Color(0xFFF5EFE6),
                  Color(0xFFEDE1D0),
                ],
              ),
            ),
          ),

          // Top Right Gold Glow
          Positioned(
            top: -170,
            right: -130,
            child: _backgroundGlow(
              400,
              accentColor,
              .10,
            ),
          ),

          // Bottom Left Warm Glow
          Positioned(
            bottom: -180,
            left: -150,
            child: _backgroundGlow(
              430,
              const Color(0xFFD9B98C),
              .18,
            ),
          ),

          // Soft Center Shape
          Positioned(
            top: 350,
            left: 350,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD8B58A)
                    .withValues(alpha: .035),
              ),
            ),
          ),

          // =====================================================
          // MAIN CONTENT
          // =====================================================

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {

                final isDesktop =
                    constraints.maxWidth >= 900;

                return Center(
                  child: SingleChildScrollView(
                    physics:
                        const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          isDesktop ? 70 : 20,
                      vertical: 35,
                    ),
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(
                        maxWidth: 1180,
                      ),
                      child: isDesktop
                          ? _desktopLayout(
                              context,
                              controller,
                              branding.businessName,
                              branding.welcomeMessage,
                              primaryColor,
                              accentColor,
                            )
                          : _mobileLayout(
                              context,
                              controller,
                              branding.businessName,
                              branding.welcomeMessage,
                              primaryColor,
                              accentColor,
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP LAYOUT
  // ============================================================

  Widget _desktopLayout(
    BuildContext context,
    LoginController controller,
    String businessName,
    String welcomeMessage,
    Color primaryColor,
    Color accentColor,
  ) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 650,
      ),
      child: Row(
        children: [

          // LEFT BRANDING
          Expanded(
            child: _brandingSection(
              businessName,
              welcomeMessage,
              accentColor,
            ),
          ),

          const SizedBox(width: 75),

          // RIGHT LOGIN
          SizedBox(
            width: 470,
            child: _loginPanel(
              context,
              controller,
              primaryColor,
              accentColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE LAYOUT
  // ============================================================

  Widget _mobileLayout(
    BuildContext context,
    LoginController controller,
    String businessName,
    String welcomeMessage,
    Color primaryColor,
    Color accentColor,
  ) {
    return Column(
      children: [

        _brandingSection(
          businessName,
          welcomeMessage,
          accentColor,
          mobile: true,
        ),

        const SizedBox(height: 35),

        _loginPanel(
          context,
          controller,
          primaryColor,
          accentColor,
        ),
      ],
    );
  }

  // ============================================================
  // BRANDING SECTION
  // ============================================================

  Widget _brandingSection(
    String businessName,
    String welcomeMessage,
    Color accentColor, {
    bool mobile = false,
  }) {
    return Column(
      crossAxisAlignment: mobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [

        // ======================================================
        // LOGO
        // ======================================================

        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF6D77A),
                accentColor,
                Color.alphaBlend(
                  Colors.black12,
                  accentColor,
                ),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(
                  alpha: .25,
                ),
                blurRadius: 35,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2C1810),
            ),
            child: Icon(
              Icons.bakery_dining_rounded,
              size: 50,
              color: Color(0xFFD4AF37),
            ),
          ),
        ),

        const SizedBox(height: 30),

        // ======================================================
        // SMALL BRAND LABEL
        // ======================================================

        Row(
          mainAxisAlignment: mobile
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [

            Container(
              width: 38,
              height: 1,
              color: accentColor,
            ),

            const SizedBox(width: 10),

            Text(
              'ARTISAN BAKERY',
              style: GoogleFonts.outfit(
                color: const Color(0xFFA67C1E),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.5,
              ),
            ),

            const SizedBox(width: 10),

            Container(
              width: 38,
              height: 1,
              color: accentColor,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ======================================================
        // BUSINESS NAME
        // ======================================================

        Text(
          businessName,
          textAlign:
              mobile ? TextAlign.center : TextAlign.left,
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF2C1810),
            fontSize: mobile ? 34 : 52,
            height: 1.08,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 18),

        // ======================================================
        // WELCOME MESSAGE
        // ======================================================

        SizedBox(
          width: 470,
          child: Text(
            welcomeMessage,
            textAlign:
                mobile ? TextAlign.center : TextAlign.left,
            style: GoogleFonts.outfit(
              color: const Color(0xFF806F63),
              fontSize: 14,
              height: 1.7,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),

        const SizedBox(height: 30),

        // ======================================================
        // FEATURES
        // ======================================================

        Wrap(
          alignment: mobile
              ? WrapAlignment.center
              : WrapAlignment.start,
          spacing: 22,
          runSpacing: 12,
          children: [

            _feature(
              Icons.auto_awesome_rounded,
              'Premium',
              accentColor,
            ),

            _feature(
              Icons.bakery_dining_rounded,
              'Artisan',
              accentColor,
            ),

            _feature(
              Icons.verified_rounded,
              'Trusted',
              accentColor,
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // LOGIN PANEL
  // ============================================================

  Widget _loginPanel(
    BuildContext context,
    LoginController controller,
    Color primaryColor,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE2D3BF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4B32)
                .withValues(alpha: .10),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: accentColor.withValues(
              alpha: .08,
            ),
            blurRadius: 25,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          // ====================================================
          // HEADER
          // ====================================================

          Row(
            children: [

              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withValues(
                        alpha: .18,
                      ),
                      accentColor.withValues(
                        alpha: .07,
                      ),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color: accentColor.withValues(
                      alpha: .30,
                    ),
                  ),
                ),
                child: Icon(
                  Icons.lock_person_rounded,
                  color: const Color(0xFFA67C1E),
                  size: 23,
                ),
              ),

              const SizedBox(width: 13),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    'WELCOME BACK',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA67C1E),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Sign in to continue',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C1810),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 30),

          // ====================================================
          // LOGIN AS
          // ====================================================

          _sectionTitle(
            'LOGIN AS',
            accentColor,
          ),

          const SizedBox(height: 9),

          Obx(
            () => _roleSelector(
              controller,
              primaryColor,
              accentColor,
            ),
          ),

          const SizedBox(height: 24),

          // ====================================================
          // EMAIL
          // ====================================================

          _sectionTitle(
            'EMAIL ADDRESS',
            accentColor,
          ),

          const SizedBox(height: 8),

          _textField(
            controller: controller.emailController,
            hint: 'owner@bakery.co.uk',
            icon: Icons.person_outline_rounded,
            primaryColor: primaryColor,
          ),

          const SizedBox(height: 17),

          // ====================================================
          // PASSWORD
          // ====================================================

          _sectionTitle(
            'PASSWORD',
            accentColor,
          ),

          const SizedBox(height: 8),

          Obx(
            () => _passwordField(
              controller,
              primaryColor,
              accentColor,
            ),
          ),

          // ====================================================
          // FORGOT PASSWORD
          // ====================================================

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed:
                  controller.showForgotPassword,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 5,
                ),
              ),
              child: Text(
                'Forgot password?',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFA67C1E),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 7),

          // ====================================================
          // LOGIN BUTTON
          // ====================================================

          _loginButton(
            controller,
            primaryColor,
            accentColor,
          ),

          const SizedBox(height: 22),

          // ====================================================
          // DIVIDER
          // ====================================================

          Row(
            children: [

              Expanded(
                child: Divider(
                  color: const Color(0xFFE2D6C9),
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                child: Text(
                  'OR',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFAA9B8F),
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),

              Expanded(
                child: Divider(
                  color: const Color(0xFFE2D6C9),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ====================================================
          // SIGN UP
          // ====================================================

          Center(
            child: Wrap(
              alignment:
                  WrapAlignment.center,
              children: [

                Text(
                  'New staff member? ',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF806F63),
                    fontSize: 12,
                  ),
                ),

                GestureDetector(
                  onTap: () => Get.to(
                    () => const SignUpScreen(),
                  ),
                  child: Text(
                    'Register for Access',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA67C1E),
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ROLE SELECTOR
  // ============================================================

  Widget _roleSelector(
    LoginController controller,
    Color primaryColor,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EEE4),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE3D6C6),
        ),
      ),
      child: Row(
        children: [

          _roleTab(
            UserRole.owner,
            'Owner',
            controller,
            primaryColor,
            accentColor,
          ),

          _roleTab(
            UserRole.manager,
            'Manager',
            controller,
            primaryColor,
            accentColor,
          ),

          _roleTab(
            UserRole.staff,
            'Staff',
            controller,
            primaryColor,
            accentColor,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ROLE TAB
  // ============================================================

  Widget _roleTab(
    UserRole role,
    String label,
    LoginController controller,
    Color primaryColor,
    Color accentColor,
  ) {
    final selected =
        controller.selectedRole.value == role;

    return Expanded(
      child: GestureDetector(
        onTap: () =>
            controller.switchRole(role),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 220),
          padding:
              const EdgeInsets.symmetric(
            vertical: 11,
          ),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor,
                      Color.alphaBlend(
                        Colors.black12,
                        accentColor,
                      ),
                    ],
                  )
                : null,
            borderRadius:
                BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accentColor
                          .withValues(alpha: .20),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: selected
                  ? FontWeight.w800
                  : FontWeight.w500,
              color: selected
                  ? const Color(0xFF2C1810)
                  : const Color(0xFF806F63),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color primaryColor,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.outfit(
        color: const Color(0xFF2C1810),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      decoration: _inputDecoration(
        hint,
        icon,
        primaryColor,
      ),
    );
  }

  // ============================================================
  // PASSWORD FIELD
  // ============================================================

  Widget _passwordField(
    LoginController controller,
    Color primaryColor,
    Color accentColor,
  ) {
    return TextField(
      controller:
          controller.passwordController,
      obscureText:
          controller.obscurePassword.value,
      style: GoogleFonts.outfit(
        color: const Color(0xFF2C1810),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      decoration: _inputDecoration(
        '••••••••',
        Icons.lock_outline_rounded,
        primaryColor,
      ).copyWith(
        suffixIcon: IconButton(
          onPressed: () =>
              controller.obscurePassword.toggle(),
          icon: Icon(
            controller.obscurePassword.value
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFFA67C1E),
            size: 19,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
    Color primaryColor,
  ) {
    return InputDecoration(
      hintText: hint,

      hintStyle: GoogleFonts.outfit(
        color: const Color(0xFFAA9B8F),
        fontSize: 12,
      ),

      prefixIcon: Icon(
        icon,
        color: const Color(0xFF9A8A7D),
        size: 20,
      ),

      filled: true,

      fillColor: const Color(0xFFF8F3EB),

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE3D6C6),
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE3D6C6),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN BUTTON
  // ============================================================

  Widget _loginButton(
    LoginController controller,
    Color primaryColor,
    Color accentColor,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF0CE72),
              accentColor,
              Color.alphaBlend(
                Colors.black12,
                accentColor,
              ),
            ],
          ),
          borderRadius:
              BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(
                alpha: .25,
              ),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed:
              controller.handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Colors.transparent,
            foregroundColor:
                const Color(0xFF2C1810),
            shadowColor:
                Colors.transparent,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(15),
            ),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [

              Text(
                'ENTER BAKERY DASHBOARD',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(width: 10),

              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
    String text,
    Color accentColor,
  ) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: const Color(0xFFA67C1E),
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }

  // ============================================================
  // FEATURE
  // ============================================================

  Widget _feature(
    IconData icon,
    String text,
    Color accentColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [

        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: accentColor.withValues(
              alpha: .10,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFFA67C1E),
            size: 13,
          ),
        ),

        const SizedBox(width: 7),

        Text(
          text,
          style: GoogleFonts.outfit(
            color: const Color(0xFF806F63),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BACKGROUND GLOW
  // ============================================================

  Widget _backgroundGlow(
    double size,
    Color color,
    double opacity,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(
          alpha: opacity,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(
              alpha: opacity,
            ),
            blurRadius: 120,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}