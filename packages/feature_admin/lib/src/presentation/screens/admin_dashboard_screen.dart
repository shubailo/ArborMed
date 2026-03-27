import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArborColors.background,
      appBar: AppBar(
        title: const Text('Admin Console', style: TextStyle(color: ArborColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: ArborColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatBanner(),
            const SizedBox(height: 25),
            _buildAdminMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ArborColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Total Users', value: '1,284'),
          _StatItem(label: 'Active Quizzes', value: '42'),
          _StatItem(label: 'Pending Reviews', value: '12'),
        ],
      ),
    );
  }

  Widget _buildAdminMenu(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _AdminMenuItem(icon: Icons.people_outline, label: 'User Management', onTap: () {}),
        _AdminMenuItem(icon: Icons.quiz_outlined, label: 'Manage Quizzes', onTap: () {}),
        _AdminMenuItem(icon: Icons.analytics_outlined, label: 'System Analytics', onTap: () {}),
        _AdminMenuItem(icon: Icons.settings_outlined, label: 'System Settings', onTap: () {}),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AdminMenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: ArborColors.surface,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: ArborColors.primary),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: ArborColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
