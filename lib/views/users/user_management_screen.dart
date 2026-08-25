import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import '../../controllers/user_management_controller.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branding_provider.dart';
import '../../theme/luxury_theme.dart';
import '../widgets/role_guard.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserManagementController());
    final branding = Provider.of<BrandingProvider>(context).branding;
    final primaryColor = branding.primaryColor;
    final accentColor = branding.accentColor;

    return RoleGuard(
      canAccess: (a) => a.permissions.canManageUsers,
      fallback: Scaffold(
        backgroundColor: LuxuryColors.cream,
        body: Center(child: Text("User Management Access Restricted to Bakery Owner.", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
      ),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return Scaffold(
            backgroundColor: LuxuryColors.cream,
            body: Column(
              children: [
                // Top Header Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [primaryColor, Color.alphaBlend(Colors.black38, primaryColor)]),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.5),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        CircleAvatar(backgroundColor: accentColor.withValues(alpha: 0.2), child: Icon(Icons.admin_panel_settings_rounded, color: accentColor)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Artisan Owner Control Center", style: GoogleFonts.playfairDisplay(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                              Text("Approve new user signups and assign permissions.", style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cloud_sync_rounded, color: Colors.white),
                          tooltip: "Sync Users from Cloud",
                          onPressed: () async {
                            await auth.syncUsersFromCloud();
                            Get.snackbar(
                              "Users Synced",
                              "Refreshed team accounts from Firebase Cloud!",
                              backgroundColor: primaryColor,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                              margin: const EdgeInsets.all(16),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

            // Tab Selector Pill
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x1F8D6E63)),
                ),
                child: Obx(() => Row(
                      children: [
                        _buildTabButton("Active Team (${auth.approvedUsers.length})", 0, controller, primaryColor),
                        _buildTabButton("Pending Approvals (${auth.pendingUsers.length})", 1, controller, primaryColor, badgeCount: auth.pendingCount),
                      ],
                    )),
              ),
            ),

            // Tab View Content
            Expanded(
              child: Obx(() {
                if (controller.selectedTab.value == 0) {
                  // Active Team
                  final users = auth.approvedUsers;
                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline_rounded, size: 50, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text("No active staff users yet.", style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14)),
                          const SizedBox(height: 6),
                          Text("Tap '+ Add Direct Staff' below to register team members.", style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isCurrent = user.id == auth.currentUser?.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x1F8D6E63))),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryColor,
                            child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user.name,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCurrent) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                  child: Text("YOU", style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: primaryColor)),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text("${user.email} • Role: ${user.role.displayName}", style: GoogleFonts.outfit(fontSize: 12, color: LuxuryColors.textSecondary)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButton<UserRole>(
                                value: user.role,
                                underline: const SizedBox(),
                                onChanged: isCurrent && user.role == UserRole.owner
                                    ? null
                                    : (newRole) {
                                        if (newRole != null) auth.updateUserRole(user.id, newRole);
                                      },
                                items: UserRole.values
                                    .map((r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(
                                            r.displayName,
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              fontWeight: r == user.role ? FontWeight.bold : FontWeight.normal,
                                              color: r == UserRole.owner ? primaryColor : Colors.black87,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                              if (!isCurrent) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
                                  tooltip: 'Delete User',
                                  onPressed: () => _confirmDeleteUser(context, user, auth, primaryColor),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  // Pending Approvals
                  final pending = auth.pendingUsers;
                  if (pending.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade600, size: 44),
                          const SizedBox(height: 10),
                          Text("No Pending Approvals", style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("All registration requests reviewed.", style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: pending.length,
                    itemBuilder: (context, index) {
                      final user = pending[index];
                      final dateStr = user.createdAt != null ? DateFormat("dd MMM, HH:mm").format(user.createdAt!) : "Recent";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.amber.shade300, width: 1.5),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(backgroundColor: Colors.amber.shade50, child: Icon(Icons.person_add_rounded, color: Colors.amber.shade900, size: 20)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user.name, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                                      Text("${user.email} • $dateStr", style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                                  child: Text("Req: ${user.role.displayName}", style: GoogleFonts.outfit(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 10)),
                                ),
                              ],
                            ),
                            if (user.note != null && user.note!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text("“${user.note}”", style: GoogleFonts.outfit(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.brown)),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => controller.showRejectDialog(user),
                                  style: OutlinedButton.styleFrom(minimumSize: const Size(80, 36), side: BorderSide(color: Colors.red.shade300)),
                                  child: const Text("Reject", style: TextStyle(color: Colors.red, fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => controller.showApproveDialog(user),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, minimumSize: const Size(120, 36)),
                                  child: const Text("Approve", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              }),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: null,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          onPressed: controller.showAddUserModal,
          icon: Icon(Icons.person_add_alt_1_rounded, color: accentColor),
          label: Text("Add Direct Staff", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      );
    },
  ),
);
}

  Widget _buildTabButton(String title, int index, UserManagementController controller, Color primaryColor, {int badgeCount = 0}) {
    final isSelected = controller.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectTab(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, UserModel user, AuthProvider auth, Color primaryColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 26),
            const SizedBox(width: 10),
            Text("Delete User Account?", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          "Are you sure you want to remove ${user.name} (${user.email}) from the bakery team?",
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.deleteUser(user.id);
              Get.snackbar("User Removed", "${user.name}'s account has been deleted.", backgroundColor: primaryColor, colorText: Colors.white);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            child: Text("Delete", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
