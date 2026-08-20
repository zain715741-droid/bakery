import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branding_provider.dart';
import '../../models/user_model.dart';
import '../shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'owner@bakery.co.uk');
  final _passwordController = TextEditingController(text: 'bakery123');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();

    // Find matching user or fallback to owner
    final matchedUser = auth.allUsers.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => UserModel(
        id: 'u_logged_in',
        email: email.isNotEmpty ? email : 'owner@bakery.co.uk',
        name: 'Bakery User',
        role: UserRole.owner,
      ),
    );

    auth.loginAsUser(matchedUser);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ShellScreen()),
    );
  }

  void _showPasswordResetDialog() {
    final resetController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Password Reset"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enter your registered email address to receive reset instructions."),
            const SizedBox(height: 12),
            TextField(
              controller: resetController,
              decoration: const InputDecoration(
                labelText: "Email Address",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Password reset email sent to ${resetController.text.isEmpty ? 'your email' : resetController.text}"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Send Link"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branding = Provider.of<BrandingProvider>(context).branding;
    final primaryColor = branding.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Business Logo / Icon Header
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bakery_dining_rounded,
                          size: 40,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        branding.businessName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        branding.welcomeMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 28),

                      // Quick Demo Role Switcher Tabs
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Quick Role Demo Login:",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildRoleChip(UserRole.owner, "Owner (Full)", auth),
                                  const SizedBox(width: 6),
                                  _buildRoleChip(UserRole.manager, "Manager", auth),
                                  const SizedBox(width: 6),
                                  _buildRoleChip(UserRole.staff, "Staff", auth),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),

                      // Credentials Form
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: "Username or Email",
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showPasswordResetDialog,
                          child: const Text("Forgot Password?"),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: const Text(
                            "Sign In to Bakery App",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(UserRole role, String label, AuthProvider auth) {
    final isSelected = auth.currentRole == role;
    final primaryColor = Provider.of<BrandingProvider>(context).branding.primaryColor;

    return Expanded(
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
        selected: isSelected,
        selectedColor: primaryColor,
        backgroundColor: Colors.grey.shade200,
        onSelected: (selected) {
          if (selected) {
            auth.switchRole(role);
            if (role == UserRole.owner) {
              _emailController.text = 'owner@bakery.co.uk';
            } else if (role == UserRole.manager) {
              _emailController.text = 'manager@bakery.co.uk';
            } else {
              _emailController.text = 'staff@bakery.co.uk';
            }
          }
        },
      ),
    );
  }
}
