import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _isMuted = false;
  String? _currentAmbientPath;

  Future<void> init() async {
    // Configure audio context to mix with other apps
    // respectSilence = true enables ambient category on iOS and ducking
    await AudioPlayer.global.setAudioContext(AudioContextConfig(
      respectSilence: true,
    ).build());
    
    await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
  }

  void playAmbient(String assetPath) async {
    _currentAmbientPath = assetPath;
    if (_isMuted) return;
    await _ambientPlayer.play(AssetSource(assetPath), volume: 0.3);
  }

  void stopAmbient() async {
    await _ambientPlayer.stop();
  }

  void pauseAmbient() async {
    await _ambientPlayer.pause();
  }

  void resumeAmbient() async {
    if (_isMuted) return;
    if (_currentAmbientPath != null) {
      await _ambientPlayer.resume();
    }
  }

  void playSfx(String assetPath) async {
    if (_isMuted) return;
    await _sfxPlayer.play(AssetSource(assetPath), volume: 0.6);
  }

  void playClick() => playSfx('audio/sfx/click.wav');
  void playSuccess() => playSfx('audio/sfx/success.mp3');

  void setMuted(bool muted) {
    _isMuted = muted;
    if (muted) {
      stopAmbient();
    } else {
      if (_currentAmbientPath != null) {
        playAmbient(_currentAmbientPath!);
      }
    }
  }

  void dispose() {
    _ambientPlayer.dispose();
    _sfxPlayer.dispose();
  }
}
