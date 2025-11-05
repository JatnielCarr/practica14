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

-- Políticas de acceso (permitir todo por simplicidad)
DROP POLICY IF EXISTS "Allow all on palabras_exclusivas" ON palabras_exclusivas;
DROP POLICY IF EXISTS "Allow all on usuarios" ON usuarios;
DROP POLICY IF EXISTS "Allow all on ranking" ON ranking;

CREATE POLICY "Allow all on palabras_exclusivas" ON palabras_exclusivas FOR ALL USING (true);
CREATE POLICY "Allow all on usuarios" ON usuarios FOR ALL USING (true);
CREATE POLICY "Allow all on ranking" ON ranking FOR ALL USING (true);

