import 'package:flutter/material.dart';
import '../../widgets/admin/admin_scaffold.dart';
import '../../widgets/admin/admin_guard.dart';
import 'dashboard_screen.dart';
import 'questions_screen.dart';
import 'admin_quotes_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminQuestionsScreen(),
    const AdminQuotesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      child: AdminScaffold(
        title: _selectedIndex == 0 ? "Dashboard" : (_selectedIndex == 1 ? "Questions" : "Quotes"),
        showHeader: false, // Removed header as requested
        selectedIndex: _selectedIndex,
        onNavigationChanged: (index) {
          setState(() => _selectedIndex = index);
        },
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
    );
  }
}
