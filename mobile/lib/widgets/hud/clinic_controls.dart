import 'package:flutter/material.dart';
import '../../theme/cozy_theme.dart';

class ClinicControls extends StatelessWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onDecorateTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onFocusTap;

  const ClinicControls({
    super.key,
    required this.onProfileTap,
    required this.onDecorateTap,
    required this.onSettingsTap,
    required this.onFocusTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bottom Left: Profile (Big Circle)
          _buildCozyButton(
            context: context,
            icon: Icons.person_rounded,
            color: CozyTheme.of(context).primary,
            size: 64,
            iconSize: 32,
            onTap: onProfileTap,
            heroTag: "profile_btn",
          ),

          // Bottom Right: Stacked Buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Decorate (Accent Color, slightly smaller)
              _buildCozyButton(
                context: context,
                icon: Icons.brush_rounded,
                color: CozyTheme.of(context).secondary,
                size: 56,
                iconSize: 28,
                onTap: onDecorateTap,
                heroTag: "decorate_btn",
                tooltip: "Decorate Room",
              ),
              const SizedBox(height: 16),
              
              // Settings (Secondary Color)
              _buildCozyButton(
                context: context,
                icon: Icons.settings_rounded,
                color: CozyTheme.of(context).textSecondary,
                size: 56,
                iconSize: 28,
                onTap: onSettingsTap,
                heroTag: "settings_btn",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCozyButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required double size,
    required double iconSize,
    required VoidCallback onTap,
    required String heroTag,
    String? tooltip,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onTap,
        backgroundColor: color,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tooltip: tooltip,
        child: Icon(icon, size: iconSize, color: Colors.white),
      ),
    );
  }
}
