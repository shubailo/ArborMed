import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/cozy_theme.dart';

class AdminScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onNavigationChanged;
  final bool showHeader;
  final EdgeInsets? contentPadding;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.selectedIndex,
    required this.onNavigationChanged,
    this.showHeader = true,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CozyTheme.of(context).background,
      body: Stack(
        children: [
          // 1. Main Content (Padded to make room for sidebar)
          Padding(
            padding: const EdgeInsets.only(left: 260),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                if (showHeader)
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    alignment: Alignment.centerLeft,
                    color: CozyTheme.of(context).paperWhite,
                    child: Text(
                      title,
                      style: GoogleFonts.quicksand(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: CozyTheme.of(context).textPrimary
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

          // 2. Sidebar (Fixed Left, High Z-Index for Shadow)
          Positioned(
            left: 0, top: 0, bottom: 0,
            width: 260,
            child: Container(
              decoration: BoxDecoration(
                color: CozyTheme.of(context).paperWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(4, 0),
                  )
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Logo Area
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: CozyTheme.of(context).primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.school_rounded, size: 32, color: CozyTheme.of(context).primary),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "MedBuddy",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: CozyTheme.of(context).textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 24),
                     child: Text("TEACHER PORTAL", style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                  const SizedBox(height: 32),

                  // Menu Items
                  _AdminMenuItem(
                    icon: Icons.dashboard_rounded,
                    label: "Dashboard",
                    isActive: selectedIndex == 0,
                    onTap: () => onNavigationChanged(0),
                  ),
                  const SizedBox(height: 8),
                  _AdminMenuItem(
                    icon: Icons.question_answer_rounded,
                    label: "Questions",
                    isActive: selectedIndex == 1,
                    onTap: () => onNavigationChanged(1),
                  ),
                  const SizedBox(height: 8),
                  _AdminMenuItem(
                    icon: Icons.format_quote_rounded,
                    label: "Quotes",
                    isActive: selectedIndex == 2,
                    onTap: () => onNavigationChanged(2),
                  ),
                  const Spacer(),
                  
                  // Exit
                  const Divider(height: 32),
                  _AdminMenuItem(
                    icon: Icons.exit_to_app_rounded,
                    label: "Return to App",
                    isActive: false,
                    onTap: () => Navigator.pushReplacementNamed(context, '/game'),
                    isDestructive: true,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
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
  final bool isDestructive;

  const _AdminMenuItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine visuals
    final Color bgColor = isActive ? CozyTheme.of(context).primary.withValues(alpha: 0.08) : Colors.transparent;
    final Color textColor = isActive 
        ? CozyTheme.of(context).primary 
        : (isDestructive ? Colors.red.shade400 : Colors.grey[700]!);
    final Color iconColor = isActive 
        ? CozyTheme.of(context).primary 
        : (isDestructive ? Colors.red.shade300 : Colors.grey[500]!);
    final FontWeight weight = isActive ? FontWeight.w700 : FontWeight.w500;
    
    // Left Border for active state
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.grey.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 14),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: weight,
                      color: textColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                if (isActive) ...[
                   const Spacer(),
                   Container(
                     width: 6, height: 6,
                     decoration: BoxDecoration(shape: BoxShape.circle, color: CozyTheme.of(context).primary),
                   )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
