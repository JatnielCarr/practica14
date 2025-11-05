// ✅ EJEMPLO CORRECTO - Configuración de Supabase
// Este es un ejemplo de cómo DEBE verse tu archivo supabase_config.dart
// DESPUÉS de configurarlo con tu API key real

class SupabaseConfig {
  static const String supabaseUrl = 'https://hfzbqgzrgmrfvvmlgxfh.supabase.co';
  
  // ✅ AQUÍ debes poner tu clave real (anon public key)
  // Ejemplo de cómo se vería (esta clave es FALSA, solo para demostración):
  static const String supabaseAnonKey = 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhmenpxZ3pyZ21yZnZ2bWxneGZoIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTU0MjM4NzEsImV4cCI6MjAxMDk5OTg3MX0.EJEMPLO_FALSO_REEMPLAZA_CON_TU_CLAVE_REAL';
}

// ❌ INCORRECTO - NO dejes esto:
// static const String supabaseAnonKey = 'TU_API_KEY_ANON_AQUI';

// 🔍 Dónde encontrar tu clave REAL:
// 1. Ve a https://app.supabase.com
// 2. Abre tu proyecto
// 3. Settings > API
// 4. Copia la clave que dice "anon" "public"
// 5. Pégala aquí reemplazando el texto de ejemplo

// ⚠️ IMPORTANTE:
// - La clave debe estar entre comillas simples ''
// - Es normal que sea MUY larga (más de 100 caracteres)
// - Empieza con: eyJ...
// - Si vas a subir tu código a GitHub público, añade este archivo al .gitignore
