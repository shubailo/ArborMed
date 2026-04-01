import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arbormed_core/arbormed_core.dart';
import '../../application/admin_service.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminService>().fetchUsersPerformance();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();

    return Scaffold(
      backgroundColor: CozyTheme.of(context).background,
      appBar: AppBar(
        title: const Text('User Management'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                adminService.fetchUsersPerformance(search: value);
              },
            ),
          ),
        ),
      ),
      body: adminService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: adminService.usersPerformance.length,
              itemBuilder: (context, index) {
                final user = adminService.usersPerformance[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user.email),
                  subtitle: Text('Last Activity: ${user.lastActivity?.toIso8601String() ?? 'Never'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Implement User Details Modal/Screen
                  },
                );
              },
            ),
    );
  }
}
