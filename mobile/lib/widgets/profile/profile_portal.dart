import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/stats_provider.dart';
import '../../theme/cozy_theme.dart';
import '../cozy/cozy_dialog_sheet.dart';
import '../cozy/cozy_tile.dart';
import 'activity_view.dart';

enum ProfileTab { profile, activity }

class ProfilePortal extends StatefulWidget {
  final Function(String name, String slug)? onSectionSelected;

  const ProfilePortal({super.key, this.onSectionSelected});

  @override
  createState() => _ProfilePortalState();
}

class _ProfilePortalState extends State<ProfilePortal> {
  ProfileTab _activeTab = ProfileTab.profile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).refreshUser();
      Provider.of<StatsProvider>(context, listen: false).fetchSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CozyDialogSheet(
      onTapOutside: () => Navigator.pop(context),
      child: Column(
        children: [
          const SizedBox(height: 10), // Small gap from handle
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _activeTab == ProfileTab.profile 
                ? _buildProfileContent() 
                : const ActivityView(),
            ),
          ),

          // Bottom Navigation
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (user == null) {
      return Center(child: CircularProgressIndicator(color: CozyTheme.of(context).primary));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Avatar & Identity Header
        Center(
          child: Column(
            children: [
              // Avatar Placeholder (Default Bean)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: CozyTheme.of(context).paperCream,
                  shape: BoxShape.circle,
                  border: Border.all(color: CozyTheme.of(context).primary, width: 4),
                  boxShadow: [BoxShadow(color: CozyTheme.of(context).textPrimary.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Icon(Icons.person_pin, size: 80, color: CozyTheme.of(context).primary),
              ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.displayName ?? user.username ?? 'Doctor',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: CozyTheme.of(context).textPrimary),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showChangeNicknameDialog(),
                      child: Icon(Icons.badge_outlined, size: 20, color: CozyTheme.of(context).primary),
                    ),
                  ],
                ),
                Text(
                  "@${user.username ?? 'doctor'}",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: CozyTheme.of(context).textSecondary),
                ),
              const SizedBox(height: 8),
              Text(
                "MEDICAL ID: #${user.id.toString().padLeft(3, '0')}",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: CozyTheme.of(context).textSecondary.withValues(alpha: 0.5), letterSpacing: 1.2),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Stats Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2, // Much smaller height
          children: [
            _buildStatTile("STREAK", user.streakCount.toString(), Icons.local_fire_department, CozyTheme.of(context).warning),
            _buildStatTile("XP", user.xp.toString(), Icons.bolt, CozyTheme.of(context).primary),
          ],
        ),

        const SizedBox(height: 32),

        // Settings Section
        const Text("ACCOUNT SETTINGS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF8D6E63))),
        const SizedBox(height: 12),
         const SizedBox(height: 12),
 
         CozyTile(
           onTap: () => _showChangePasswordDialog(),
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
           child: Row(
             children: [
               Icon(Icons.lock_outline, color: CozyTheme.of(context).textPrimary),
               const SizedBox(width: 12),
               Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold, color: CozyTheme.of(context).textPrimary)),
               const Spacer(),
               Icon(Icons.chevron_right, color: CozyTheme.of(context).textSecondary.withValues(alpha: 0.5)),
             ],
           ),
         ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return CozyTile(
      onTap: () {},
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: CozyTheme.of(context).textSecondary)),
            ],
          ),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: CozyTheme.of(context).textPrimary)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: _buildBottomButton(
              "Profile", 
              _activeTab == ProfileTab.profile, 
              () => setState(() => _activeTab = ProfileTab.profile)
            )
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildBottomButton(
              "Activity", 
              _activeTab == ProfileTab.activity, 
              () => setState(() => _activeTab = ProfileTab.activity)
            )
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(String label, bool active, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? CozyTheme.of(context).primary : CozyTheme.of(context).paperWhite,
        foregroundColor: active ? CozyTheme.of(context).textInverse : CozyTheme.of(context).primary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: active ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), 
          side: BorderSide(color: CozyTheme.of(context).primary)
        ),
      ),
      child: Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: CozyTheme.of(context).paperCream,
          title: Text("Change Password", style: TextStyle(fontWeight: FontWeight.w900, color: CozyTheme.of(context).textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Current Password", hintText: "Enter your current password"),
              ),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "New Password", hintText: "Enter your new password"),
              ),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirm New Password", hintText: "Repeat your new password"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CANCEL", style: TextStyle(color: CozyTheme.of(context).textSecondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (newController.text != confirmController.text) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New passwords do not match")));
                   return;
                }
                
                setDialogState(() => isSubmitting = true);
                try {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  await auth.apiService.post('/auth/change-password', {
                    'currentPassword': currentController.text,
                    'newPassword': newController.text,
                  });
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password changed successfully")));
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
                } finally {
                  setDialogState(() => isSubmitting = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: CozyTheme.of(context).primary),
              child: isSubmitting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text("UPDATE", style: TextStyle(fontWeight: FontWeight.bold, color: CozyTheme.of(context).textInverse)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeNicknameDialog() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final controller = TextEditingController(text: auth.user?.displayName);
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: CozyTheme.of(context).paperCream,
          title: Text("Change Nickname", style: TextStyle(fontWeight: FontWeight.w900, color: CozyTheme.of(context).textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("This name will be visible to other doctors in the Medical Network.", style: TextStyle(fontSize: 12, color: CozyTheme.of(context).textSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "New Nickname",
                  hintText: "Enter your nickname...",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CANCEL", style: TextStyle(color: CozyTheme.of(context).textSecondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (controller.text.trim().isEmpty) return;
                
                setDialogState(() => isSubmitting = true);
                try {
                  await auth.updateNickname(controller.text.trim());
                  await auth.updateNickname(controller.text.trim());
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nickname updated!")));
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
                } finally {
                  setDialogState(() => isSubmitting = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: CozyTheme.of(context).primary),
              child: isSubmitting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold, color: CozyTheme.of(context).textInverse)),
            ),
          ],
        ),
      ),
    );
  }
}
