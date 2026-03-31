import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core_interop/core_interop.dart';
import 'package:get_it/get_it.dart';
import 'package:feature_admin/src/application/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AuthContract _auth;

  @override
  void initState() {
    super.initState();
    _auth = GetIt.I<AuthContract>();
    if (_auth.userRole == 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AdminService>().fetchQuestions();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.userRole != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('You do not have permission to view the Admin Dashboard.',
              style: TextStyle(color: Colors.red, fontSize: 16)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin CMS'),
        centerTitle: true,
      ),
      body: Consumer<AdminService>(
        builder: (context, service, _) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return const Center(
            child: Text('Admin Control Panel. Questions functionality pending...'),
          );
        },
      ),
    );
  }
}
