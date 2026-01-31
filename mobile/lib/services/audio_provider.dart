import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioProvider extends ChangeNotifier with WidgetsBindingObserver {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isMusicMuted = false;
  bool _isSfxMuted = false;
  double _musicVolume = 0.5;
  final double _sfxVolume = 1.0;

  // Placeholder Lofi Track (Free to use / Creative Commons usually safest for demos)
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
    WidgetsBinding.instance.addObserver(this); // Listen to lifecycle
    _initMusic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("[Audio] Lifecycle changed to: $state");
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _musicPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (!_isMusicMuted) {
        _musicPlayer.resume();
      }
    }
  }

  void _initMusic() async {
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _updateMusicVolume();
    
    // Start music automatically
    playMusic();

    // 🔍 DEBUG: Listen to player streams
    _musicPlayer.onPlayerStateChanged.listen((state) {
      debugPrint("[Audio] Music Player State: $state");
    });
  }

  void playMusic() async {
    if (_isMusicMuted) return;
    try {
      debugPrint("[Audio] Attempting to play music from: $_currentTrackPath. Volume: $_musicVolume (Web: $kIsWeb)");
      
      // On Web, AssetSource can sometimes trigger "Code: 4" (Format Error) due to how it's served.
      // Using UrlSource to point directly to the assets folder is often more stable.
      final Source source = kIsWeb 
          ? UrlSource('assets/assets/$_currentTrackPath') 
          : AssetSource(_currentTrackPath);

      await _musicPlayer.play(source);
    } catch (e) {
      debugPrint("[Audio] Critical Error playing music: $e");
      // Fallback: Try raw AssetSource if UrlSource failed on Web
      if (kIsWeb) {
        try {
          debugPrint("[Audio] Web Fallback: Trying AssetSource...");
          await _musicPlayer.play(AssetSource(_currentTrackPath));
        } catch (e2) {
           debugPrint("[Audio] All play attempts failed: $e2");
        }
      }
    }
  }

  /// Callable from UI to start music if it was blocked by autoplay policy
  /// or simply hasn't started yet.
  void ensureMusicPlaying() async {
    if (_isMusicMuted) return;
    if (_musicPlayer.state != PlayerState.playing) {
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
  
  void changeTrack(String path) async {
    _currentTrackPath = path;
    if (!_isMusicMuted) {
      await _musicPlayer.stop();
      playMusic();
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
