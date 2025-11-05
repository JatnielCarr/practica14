import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio_service.dart';
import '../providers.dart';
import 'crossword_generator_widget.dart';
import 'crossword_puzzle_widget.dart';
import 'puzzle_completed_widget.dart';

class CrosswordPuzzleApp extends ConsumerStatefulWidget {
  final AudioService? audioService;

  const CrosswordPuzzleApp({super.key, this.audioService});

  @override
  ConsumerState<CrosswordPuzzleApp> createState() => _CrosswordPuzzleAppState();
}

class _CrosswordPuzzleAppState extends ConsumerState<CrosswordPuzzleApp> {
  bool _audioStarted = false;

  @override
  void initState() {
    super.initState();
    // Reproducir música de fondo después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_audioStarted && mounted) {
        _audioStarted = true;
        try {
          debugPrint('🎵 Intentando reproducir música de fondo...');
          await widget.audioService?.playBackgroundMusic();
        } catch (e) {
          debugPrint('⚠️ Error al reproducir música: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    // Detener la música cuando se cierra la app
    widget.audioService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = ref.watch(puzzleProvider);
    final workQueue = ref.watch(workQueueProvider).value;

    // Show generation screen while generating
    if (workQueue == null || !workQueue.isCompleted) {
      return const CrosswordGeneratorWidget();
    }

    // Show completion screen when puzzle is solved
    if (puzzle.isCompleted) {
      return const PuzzleCompletedWidget();
    }

    // Show puzzle game
    return const CrosswordPuzzleWidget();
  }
}