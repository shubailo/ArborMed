import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isMusicMuted = false;
  bool _isSfxMuted = false;
  double _musicVolume = 0.5;
  final double _sfxVolume = 1.0;
  Timer? _fadeTimer;
  bool _isFading = false;

  final List<Map<String, String>> _tracks = [
    {'name': 'Quiet Ward Rounds', 'path': 'audio/music/quiet_ward_rounds.mp3'},
    {'name': 'Cool Ward Loop', 'path': 'audio/music/cool_ward_loop.mp3'},
    {'name': 'Heartbeat Hallway', 'path': 'audio/music/heartbeat_hallway.mp3'},
    {'name': 'Ward Carousel', 'path': 'audio/music/ward_carousel.mp3'},
  ];
  
  String _currentTrackPath = 'audio/music/quiet_ward_rounds.mp3';
  
  bool get isMusicMuted => _isMusicMuted;
  bool get isSfxMuted => _isSfxMuted;
  double get musicVolume => _musicVolume;
  List<Map<String, String>> get tracks => _tracks;
  String get currentTrackPath => _currentTrackPath;
  
  AudioProvider() {
    _initMusic();
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  void _initMusic() async {
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(_isMusicMuted ? 0 : _musicVolume);
    
    // Start playing automatically
    final Source source = kIsWeb 
        ? UrlSource('assets/assets/$_currentTrackPath')
        : AssetSource(_currentTrackPath);
    
    try {
      await _musicPlayer.play(source);
    } catch (e) {
      debugPrint("Autoplay blocked or failed: $e");
    }
  }

  Future<void> fadeIn({Duration duration = const Duration(seconds: 2)}) async {
    if (_isMusicMuted || _isFading) return;
    _isFading = true;
    
    _fadeTimer?.cancel();
    _fadeTimer = null;
    
    try {
      // Ensure music is playing
      await ensureMusicPlaying();
      
      final double targetVolume = _musicVolume;
      const int steps = 20;
      final double stepValue = targetVolume / steps;
      final int intervalMs = duration.inMilliseconds ~/ steps;
      
      double currentVol = 0.0;
      await _musicPlayer.setVolume(currentVol);
      
      final completer = Completer<void>();
      
      _fadeTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
        currentVol += stepValue;
        if (currentVol >= targetVolume) {
          currentVol = targetVolume;
          _musicPlayer.setVolume(currentVol);
          timer.cancel();
          completer.complete();
        } else {
          _musicPlayer.setVolume(currentVol);
        }
      });
      
      await completer.future;
    } catch (e) {
      debugPrint("Error during fade in: $e");
    } finally {
      _isFading = false;
    }
  }

  Future<void> changeTrack(String path) async {    _currentTrackPath = path;
    
    await _musicPlayer.stop();
    
    final Source source = kIsWeb 
        ? UrlSource('assets/assets/$_currentTrackPath')
        : AssetSource(_currentTrackPath);
    
    await _musicPlayer.play(source);
    notifyListeners();
  }

  void toggleMusic(bool enabled) {
    _isMusicMuted = !enabled;
    if (_isMusicMuted) {
      _musicPlayer.pause();
    } else {
      _musicPlayer.resume();
    }
    notifyListeners();
  }

  void setMusicVolume(double volume) {
    _musicVolume = volume;
    _musicPlayer.setVolume(_musicVolume);
    notifyListeners();
  }

  void playSfx(String sfxName) async {
    if (_isSfxMuted) return;
    try {
      if (_sfxPlayer.state == PlayerState.playing) {
        await _sfxPlayer.stop();
      }
      await _sfxPlayer.play(AssetSource('audio/sfx/$sfxName.wav'), volume: _sfxVolume);
      
      // 🩺 Refinement: Sync Haptics with specific medical sound effects
      if (sfxName == 'success') {
        _triggerLubDub();
      } else if (sfxName == 'pop' || sfxName == 'error' || sfxName == 'incorrect') {
        _triggerFlatline();
      }
    } catch (e) {
      debugPrint("Error playing sfx: $e");
    }
  }

  /// 🫀 The Heartbeat Pulse: Medium -> Light sync
  /// Robust pattern for "Lub-Dub": 
  /// 0ms wait, 40ms vibrate (Lub), 120ms wait, 20ms vibrate (Dub)
  void _triggerLubDub() async {
    if (await Vibration.hasVibrator() == true) {
      if (await Vibration.hasCustomVibrationsSupport() == true) {
        Vibration.vibrate(pattern: [0, 40, 120, 20], intensities: [0, 128, 0, 64]);
      } else {
        Vibration.vibrate(duration: 100);
      }
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  /// ⚠️ The Flatline Pulse: 3 quick heavy hits
  void _triggerFlatline() async {
    if (await Vibration.hasVibrator() == true) {
      if (await Vibration.hasCustomVibrationsSupport() == true) {
         Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100], intensities: [0, 255, 0, 255, 0, 255]);
      } else {
         Vibration.vibrate(duration: 500);
      }
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void toggleSfx(bool enabled) {
    _isSfxMuted = !enabled;
    notifyListeners();
  }

  Future<void> ensureMusicPlaying() async {
    if (_musicPlayer.state != PlayerState.playing && !_isMusicMuted) {
      final Source source = kIsWeb 
          ? UrlSource('assets/assets/$_currentTrackPath')
          : AssetSource(_currentTrackPath);
      await _musicPlayer.play(source);
    }
  }
}
