import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/stats_provider.dart';
import '../cozy/cozy_dialog_sheet.dart';
import '../cozy/cozy_tile.dart';
import 'activity_view.dart';

enum ProfileTab { profile, activity }

class ProfilePortal extends StatefulWidget {
  final Function(String name, String slug)? onSectionSelected;

  const ProfilePortal({Key? key, this.onSectionSelected}) : super(key: key);

  @override
  _ProfilePortalState createState() => _ProfilePortalState();
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFF8CAA8C)));
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
                  color: const Color(0xFFEFEBE9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF8CAA8C), width: 4),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: const Icon(Icons.person_pin, size: 80, color: Color(0xFF8CAA8C)),
              ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.displayName ?? user.username ?? 'Doctor',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF5D4037)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showChangeNicknameDialog(),
                      child: const Icon(Icons.badge_outlined, size: 20, color: Color(0xFF8CAA8C)),
                    ),
                  ],
                ),
                Text(
                  "@${user.username ?? 'doctor'}",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF8D6E63)),
                ),
              const SizedBox(height: 8),
              Text(
                "MEDICAL ID: #${user.id.toString().padLeft(3, '0')}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFB0BEC5), letterSpacing: 1.2),
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
            _buildStatTile("STREAK", user.streakCount.toString(), Icons.local_fire_department, Colors.orange),
            _buildStatTile("XP", user.xp.toString(), Icons.bolt, Colors.yellow[700]!),
          ],
        ),

        const SizedBox(height: 32),

        // Settings Section
        const Text("ACCOUNT SETTINGS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFB0BEC5))),
        const SizedBox(height: 12),
         const SizedBox(height: 12),
 
         CozyTile(
           onTap: () => _showChangePasswordDialog(),
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
           child: Row(
             children: const [
               Icon(Icons.lock_outline, color: Color(0xFF5D4037)),
               SizedBox(width: 12),
               Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
               Spacer(),
               Icon(Icons.chevron_right, color: Color(0xFFB0BEC5)),
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
              Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFB0BEC5))),
            ],
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF5D4037))),
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
        backgroundColor: active ? const Color(0xFF8CAA8C) : Colors.white,
        foregroundColor: active ? Colors.white : const Color(0xFF8CAA8C),
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: active ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), 
          side: const BorderSide(color: Color(0xFF8CAA8C))
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
          backgroundColor: const Color(0xFFFFFDF5),
          title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF5D4037))),
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
              child: const Text("CANCEL", style: TextStyle(color: Color(0xFFB0BEC5), fontWeight: FontWeight.bold)),
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
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password changed successfully")));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
                } finally {
                  setDialogState(() => isSubmitting = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8CAA8C)),
              child: isSubmitting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("UPDATE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
          backgroundColor: const Color(0xFFFFFDF5),
          title: const Text("Change Nickname", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF5D4037))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("This name will be visible to other doctors in the Medical Network.", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
              child: const Text("CANCEL", style: TextStyle(color: Color(0xFFB0BEC5), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (controller.text.trim().isEmpty) return;
                
                setDialogState(() => isSubmitting = true);
                try {
                  await auth.updateNickname(controller.text.trim());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nickname updated!")));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
                } finally {
                  setDialogState(() => isSubmitting = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8CAA8C)),
              child: isSubmitting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
