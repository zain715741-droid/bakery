import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/signup_controller.dart';
import '../../models/user_model.dart';
import '../../providers/branding_provider.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _noteController;
  late final SignUpController _controller;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _noteController = TextEditingController();
    _controller = Get.put(SignUpController());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = Get.find<BrandingProvider>().branding;
    final primaryColor = branding.primaryColor;
    final accentColor = branding.accentColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: Stack(
        children: [
          // Background Gradient
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
            child: _backgroundGlow(400, accentColor, .10),
          ),

          // Bottom Left Warm Glow
          Positioned(
            bottom: -180,
            left: -150,
            child: _backgroundGlow(430, const Color(0xFFD9B98C), .18),
          ),

          // Main Scrollable Area
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;
                return Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 70 : 20,
                      vertical: 35,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: isDesktop
                          ? _desktopLayout(context, branding.businessName, primaryColor, accentColor)
                          : _mobileLayout(context, branding.businessName, primaryColor, accentColor),
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

  Widget _desktopLayout(BuildContext context, String businessName, Color primaryColor, Color accentColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _brandingSidebar(businessName, accentColor)),
        const SizedBox(width: 60),
        SizedBox(
          width: 520,
          child: _signupPanel(context, primaryColor, accentColor),
        ),
      ],
    );
  }

  Widget _mobileLayout(BuildContext context, String businessName, Color primaryColor, Color accentColor) {
    return Column(
      children: [
        _brandingSidebar(businessName, accentColor, mobile: true),
        const SizedBox(height: 25),
        _signupPanel(context, primaryColor, accentColor),
      ],
    );
  }

  Widget _brandingSidebar(String businessName, Color accentColor, {bool mobile = false}) {
    return Column(
      crossAxisAlignment: mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [const Color(0xFFF6D77A), accentColor, Color.alphaBlend(Colors.black12, accentColor)],
            ),
            boxShadow: [
              BoxShadow(color: accentColor.withValues(alpha: .25), blurRadius: 30, offset: const Offset(0, 8)),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2C1810)),
            child: const Icon(Icons.person_add_alt_1_rounded, size: 40, color: Color(0xFFD4AF37)),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'STAFF ONBOARDING',
          style: GoogleFonts.outfit(
            color: const Color(0xFFA67C1E),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Join the\nArtisan Team',
          textAlign: mobile ? TextAlign.center : TextAlign.left,
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF2C1810),
            fontSize: mobile ? 30 : 44,
            height: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Register your account to access baking recipes, pos checkout, and inventory operations. All registrations require Bakery Owner approval.',
          textAlign: mobile ? TextAlign.center : TextAlign.left,
          style: GoogleFonts.outfit(color: const Color(0xFF806F63), fontSize: 13, height: 1.6),
        ),
      ],
    );
  }

  Widget _signupPanel(BuildContext context, Color primaryColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2D3BF), width: 1),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6B4B32).withValues(alpha: .10), blurRadius: 36, offset: const Offset(0, 16)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.app_registration_rounded, color: Color(0xFFA67C1E), size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NEW ACCOUNT', style: GoogleFonts.outfit(color: const Color(0xFFA67C1E), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  Text('Register Staff Profile', style: GoogleFonts.outfit(color: const Color(0xFF2C1810), fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Role selection
          _fieldLabel('REQUESTED ACCESS ROLE', accentColor),
          const SizedBox(height: 8),
          Obx(
            () => Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: const Color(0xFFF5EEE4), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  _roleChoiceTab(UserRole.staff, 'Staff Member', accentColor),
                  _roleChoiceTab(UserRole.manager, 'Bakery Manager', accentColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          _fieldLabel('FULL NAME *', accentColor),
          const SizedBox(height: 6),
          _textField(controller: _nameController, hint: 'e.g. John Baker', icon: Icons.badge_outlined, primaryColor: primaryColor),
          const SizedBox(height: 14),

          // Email
          _fieldLabel('EMAIL ADDRESS *', accentColor),
          const SizedBox(height: 6),
          _textField(controller: _emailController, hint: 'john@example.com', icon: Icons.alternate_email_rounded, primaryColor: primaryColor),
          const SizedBox(height: 14),

          // Password
          _fieldLabel('PASSWORD (MIN 6 CHARACTERS) *', accentColor),
          const SizedBox(height: 6),
          Obx(
            () => TextField(
              controller: _passwordController,
              obscureText: _controller.obscurePassword.value,
              style: GoogleFonts.outfit(fontSize: 13),
              decoration: _inputDecoration('••••••••', Icons.lock_outline_rounded, primaryColor).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_controller.obscurePassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: const Color(0xFFA67C1E)),
                  onPressed: () => _controller.obscurePassword.toggle(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Confirm Password
          _fieldLabel('CONFIRM PASSWORD *', accentColor),
          const SizedBox(height: 6),
          Obx(
            () => TextField(
              controller: _confirmPasswordController,
              obscureText: _controller.obscureConfirmPassword.value,
              style: GoogleFonts.outfit(fontSize: 13),
              decoration: _inputDecoration('••••••••', Icons.lock_reset_rounded, primaryColor).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_controller.obscureConfirmPassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: const Color(0xFFA67C1E)),
                  onPressed: () => _controller.obscureConfirmPassword.toggle(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Optional Note
          _fieldLabel('NOTE FOR OWNER (OPTIONAL)', accentColor),
          const SizedBox(height: 6),
          _textField(controller: _noteController, hint: 'e.g. Morning pastry chef applicant', icon: Icons.edit_note_rounded, primaryColor: primaryColor),
          const SizedBox(height: 22),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _controller.isLoading.value
                  ? null
                  : () => _controller.handleSignUp(
                        name: _nameController.text,
                        email: _emailController.text,
                        password: _passwordController.text,
                        confirmPassword: _confirmPasswordController.text,
                        note: _noteController.text,
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF1E0F0A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
              child: Obx(
                () => _controller.isLoading.value
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E0F0A))))
                    : Text('SUBMIT FOR APPROVAL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Back to Login link
          Center(
            child: GestureDetector(
              onTap: () => Get.offAll(() => const LoginScreen()),
              child: Text(
                'Back to Sign In',
                style: GoogleFonts.outfit(color: const Color(0xFFA67C1E), fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleChoiceTab(UserRole role, String label, Color accentColor) {
    final selected = _controller.selectedRole.value == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => _controller.selectedRole.value = role,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.w500, color: selected ? const Color(0xFF1E0F0A) : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, Color accentColor) {
    return Row(
      children: [
        Container(width: 4, height: 4, decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.outfit(color: const Color(0xFFA67C1E), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _textField({required TextEditingController controller, required String hint, required IconData icon, required Color primaryColor}) {
    return TextField(
      controller: controller,
      style: GoogleFonts.outfit(fontSize: 13),
      decoration: _inputDecoration(hint, icon, primaryColor),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon, Color primaryColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: const Color(0xFFAA9B8F), fontSize: 12),
      prefixIcon: Icon(icon, color: const Color(0xFF9A8A7D), size: 18),
      filled: true,
      fillColor: const Color(0xFFF8F3EB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE3D6C6))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE3D6C6))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
    );
  }

  Widget _backgroundGlow(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [BoxShadow(color: color.withValues(alpha: opacity), blurRadius: size * .7, spreadRadius: size * .2)],
      ),
    );
  }
}
