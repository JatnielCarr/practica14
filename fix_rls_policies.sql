-- ========================================
-- FIX RÁPIDO: Problemas de RLS en Supabase
-- ========================================
-- Ejecuta este script si los usuarios NO se registran en la base de datos
-- Ejecutar en: Supabase Dashboard → SQL Editor

-- PASO 1: Eliminar TODAS las políticas existentes
DROP POLICY IF EXISTS "Enable read for palabras_exclusivas" ON palabras_exclusivas;
DROP POLICY IF EXISTS "Enable read for usuarios" ON usuarios;
DROP POLICY IF EXISTS "Enable read for ranking" ON ranking;
DROP POLICY IF EXISTS "Enable insert for usuarios" ON usuarios;
DROP POLICY IF EXISTS "Enable insert for ranking" ON ranking;
DROP POLICY IF EXISTS "Allow all on palabras_exclusivas" ON palabras_exclusivas;
DROP POLICY IF EXISTS "Allow all on usuarios" ON usuarios;
DROP POLICY IF EXISTS "Allow all on ranking" ON ranking;

-- PASO 2: Habilitar RLS en todas las tablas
ALTER TABLE palabras_exclusivas ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE ranking ENABLE ROW LEVEL SECURITY;

-- PASO 3: Crear políticas PERMISIVAS (permitir todo)
CREATE POLICY "Allow all on palabras_exclusivas" ON palabras_exclusivas 
    FOR ALL 
    USING (true) 
    WITH CHECK (true);

CREATE POLICY "Allow all on usuarios" ON usuarios 
    FOR ALL 
    USING (true) 
    WITH CHECK (true);

CREATE POLICY "Allow all on ranking" ON ranking 
    FOR ALL 
    USING (true) 
    WITH CHECK (true);

-- PASO 4: Verificar que las políticas se crearon
SELECT 
    tablename, 
    policyname, 
    cmd as operacion,
    CASE 
        WHEN qual = 'true' THEN '✅ Permitido'
        ELSE '⚠️ Restringido'
    END as estado
FROM pg_policies 
WHERE tablename IN ('palabras_exclusivas', 'usuarios', 'ranking')
ORDER BY tablename;

-- PASO 5: Probar inserción manual
-- Si esto funciona, la app también debería funcionar
INSERT INTO usuarios (username) 
VALUES ('test_connection_' || floor(random() * 10000)::text) 
RETURNING id, username, created_at;

-- ========================================
-- ALTERNATIVA: Desactivar RLS completamente
-- ========================================
-- ⚠️ SOLO usar para testing/desarrollo
-- ⚠️ NO recomendado para producción

-- Descomentar estas líneas si las políticas no funcionan:

-- ALTER TABLE palabras_exclusivas DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE usuarios DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE ranking DISABLE ROW LEVEL SECURITY;

-- ========================================
-- VERIFICACIÓN FINAL
-- ========================================

-- Ver estado RLS de las tablas
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity = true THEN '🔒 RLS Activado'
        ELSE '🔓 RLS Desactivado'
    END as estado_rls
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('palabras_exclusivas', 'usuarios', 'ranking');

-- Contar políticas por tabla
SELECT 
    tablename,
    COUNT(*) as num_politicas
FROM pg_policies 
WHERE tablename IN ('palabras_exclusivas', 'usuarios', 'ranking')
GROUP BY tablename;
