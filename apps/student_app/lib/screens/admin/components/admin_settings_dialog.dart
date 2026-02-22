import 'package:flutter/material.dart';
import '../../../generated/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../services/audio_provider.dart';
import '../../../services/auth_provider.dart';
import '../../../services/locale_provider.dart';
import '../../../services/theme_service.dart';
import '../../../widgets/cozy/cozy_dialog_sheet.dart';
import '../../../widgets/cozy/liquid_button.dart';
import '../../../theme/cozy_theme.dart';

class AdminSettingsDialog extends StatefulWidget {
  const AdminSettingsDialog({super.key});

  @override
  State<AdminSettingsDialog> createState() => _AdminSettingsDialogState();
}

class _AdminSettingsDialogState extends State<AdminSettingsDialog> {
  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);

    return CozyDialogSheet(
      onTapOutside: () {
        Provider.of<AudioProvider>(context, listen: false).playSfx('click');
        Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.adminSettings,
                style: GoogleFonts.quicksand(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: palette.textPrimary,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          // Content Wrapper
          Flexible(
            child: _buildMainSettings(),
          ),

          // Bottom Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Expanded(
                  child: LiquidButton(
                    onPressed: () {
                      Provider.of<AudioProvider>(context, listen: false)
                          .playSfx('click');
                      Navigator.pop(context); // Close dialog
                      Navigator.of(context).pushReplacementNamed('/game');
                    },
                    label: AppLocalizations.of(context)!.adminGoToGame,
                    variant: LiquidButtonVariant.primary,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: LiquidButton(
                    onPressed: () async {
                      Provider.of<AudioProvider>(context, listen: false)
                          .playSfx('click');
                      final auth =
                          Provider.of<AuthProvider>(context, listen: false);
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    },
                    label: AppLocalizations.of(context)!.signOut.toUpperCase(),
                    variant: LiquidButtonVariant.destructive,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSettings() {
    final palette = CozyTheme.of(context);
    return Consumer2<AudioProvider, ThemeService>(
      builder: (context, audio, themeService, child) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _buildSettingTile(Icons.notifications_none_rounded,
                AppLocalizations.of(context)!.notifications, "On"),

            // SFX Toggle
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: palette.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: palette.textPrimary.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Icon(
                      audio.isSfxMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: palette.secondary,
                      size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Text(AppLocalizations.of(context)!.soundEffects,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary))),
                  Switch(
                    value: !audio.isSfxMuted,
                    activeThumbColor: palette.primary,
                    activeTrackColor: palette.primary.withValues(alpha: 0.2),
                    onChanged: (val) {
                      if (val) {
                        audio.playSfx('success');
                      }
                      audio.toggleSfx(val);
                    },
                  ),
                ],
              ),
            ),

            // Theme Toggle
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: palette.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: palette.textPrimary.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Icon(
                      themeService.isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: palette.secondary,
                      size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.themeMode,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary),
                    ),
                  ),

                  // Toggle Group
                  Container(
                    decoration: BoxDecoration(
                      color: palette.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: palette.textPrimary.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLanguageButton(
                          context,
                          AppLocalizations.of(context)!.themeLight,
                          themeService.themeMode == ThemeMode.light,
                          () {
                            audio.playSfx('click');
                            themeService.setThemeMode(ThemeMode.light);
                          },
                        ),
                        _buildLanguageButton(
                          context,
                          AppLocalizations.of(context)!.themeDark,
                          themeService.themeMode == ThemeMode.dark,
                          () {
                            audio.playSfx('click');
                            themeService.setThemeMode(ThemeMode.dark);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Language Selector
            Consumer<LocaleProvider>(
              builder: (context, localeProvider, child) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: palette.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: palette.textPrimary.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.language_rounded,
                          color: palette.textSecondary, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.language,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary),
                        ),
                      ),
                      // Language Toggle Buttons
                      Container(
                        decoration: BoxDecoration(
                          color: palette.surface.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: palette.textPrimary.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLanguageButton(
                              context,
                              'EN',
                              localeProvider.locale.languageCode == 'en',
                              () {
                                audio.playSfx('click');
                                localeProvider.setLocale(const Locale('en'));
                              },
                            ),
                            _buildLanguageButton(
                              context,
                              'HU',
                              localeProvider.locale.languageCode == 'hu',
                              () {
                                audio.playSfx('click');
                                localeProvider.setLocale(const Locale('hu'));
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String value,
      {VoidCallback? onTap}) {
    final palette = CozyTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: palette.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: palette.textPrimary.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: palette.textSecondary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: palette.textPrimary),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                  color: palette.primary, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: palette.textSecondary.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(
      BuildContext context, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: isSelected ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? CozyTheme.of(context).primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : CozyTheme.of(context).secondary,
          ),
        ),
      ),
    );
  }
}
