import 'package:flutter/material.dart';
import '../../theme/cozy_theme.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';

class AdminScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final String activeRoute;
  final EdgeInsets? contentPadding;
  final bool showHeader;

  const AdminScaffold({
    Key? key,
    required this.title,
    required this.child,
    required this.activeRoute,
    this.contentPadding,
    this.showHeader = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CozyTheme.background,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 30),
                // Logo Area
                const Icon(Icons.school_rounded, size: 48, color: CozyTheme.primary),
                const SizedBox(height: 10),
                const Text(
                  "Teacher Portal",
                  style: TextStyle(fontFamily: 'Quicksand', fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                // Menu Items
                _AdminMenuItem(
                  icon: Icons.dashboard_rounded,
                  label: "Dashboard",
                  isActive: activeRoute == '/admin/dashboard',
                  onTap: () => Navigator.pushReplacementNamed(context, '/admin/dashboard'),
                ),
                _AdminMenuItem(
                  icon: Icons.question_answer_rounded,
                  label: "Questions",
                  isActive: activeRoute == '/admin/questions',
                  onTap: () => Navigator.pushReplacementNamed(context, '/admin/questions'),
                ),
                const Spacer(),
                
                // Exit
                _AdminMenuItem(
                  icon: Icons.exit_to_app_rounded,
                  label: "Back to App",
                  isActive: false,
                  onTap: () => Navigator.pushReplacementNamed(context, '/game'),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                if (showHeader)
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    alignment: Alignment.centerLeft,
                    color: Colors.white,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: CozyTheme.textPrimary
                      ),
                    ),
                  ),
                // Body
                Expanded(
                  child: Padding(
                    padding: contentPadding ?? const EdgeInsets.all(40),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _AdminMenuItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? CozyTheme.primary.withOpacity(0.1) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? CozyTheme.primary : Colors.grey[600],
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? CozyTheme.primary : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
