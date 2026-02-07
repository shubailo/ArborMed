import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/theme_service.dart';
import '../../../theme/cozy_theme.dart';
import '../../../widgets/cozy/paper_texture.dart';
import 'admin_settings_dialog.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const double _itemHeight = 56.0;
  static const double _itemTotalHeight = 68.0;

  @override
  Widget build(BuildContext context) {
    const width = 84.0;
    final palette = CozyTheme.of(context);
    
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Provider.of<ThemeService>(context).isDark ? palette.surface : palette.textPrimary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 32,
            offset: const Offset(4, 0),
          )
        ],
      ),
      child: PaperTexture(
        grainColor: Colors.white,
        opacity: 0.03,
        child: Column(
          children: [
            const SizedBox(height: 32),
            
            // 1. Logo Section
            _buildLogo(palette),
            
            const SizedBox(height: 48),
            
            // 2. Navigation Items
            Expanded(
              child: SingleChildScrollView(
                child: Stack(
                  children: [
                    // Animated Indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.fastLinearToSlowEaseIn,
                      left: 0,
                      top: (_itemHeight - 32) / 2 + (selectedIndex * _itemTotalHeight),
                      child: Container(
                        width: 4,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 10),
                          ],
                        ),
                      ),
                    ),                    
                    Column(
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
                  ],
                ),
              ),
            ),
            
            const Divider(height: 1, color: Colors.white10),
            const SizedBox(height: 16),
            
            // SETTINGS BUTTON
            _SidebarItem(
              icon: Icons.settings_rounded,
              label: "Settings",
              isActive: false,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const AdminSettingsDialog(),
                );
              },
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(CozyPalette palette) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.white10, blurRadius: 8),
              ],
            ),
          ),
          const Icon(Icons.school_rounded, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.activeIcon,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.isActive 
        ? Colors.white
        : Colors.white.withValues(alpha: _isHovered ? 0.9 : 0.6);
        
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Tooltip(
        message: widget.label,
        child: MouseRegion(
          onEnter: (_) {
            setState(() => _isHovered = true);
            _anim.forward();
          },
          onExit: (_) {
            setState(() => _isHovered = false);
            _anim.reverse();
          },
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: widget.isActive 
                  ? Colors.white.withValues(alpha: 0.1) 
                  : (_isHovered ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isActive ? Colors.white24 : Colors.transparent,
                  width: 1,
                ),
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.1).animate(_anim),
                child: Center(
                  child: Icon(
                    widget.isActive ? (widget.activeIcon ?? widget.icon) : widget.icon,
                    color: color,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
