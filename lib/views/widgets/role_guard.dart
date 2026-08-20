import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RoleGuard extends StatelessWidget {
  final bool Function(AuthProvider auth) canAccess;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.canAccess,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (canAccess(auth)) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
