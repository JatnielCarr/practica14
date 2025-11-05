import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

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
      await _backgroundPlayer.setLoopMode(LoopMode.one);
      await _backgroundPlayer.setVolume(0.3);
      _isInitialized = true;
      debugPrint('✅ AudioService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing AudioService: $e');
    }
  }

  Future<void> playBackgroundMusic() async {
    if (_isPlaying) {
      debugPrint('⚠️ Music is already playing');
      return;
    }

    try {
      await initialize();
      debugPrint('🎵 Attempting to play background music...');
      await _backgroundPlayer.setAsset('assets/audio/retro-game-arcade-236133.mp3');
      await _backgroundPlayer.play();
      _isPlaying = true;
      debugPrint('✅ Background music started successfully');
    } catch (e) {
      debugPrint('❌ Error playing background music: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> stopBackgroundMusic() async {
    try {
      await _backgroundPlayer.stop();
      _isPlaying = false;
      debugPrint('⏹️ Background music stopped');
    } catch (e) {
      debugPrint('❌ Error stopping background music: $e');
    }
  }

  Future<void> pauseBackgroundMusic() async {
    try {
      await _backgroundPlayer.pause();
      _isPlaying = false;
      debugPrint('⏸️ Background music paused');
    } catch (e) {
      debugPrint('❌ Error pausing background music: $e');
    }
  }

  Future<void> resumeBackgroundMusic() async {
    try {
      await _backgroundPlayer.play();
      _isPlaying = true;
      debugPrint('▶️ Background music resumed');
    } catch (e) {
      debugPrint('❌ Error resuming background music: $e');
    }
  }

  void dispose() {
    _backgroundPlayer.dispose();
    debugPrint('🗑️ AudioService disposed');
  }
}