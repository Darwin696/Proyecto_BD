-- =====================================================================
-- Banco de sangre - Loja, Ecuador
-- 03_consultas.sql : 5 consultas (algebra relacional traducida a SQL)
-- Ejecutar DESPUES de 01_ddl.sql y 02_dml.sql.
-- =====================================================================

USE banco_sangre;

-- ---------------------------------------------------------------
-- Consulta 1 — Selección y proyección (operadores σ, π)
-- Unidades disponibles que caducan en los próximos 30 días desde el 09/11/2026 (para usarlas primero o transferirlas).
-- Resultado esperado: Dos unidades de globulos rojos: UN-2026-007 (01/12/2026) y UN-2026-009 (08/12/2026).
-- ---------------------------------------------------------------
SELECT u.codigo_unidad, u.componente, u.fecha_caducidad
FROM UNIDAD_SANGRE u
WHERE u.estado = 'DISPONIBLE'
  AND u.fecha_caducidad BETWEEN '2026-11-09' AND '2026-12-09'
ORDER BY u.fecha_caducidad;

-- ---------------------------------------------------------------
-- Consulta 2 — Reunión (operador ⋈) con selección y proyección
-- Unidades de glóbulos rojos disponibles compatibles con la paciente 1101000003 (tipo B+), que tiene una solicitud pendiente. Une cuatro tablas: paciente, compatibilidad, unidad y tipo de sangre.
-- Resultado esperado: Dos unidades compatibles: UN-2026-007 (O+) y UN-2026-009 (B+).
-- ---------------------------------------------------------------
SELECT u.codigo_unidad, t.grupo_abo, t.factor_rh, u.componente,
       u.fecha_caducidad
FROM PACIENTE p
JOIN COMPATIBILIDAD c ON c.id_tipo_receptor = p.id_tipo
JOIN UNIDAD_SANGRE u  ON u.id_tipo = c.id_tipo_donante
JOIN TIPO_SANGRE t    ON t.id_tipo = u.id_tipo
WHERE p.cedula_paciente = '1101000003'
  AND c.componente = 'CGR'
  AND u.componente = 'CGR'
  AND u.estado = 'DISPONIBLE'
ORDER BY u.fecha_caducidad;

-- ---------------------------------------------------------------
-- Consulta 3 — Diferencia (operador −)
-- Donantes que llenaron un formulario pero nunca completaron una donación: a los donantes con formulario se les resta los que llegaron a donar.
-- Resultado esperado: Tres donantes: 1100000005, 1100000006 y 1100000008.
-- ---------------------------------------------------------------
SELECT d.cedula, d.nombres, d.apellidos
FROM DONANTE d
WHERE d.cedula IN (SELECT f.cedula FROM FORMULARIO_DONACION f)
  AND d.cedula NOT IN (
        SELECT f.cedula
        FROM FORMULARIO_DONACION f
        JOIN EXAMEN_FISICO e      ON e.id_formulario = f.id_formulario
        JOIN ENTREVISTA_MEDICA i  ON i.id_examen = e.id_examen
        JOIN DONACION n           ON n.id_entrevista = i.id_entrevista)
ORDER BY d.cedula;

-- ---------------------------------------------------------------
-- Consulta 4 — División (operador ÷)
-- Donaciones con tamizaje completo, es decir, analizadas para todos los marcadores. La división responde a «los que se relacionan con todos los elementos de un conjunto».
-- Resultado esperado: Donaciones 1 a 5 (la 6 no tiene el marcador HTLV).
-- ---------------------------------------------------------------
SELECT n.id_donacion, n.fecha_hora
FROM DONACION n
WHERE NOT EXISTS (
        SELECT m.marcador
        FROM (SELECT DISTINCT marcador FROM PRUEBA_TAMIZAJE) m
        WHERE NOT EXISTS (
                SELECT 1
                FROM PRUEBA_TAMIZAJE p
                WHERE p.id_donacion = n.id_donacion
                  AND p.marcador = m.marcador))
ORDER BY n.id_donacion;

-- ---------------------------------------------------------------
-- Consulta 5 — Agrupamiento y funciones de agregación (operador γ)
-- Inventario disponible por tipo de sangre (unidades y volumen total), solo para tipos con dos o más unidades; sirve para decidir en qué tipos convocar donantes.
-- Resultado esperado: O+ con 3 unidades (680 ml) y B+ con 2 unidades (480 ml).
-- ---------------------------------------------------------------
SELECT t.grupo_abo, t.factor_rh,
       COUNT(u.codigo_unidad) AS unidades,
       SUM(u.volumen_ml)      AS volumen_total_ml
FROM UNIDAD_SANGRE u
JOIN TIPO_SANGRE t ON t.id_tipo = u.id_tipo
WHERE u.estado = 'DISPONIBLE'
GROUP BY t.grupo_abo, t.factor_rh
HAVING COUNT(u.codigo_unidad) >= 2
ORDER BY unidades DESC, t.grupo_abo;
