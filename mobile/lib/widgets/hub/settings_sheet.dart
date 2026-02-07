import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/audio_provider.dart';
import '../../services/auth_provider.dart';
import '../../services/locale_provider.dart';
import '../../services/theme_service.dart'; // 🎨 Theme Service
import '../cozy/cozy_dialog_sheet.dart';
import '../../theme/cozy_theme.dart';

enum SettingsView { main, about }

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  SettingsView _view = SettingsView.main;

  void _setView(SettingsView view) {
    setState(() {
      _view = view;
    });
  }

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
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_view == SettingsView.about)
                  Positioned(
                    left: 0,
                    child: GestureDetector(
                      onTap: () {
                        Provider.of<AudioProvider>(context, listen: false).playSfx('click');
                        _setView(SettingsView.main);
                      },
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: palette.textSecondary, size: 20),
                    ),
                  ),
                Center(
                  child: Text(
                    _view == SettingsView.main ? AppLocalizations.of(context)!.settingsTitle : AppLocalizations.of(context)!.aboutApp,
                    style: GoogleFonts.quicksand(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: palette.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Wrapper with AnimatedSwitcher
          // Content Wrapper with AnimatedSwitcher
          // Content Wrapper with AnimatedSwitcher
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: _view == SettingsView.main ? const Offset(-0.1, 0) : const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey(_view),
                child: _view == SettingsView.main ? _buildMainSettings() : _buildAboutContent(),
              ),
            ),
          ),

          // Sign Out & Admin Button (Only in Main Settings)
          if (_view == SettingsView.main)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final isAdmin = auth.user?.role == 'admin';
                  return Row(
                    children: [
                      if (isAdmin) ...[
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CozyTheme.of(context).primary.withValues(alpha: 0.1),
                              foregroundColor: CozyTheme.of(context).primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16), 
                                side: BorderSide(color: CozyTheme.of(context).primary.withValues(alpha: 0.2)),
                              ),
                            ),
                            onPressed: () {
                              Provider.of<AudioProvider>(context, listen: false).playSfx('click');
                              Navigator.pop(context); // Close settings
                              Navigator.of(context).pushNamed('/admin');
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(AppLocalizations.of(context)!.adminPanel, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CozyTheme.of(context).error.withValues(alpha: 0.1),
                            foregroundColor: CozyTheme.of(context).error,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16), 
                              side: BorderSide(color: CozyTheme.of(context).error.withValues(alpha: 0.2)),
                            ),
                          ),
                          onPressed: () {
                            Provider.of<AudioProvider>(context, listen: false).playSfx('click');
                            auth.logout();
                            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(AppLocalizations.of(context)!.signOut, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              ),
            ),
          if (_view == SettingsView.about) const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMainSettings() {
    final palette = CozyTheme.of(context);
    return Consumer2<AudioProvider, ThemeService>(
      builder: (context, audio, themeService, child) {
        return ListView(
          // shrinkWrap: true, 

          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _buildSettingTile(Icons.notifications_none_rounded, AppLocalizations.of(context)!.notifications, "On"),
            
            // Music Volume Slider
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: palette.paperWhite.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.textPrimary.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(audio.isMusicMuted ? Icons.music_off_rounded : Icons.music_note_rounded, color: palette.secondary, size: 24),
                      const SizedBox(width: 16),
                      Expanded(child: Text(AppLocalizations.of(context)!.musicVolume, style: TextStyle(fontWeight: FontWeight.bold, color: palette.textPrimary))),
                      Switch(
                        value: !audio.isMusicMuted,
                        activeThumbColor: palette.primary,
                        activeTrackColor: palette.primary.withValues(alpha: 0.2),
                        onChanged: (val) {
                          audio.playSfx('click');
                          audio.toggleMusic(val); 
                        },
                      ),
                    ],
                  ),
                  if (!audio.isMusicMuted)
                    Slider(
                      value: audio.musicVolume,
                      activeColor: palette.primary,
                      inactiveColor: palette.primary.withValues(alpha: 0.3),
                      onChanged: (val) => audio.setMusicVolume(val),
                    ),
                ],
              ),
            ),

            // Music Selection (Roll Down Accordion)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: CozyTheme.of(context).surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CozyTheme.of(context).textPrimary.withValues(alpha: 0.05)),
                ),
                child: ExpansionTile(
                  shape: const RoundedRectangleBorder(side: BorderSide.none),
                  collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                  iconColor: palette.primary,
                  leading: Icon(Icons.library_music_rounded, color: palette.secondary, size: 24),
                  title: Text(
                    AppLocalizations.of(context)!.selectTrack,
                    style: TextStyle(fontWeight: FontWeight.bold, color: palette.textPrimary),
                  ),
                  subtitle: Text(
                    audio.tracks.firstWhere((t) => t['path'] == audio.currentTrackPath)['name'] ?? "None",
                    style: TextStyle(color: palette.primary, fontSize: 12),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        children: audio.tracks.map((track) {
                          final isSelected = audio.currentTrackPath == track['path'];
                          return GestureDetector(
                            onTap: () {
                              audio.playSfx('click');
                              audio.changeTrack(track['path']!);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? CozyTheme.of(context).primary.withValues(alpha: 0.1) : CozyTheme.of(context).surface.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSelected ? CozyTheme.of(context).primary : Colors.transparent),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.audiotrack_rounded, size: 16, color: isSelected ? CozyTheme.of(context).primary : Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      track['name']!,
                                      style: TextStyle(
                                        color: isSelected ? palette.primary : palette.textPrimary,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isSelected) Icon(Icons.check_circle_rounded, size: 16, color: palette.primary),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // SFX Toggle
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
              decoration: BoxDecoration(
                color: CozyTheme.of(context).surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CozyTheme.of(context).textPrimary.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Icon(audio.isSfxMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: CozyTheme.of(context).secondary, size: 24),
                  const SizedBox(width: 16),
                  Expanded(child: Text(AppLocalizations.of(context)!.soundEffects, style: TextStyle(fontWeight: FontWeight.bold, color: CozyTheme.of(context).textPrimary))),
                  Switch(
                    value: !audio.isSfxMuted,
                    activeThumbColor: CozyTheme.of(context).primary,
                        activeTrackColor: CozyTheme.of(context).primary.withValues(alpha: 0.2),
                    onChanged: (val) {
                      if (val) audio.playSfx('success'); // Play sound when enabling
                      audio.toggleSfx(val); 
                    },
                  ),
                ],
              ),
            ),

            // Theme Toggle (3-Way)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
              decoration: BoxDecoration(
                color: CozyTheme.of(context).surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CozyTheme.of(context).textPrimary.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Icon(
                    themeService.themeMode == ThemeMode.system 
                      ? Icons.brightness_auto_rounded 
                      : (themeService.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded), 
                    color: CozyTheme.of(context).secondary, 
                    size: 24
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.themeMode,
                      style: TextStyle(fontWeight: FontWeight.bold, color: CozyTheme.of(context).textPrimary),
                    ),
                  ),
                  
                  // 3-Way Toggle Group
                  Container(
                    decoration: BoxDecoration(
                      color: CozyTheme.of(context).surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CozyTheme.of(context).textPrimary.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLanguageButton(
                          context,
                          'Auto',
                          themeService.themeMode == ThemeMode.system,
                          () {
                            audio.playSfx('click');
                            themeService.setThemeMode(ThemeMode.system);
                          },
                        ),
                        _buildLanguageButton(
                          context,
                          'Light',
                          themeService.themeMode == ThemeMode.light,
                          () {
                            audio.playSfx('click');
                            themeService.setThemeMode(ThemeMode.light);
                          },
                        ),
                        _buildLanguageButton(
                          context,
                          'Dark',
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: CozyTheme.of(context).surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CozyTheme.of(context).textPrimary.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.language_rounded, color: palette.textSecondary, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.language,
                          style: TextStyle(fontWeight: FontWeight.bold, color: CozyTheme.of(context).textPrimary),
                        ),
                      ),
                      // Language Toggle Buttons
                      Container(
                        decoration: BoxDecoration(
                          color: CozyTheme.of(context).surface.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: CozyTheme.of(context).textPrimary.withValues(alpha: 0.05)),
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

            _buildSettingTile(
              Icons.info_outline_rounded, 
              AppLocalizations.of(context)!.aboutApp, 
              "", 
              onTap: () {
                Provider.of<AudioProvider>(context, listen: false).playSfx('click');
                _setView(SettingsView.about);
              }
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildAboutContent() {
    final palette = CozyTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CozyTheme.of(context).surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: CozyTheme.of(context).textPrimary.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                Icon(Icons.medical_services_rounded, size: 56, color: palette.primary),
                const SizedBox(height: 16),
                Text(
                  "ArborMed",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: palette.textPrimary),
                ),
                Text(
                  AppLocalizations.of(context)!.appVersion,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: palette.primary.withValues(alpha: 0.8), letterSpacing: 1),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.appDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: CozyTheme.of(context).textPrimary, height: 1.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.appMission,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: CozyTheme.of(context).secondary, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.person_pin_rounded, AppLocalizations.of(context)!.createdBy, "Shubail Abdulrahman & Eklics Teodóra"),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.bolt_rounded, AppLocalizations.of(context)!.vision, AppLocalizations.of(context)!.visionStatement),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.copyright,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: palette.textSecondary),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final palette = CozyTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CozyTheme.of(context).surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CozyTheme.of(context).textPrimary.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF8D6E63), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: CozyTheme.of(context).secondary, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: palette.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String value, {VoidCallback? onTap}) {
    final palette = CozyTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CozyTheme.of(context).surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CozyTheme.of(context).textPrimary.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: palette.textSecondary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: palette.textPrimary),
              ),
            ),
            Text(
              value,
              style: TextStyle(color: palette.primary, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: palette.textSecondary.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: isSelected ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? CozyTheme.of(context).primary : Colors.transparent,
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
