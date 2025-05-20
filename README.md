# ETL para análisis de suicidios en Argentina (2017–2023)

## 🧾 Descargo de responsabilidad

Este proyecto trata datos sensibles relacionados con suicidios en Argentina. El material se utiliza exclusivamente con fines educativos y de análisis de datos públicos. No se busca hacer apología ni minimizar la problemática.  
El código y las consultas se ofrecen "tal cual", sin garantía. Usalo con responsabilidad.

---

## 📂 Descarga de Datasets

Los datos provienen del portal de datos abiertos del gobierno argentino:  
🔗 [https://datos.gob.ar/dataset/seguridad-suicidios-sistema-alerta-temprana-estadisticas-criminales-republica-argentina](https://datos.gob.ar/dataset/seguridad-suicidios-sistema-alerta-temprana-estadisticas-criminales-republica-argentina)

---

## 📌 Descripción del Proyecto

Este proyecto implementa un pipeline ETL para analizar los suicidios registrados en Argentina entre 2017 y 2023. Utiliza:

- **PostgreSQL** para almacenar los datos.
- **Apache Superset** para visualizar y consultar.
- **Docker** para orquestar los servicios.

El objetivo es detectar patrones por provincia, edad y horarios frecuentes, y facilitar la exploración de los datos desde una interfaz amigable.

---

## ⚙️ Servicios en `docker-compose.yml`

```yaml
networks:
  net:
    external: false

volumes:
  postgres-db:
    external: false

services:
  db:
    image: postgres:alpine
    env_file:
      - .env.db
    restart: unless-stopped
    environment:
      - POSTGRES_INITDB_ARGS=--auth-host=md5 --auth-local=trust
    healthcheck:
      test: ["CMD-SHELL", "pg_isready"]
      interval: 10s
      timeout: 2s
      retries: 5
    ports:
      - 5433:5432
    volumes:
      - postgres-db:/var/lib/postgresql/data
      - ./scripts:/docker-entrypoint-initdb.d
      - ./datos:/datos
    networks:
      - net

  superset:
    image: apache/superset:4.0.0
    restart: unless-stopped
    env_file:
      - .env.db
    ports:
      - 8088:8088
    depends_on:
      db:
        condition: service_healthy
    networks:
      - net
```

---

## 🧭 Acceso a Apache Superset

Una vez levantados los contenedores con:

```bash
docker compose up -d
```

Accedé a Superset desde tu navegador:  
🔗 [http://localhost:8088](http://localhost:8088)

Credenciales por defecto (si no las cambiaste):  
**Usuario:** `admin` — **Contraseña:** `admin`

---

## 🧠 Consultas SQL principales

### 1. Provincia con más suicidios (2017–2023)

```sql
SELECT
  p.id_iso AS iso_provincia,
  p.iso_nombre AS provincia,
  COUNT(s.id) AS total_suicidios
FROM public.suicidio s
JOIN public.provincia p ON s.id_provincia = p.id
WHERE
  (CASE
    WHEN LENGTH(s.fecha_hecho) = 8 THEN
      CASE
        WHEN CAST(RIGHT(s.fecha_hecho, 2) AS INTEGER) BETWEEN 0 AND 23
          THEN 2000 + CAST(RIGHT(s.fecha_hecho, 2) AS INTEGER)
        ELSE
          1900 + CAST(RIGHT(s.fecha_hecho, 2) AS INTEGER)
      END
    ELSE NULL
  END) BETWEEN 2017 AND 2023
GROUP BY p.id_iso, p.iso_nombre
ORDER BY total_suicidios DESC;
```

### 2. Horas frecuentes de suicidio en el Departamento General José de San Martin, Córdoba

```sql
SELECT
  CASE
    WHEN position('.' IN s.hora_hecho) > 0 THEN
      LEFT(s.hora_hecho, position('.' IN s.hora_hecho) - 1)
    ELSE
      s.hora_hecho
  END AS hora_texto,
  CAST(
    CASE
      WHEN position('.' IN s.hora_hecho) > 0 THEN
        LEFT(s.hora_hecho, position('.' IN s.hora_hecho) - 1)
      ELSE
        s.hora_hecho
    END AS INTEGER
  ) AS hora_entero,
  COUNT(*) AS cantidad_suicidios
FROM public.suicidio s
JOIN public.provincia p ON s.id_provincia = p.id
WHERE p.iso_nombre = 'Córdoba'
  AND s.departamento_nombre = 'General San Martín'
  AND s.hora_hecho IS NOT NULL
  AND s.hora_hecho <> ''
GROUP BY hora_texto, hora_entero
ORDER BY hora_entero ASC;
```

### 3. Suicidios de menores de edad

```sql
SELECT
  CASE
    WHEN suicida_18_anios_o_mas = 'Si' THEN 'Mayor o igual a 18 años'
    WHEN suicida_18_anios_o_mas = 'No' THEN 'Menor de 18 años'
    WHEN suicida_18_anios_o_mas = 'Sin determinación' THEN 'Sin determinación'
    ELSE 'Desconocido'
  END AS grupo_edad,
  COUNT(*) AS cantidad
FROM public.suicidio
GROUP BY grupo_edad
ORDER BY cantidad DESC;
```

---

## 📁 Estructura del Proyecto

```
suicidios-etl/
├── datos/                       # Archivos CSV y datos de entrada
├── graficos/                    # Gráficos exportados con superset
├── scripts/                     # Scripts SQL para inicializar la base
├── .env.db                      # Variables de entorno
├── README.md                    # Documentación del proyecto
├── docker-compose.yml           # Definición de servicios Docker
└── init.sh                      # Script de inicialización

```
