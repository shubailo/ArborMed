import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioProvider with ChangeNotifier {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isMusicMuted = false;
  bool _isSfxMuted = false;
  double _musicVolume = 0.5;
  final double _sfxVolume = 1.0;

  // Placeholder Lofi Track (Free to use / Creative Commons usually safest for demos)
  static const String _bgmPath = 'audio/music/cozy_lofi.wav'; 
  
  bool get isMusicMuted => _isMusicMuted;
  bool get isSfxMuted => _isSfxMuted;
  double get musicVolume => _musicVolume;
  
  AudioProvider() {
    _initMusic();
  }

  void _initMusic() async {
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _updateMusicVolume();
    
    // 🔍 DEBUG: Listen to player streams
    _musicPlayer.onPlayerStateChanged.listen((state) {
      debugPrint("[Audio] Music Player State: $state");
    });

    _musicPlayer.onDurationChanged.listen((duration) {
       debugPrint("[Audio] Music Duration: $duration");
    });
    
    _musicPlayer.onLog.listen((msg) {
      debugPrint("[Audio] Player Log: $msg");
    });
  }

  void playMusic() async {
    if (_isMusicMuted) return;
    try {
      debugPrint("[Audio] Attempting to play music from: $_bgmPath. Volume: $_musicVolume");
      // await _musicPlayer.play(AssetSource(_bgmPath));
      
      // 🧪 TEST: Use remote URL to verify player works (Asset seems too short/broken)
      await _musicPlayer.play(UrlSource('https://luan.xyz/files/audio/ambient_c_motion.mp3'));
    } catch (e) {
      debugPrint("[Audio] Error playing music: $e");
    }
  }

  /// Callable from UI to start music if it was blocked by autoplay policy
  /// or simply hasn't started yet.
  void ensureMusicPlaying() async {
    if (_isMusicMuted) return;
    if (_musicPlayer.state != PlayerState.playing) {
      debugPrint("[Audio] ensureMusicPlaying triggered. Starting music...");
      playMusic();
    }
  }

  void stopMusic() {
    _musicPlayer.stop();
  }

  void toggleMusic(bool enabled) {
    _isMusicMuted = !enabled;
    if (_isMusicMuted) {
      _musicPlayer.pause();
    } else {
      _musicPlayer.resume();
      // If resume fails because it wasn't playing, try play
      if (_musicPlayer.state != PlayerState.playing) {
        playMusic();
      }
    }
    notifyListeners();
  }

  void setMusicVolume(double volume) {
    _musicVolume = volume;
    _updateMusicVolume();
    notifyListeners();
  }

  void _updateMusicVolume() {
    if (_isMusicMuted) {
      _musicPlayer.setVolume(0);
    } else {
      _musicPlayer.setVolume(_musicVolume);
    }
  }

  // SFX
  void playSfx(String sfxName) async {
    if (_isSfxMuted) return;
    try {
      // Use local AssetSource now that we have valid WAV files
      await _sfxPlayer.play(AssetSource('audio/sfx/$sfxName.wav'), volume: _sfxVolume);
    } catch (e) {
       print("Error playing sfx: $e");
    }
  }

  void toggleSfx(bool enabled) {
    _isSfxMuted = !enabled;
    notifyListeners();
  }
}
