-- ═══════════════════════════════════════════════════════════
--  Módulo: Materias Primas — Índices, Vista, SPs y Permisos
--  Base de datos: dulce_migaja
--  Ejecutar como root en MySQL Workbench
--
--  Contenido:
--    1. Índices adicionales en `materias_primas`
--    2. Vista    — vw_materias_primas
--    3. SP       — sp_crear_materia_prima
--    4. SP       — sp_editar_materia_prima
--    5. SP       — sp_toggle_materia_prima
--    6. Permisos — GRANT EXECUTE a rol_admin / rol_empleado / rol_panadero
-- ═══════════════════════════════════════════════════════════

USE dulce_migaja;

-- ─────────────────────────────────────────────────────────
--  1. ÍNDICES
--     • idx_mp_nombre   → búsqueda/ordenamiento por nombre
--     • idx_mp_estatus  → filtrado activo/inactivo
--     • idx_mp_categoria → filtrado por categoría
-- ─────────────────────────────────────────────────────────
CREATE INDEX idx_mp_nombre    ON materias_primas (nombre);
CREATE INDEX idx_mp_estatus   ON materias_primas (estatus);
CREATE INDEX idx_mp_categoria ON materias_primas (categoria);


-- ─────────────────────────────────────────────────────────
--  2. VISTA — vw_materias_primas
--     Agrega la columna calculada `nivel_stock`:
--       • 'critico' → stock_actual <= 0
--       • 'bajo'    → 0 < stock_actual <= stock_minimo
--       • 'normal'  → stock_actual  > stock_minimo
-- ─────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_materias_primas AS
SELECT
    mp.id_materia,
    mp.uuid_materia,
    mp.nombre,
    mp.categoria,
    mp.unidad_base,
    mp.stock_actual,
    mp.stock_minimo,
    mp.estatus,
    mp.creado_en,
    mp.actualizado_en,
    CASE
        WHEN mp.stock_actual <= 0                                           THEN 'critico'
        WHEN mp.stock_actual > 0 AND mp.stock_actual <= mp.stock_minimo     THEN 'bajo'
        ELSE                                                                     'normal'
    END AS nivel_stock
FROM materias_primas mp;


-- ─────────────────────────────────────────────────────────
--  3. SP — sp_crear_materia_prima
--     Alta de una nueva materia prima.
--     Valida: nombre obligatorio · unidad_base obligatoria ·
--             nombre único (case-insensitive).
--     Inserta en materias_primas y deja traza en logs_sistema.
--     Retorna: id_materia del registro creado.
-- ─────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_crear_materia_prima;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_crear_materia_prima(
    IN  p_uuid         VARCHAR(36)    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_nombre       VARCHAR(120)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_categoria    VARCHAR(60)    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_unidad_base  VARCHAR(20)    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_stock_minimo DECIMAL(12,4),
    IN  p_estatus      VARCHAR(10)    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_creado_por   INT
)
BEGIN
    -- Validar nombre obligatorio
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre de la materia prima es obligatorio.';
    END IF;

    -- Validar unidad_base obligatoria
    IF p_unidad_base IS NULL OR TRIM(p_unidad_base) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La unidad base es obligatoria.';
    END IF;

    -- Validar nombre único (case-insensitive)
    IF EXISTS (
        SELECT 1 FROM materias_primas
        WHERE  LOWER(nombre) = LOWER(TRIM(p_nombre))
        LIMIT  1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe una materia prima con ese nombre.';
    END IF;

    -- Insertar materia prima
    INSERT INTO materias_primas (
        uuid_materia,   nombre,        categoria,
        unidad_base,    stock_actual,  stock_minimo,
        estatus,        creado_en,     actualizado_en,
        creado_por
    ) VALUES (
        p_uuid,
        TRIM(p_nombre),
        NULLIF(TRIM(p_categoria), ''),
        TRIM(p_unidad_base),
        0,
        IFNULL(p_stock_minimo, 0),
        IF(p_estatus IN ('activo', 'inactivo'), p_estatus, 'activo'),
        NOW(),
        NOW(),
        p_creado_por
    );

    -- Auditoría en logs_sistema
    INSERT INTO logs_sistema (
        tipo,         nivel,  id_usuario,  modulo,
        accion,       descripcion,         creado_en
    ) VALUES (
        'ajuste_inv', 'INFO', p_creado_por, 'materias_primas',
        'CREAR',
        CONCAT('Materia prima creada: ', TRIM(p_nombre)),
        NOW()
    );

    -- Retornar el id generado
    SELECT LAST_INSERT_ID() AS id_materia;
END ;;
DELIMITER ;


-- ─────────────────────────────────────────────────────────
--  4. SP — sp_editar_materia_prima
--     Actualiza datos de una materia prima existente.
--     Valida: existencia · nombre obligatorio ·
--             unidad_base obligatoria · nombre único.
-- ─────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_editar_materia_prima;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_editar_materia_prima(
    IN  p_id_materia   INT,
    IN  p_nombre       VARCHAR(120)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_categoria    VARCHAR(60)    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_unidad_base  VARCHAR(20)    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_stock_minimo DECIMAL(12,4),
    IN  p_estatus      VARCHAR(10)    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_ejecutado_por INT
)
BEGIN
    -- Verificar que la materia prima exista
    IF NOT EXISTS (
        SELECT 1 FROM materias_primas WHERE id_materia = p_id_materia
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La materia prima no existe.';
    END IF;

    -- Validar nombre obligatorio
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre de la materia prima es obligatorio.';
    END IF;

    -- Validar unidad_base obligatoria
    IF p_unidad_base IS NULL OR TRIM(p_unidad_base) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La unidad base es obligatoria.';
    END IF;

    -- Validar nombre único excluyendo el propio registro
    IF EXISTS (
        SELECT 1 FROM materias_primas
        WHERE  LOWER(nombre) = LOWER(TRIM(p_nombre))
          AND  id_materia    <> p_id_materia
        LIMIT  1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe otra materia prima con ese nombre.';
    END IF;

    UPDATE materias_primas
    SET nombre         = TRIM(p_nombre),
        categoria      = NULLIF(TRIM(p_categoria), ''),
        unidad_base    = TRIM(p_unidad_base),
        stock_minimo   = IFNULL(p_stock_minimo, stock_minimo),
        estatus        = IF(p_estatus IN ('activo', 'inactivo'), p_estatus, estatus),
        actualizado_en = NOW()
    WHERE id_materia = p_id_materia;

    -- Auditoría
    INSERT INTO logs_sistema (
        tipo,         nivel,  id_usuario,     modulo,
        accion,       descripcion,            creado_en
    ) VALUES (
        'ajuste_inv', 'INFO', p_ejecutado_por, 'materias_primas',
        'EDITAR',
        CONCAT('Materia prima editada: ', TRIM(p_nombre), ' (id=', p_id_materia, ')'),
        NOW()
    );
END ;;
DELIMITER ;


-- ─────────────────────────────────────────────────────────
--  5. SP — sp_toggle_materia_prima
--     Alterna estatus activo ↔ inactivo de una materia prima.
--     Retorna: nuevo_estatus y nombre para el flash message.
-- ─────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_toggle_materia_prima;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_toggle_materia_prima(
    IN  p_id_materia    INT,
    IN  p_ejecutado_por INT
)
BEGIN
    DECLARE v_estatus_actual VARCHAR(10);
    DECLARE v_nombre         VARCHAR(120);
    DECLARE v_nuevo_estatus  VARCHAR(10);

    -- Leer estado actual
    SELECT estatus, nombre
    INTO   v_estatus_actual, v_nombre
    FROM   materias_primas
    WHERE  id_materia = p_id_materia;

    IF v_estatus_actual IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La materia prima no existe.';
    END IF;

    SET v_nuevo_estatus = IF(v_estatus_actual = 'activo', 'inactivo', 'activo');

    UPDATE materias_primas
    SET estatus        = v_nuevo_estatus,
        actualizado_en = NOW()
    WHERE id_materia = p_id_materia;

    -- Auditoría
    INSERT INTO logs_sistema (
        tipo,         nivel,  id_usuario,     modulo,
        accion,       descripcion,            creado_en
    ) VALUES (
        'ajuste_inv', 'INFO', p_ejecutado_por, 'materias_primas',
        'TOGGLE_ESTATUS',
        CONCAT('Materia prima "', v_nombre, '" cambiada a ', v_nuevo_estatus),
        NOW()
    );

    -- Retornar resultado para uso en Flask
    SELECT v_nuevo_estatus AS nuevo_estatus,
           v_nombre        AS nombre;
END ;;
DELIMITER ;


-- ─────────────────────────────────────────────────────────
--  6. PERMISOS
--     Los tres roles operativos pueden ejecutar los SPs.
--     (rol_admin, rol_empleado, rol_panadero ya tienen
--      SELECT sobre la vista por herencia de tabla.)
-- ─────────────────────────────────────────────────────────
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_materia_prima  TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_materia_prima TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_toggle_materia_prima TO rol_admin;

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_materia_prima  TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_materia_prima TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_toggle_materia_prima TO rol_empleado;

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_materia_prima  TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_materia_prima TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_toggle_materia_prima TO rol_panadero;

FLUSH PRIVILEGES;

-- Verificar
SHOW GRANTS FOR rol_admin;
SHOW GRANTS FOR rol_empleado;
SHOW GRANTS FOR rol_panadero;
