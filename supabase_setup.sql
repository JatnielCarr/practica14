-- Script SQL para configurar la base de datos en Supabase
-- Ejecuta este script en el SQL Editor de Supabase Dashboard

-- Tabla palabras_exclusivas (palabras que deben aparecer en el crucigrama)
CREATE TABLE IF NOT EXISTS palabras_exclusivas (
    id BIGSERIAL PRIMARY KEY,
    palabra TEXT UNIQUE NOT NULL
);

-- Insertar palabras iniciales
INSERT INTO palabras_exclusivas (palabra) VALUES
    ('Kirito'),
    ('gromechi'),
    ('pablini'),
    ('secuaz'),
    ('niño'),
    ('celismar')
ON CONFLICT (palabra) DO NOTHING;

-- Tabla usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla ranking (basado en tiempo - menor tiempo es mejor)
CREATE TABLE IF NOT EXISTS ranking (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    tiempo_en_milisegundos BIGINT NOT NULL,
    fecha_completado TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_ranking_user_id ON ranking(user_id);
CREATE INDEX IF NOT EXISTS idx_ranking_tiempo ON ranking(tiempo_en_milisegundos ASC);
CREATE INDEX IF NOT EXISTS idx_usuarios_username ON usuarios(username);

-- Habilitar Row Level Security (RLS) - Opcional pero recomendado
ALTER TABLE palabras_exclusivas ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE ranking ENABLE ROW LEVEL SECURITY;

-- Políticas de acceso (permitir lectura y escritura pública por simplicidad)
-- IMPORTANTE: Eliminar políticas existentes primero
DROP POLICY IF EXISTS "Allow all on palabras_exclusivas" ON palabras_exclusivas;
DROP POLICY IF EXISTS "Allow all on usuarios" ON usuarios;
DROP POLICY IF EXISTS "Allow all on ranking" ON ranking;

DROP POLICY IF EXISTS "Enable read for palabras_exclusivas" ON palabras_exclusivas;
DROP POLICY IF EXISTS "Enable read for usuarios" ON usuarios;
DROP POLICY IF EXISTS "Enable read for ranking" ON ranking;
DROP POLICY IF EXISTS "Enable insert for usuarios" ON usuarios;
DROP POLICY IF EXISTS "Enable insert for ranking" ON ranking;

-- Crear políticas más específicas
-- Palabras exclusivas: Solo lectura
CREATE POLICY "Enable read for palabras_exclusivas" ON palabras_exclusivas 
    FOR SELECT USING (true);

-- Usuarios: Lectura y creación
CREATE POLICY "Enable read for usuarios" ON usuarios 
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for usuarios" ON usuarios 
    FOR INSERT WITH CHECK (true);

-- Ranking: Lectura y creación
CREATE POLICY "Enable read for ranking" ON ranking 
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for ranking" ON ranking 
    FOR INSERT WITH CHECK (true);

-- ALTERNATIVA SI LAS POLÍTICAS ESPECÍFICAS NO FUNCIONAN:
-- Descomentar las siguientes líneas y comentar las políticas específicas arriba

-- DROP POLICY IF EXISTS "Enable read for palabras_exclusivas" ON palabras_exclusivas;
-- DROP POLICY IF EXISTS "Enable read for usuarios" ON usuarios;
-- DROP POLICY IF EXISTS "Enable read for ranking" ON ranking;
-- DROP POLICY IF EXISTS "Enable insert for usuarios" ON usuarios;
-- DROP POLICY IF EXISTS "Enable insert for ranking" ON ranking;

-- CREATE POLICY "Allow all on palabras_exclusivas" ON palabras_exclusivas FOR ALL USING (true) WITH CHECK (true);
-- CREATE POLICY "Allow all on usuarios" ON usuarios FOR ALL USING (true) WITH CHECK (true);
-- CREATE POLICY "Allow all on ranking" ON ranking FOR ALL USING (true) WITH CHECK (true);

-- Verificar que las políticas se crearon correctamente
-- Ejecuta esto después para verificar:
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
-- FROM pg_policies 
-- WHERE tablename IN ('palabras_exclusivas', 'usuarios', 'ranking');

