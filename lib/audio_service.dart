import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal();

  final AudioPlayer _backgroundPlayer = AudioPlayer();
  bool _isInitialized = false;
  bool _isPlaying = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundPlayer.setVolume(0.2); // Volumen más bajo
      _isInitialized = true;
    } catch (e) {
      // Silently handle initialization errors
    }
  }

  Future<void> playBackgroundMusic() async {
    if (_isPlaying) return;

    try {
      await initialize();
      await _backgroundPlayer.play(AssetSource('audio/retro-game-arcade-236133.mp3'));
      _isPlaying = true;
    } catch (e) {
      // Silently handle playback errors
    }
  }

  Future<void> stopBackgroundMusic() async {
    try {
      await _backgroundPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      // Silently handle stop errors
    }
  }

  Future<void> pauseBackgroundMusic() async {
    try {
      await _backgroundPlayer.pause();
      _isPlaying = false;
    } catch (e) {
      // Silently handle pause errors
    }
  }

  Future<void> resumeBackgroundMusic() async {
    try {
      await _backgroundPlayer.resume();
      _isPlaying = true;
    } catch (e) {
      // Silently handle resume errors
    }
  }

  void dispose() {
    _backgroundPlayer.dispose();
  }
}