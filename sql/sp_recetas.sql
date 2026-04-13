-- ═══════════════════════════════════════════════════════════
--  Módulo: Recetas — Vista, SPs y Permisos
--  Base de datos: dulce_migaja
--  Ejecutar como root en MySQL Workbench
--
--  Contenido:
--    1. Índices adicionales en `recetas`
--    2. Vista  — vw_recetas
--    3. SP     — sp_crear_receta
--    4. SP     — sp_editar_receta
--    5. SP     — sp_toggle_receta
--    6. Permisos — GRANT EXECUTE a rol_admin / rol_empleado / rol_panadero
-- ═══════════════════════════════════════════════════════════

USE dulce_migaja;

-- ─────────────────────────────────────────────────────────
--  1. ÍNDICES
-- ─────────────────────────────────────────────────────────
CREATE INDEX idx_rec_nombre  ON recetas (nombre);
CREATE INDEX idx_rec_estatus ON recetas (estatus);


-- ─────────────────────────────────────────────────────────
--  2. VISTA — vw_recetas
--     Une recetas con productos para obtener el nombre del
--     producto asociado, y cuenta los insumos distintos de
--     cada receta mediante una subconsulta agregada.
-- ─────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_recetas AS
SELECT
    r.id_receta,
    r.uuid_receta,
    r.nombre,
    r.descripcion,
    r.id_producto,
    p.nombre                                   AS producto_nombre,
    r.rendimiento,
    r.unidad_rendimiento,
    r.precio_venta,
    r.estatus,
    r.creado_en,
    r.actualizado_en,
    r.creado_por,
    IFNULL(ins.total_insumos, 0)               AS total_insumos
FROM recetas r
LEFT JOIN productos        p   ON p.id_producto = r.id_producto
LEFT JOIN (
    SELECT id_receta, COUNT(DISTINCT id_materia) AS total_insumos
    FROM   detalle_recetas
    GROUP  BY id_receta
) ins ON ins.id_receta = r.id_receta;


-- ─────────────────────────────────────────────────────────
--  3. SP — sp_crear_receta
--     Crea el encabezado de la receta.
--     Valida: nombre obligatorio · producto existente ·
--             nombre único (case-insensitive) · rendimiento > 0.
--     Los detalles (insumos) los inserta Python después de
--     obtener el id_receta retornado.
-- ─────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_crear_receta;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_crear_receta(
    IN  p_uuid              VARCHAR(36)    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_id_producto       INT,
    IN  p_nombre            VARCHAR(120)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_descripcion       TEXT           CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_rendimiento       DECIMAL(10,2),
    IN  p_unidad_rendimiento VARCHAR(20)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_precio_venta      DECIMAL(10,2),
    IN  p_creado_por        INT
)
BEGIN
    -- Validar nombre obligatorio
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre de la receta es obligatorio.';
    END IF;

    -- Validar rendimiento > 0
    IF p_rendimiento IS NULL OR p_rendimiento <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El rendimiento debe ser mayor a 0.';
    END IF;

    -- Validar que el producto exista (si se proporcionó)
    IF p_id_producto IS NOT NULL AND p_id_producto <> 0 AND
       NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = p_id_producto) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El producto seleccionado no existe.';
    END IF;

    -- Validar nombre único (case-insensitive)
    IF EXISTS (
        SELECT 1 FROM recetas
        WHERE  LOWER(nombre) = LOWER(TRIM(p_nombre))
        LIMIT  1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe una receta con ese nombre.';
    END IF;

    -- Insertar encabezado de receta
    INSERT INTO recetas (
        uuid_receta,       id_producto,      nombre,
        descripcion,       rendimiento,      unidad_rendimiento,
        precio_venta,      estatus,          creado_en,
        actualizado_en,    creado_por
    ) VALUES (
        p_uuid,
        NULLIF(p_id_producto, 0),
        TRIM(p_nombre),
        NULLIF(TRIM(IFNULL(p_descripcion, '')), ''),
        p_rendimiento,
        p_unidad_rendimiento,
        NULLIF(p_precio_venta, 0),
        'activo',
        NOW(),
        NOW(),
        p_creado_por
    );

    -- Auditoría
    INSERT INTO logs_sistema (
        tipo,         nivel,  id_usuario,  modulo,
        accion,       descripcion,         creado_en
    ) VALUES (
        'produccion', 'INFO', p_creado_por, 'recetas',
        'CREAR',
        CONCAT('Receta creada: ', TRIM(p_nombre)),
        NOW()
    );

    -- Retornar el id generado para que Python pueda insertar los detalles
    SELECT LAST_INSERT_ID() AS id_receta;
END ;;
DELIMITER ;


-- ─────────────────────────────────────────────────────────
--  4. SP — sp_editar_receta
--     Actualiza el encabezado de una receta existente.
--     Valida: existencia · nombre obligatorio ·
--             rendimiento > 0 · nombre único.
--     Los detalles los gestiona Python (delete + re-insert).
-- ─────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_editar_receta;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_editar_receta(
    IN  p_id_receta          INT,
    IN  p_id_producto        INT,
    IN  p_nombre             VARCHAR(120)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_descripcion        TEXT          CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_rendimiento        DECIMAL(10,2),
    IN  p_unidad_rendimiento VARCHAR(20)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_precio_venta       DECIMAL(10,2),
    IN  p_ejecutado_por      INT
)
BEGIN
    -- Verificar existencia
    IF NOT EXISTS (SELECT 1 FROM recetas WHERE id_receta = p_id_receta) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La receta no existe.';
    END IF;

    -- Validar nombre obligatorio
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre de la receta es obligatorio.';
    END IF;

    -- Validar rendimiento > 0
    IF p_rendimiento IS NULL OR p_rendimiento <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El rendimiento debe ser mayor a 0.';
    END IF;

    -- Validar producto existente (si se proporcionó)
    IF p_id_producto IS NOT NULL AND p_id_producto <> 0 AND
       NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = p_id_producto) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El producto seleccionado no existe.';
    END IF;

    -- Validar nombre único excluyendo el propio registro
    IF EXISTS (
        SELECT 1 FROM recetas
        WHERE  LOWER(nombre) = LOWER(TRIM(p_nombre))
          AND  id_receta     <> p_id_receta
        LIMIT  1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe otra receta con ese nombre.';
    END IF;

    UPDATE recetas
    SET id_producto        = NULLIF(p_id_producto, 0),
        nombre             = TRIM(p_nombre),
        descripcion        = NULLIF(TRIM(IFNULL(p_descripcion, '')), ''),
        rendimiento        = p_rendimiento,
        unidad_rendimiento = p_unidad_rendimiento,
        precio_venta       = NULLIF(p_precio_venta, 0),
        actualizado_en     = NOW()
    WHERE id_receta = p_id_receta;

    -- Auditoría
    INSERT INTO logs_sistema (
        tipo,         nivel,  id_usuario,     modulo,
        accion,       descripcion,            creado_en
    ) VALUES (
        'produccion', 'INFO', p_ejecutado_por, 'recetas',
        'EDITAR',
        CONCAT('Receta editada: ', TRIM(p_nombre), ' (id=', p_id_receta, ')'),
        NOW()
    );
END ;;
DELIMITER ;


-- ─────────────────────────────────────────────────────────
--  5. SP — sp_toggle_receta
--     Alterna estatus activo ↔ inactivo de una receta.
--     Retorna: nuevo_estatus y nombre para el flash message.
-- ─────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_toggle_receta;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_toggle_receta(
    IN  p_id_receta      INT,
    IN  p_ejecutado_por  INT
)
BEGIN
    DECLARE v_estatus_actual VARCHAR(10);
    DECLARE v_nombre         VARCHAR(120);
    DECLARE v_nuevo_estatus  VARCHAR(10);

    -- Leer estado actual
    SELECT estatus, nombre
    INTO   v_estatus_actual, v_nombre
    FROM   recetas
    WHERE  id_receta = p_id_receta;

    IF v_estatus_actual IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La receta no existe.';
    END IF;

    SET v_nuevo_estatus = IF(v_estatus_actual = 'activo', 'inactivo', 'activo');

    UPDATE recetas
    SET estatus        = v_nuevo_estatus,
        actualizado_en = NOW()
    WHERE id_receta = p_id_receta;

    -- Auditoría
    INSERT INTO logs_sistema (
        tipo,         nivel,  id_usuario,     modulo,
        accion,       descripcion,            creado_en
    ) VALUES (
        'produccion', 'INFO', p_ejecutado_por, 'recetas',
        'TOGGLE_ESTATUS',
        CONCAT('Receta "', v_nombre, '" cambiada a ', v_nuevo_estatus),
        NOW()
    );

    -- Retornar resultado
    SELECT v_nuevo_estatus AS nuevo_estatus,
           v_nombre        AS nombre;
END ;;
DELIMITER ;


-- ─────────────────────────────────────────────────────────
--  6. PERMISOS
-- ─────────────────────────────────────────────────────────
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_receta  TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_receta TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_toggle_receta TO rol_admin;

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_receta  TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_receta TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_toggle_receta TO rol_empleado;

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_receta  TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_receta TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_toggle_receta TO rol_panadero;

FLUSH PRIVILEGES;

-- Verificar
SHOW GRANTS FOR rol_admin;
SHOW GRANTS FOR rol_empleado;
SHOW GRANTS FOR rol_panadero;
