import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:go_router/go_router.dart';
import '../../application/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminService>().fetchAdminSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();

    return Scaffold(
      backgroundColor: CozyTheme.of(context).background,
      appBar: AppBar(
        title: Text('Admin Console', 
          style: TextStyle(
            color: CozyTheme.of(context).textPrimary, 
            fontWeight: FontWeight.bold
          )
        ),
        backgroundColor: CozyTheme.of(context).surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: adminService.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatBanner(context, adminService),
                const SizedBox(height: 32),
                Text('Management', 
                  style: CozyTheme.of(context).headingMedium
                ),
                const SizedBox(height: 16),
                _buildAdminMenu(context),
              ],
            ),
          ),
    );
  }

  Widget _buildStatBanner(BuildContext context, AdminService service) {
    final stats = service.adminSummary;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CozyTheme.of(context).primary,
            CozyTheme.of(context).primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CozyTheme.of(context).primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Students', 
            value: _getStatValue(stats, 'total_students', '0')
          ),
          _StatItem(
            label: 'Questions', 
            value: _getStatValue(stats, 'total_questions', '0')
          ),
          _StatItem(
            label: 'Reports', 
            value: _getStatValue(stats, 'pending_reports', '0')
          ),
        ],
      ),
    );
  }

  String _getStatValue(List<Map<String, dynamic>> stats, String key, String defaultValue) {
    if (stats.isEmpty) return defaultValue;
    final item = stats.firstWhere((s) => s['key'] == key, orElse: () => {'value': defaultValue});
    return item['value'].toString();
  }

  Widget _buildAdminMenu(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _AdminMenuItem(
          icon: Icons.people_rounded, 
          label: 'Users', 
          subtitle: 'Manage & Roles',
          onTap: () => context.push('/admin/users'),
        ),
        _AdminMenuItem(
          icon: Icons.quiz_rounded, 
          label: 'CMS', 
          subtitle: 'Content Library',
          onTap: () => context.push('/admin/questions'),
        ),
        _AdminMenuItem(
          icon: Icons.analytics_rounded, 
          label: 'Analytics', 
          subtitle: 'System Health',
          onTap: () => context.push('/admin/analytics'),
        ),
        _AdminMenuItem(
          icon: Icons.monitor_heart_rounded, 
          label: 'ECG Labs', 
          subtitle: 'Manage Cases',
          onTap: () => context.push('/admin/ecg'),
        ),
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
        Text(value, 
          style: const TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
            color: Colors.white
          )
        ),
        const SizedBox(height: 4),
        Text(label, 
          style: TextStyle(
            fontSize: 13, 
            color: Colors.white.withValues(alpha: 0.8)
          )
        ),
      ],
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminMenuItem({
    required this.icon, 
    required this.label, 
    required this.subtitle,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CozyTheme.of(context).surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: CozyTheme.of(context).divider.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CozyTheme.of(context).primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: CozyTheme.of(context).primary),
            ),
            const SizedBox(height: 12),
            Text(label, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 16,
                color: CozyTheme.of(context).textPrimary
              )
            ),
            const SizedBox(height: 2),
            Text(subtitle, 
              style: TextStyle(
                fontSize: 12,
                color: CozyTheme.of(context).textSecondary
              )
            ),
          ],
        ),
      ),
    );
  }
}
