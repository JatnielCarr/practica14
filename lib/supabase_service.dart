import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para manejar la integración con Supabase
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  static SupabaseService get instance => _instance;
  SupabaseService._internal();

  final _supabase = Supabase.instance.client;

  /// Verificar si la conexión a Supabase está funcionando
  Future<bool> testConnection() async {
    try {
      debugPrint('🔌 Probando conexión a Supabase...');
      
      // Intentar una consulta simple para verificar conectividad
      await _supabase
          .from('palabras_exclusivas')
          .select('palabra')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      
      debugPrint('✅ Conexión a Supabase exitosa');
      return true;
    } catch (e) {
      debugPrint('❌ Fallo en conexión a Supabase: $e');
      return false;
    }
  }

  /// Obtener todas las palabras exclusivas desde Supabase
  Future<List<String>> getPalabrasExclusivas() async {
    try {
      debugPrint('📚 Intentando obtener palabras exclusivas...');
      
      final response = await _supabase
          .from('palabras_exclusivas')
          .select('palabra')
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('⏱️ Timeout al obtener palabras exclusivas');
              throw Exception('Timeout al conectar con Supabase');
            },
          );
      
      final palabras = (response as List)
          .where((item) => item != null && item['palabra'] != null)
          .map((item) => (item['palabra'] as String).toLowerCase().trim())
          .where((word) => word.isNotEmpty)
          .toList();
      
      debugPrint('✅ Obtenidas ${palabras.length} palabras exclusivas');
      return palabras;
    } catch (e, stackTrace) {
      debugPrint('❌ Error al obtener palabras exclusivas: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Buscar o crear usuario
  Future<String?> loginOrCreateUser(String username) async {
    try {
      debugPrint('🔐 Intentando login/registro para usuario: $username');
      
      // Buscar usuario existente
      debugPrint('🔍 Buscando usuario existente...');
      final existingUser = await _supabase
          .from('usuarios')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      if (existingUser != null) {
        final userId = existingUser['id'] as String;
        debugPrint('✅ Usuario encontrado con ID: $userId');
        return userId;
      }

      // Crear nuevo usuario
      debugPrint('➕ Usuario no existe, creando nuevo...');
      final newUser = await _supabase
          .from('usuarios')
          .insert({'username': username})
          .select('id')
          .single();

      final newUserId = newUser['id'] as String;
      debugPrint('✅ Usuario creado exitosamente con ID: $newUserId');
      return newUserId;
    } catch (e, stackTrace) {
      debugPrint('❌ Error en login/registro: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      
      // Intentar obtener más detalles del error
      if (e is PostgrestException) {
        debugPrint('⚠️ Error de Postgres: ${e.message}');
        debugPrint('⚠️ Código: ${e.code}');
        debugPrint('⚠️ Detalles: ${e.details}');
        debugPrint('⚠️ Hint: ${e.hint}');
      }
      
      return null;
    }
  }

  /// Registrar tiempo completado (en milisegundos)
  Future<void> registrarTiempo(String userId, int tiempoEnMilisegundos) async {
    try {
      debugPrint('⏱️ Registrando tiempo para usuario $userId: ${tiempoEnMilisegundos}ms');
      
      await _supabase.from('ranking').insert({
        'user_id': userId,
        'tiempo_en_milisegundos': tiempoEnMilisegundos,
        'fecha_completado': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ Tiempo registrado exitosamente');
    } catch (e, stackTrace) {
      debugPrint('❌ Error al registrar tiempo: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      
      if (e is PostgrestException) {
        debugPrint('⚠️ Error de Postgres: ${e.message}');
        debugPrint('⚠️ Código: ${e.code}');
      }
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
      debugPrint('Error al obtener ranking: $e');
      return [];
    }
  }
}