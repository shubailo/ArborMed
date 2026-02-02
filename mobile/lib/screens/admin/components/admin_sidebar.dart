import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/cozy_theme.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final bool isExtended;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onToggle;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.isExtended,
    required this.onDestinationSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final width = isExtended ? 260.0 : 80.0;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
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
                    isExtended: isExtended,
                    onTap: () => onDestinationSelected(0),
                  ),
                  const SizedBox(height: 12),
                  _SidebarItem(
                    icon: Icons.question_answer_outlined,
                    activeIcon: Icons.question_answer_rounded,
                    label: "Questions",
                    isActive: selectedIndex == 1,
                    isExtended: isExtended,
                    onTap: () => onDestinationSelected(1),
                  ),
                  const SizedBox(height: 12),
                  _SidebarItem(
                    icon: Icons.people_outline,
                    activeIcon: Icons.people_rounded,
                    label: "Users",
                    isActive: selectedIndex == 3,
                    isExtended: isExtended,
                    onTap: () => onDestinationSelected(3),
                  ),
                  const SizedBox(height: 12),
                  _SidebarItem(
                    icon: Icons.format_quote_outlined,
                    activeIcon: Icons.format_quote_rounded,
                    label: "Quotes",
                    isActive: selectedIndex == 4,
                    isExtended: isExtended,
                    onTap: () => onDestinationSelected(4),
                  ),
                ],
              ),
            ),
          ),
          
          // 3. Footer Section (Collapse & Exit)
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          
          // Toggle Button
          _SidebarItem(
            icon: isExtended ? Icons.arrow_back_ios_new_rounded : Icons.menu_rounded,
            label: "Collapse",
            isActive: false,
            isExtended: isExtended,
            onTap: onToggle,
          ),
          
          const SizedBox(height: 8),
          
          // EXIT BUTTON (Functional)
          _SidebarItem(
            icon: Icons.logout_rounded,
            label: "Back to App",
            isActive: false,
            isExtended: isExtended,
            isDestructive: true,
            onTap: () {
              // Try pop first, then fallback to replacement if needed
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
    return AnimatedPadding(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: isExtended ? 24 : 12), // Minimum 12 for collapsed padding
      child: Row(
        mainAxisAlignment: isExtended ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
          ),
          if (isExtended) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "MedBuddy",
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "ADMIN PANEL",
                    style: GoogleFonts.quicksand(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final bool isExtended;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isExtended,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: Colors.white.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isExtended ? 16 : 0,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: isExtended ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? (activeIcon ?? icon) : icon,
                color: color,
                size: 24,
              ),
              if (isExtended) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
