import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isMusicMuted = false;
  bool _isSfxMuted = false;
  double _musicVolume = 0.5;
  final double _sfxVolume = 1.0;

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
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  void _initMusic() async {
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _musicPlayer.setVolume(_musicVolume);
    
    // Start playing automatically
    final source = kIsWeb 
        ? UrlSource('assets/assets/$_currentTrackPath')
        : AssetSource(_currentTrackPath);
    
    await _musicPlayer.play(source);
  }

  void changeTrack(String path) async {
    _currentTrackPath = path;
    
    await _musicPlayer.stop();
    
    final source = kIsWeb 
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
      await _sfxPlayer.play(AssetSource('audio/sfx/$sfxName.wav'), volume: _sfxVolume);
    } catch (e) {
      debugPrint("Error playing sfx: $e");
    }
  }

  void toggleSfx(bool enabled) {
    _isSfxMuted = !enabled;
    notifyListeners();
  }

  void ensureMusicPlaying() async {
    if (_musicPlayer.state != PlayerState.playing && !_isMusicMuted) {
      final source = kIsWeb 
          ? UrlSource('assets/assets/$_currentTrackPath')
          : AssetSource(_currentTrackPath);
      await _musicPlayer.play(source);
    }
  }
}
