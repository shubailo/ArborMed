import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import './haptic_service.dart';

class AudioProvider extends ChangeNotifier with WidgetsBindingObserver {
  final AudioPlayer _music = AudioPlayer();
  final AudioPlayer _sfx = AudioPlayer();

  // State
  bool _isAuthenticated = false;
  bool _isMuted = false;
  bool _isSfxMuted = false;
  bool _isPaused = false; // Temporary pause (e.g. video/admin)
  double _volume = 0.5;
  
  // Tracks
  final List<Map<String, String>> _tracks = [
    {'name': 'Quiet Ward Rounds', 'path': 'audio/music/quiet_ward_rounds.mp3'},
    {'name': 'Cool Ward Loop', 'path': 'audio/music/cool_ward_loop.mp3'},
    {'name': 'Heartbeat Hallway', 'path': 'audio/music/heartbeat_hallway.mp3'},
    {'name': 'Ward Carousel', 'path': 'audio/music/ward_carousel.mp3'},
  ];
  String _currentTrack = 'audio/music/quiet_ward_rounds.mp3';

  // Getters
  bool get isMusicMuted => _isMuted;
  bool get isSfxMuted => _isSfxMuted;
  double get musicVolume => _volume;
  List<Map<String, String>> get tracks => _tracks;
  String get currentTrackPath => _currentTrack;

  bool get _shouldPlay => _isAuthenticated && !_isMuted && !_isPaused;

  AudioProvider() {
    _init();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _music.dispose();
    _sfx.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // FIX: Use a context that allows mixing and ducking, preventing SFX from stopping music.
    // AudioFocus.none is key for "ambient" feel on Android.
    if (!kIsWeb) {
      await AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none, 
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ));
    }
    
    await _music.setReleaseMode(ReleaseMode.loop);
  }

  // --- Lifecycle & Auth ---

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _music.pause();
    } else if (state == AppLifecycleState.resumed) {
      _updateMusicState();
    }
  }

  void updateAuthState(bool isAuthenticated, {bool isAdmin = false}) {
    if (_isAuthenticated == isAuthenticated && _isPaused == isAdmin) return;
    _isAuthenticated = isAuthenticated;
    
    // 🔇 Automatically pause if user is an admin
    if (_isAuthenticated && isAdmin) {
      _isPaused = true;
    }
    
    _updateMusicState();
  }

  // --- Controls ---

  Future<void> _updateMusicState() async {
    if (_shouldPlay) {
      if (_music.state != PlayerState.playing) {
        // Just play - ReleaseMode.loop handles the rest
        await _music.play(AssetSource(_currentTrack), volume: _volume);
      } else {
        await _music.setVolume(_volume); // Ensure volume is correct
      }
    } else {
      if (_music.state == PlayerState.playing) {
        await _music.pause();
      }
    }
  }

  void toggleMusic(bool enabled) {
    _isMuted = !enabled;
    notifyListeners();
    _updateMusicState();
  }

  void toggleSfx(bool enabled) {
    _isSfxMuted = !enabled;
    notifyListeners();
  }

  // Temporary pause for other media (videos, etc)
  void pauseTemporary() {
    _isPaused = true;
    _updateMusicState();
  }

  void resumeTemporary() {
    _isPaused = false;
    _updateMusicState();
  }

  Future<void> changeTrack(String path) async {
    _currentTrack = path;
    notifyListeners();
    if (_shouldPlay) {
      await _music.play(AssetSource(_currentTrack), volume: _volume);
    }
  }

  void setMusicVolume(double volume) {
    _volume = volume;
    notifyListeners();
    if (_music.state == PlayerState.playing) {
      _music.setVolume(volume);
    }
  }

  // --- Features ---

  Future<void> fadeIn({Duration duration = const Duration(seconds: 2)}) async {
    if (!_shouldPlay) return;

    // Start at 0
    await _music.setVolume(0);
    if (_music.state != PlayerState.playing) {
      await _music.play(AssetSource(_currentTrack));
    }

    // Simple Linear Fade
    const steps = 20;
    final stepTime = duration ~/ steps;
    final stepVol = _volume / steps;

    for (int i = 1; i <= steps; i++) {
      if (!_shouldPlay) return; // Abort if paused/muted during fade
      await Future.delayed(stepTime);
      await _music.setVolume(stepVol * i);
    }
  }

  Future<void> playSfx(String name) async {
    if (_isSfxMuted) return;

    try {
      // Create a fresh player for overlapping SFX if needed, 
      // but simpler to reuse _sfx for now (single channel SFX).
      // If you want overlapping SFX, instantiate a new AudioPlayer() here.
      if (_sfx.state == PlayerState.playing) {
        await _sfx.stop();
      }
      
      String extension = '.wav';
      if (['success', 'incorrect', 'error'].contains(name)) {
        extension = '.mp3';
      }

      await _sfx.play(
        AssetSource('audio/sfx/$name$extension'),
        volume: 1.0,
        ctx: kIsWeb ? null : AudioContext(
             android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
             iOS: AudioContextIOS(options: {AVAudioSessionOptions.mixWithOthers})
        )
      );

      // Haptics Integration
      if (name == 'success') {
        CozyHaptics.success();
      } else if (['pop', 'error', 'incorrect'].contains(name)) {
        CozyHaptics.error();
      }
    } catch (e) {
      debugPrint("SFX Error: $e");
    }
  }
  
  // Backward compatibility alias if needed
  Future<void> ensureMusicPlaying() async => _updateMusicState();
}
