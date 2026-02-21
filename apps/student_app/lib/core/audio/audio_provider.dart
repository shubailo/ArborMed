import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_manager.dart';

final audioManagerProvider = Provider<AudioManager>((ref) {
  final manager = AudioManager();
  manager.init();
  ref.onDispose(() => manager.dispose());
  return manager;
});

final audioSettingsProvider = StateNotifierProvider<AudioSettingsNotifier, bool>((ref) {
  final manager = ref.read(audioManagerProvider);
  return AudioSettingsNotifier(manager);
});

class AudioSettingsNotifier extends StateNotifier<bool> {
  final AudioManager _audioManager;
  static const _muteKey = 'arbormed_audio_muted';

  AudioSettingsNotifier(this._audioManager) : super(false) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isMuted = prefs.getBool(_muteKey) ?? false;
    state = isMuted;
    _audioManager.setMuted(isMuted);
  }

  Future<void> toggleMute() async {
    final newState = !state;
    state = newState;
    _audioManager.setMuted(newState);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_muteKey, newState);
  }
}
