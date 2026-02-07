import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_provider.dart';
import '../../../services/theme_service.dart';
import '../../../theme/cozy_theme.dart';
import '../../../widgets/cozy/cozy_dialog_sheet.dart';

class AdminSettingsDialog extends StatelessWidget {
  const AdminSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    final themeService = Provider.of<ThemeService>(context);

    return CozyDialogSheet(
      onTapOutside: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Text(
                'Admin Settings',
                style: GoogleFonts.quicksand(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 1. Go to Game
            _buildOption(
              context,
              icon: Icons.videogame_asset_rounded,
              label: 'Go to Game',
              onTap: () {
                Navigator.of(context).pushReplacementNamed('/game');
              },
            ),
            const SizedBox(height: 16),

            // 2. Theme Toggle (3-Way)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: palette.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: palette.textSecondary.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(
                    themeService.themeMode == ThemeMode.system
                        ? Icons.brightness_auto_rounded
                        : (themeService.isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded),
                    color: palette.textPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Theme Mode',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  // 3-Way Toggle Group
                  Container(
                    decoration: BoxDecoration(
                      color: palette.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: palette.textSecondary.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildThemeButton(
                          context,
                          'Auto',
                          themeService.themeMode == ThemeMode.system,
                          () {
                            themeService.setThemeMode(ThemeMode.system);
                          },
                        ),
                        _buildThemeButton(
                          context,
                          'Light',
                          themeService.themeMode == ThemeMode.light,
                          () {
                            themeService.setThemeMode(ThemeMode.light);
                          },
                        ),
                        _buildThemeButton(
                          context,
                          'Dark',
                          themeService.themeMode == ThemeMode.dark,
                          () {
                            themeService.setThemeMode(ThemeMode.dark);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Sign Out (Destructive)
            _buildOption(
              context,
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              isDestructive: true,
              onTap: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final palette = CozyTheme.of(context);
    final color = isDestructive ? palette.error : palette.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: palette.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDestructive
                ? palette.error.withValues(alpha: 0.2)
                : palette.textSecondary.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeButton(
      BuildContext context, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: isSelected ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? CozyTheme.of(context).primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color:
                isSelected ? Colors.white : CozyTheme.of(context).textSecondary,
          ),
        ),
      ),
    );
  }
}
