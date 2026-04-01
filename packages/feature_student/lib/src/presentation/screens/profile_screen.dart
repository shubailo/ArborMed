import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:core_interop/core_interop.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);
    final student = GetIt.I<StudentContract>();
    final auth = GetIt.I<AuthContract>();

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text('Medical Profile', style: theme.headingLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildProfileHeader(context, student),
            const SizedBox(height: 32),
            _buildProfileSection(context, 'Academic Resources', [
              _buildProfileItem(context, Icons.history_edu_rounded, 'Learning History'),
              _buildProfileItem(context, Icons.analytics_outlined, 'Detailed Performance'),
              _buildProfileItem(context, Icons.workspace_premium_rounded, 'Board Exam Readiness'),
            ]),
            const SizedBox(height: 24),
            _buildProfileSection(context, 'Account Settings', [
              _buildProfileItem(context, Icons.person_outline_rounded, 'Personal Details'),
              _buildProfileItem(context, Icons.lock_outline_rounded, 'Security & Privacy'),
              _buildProfileItem(context, Icons.notifications_none_rounded, 'Notifications'),
            ]),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () async {
                  await auth.logout();
                  // Router will handle redirect to /auth
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.accent),
                  foregroundColor: theme.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            Text('ArborMed v1.2.0-modular', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, StudentContract student) {
    final theme = CozyTheme.of(context);

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.primary, width: 2),
              ),
              child: const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: Icon(Icons.person_rounded, size: 80, color: Colors.grey),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primary,
                shape: BoxShape.circle,
                boxShadow: theme.shadowSmall,
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Medical Student',
          style: theme.headingLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Level ${student.getLevel()} Specialist',
          style: theme.bodyMedium.copyWith(color: theme.primary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProfileSection(BuildContext context, String title, List<Widget> items) {
    final theme = CozyTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(title, style: theme.headingSmall.copyWith(color: theme.textSecondary.withValues(alpha: 0.8))),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.paperWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: theme.shadowSmall,
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildProfileItem(BuildContext context, IconData icon, String title) {
    final theme = CozyTheme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.primary, size: 20),
      ),
      title: Text(title, style: theme.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right_rounded, color: theme.textSecondary.withValues(alpha: 0.5)),
      onTap: () {},
    );
  }
}
