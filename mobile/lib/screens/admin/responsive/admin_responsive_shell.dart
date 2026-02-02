import 'package:flutter/material.dart';
 import 'package:mobile/screens/admin/dashboard_screen.dart';
 import 'package:mobile/screens/admin/questions_screen.dart';
 import 'package:mobile/screens/admin/admin_quotes_screen.dart';
 import 'package:mobile/screens/admin/admin_users_screen.dart';
 import '../../../widgets/admin/admin_guard.dart';
import '../../../theme/cozy_theme.dart';
import '../components/admin_sidebar.dart';

class AdminResponsiveShell extends StatefulWidget {
  const AdminResponsiveShell({super.key});

  @override
  State<AdminResponsiveShell> createState() => _AdminResponsiveShellState();
}

class _AdminResponsiveShellState extends State<AdminResponsiveShell> {
  int _selectedIndex = 0;
  bool _isRailExtended = false; // Default to collapsed for more screen space

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminQuestionsScreen(),
    const AdminQuotesScreen(),
    const AdminUsersScreen(),
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      child: Scaffold(
        backgroundColor: CozyTheme.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return _buildDesktopLayout();
            } else {
              return _buildMobileLayout();
            }
          },
        ),
        bottomNavigationBar: MediaQuery.of(context).size.width <= 900
            ? NavigationBarTheme(
                data: NavigationBarThemeData(
                  indicatorColor: Colors.white.withValues(alpha: 0.1),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12);
                    }
                    return TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12);
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const IconThemeData(color: Colors.white, size: 26);
                    }
                    return IconThemeData(color: Colors.white.withValues(alpha: 0.7), size: 24);
                  }),
                ),
                child: NavigationBar(
                  backgroundColor: CozyTheme.textPrimary, // Brown for Mobile too
                  elevation: 10,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
                    NavigationDestination(icon: Icon(Icons.question_answer_outlined), selectedIcon: Icon(Icons.question_answer_rounded), label: 'Questions'),
                    NavigationDestination(icon: Icon(Icons.format_quote_outlined), selectedIcon: Icon(Icons.format_quote_rounded), label: 'Quotes'),
                    NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people_rounded), label: 'Users'),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        AdminSidebar(
          selectedIndex: _selectedIndex,
          isExtended: _isRailExtended,
          onDestinationSelected: _onDestinationSelected,
          onToggle: () => setState(() => _isRailExtended = !_isRailExtended),
        ),
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return IndexedStack(
      index: _selectedIndex,
      children: _screens,
    );
  }
}
