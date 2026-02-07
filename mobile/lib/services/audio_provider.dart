import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class AudioProvider extends ChangeNotifier with WidgetsBindingObserver {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isMusicMuted = false;
  bool _isSfxMuted = false;
  double _musicVolume = 0.5;
  final double _sfxVolume = 1.0;
  Timer? _fadeTimer;
  bool _isFading = false;
  
  // 🎵 State Guarding
  bool _isTemporarilyPaused = false; // Admin/Video
  bool _isAuthenticated = false;     // Auth State
  StreamSubscription? _playerStateSubscription;

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
    _configureAudioContext();
    // ❌ REMOVED: _initMusic(); -> Music now starts only on login
    _setupStateWatcher();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeTimer?.cancel();
    _playerStateSubscription?.cancel();
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  /// 🔄 Lifecycle Hook: Handle App Backgrounding/Foregrounding
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ❌ REMOVED: super.didChangeAppLifecycleState(state); -> Mixin doesn't have super match
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive: // iOS frequently uses inactive
        _pauseLifecycle();
        break;
      case AppLifecycleState.resumed:
        _resumeLifecycle();
        break;
      default:
        break;
    }
  }

  /// 🔒 Auth State Hook: Called by ProxyProvider in main.dart
  void updateAuthState(bool isAuthenticated) {
    // Dedup updates
    if (_isAuthenticated == isAuthenticated) return;
    
    _isAuthenticated = isAuthenticated;
    debugPrint("🔊 AudioProvider: Auth State Changed -> $_isAuthenticated");

    if (_isAuthenticated) {
      // ✅ User Logged In -> Start Music
      _initMusic();
    } else {
      // ❌ User Logged Out -> Stop Music
      _stopMusic();
    }
  }

  void _stopMusic() async {
    await _musicPlayer.stop();
  }

  void _pauseLifecycle() {
    // Only pause if we were actually playing/allowed to play
    if (_isAuthenticated && !_isMusicMuted && !_isTemporarilyPaused) {
       _musicPlayer.pause();
       debugPrint("⏸️ App Backgrounded: Music Paused");
    }
  }

  void _resumeLifecycle() {
    // Only resume if we are authenticated and not locally muted/paused
    if (_isAuthenticated && !_isMusicMuted && !_isTemporarilyPaused) {
      _musicPlayer.resume();
      debugPrint("▶️ App Resumed: Music Resumed");
    }
  }

  /// 🎚️ Force Mixing: Don't let SFX kill the music
  Future<void> _configureAudioContext() async {
    try {
      final AudioContext audioContext = AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers, // Optional: lower music volume when SFX plays
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck, // Allow background music to duck
        ),
      );
      
      await AudioPlayer.global.setAudioContext(audioContext);
      debugPrint("🔊 Audio Context Configured: Ambient/MixWithOthers");
    } catch (e) {
      debugPrint("⚠️ Error configuring AudioContext: $e");
    }
  }

  void _setupStateWatcher() {
    _playerStateSubscription = _musicPlayer.onPlayerStateChanged.listen((state) {
      // 🚑 Auto-Rescue: If music stopped but shouldn't have, restart it
      // ONLY VALID IF AUTHENTICATED AND FOREGROUND
      if (state == PlayerState.stopped || state == PlayerState.completed) {
        if (_isAuthenticated && !_isMusicMuted && !_isTemporarilyPaused) {
           debugPrint("🚑 Music stopped unexpectedly. Attempting auto-restart...");
           // Small delay to prevent tight loop if file is broken
           Future.delayed(const Duration(milliseconds: 500), () => ensureMusicPlaying());
        }
      }
    });
  }

  void _initMusic() async {
    // Strictly enforce Loop Mode
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(_isMusicMuted ? 0 : _musicVolume);
    
    // Start playing automatically
    await ensureMusicPlaying();
  }

  Future<void> fadeIn({Duration duration = const Duration(seconds: 2)}) async {
    if (_isMusicMuted || !_isAuthenticated) return;

    _fadeTimer?.cancel();
    _fadeTimer = null;

    if (_isFading) return;
    _isFading = true;
    
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
          _isFading = false;
          completer.complete();
        } else {
          _musicPlayer.setVolume(currentVol);
        }
      });
      
      await completer.future;
    } catch (e) {
      debugPrint("Error during fade in: $e");
      _isFading = false;
    }
  }

  Future<void> changeTrack(String path) async {
    _currentTrackPath = path;
    
    // Only attempt to play if authenticated
    if (!_isAuthenticated) return;

    await _musicPlayer.stop();
    
    // Re-ensure loop mode just in case
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    
    final Source source = kIsWeb 
        ? UrlSource('assets/assets/$_currentTrackPath')
        : AssetSource(_currentTrackPath);
    
    try {
      await _musicPlayer.play(source);
    } catch (e) {
      debugPrint("Error changing track: $e");
    }
    notifyListeners();
  }

  void toggleMusic(bool enabled) {
    _isMusicMuted = !enabled; // "enabled" comes from switch value (True = Music ON)
    if (_isMusicMuted) {
      _musicPlayer.pause();
    } else {
      if (!_isTemporarilyPaused && _isAuthenticated) {
        _musicPlayer.resume();
      }
    }
    notifyListeners();
  }

  /// 🚦 Lifecycle Pause: Called when entering Admin/Video screens
  void pauseTemporary() {
    _isTemporarilyPaused = true;
    _musicPlayer.pause();
    debugPrint("⏸️ Music Paused (Temporary)");
  }

  /// 🚦 Lifecycle Resume: Called when returning to Dashboard
  void resumeTemporary() {
    _isTemporarilyPaused = false;
    if (!_isMusicMuted && _isAuthenticated) {
      _musicPlayer.resume();
      debugPrint("▶️ Music Resumed (Temporary)");
    }
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
    try {
      if (await Vibration.hasVibrator() == true) {
        if (await Vibration.hasCustomVibrationsSupport() == true) {
          Vibration.vibrate(pattern: [0, 40, 120, 20], intensities: [0, 128, 0, 64]);
        } else {
          Vibration.vibrate(duration: 100);
        }
      } else {
        HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }

  /// ⚠️ The Flatline Pulse: 3 quick heavy hits
  void _triggerFlatline() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        if (await Vibration.hasCustomVibrationsSupport() == true) {
           Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100], intensities: [0, 255, 0, 255, 0, 255]);
        } else {
           Vibration.vibrate(duration: 500);
        }
      } else {
        HapticFeedback.heavyImpact();
      }
    } catch (_) {}
  }

  void toggleSfx(bool enabled) {
    _isSfxMuted = !enabled;
    notifyListeners();
  }

  Future<void> ensureMusicPlaying() async {
    // 🛡️ Guard: Only play if Authenticated, Not Paused, and Not Muted
    if (_isTemporarilyPaused || !_isAuthenticated || _isMusicMuted) return; 
    
    if (_musicPlayer.state != PlayerState.playing) {
      final Source source = kIsWeb 
          ? UrlSource('assets/assets/$_currentTrackPath')
          : AssetSource(_currentTrackPath);
      
      try {
        await _musicPlayer.setReleaseMode(ReleaseMode.loop);
        await _musicPlayer.play(source);
      } catch (e) {
         debugPrint("Error in ensureMusicPlaying: $e");
      }
    }
  }
}
