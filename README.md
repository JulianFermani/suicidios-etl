SCRIPTS:

-- 1. Provincia que tiene el mayor número de suicidios desde 2017 a 2023.

```sql
SELECT
  p.id_iso AS iso_provincia,
  p.iso_nombre AS provincia,
  COUNT(s.id) AS total_suicidios
FROM
  public.suicidio s
JOIN
sql
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
GROUP BY
  p.id_iso,
  p.iso_nombre
ORDER BY
  total_suicidios DESC;
```

-- 2. Horarios frecuentes de suicidio en la provincia de Córdoba.

```sql
SELECT
  -- Extraemos la parte antes del primer punto '.' en hora_hecho
  CASE
    WHEN position('.' IN s.hora_hecho) > 0 THEN
      LEFT(s.hora_hecho, position('.' IN s.hora_hecho) - 1)
    ELSE
      s.hora_hecho
  END AS hora_texto,
  -- Convertimos esa hora a entero para ordenar o filtrar
  CAST(
    CASE
      WHEN position('.' IN s.hora_hecho) > 0 THEN
        LEFT(s.hora_hecho, position('.' IN s.hora_hecho) - 1)
      ELSE
        s.hora_hecho
    END AS INTEGER
  ) AS hora_entero,
  COUNT(*) AS cantidad_suicidios
FROM
  public.suicidio s
JOIN
  public.provincia p ON s.id_provincia = p.id
WHERE
  p.iso_nombre = 'Córdoba'
  AND s.hora_hecho IS NOT NULL
  AND s.hora_hecho <> ''
GROUP BY
  hora_texto, hora_entero
ORDER BY
  hora_entero ASC;
```

-- 3. Cantidad de personas menores de edad que cometieron suicidio.

```sql
SELECT
  CASE
    WHEN suicida_18_anios_o_mas = 'Si' THEN 'Mayor o igual a 18 años'
    WHEN suicida_18_anios_o_mas = 'No' THEN 'Menor de 18 años'
    WHEN suicida_18_anios_o_mas = 'Sin determinación' THEN 'Sin determinación'
    ELSE 'Desconocido'
  END AS grupo_edad,
  COUNT(*) AS cantidad
FROM
  public.suicidio
GROUP BY
  grupo_edad
ORDER BY
  cantidad DESC;
```
