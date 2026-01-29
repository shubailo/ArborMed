import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_provider.dart';
import '../cozy/floating_medical_icons.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Dimmed Background with Floating Icons
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              Provider.of<AudioProvider>(context, listen: false).playSfx('click');
              Navigator.pop(context);
            },
            child: Container(
              color: Colors.black.withOpacity(0.4),
              child: FloatingMedicalIcons(
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
        ),

        // 2. The Settings Clipboard Card
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 500,
              constraints: const BoxConstraints(maxHeight: 500),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF8D6E63), width: 4), 
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Clipboard Top Handle
                    Container(
                      width: 100,
                      height: 12,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8D6E63),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),

                    // Header
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Center(
                        child: Text(
                          "SETTINGS",
                          style: TextStyle(
                            fontFamily: 'Quicksand',
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF5D4037),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),

                    // Settings List
                    Expanded(
                      child: Consumer<AudioProvider>(
                        builder: (context, audio, child) {
                          return ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              _buildSettingTile(Icons.notifications_none_rounded, "Notifications", "On"),
                              
                              // Music Volume Slider
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(audio.isMusicMuted ? Icons.music_off_rounded : Icons.music_note_rounded, color: const Color(0xFF8D6E63), size: 24),
                                        const SizedBox(width: 16),
                                        const Expanded(child: Text("Music Volume", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037)))),
                                        Switch(
                                          value: !audio.isMusicMuted,
                                          activeColor: const Color(0xFF8CAA8C),
                                          onChanged: (val) {
                                            audio.playSfx('click');
                                            audio.toggleMusic(val); // Fix: pass val directly
                                          },
                                        ),
                                      ],
                                    ),
                                    if (!audio.isMusicMuted)
                                      Slider(
                                        value: audio.musicVolume,
                                        activeColor: const Color(0xFF8CAA8C),
                                        inactiveColor: const Color(0xFF8CAA8C).withOpacity(0.3),
                                        onChanged: (val) => audio.setMusicVolume(val),
                                      ),
                                  ],
                                ),
                              ),

                              // SFX Toggle
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // slightly tighter
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(audio.isSfxMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: const Color(0xFF8D6E63), size: 24),
                                    const SizedBox(width: 16),
                                    const Expanded(child: Text("Sound Effects", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037)))),
                                    Switch(
                                      value: !audio.isSfxMuted,
                                      activeColor: const Color(0xFF8CAA8C),
                                      onChanged: (val) {
                                        if (val) audio.playSfx('success'); // Play sound when enabling
                                        audio.toggleSfx(val); // Fix: pass val directly
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              _buildSettingTile(Icons.color_lens_outlined, "Theme Mode", "Cozy Cream"),
                              _buildSettingTile(Icons.info_outline_rounded, "About App", "v0.1.0"),
                            ],
                          );
                        },
                      ),
                    ),

                    // Sign Out Button (At Bottom)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red[700],
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16), 
                              side: BorderSide(color: Colors.red.shade100),
                            ),
                          ),
                          onPressed: () {},
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8D6E63), size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037)))),
          Text(value, style: const TextStyle(color: Color(0xFF8CAA8C), fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[350]),
        ],
      ),
    );
  }
}
