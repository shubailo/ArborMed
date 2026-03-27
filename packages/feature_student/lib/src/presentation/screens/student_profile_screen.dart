import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArborColors.background,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: ArborColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: ArborColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ArborColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: ArborColors.primary,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 15),
            const Text(
              'John Doe',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ArborColors.textPrimary),
            ),
            const Text(
              'Medical Student • Year 3',
              style: TextStyle(color: ArborColors.textSecondary),
            ),
            const SizedBox(height: 30),
            _buildProfileSection('Account Settings', [
              _buildProfileItem(Icons.person_outline, 'Personal Information'),
              _buildProfileItem(Icons.email_outlined, 'Email Notifications'),
              _buildProfileItem(Icons.lock_outline, 'Change Password'),
            ]),
            const SizedBox(height: 20),
            _buildProfileSection('Learning', [
              _buildProfileItem(Icons.history_outlined, 'Learning History'),
              _buildProfileItem(Icons.bookmark_border_outlined, 'Saved Resources'),
              _buildProfileItem(Icons.star_outline, 'Achievements'),
            ]),
            const SizedBox(height: 30),
            ArborButton(
              text: 'Log Out',
              onPressed: () {},
              type: ArborButtonType.outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ArborColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: ArborColors.surface,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: ArborColors.primary),
      title: Text(title, style: const TextStyle(color: ArborColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: ArborColors.textSecondary),
      onTap: () {},
    );
  }
}
