import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'audio_service.dart';
import 'supabase_config.dart';
import 'widgets/crossword_puzzle_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

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
      child: MyApp(audioService: audioService),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AudioService? audioService;

  const MyApp({super.key, this.audioService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crucigrama con Palabras Exclusivas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: CrosswordPuzzleApp(audioService: audioService),
    );
  }
}