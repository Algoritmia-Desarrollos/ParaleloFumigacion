-- ========= CREACIÓN DE TABLAS PRINCIPALES =========

-- Tabla de Usuarios (Conectada a Supabase Auth, sin contraseña)
CREATE TABLE public.usuarios (
    id uuid NOT NULL PRIMARY KEY,
    nombre text NOT NULL,
    apellido text NOT NULL,
    email text NOT NULL UNIQUE,
    role text NOT NULL CHECK (role IN ('admin', 'operario', 'supervisor')),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT fk_auth_user FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Tabla de Clientes
CREATE TABLE public.clientes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre text UNIQUE NOT NULL
);

-- Tabla de Depósitos (Silos/Celdas)
CREATE TABLE public.depositos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre text NOT NULL,
    tipo text NOT NULL CHECK (tipo IN ('silo', 'celda')),
    cliente_id uuid REFERENCES public.clientes(id) ON DELETE CASCADE NOT NULL,
    capacidad_toneladas numeric,
    UNIQUE (cliente_id, nombre, tipo)
);

-- Tabla de Mercaderías
CREATE TABLE public.mercaderias (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre text UNIQUE NOT NULL
);

-- Tabla de Operaciones
CREATE TABLE public.operaciones (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone,
    cliente_id uuid REFERENCES public.clientes(id),
    deposito_id uuid REFERENCES public.depositos(id),
    mercaderia_id uuid REFERENCES public.mercaderias(id),
    supervisor_id uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
    operario_nombre text,
    estado text DEFAULT 'en curso' CHECK (estado IN ('en curso', 'finalizada')),
    tipo_registro text,
    metodo_fumigacion text,
    tratamiento text,
    modalidad text,
    toneladas numeric,
    producto_usado_cantidad numeric,
    deposito_origen_stock text,
    operacion_original_id uuid REFERENCES public.operaciones(id) ON DELETE CASCADE,
    estado_aprobacion text DEFAULT 'pendiente' CHECK (estado_aprobacion IN ('aprobado', 'pendiente', 'rechazado')),
    observacion_aprobacion text,
    fecha_aprobacion timestamp with time zone,
    observacion_finalizacion text,
    operario_nombre_finalizacion text,
    con_garantia boolean DEFAULT false,
    fecha_vencimiento_garantia date
);

-- Tabla de Stock
CREATE TABLE public.stock (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    deposito text NOT NULL,
    tipo_producto text NOT NULL,
    cantidad_kg numeric DEFAULT 0,
    cantidad_unidades numeric,
    UNIQUE(deposito, tipo_producto)
);

-- Tabla de Historial de Stock
CREATE TABLE public.historial_stock (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    tipo_movimiento text NOT NULL,
    deposito text NOT NULL,
    tipo_producto text NOT NULL,
    cantidad_kg_movido numeric,
    cantidad_unidades_movidas numeric,
    descripcion text,
    operacion_id uuid REFERENCES public.operaciones(id) ON DELETE SET NULL
);

-- Tabla de Checklist
CREATE TABLE public.checklist_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    operacion_id uuid NOT NULL REFERENCES public.operaciones(id) ON DELETE CASCADE,
    item text NOT NULL,
    completado boolean DEFAULT false,
    imagen_url text
);

-- Tabla de Limpiezas
CREATE TABLE public.limpiezas (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    deposito_id uuid NOT NULL REFERENCES public.depositos(id) ON DELETE CASCADE,
    fecha_limpieza date NOT NULL,
    fecha_garantia_limpieza date,
    observaciones text
);

-- Tabla de Muestreos
CREATE TABLE public.muestreos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    operacion_id uuid NOT NULL REFERENCES public.operaciones(id) ON DELETE CASCADE,
    observacion text,
    media_url text[]
);

-- Tabla de relación Operario <-> Cliente
CREATE TABLE public.operario_clientes (
    operario_id uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    cliente_id uuid NOT NULL REFERENCES public.clientes(id) ON DELETE CASCADE,
    PRIMARY KEY (operario_id, cliente_id)
);


-- ========= DATOS INICIALES =========

-- Insertar datos iniciales de stock
INSERT INTO public.stock (deposito, tipo_producto, cantidad_kg, cantidad_unidades) VALUES
('Fagaz', 'pastillas', 30, 10000),
('Fagaz', 'liquido', 60, null),
('Baigorria', 'pastillas', 45, 15000),
('Baigorria', 'liquido', 60, null);


-- ========= POLÍTICAS DE SEGURIDAD (RLS) =========

-- Habilitar RLS en todas las tablas
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.depositos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mercaderias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.historial_stock ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.limpiezas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.muestreos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operario_clientes ENABLE ROW LEVEL SECURITY;

-- Políticas para la tabla 'usuarios'
CREATE POLICY "Los admins pueden gestionar usuarios" ON public.usuarios FOR ALL
    USING ((SELECT role FROM public.usuarios WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Permitir a usuarios autenticados leer perfiles" ON public.usuarios FOR SELECT
    USING (auth.role() = 'authenticated');

-- Políticas para la tabla 'operario_clientes'
CREATE POLICY "Los admins pueden gestionar relaciones" ON public.operario_clientes FOR ALL
    USING ((SELECT role FROM public.usuarios WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Usuarios pueden ver sus propias relaciones" ON public.operario_clientes FOR SELECT
    USING (auth.uid() = operario_id);

-- Políticas Generales (Permitir a usuarios autenticados usar la app)
CREATE POLICY "Acceso a autenticados" ON public.clientes FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso a autenticados" ON public.depositos FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso a autenticados" ON public.mercaderias FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso a autenticados" ON public.operaciones FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso a autenticados" ON public.stock FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso a autenticados" ON public.historial_stock FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso a autenticados" ON public.checklist_items FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso a autenticados" ON public.limpiezas FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso a autenticados" ON public.muestreos FOR ALL USING (auth.role() = 'authenticated');