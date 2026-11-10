-- =====================================================================
-- Banco de sangre - Loja, Ecuador
-- 03_consultas.sql : 5 consultas (algebra relacional traducida a SQL)
-- Ejecutar DESPUES de 01_ddl.sql y 02_dml.sql.
-- =====================================================================

USE banco_sangre;

-- ---------------------------------------------------------------
-- Consulta 1 — Selección y proyección (operadores σ, π)
-- Listar las unidades disponibles que caducan en los próximos 30 días a partir del 09/11/2026, para usarlas primero o gestionar su transferencia antes de que se pierdan. Es la consulta más simple: un filtro con tres condiciones sobre una sola tabla, del que se extraen tres columnas.
--
-- Algebra relacional:
--   π codigo_unidad, componente, fecha_caducidad ( σ estado = 'DISPONIBLE' ∧ fecha_caducidad ≥ '2026-11-09' ∧ fecha_caducidad ≤ '2026-12-09' ( UNIDAD_SANGRE ) )
--
-- Resultado esperado: Se obtienen las dos unidades de glóbulos rojos que siguen disponibles y vencen entre el 09/11/2026 y el 09/12/2026: UN-2026-007 (caduca el 01/12/2026) y UN-2026-009 (caduca el 08/12/2026). El plasma no aparece porque caduca en 2027.
-- ---------------------------------------------------------------
SELECT u.codigo_unidad, u.componente, u.fecha_caducidad
FROM UNIDAD_SANGRE u
WHERE u.estado = 'DISPONIBLE'
  AND u.fecha_caducidad BETWEEN '2026-11-09' AND '2026-12-09'
ORDER BY u.fecha_caducidad;

-- ---------------------------------------------------------------
-- Consulta 2 — Reunión (operador ⋈) con selección y proyección
-- Buscar las unidades de glóbulos rojos disponibles que son compatibles con el tipo de sangre de una paciente (cédula 1101000003, tipo B+), que tiene una solicitud pendiente. Combina cuatro relaciones: paciente, compatibilidad, unidad y tipo de sangre.
--
-- Algebra relacional:
--   π u.codigo_unidad, t.grupo_abo, t.factor_rh, u.componente, u.fecha_caducidad (
--      σ p.cedula_paciente = '1101000003' ∧ c.componente = 'CGR' ∧ u.componente = 'CGR' ∧ u.estado = 'DISPONIBLE' (
--         ρ p (PACIENTE) ⋈ p.id_tipo = c.id_tipo_receptor ρ c (COMPATIBILIDAD)
--         ⋈ c.id_tipo_donante = u.id_tipo ρ u (UNIDAD_SANGRE) ⋈ u.id_tipo = t.id_tipo ρ t (TIPO_SANGRE) ) )
--
-- Resultado esperado: Se obtienen dos unidades compatibles con B+: UN-2026-007, de tipo O+, y UN-2026-009, de tipo B+. La unidad UN-2026-005 (O-) también sería compatible por tipo, pero no aparece porque fue descartada por un tamizaje reactivo.
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
-- Identificar los donantes que llenaron un formulario pero nunca completaron una donación (por ejemplo, porque su formulario fue no apto, su donación fue diferida o aún no se agenda). Es el caso típico de la diferencia: al conjunto de donantes con formulario se le resta el de los donantes que llegaron hasta la donación.
--
-- Algebra relacional:
--   CON_FORM ← π cedula ( FORMULARIO_DONACION )
--   CON_DON ← π f.cedula ( ρ f (FORMULARIO_DONACION) ⋈ f.id_formulario = e.id_formulario ρ e (EXAMEN_FISICO)
--                          ⋈ e.id_examen = i.id_examen ρ i (ENTREVISTA_MEDICA) ⋈ i.id_entrevista = n.id_entrevista ρ n (DONACION) )
--   π cedula, nombres, apellidos ( DONANTE ⋈ ( CON_FORM − CON_DON ) )
--
-- Resultado esperado: Se obtienen tres donantes: 1100000005 (su donación fue diferida por hemoglobina baja), 1100000006 (su formulario resultó no apto por un tatuaje reciente) y 1100000008 (es apta, pero la donación aún no se realiza). Se muestran sus cédulas, nombres y apellidos.
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
-- Encontrar las donaciones que tienen el tamizaje completo, es decir, que fueron analizadas para todos los marcadores usados en el banco. La división responde a preguntas del tipo «los que se relacionan con todos los elementos de un conjunto» y es el único operador que no puede expresarse con una simple reunión.
--
-- Algebra relacional:
--   DON_MARC ← π id_donacion, marcador ( PRUEBA_TAMIZAJE )
--   MARCADORES ← π marcador ( PRUEBA_TAMIZAJE )
--   π id_donacion, fecha_hora ( DONACION ⋈ ( DON_MARC ÷ MARCADORES ) )
--   donde  DON_MARC ÷ MARCADORES = π id_donacion (DON_MARC) − π id_donacion ( ( π id_donacion (DON_MARC) × MARCADORES ) − DON_MARC )
--
-- Resultado esperado: Se obtienen las donaciones 1 a 5, que tienen los seis marcadores (VIH, hepatitis B, hepatitis C, sífilis, Chagas y HTLV). La donación 6 no aparece porque su tamizaje está incompleto (falta HTLV), por lo que sus unidades siguen en cuarentena. Se muestran el identificador y la fecha y hora de cada donación.
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
-- Resumir el inventario disponible por tipo de sangre: cuántas unidades hay y qué volumen total suman, considerando solo los tipos con dos o más unidades. Sirve para ver en qué tipos hay reserva suficiente y en cuáles se debe convocar a donantes.
--
-- Algebra relacional:
--   σ unidades ≥ 2 ( γ grupo_abo, factor_rh ; COUNT(codigo_unidad) → unidades, SUM(volumen_ml) → volumen_total_ml
--                     ( σ estado = 'DISPONIBLE' ( UNIDAD_SANGRE ⋈ id_tipo TIPO_SANGRE ) ) )
--
-- Resultado esperado: Se obtienen dos tipos: O+ con 3 unidades disponibles (680 ml en total) y B+ con 2 unidades (480 ml). El tipo A+ tiene solo una unidad disponible, por lo que el filtro lo excluye.
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
