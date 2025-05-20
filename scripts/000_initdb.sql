-- 1. Provincia que tiene el mayor número de suicidios desde 2017 a 2023.
-- Suicidios: id_hecho, id_provincia, id_departamento, id_localidad, fecha_hecho, hora_hecho, suicida_18_años_o_mas
-- Provincias: id, iso_nombre
-- Departamentos: id, nombre, id_provincia
-- Crear tabla de provincias
CREATE TABLE public.provincia (
    id BIGINT PRIMARY KEY,
    iso_nombre VARCHAR,
    id_iso VARCHAR
);

-- Crear tabla de departamentos
CREATE TABLE public.departamento (
    id BIGINT PRIMARY KEY,
    nombre VARCHAR,
    id_provincia BIGINT,
    FOREIGN KEY(id_provincia) REFERENCES provincia(id)
);

-- Crear tabla de suicidios (AGREGADO: departamento_nombre)
CREATE TABLE public.suicidio(
    id serial PRIMARY KEY,
    id_provincia BIGINT,
    FOREIGN KEY(id_provincia) REFERENCES provincia(id),
    fecha_hecho VARCHAR,
    hora_hecho VARCHAR,
    suicida_18_anios_o_mas VARCHAR,
    departamento_nombre TEXT  -- agregado
);

-- Tablas temporales para importar CSV
CREATE TEMPORARY TABLE provincia_temp (
    categoria VARCHAR,
    centroide_lat FLOAT,
    centroide_lon FLOAT,
    fuente VARCHAR,
    id VARCHAR,
    iso_id VARCHAR,
    iso_nombre VARCHAR,
    nombre VARCHAR,
    nombre_completo VARCHAR
);

CREATE TEMPORARY TABLE temp_departamento (
    categoria VARCHAR,
    centroide_lat FLOAT,
    centroide_lon FLOAT,
    fuente VARCHAR,
    id VARCHAR,
    nombre VARCHAR,
    nombre_completo VARCHAR,
    provincia_id VARCHAR,
    provincia_interseccion FLOAT,
    provincia_nombre VARCHAR
);

CREATE TEMPORARY TABLE temp_suicidio (
    id_hecho INTEGER,
    tipo_persona_id TEXT,
    federal TEXT,
    provincia_id TEXT,
    provincia_nombre TEXT,
    departamento_id TEXT,
    departamento_nombre TEXT,
    localidad_id TEXT,
    localidad_nombre TEXT,
    anio TEXT,
    mes TEXT,
    fecha_hecho TEXT,
    hora_hecho TEXT,
    tipo_lugar TEXT,
    tipo_lugar_ampliado TEXT,
    tipo_lugar_otro TEXT,
    modalidad TEXT,
    modalidad_ampliado TEXT,
    modalidad_otro TEXT,
    motivo_origen_registro TEXT,
    motivo_origen_registro_otro TEXT,
    suicida_sexo TEXT,
    suicida_tr_edad TEXT,
    suicida_18_anios_o_mas TEXT,
    suicida_clase TEXT,
    suicida_clase_otro TEXT,
    suicida_identidad_genero TEXT
);

-- Cargar datos
COPY provincia_temp
FROM '/datos/provincias.csv' DELIMITER ',' CSV HEADER NULL '';

INSERT INTO public.provincia (id, iso_nombre, id_iso)
SELECT
    id::INTEGER,
    iso_nombre,
    iso_id
FROM provincia_temp;

COPY temp_departamento
FROM '/datos/departamentos.csv' DELIMITER ',' CSV HEADER NULL '';

INSERT INTO public.departamento (id, nombre, id_provincia)
SELECT
    id::INTEGER,
    nombre,
    provincia_id::INTEGER
FROM temp_departamento;

COPY temp_suicidio
FROM '/datos/tasa_de_suicidios.csv' DELIMITER ',' CSV HEADER NULL '';

-- Insertar datos en tabla suicidio, incluyendo departamento_nombre
INSERT INTO public.suicidio (
    id_provincia,
    fecha_hecho,
    hora_hecho,
    suicida_18_anios_o_mas,
    departamento_nombre
)
SELECT
    provincia_id::BIGINT,
    fecha_hecho::VARCHAR,
    hora_hecho::VARCHAR,
    suicida_18_anios_o_mas::VARCHAR,
    departamento_nombre::VARCHAR
FROM temp_suicidio;

-- Insertar provincias faltantes
INSERT INTO public.provincia (id, iso_nombre)
SELECT DISTINCT
    provincia_id::BIGINT,
    provincia_nombre
FROM temp_suicidio
WHERE provincia_id::BIGINT NOT IN (
    SELECT id FROM public.provincia
);

-- Insertar departamentos faltantes
INSERT INTO public.departamento (id, nombre, id_provincia)
SELECT DISTINCT
    departamento_id::BIGINT,
    departamento_nombre,
    provincia_id::BIGINT
FROM temp_suicidio
WHERE departamento_id::BIGINT NOT IN (
    SELECT id FROM public.departamento
);

-- 2. Horarios frecuentes de suicidio en la provincia de Córdoba.
-- 3. Cantidad de personas menores de edad que cometieron suicidio.
