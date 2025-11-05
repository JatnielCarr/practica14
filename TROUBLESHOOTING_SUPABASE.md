# 🔧 Solución de Problemas - Conexión Supabase

## ❌ Problema: Los usuarios no se registran en la base de datos

### 📋 Diagnóstico Paso a Paso

#### 1. Verificar Logs en la Consola

Cuando ejecutes la app, deberías ver estos mensajes en la consola de Flutter:

```
✅ Supabase initialized
🎮 Inicializando juego...
📚 Intentando obtener palabras exclusivas...
✅ Obtenidas 6 palabras exclusivas
🌐 Estado: ONLINE
👤 Usuario ingresado: [tu_nombre]
🔐 Intentando login/registro para usuario: [tu_nombre]
🔍 Buscando usuario existente...
```

**Si ves errores**, cópialos y revisa las secciones siguientes.

#### 2. Verificar Credenciales de Supabase

**Archivo:** `lib/supabase_config.dart`

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://hfzbqgzrgmrfvvmlgxfh.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGci...'; // Tu API Key
}
```

✅ **Checklist:**
- [ ] La URL termina en `.supabase.co`
- [ ] La API Key es la **anon/public key** (no la service_role)
- [ ] No hay espacios extra al inicio o final

**Cómo obtener las credenciales correctas:**
1. Ve a https://supabase.com/dashboard
2. Selecciona tu proyecto
3. Ve a **Settings** → **API**
4. Copia **Project URL** y **anon/public** key

#### 3. Verificar Políticas RLS en Supabase

**CRÍTICO:** Las políticas de Row Level Security pueden bloquear las inserciones.

**Solución 1: Desactivar RLS temporalmente (para testing)**

En Supabase SQL Editor, ejecuta:

```sql
ALTER TABLE usuarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE ranking DISABLE ROW LEVEL SECURITY;
ALTER TABLE palabras_exclusivas DISABLE ROW LEVEL SECURITY;
```

**Solución 2: Configurar políticas correctas (recomendado)**

Ejecuta este script SQL en Supabase:

```sql
-- Eliminar políticas existentes
DROP POLICY IF EXISTS "Enable read for palabras_exclusivas" ON palabras_exclusivas;
DROP POLICY IF EXISTS "Enable read for usuarios" ON usuarios;
DROP POLICY IF EXISTS "Enable read for ranking" ON ranking;
DROP POLICY IF EXISTS "Enable insert for usuarios" ON usuarios;
DROP POLICY IF EXISTS "Enable insert for ranking" ON ranking;
DROP POLICY IF EXISTS "Allow all on palabras_exclusivas" ON palabras_exclusivas;
DROP POLICY IF EXISTS "Allow all on usuarios" ON usuarios;
DROP POLICY IF EXISTS "Allow all on ranking" ON ranking;

-- Habilitar RLS
ALTER TABLE palabras_exclusivas ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE ranking ENABLE ROW LEVEL SECURITY;

-- Crear políticas permisivas
CREATE POLICY "Allow all on palabras_exclusivas" ON palabras_exclusivas 
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow all on usuarios" ON usuarios 
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow all on ranking" ON ranking 
    FOR ALL USING (true) WITH CHECK (true);
```

**Verificar que se aplicaron:**

```sql
SELECT tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename IN ('palabras_exclusivas', 'usuarios', 'ranking');
```

Deberías ver 3 políticas (una por cada tabla).

#### 4. Verificar Estructura de Tablas

En Supabase SQL Editor, ejecuta:

```sql
-- Verificar que las tablas existen
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('palabras_exclusivas', 'usuarios', 'ranking');

-- Verificar estructura de usuarios
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'usuarios';

-- Verificar estructura de ranking
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'ranking';
```

**Resultado esperado para `usuarios`:**
- `id` (uuid, NO)
- `username` (text, NO)
- `created_at` (timestamp with time zone, YES)

**Resultado esperado para `ranking`:**
- `id` (bigint, NO)
- `user_id` (uuid, NO)
- `tiempo_en_milisegundos` (bigint, NO)
- `fecha_completado` (timestamp with time zone, YES)

#### 5. Probar Inserción Manual

En Supabase SQL Editor:

```sql
-- Intentar insertar un usuario de prueba
INSERT INTO usuarios (username) 
VALUES ('test_user_123') 
RETURNING *;

-- Si funciona, deberías ver el usuario creado con un ID UUID
```

**Si falla:**
- Revisa el error exacto
- Probablemente sea un problema de RLS (vuelve al paso 3)

**Si funciona:**
- El problema está en el código de Flutter o las credenciales

#### 6. Verificar Conexión a Internet

**En el dispositivo móvil:**

```bash
# Android: Verificar permisos en AndroidManifest.xml
# Archivo: android/app/src/main/AndroidManifest.xml
```

Debe contener:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

**Probar conectividad:**
- Abre el navegador del celular
- Visita https://hfzbqgzrgmrfvvmlgxfh.supabase.co
- Deberías ver un JSON o mensaje de Supabase

#### 7. Logs Detallados Mejorados

He agregado logs más detallados. Cuando ejecutes la app, verás:

```
🔐 Intentando login/registro para usuario: nombre
🔍 Buscando usuario existente...
```

**Posibles resultados:**

✅ **Éxito:**
```
✅ Usuario encontrado con ID: abc-123-def
```
o
```
➕ Usuario no existe, creando nuevo...
✅ Usuario creado exitosamente con ID: abc-123-def
```

❌ **Error:**
```
❌ Error en login/registro: [mensaje de error]
📋 Stack trace: [detalles técnicos]
⚠️ Error de Postgres: [mensaje específico]
⚠️ Código: [código de error]
```

#### 8. Errores Comunes y Soluciones

##### Error: "new row violates row-level security policy"
**Causa:** RLS bloqueando la inserción  
**Solución:** Ejecuta el script SQL del paso 3

##### Error: "null value in column 'username' violates not-null constraint"
**Causa:** El username está vacío  
**Solución:** Verifica que el TextEditingController tenga texto

##### Error: "duplicate key value violates unique constraint"
**Causa:** El username ya existe  
**Solución:** Esto es normal, la app debería encontrar el usuario existente

##### Error: "relation 'usuarios' does not exist"
**Causa:** La tabla no se creó  
**Solución:** Ejecuta `supabase_setup.sql` completo

##### Error: "Failed host lookup" o "SocketException"
**Causa:** Sin conexión a internet  
**Solución:** Verifica WiFi/datos móviles

##### Error: "JWTExpired" o "Invalid API key"
**Causa:** API Key incorrecta o expirada  
**Solución:** Regenera la API Key en Supabase Dashboard

#### 9. Test de Conectividad Manual

Añadí un método `testConnection()` en `SupabaseService`. Para probarlo:

```dart
// En algún lugar de tu código (o en la consola de Flutter DevTools):
final isConnected = await SupabaseService.instance.testConnection();
print('Conexión: ${isConnected ? "OK" : "FALLO"}');
```

#### 10. Checklist Final

Antes de contactar soporte, verifica:

- [ ] Supabase está inicializado correctamente (logs en `main.dart`)
- [ ] Las credenciales son correctas (`lib/supabase_config.dart`)
- [ ] Las tablas existen en Supabase
- [ ] Las políticas RLS están configuradas o desactivadas
- [ ] El celular/PC tiene conexión a internet
- [ ] Los permisos de internet están en AndroidManifest.xml
- [ ] Los logs muestran el error específico
- [ ] La app está compilada en modo debug para ver logs

### 📱 Probar en Dispositivo Real

**Modo Debug (recomendado para troubleshooting):**

```bash
# Android
flutter run --debug

# iOS
flutter run --debug
```

**Ver logs en tiempo real:**

```bash
# Android
adb logcat | grep flutter

# Flutter DevTools
flutter run --debug
# Luego abre DevTools y ve a la pestaña Logging
```

### 🆘 Si Nada Funciona

1. **Limpia y reconstruye:**
   ```bash
   flutter clean
   flutter pub get
   flutter run --debug
   ```

2. **Verifica versión de Supabase:**
   ```yaml
   # pubspec.yaml
   dependencies:
     supabase_flutter: ^2.8.0  # Versión compatible
   ```

3. **Prueba la API directamente:**
   - Usa Postman o curl
   - Endpoint: `https://tu-proyecto.supabase.co/rest/v1/usuarios`
   - Headers: 
     - `apikey: tu-anon-key`
     - `Content-Type: application/json`
   - Body (POST):
     ```json
     {"username": "test_api"}
     ```

4. **Contacta soporte:**
   - Copia todos los logs de error
   - Incluye las consultas SQL ejecutadas
   - Menciona versión de Flutter: `flutter --version`
   - Menciona plataforma: Android/iOS/Web

---

## 📊 Comandos Útiles

```bash
# Ver logs completos
flutter run --verbose

# Limpiar caché
flutter clean

# Verificar análisis estático
flutter analyze

# Reconstruir código generado
dart run build_runner build --delete-conflicting-outputs

# Compilar para release (sin logs)
flutter run --release
```

## ✅ Cuando Todo Funcione

Deberías ver en Supabase Dashboard → Table Editor → usuarios:

| id (UUID) | username | created_at |
|-----------|----------|------------|
| abc-123... | tu_nombre | 2025-11-05... |

Y en la tabla `ranking` cuando completes el juego:

| id | user_id | tiempo_en_milisegundos | fecha_completado |
|----|---------|------------------------|------------------|
| 1 | abc-123... | 45230 | 2025-11-05... |

---

**Última actualización:** 5 de noviembre de 2025
