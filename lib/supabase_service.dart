import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para manejar la integración con Supabase
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  static SupabaseService get instance => _instance;
  SupabaseService._internal();

  final _supabase = Supabase.instance.client;

  /// Obtener todas las palabras exclusivas desde Supabase
  Future<List<String>> getPalabrasExclusivas() async {
    try {
      final response = await _supabase
          .from('palabras_exclusivas')
          .select('palabra');

      return (response as List)
          .map((item) => (item['palabra'] as String).toLowerCase())
          .toList();
    } catch (e) {
      print('Error al obtener palabras exclusivas: $e');
      return [];
    }
  }

  /// Buscar o crear usuario
  Future<String?> loginOrCreateUser(String username) async {
    try {
      // Buscar usuario existente
      final existingUser = await _supabase
          .from('usuarios')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      if (existingUser != null) {
        return existingUser['id'] as String;
      }

      // Crear nuevo usuario
      final newUser = await _supabase
          .from('usuarios')
          .insert({'username': username})
          .select('id')
          .single();

      return newUser['id'] as String;
    } catch (e) {
      print('Error en login/registro: $e');
      return null;
    }
  }

  /// Registrar tiempo completado (en milisegundos)
  Future<void> registrarTiempo(String userId, int tiempoEnMilisegundos) async {
    try {
      await _supabase.from('ranking').insert({
        'user_id': userId,
        'tiempo_en_milisegundos': tiempoEnMilisegundos,
        'fecha_completado': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error al registrar tiempo: $e');
    }
  }

  /// Obtener ranking ordenado por tiempo (menor a mayor)
  Future<List<Map<String, dynamic>>> getRanking() async {
    try {
      final response = await _supabase
          .from('ranking')
          .select('tiempo_en_milisegundos, fecha_completado, usuarios(username)')
          .order('tiempo_en_milisegundos', ascending: true)
          .limit(100);

      return (response as List).map((item) {
        final usuarios = item['usuarios'] as Map<String, dynamic>?;
        return {
          'username': usuarios?['username'] ?? 'Unknown',
          'tiempo_en_milisegundos': item['tiempo_en_milisegundos'],
          'fecha_completado': item['fecha_completado'],
        };
      }).toList();
    } catch (e) {
      print('Error al obtener ranking: $e');
      return [];
    }
  }
}
