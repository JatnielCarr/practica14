import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'audio_service.dart';
import 'supabase_config.dart';
import 'widgets/crossword_puzzle_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 Inicializando aplicación...');

  // Inicializar Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    debugPrint('✅ Supabase initialized');
  } catch (e) {
    debugPrint('❌ Error initializing Supabase: $e');
  }

  // Inicializar el servicio de audio (opcional)
  AudioService? audioService;
  try {
    debugPrint('🎵 Inicializando servicio de audio...');
    audioService = AudioService();
    await audioService.initialize();
  } catch (e) {
    debugPrint('⚠️ Audio no disponible (continuando sin audio): $e');
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