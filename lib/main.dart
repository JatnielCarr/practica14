import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_service.dart';
import 'widgets/crossword_puzzle_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar el servicio de audio (opcional)
  AudioService? audioService;
  try {
    audioService = AudioService();
    await audioService.initialize();
  } catch (e) {
    // Si hay problemas con el audio, continuar sin él
    audioService = null;
  }

  runApp(
    ProviderScope(
      child: MaterialApp(
        title: 'Crossword Puzzle Game',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.blueGrey,
          brightness: Brightness.light,
        ),
        home: CrosswordPuzzleApp(audioService: audioService),
      ),
    ),
  );
}