import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/cozy_theme.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    const width = 80.0;
    
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: CozyTheme.textPrimary, // Premium Deep Brown Background
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(4, 0),
          )
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          
          // 1. Logo Section
          _buildLogo(),
          
          const SizedBox(height: 48),
          
          // 2. Navigation Items
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _SidebarItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: "Dashboard",
                    isActive: selectedIndex == 0,
                    onTap: () => onDestinationSelected(0),
                  ),
                  const SizedBox(height: 12),
                  _SidebarItem(
                    icon: Icons.question_answer_outlined,
                    activeIcon: Icons.question_answer_rounded,
                    label: "Questions",
                    isActive: selectedIndex == 1,
                    onTap: () => onDestinationSelected(1),
                  ),
                  const SizedBox(height: 12),
                  _SidebarItem(
                    icon: Icons.people_outline,
                    activeIcon: Icons.people_rounded,
                    label: "Users",
                    isActive: selectedIndex == 2,
                    onTap: () => onDestinationSelected(2),
                  ),
                  const SizedBox(height: 12),
                  _SidebarItem(
                    icon: Icons.format_quote_outlined,
                    activeIcon: Icons.format_quote_rounded,
                    label: "Quotes",
                    isActive: selectedIndex == 3,
                    onTap: () => onDestinationSelected(3),
                  ),
                ],
              ),
            ),
          ),
          
          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 16),
          
          // EXIT BUTTON (Functional)
          _SidebarItem(
            icon: Icons.logout_rounded,
            label: "Back to App",
            isActive: false,
            isDestructive: true,
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                 Navigator.pushReplacementNamed(context, '/game');
              }
            },
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.activeIcon,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isActive 
        ? Colors.white
        : (isDestructive ? Colors.red.shade200 : Colors.white.withValues(alpha: 0.7));
        
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          hoverColor: Colors.white.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                isActive ? (activeIcon ?? icon) : icon,
                color: color,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
