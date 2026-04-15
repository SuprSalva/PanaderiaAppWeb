-- ============================================================
-- sp_crear_receta
-- Recibe los insumos vía tabla temporal tmp_insumos_receta
-- que Python crea y llena ANTES de llamar al SP.
-- Devuelve el id de la receta creada por parámetro OUT.
-- ============================================================

DROP PROCEDURE IF EXISTS `sp_crear_receta`;
DELIMITER $$
CREATE PROCEDURE `sp_crear_receta`(
    IN  p_uuid               VARCHAR(36),
    IN  p_id_producto        INT,
    IN  p_nombre             VARCHAR(120),
    IN  p_descripcion        TEXT,
    IN  p_rendimiento        DECIMAL(10,2),
    IN  p_unidad_rendimiento VARCHAR(20),
    IN  p_precio_venta       DECIMAL(10,2),
    IN  p_creado_por         INT,
    OUT p_id_receta          INT
)
BEGIN
    -- ── Validaciones ──────────────────────────────────────────
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre de la receta es obligatorio.';
    END IF;

    IF p_rendimiento IS NULL OR p_rendimiento <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El rendimiento debe ser mayor a 0.';
    END IF;

    IF p_id_producto IS NOT NULL AND p_id_producto <> 0 AND
       NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = p_id_producto) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El producto seleccionado no existe.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM recetas
        WHERE  CONVERT(nombre USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
             = CONVERT(TRIM(p_nombre) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
        LIMIT 1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe una receta con ese nombre.';
    END IF;

    -- ── Insertar encabezado ───────────────────────────────────
    INSERT INTO recetas (
        uuid_receta, id_producto, nombre, descripcion,
        rendimiento, unidad_rendimiento, precio_venta,
        estatus, creado_en, actualizado_en, creado_por
    ) VALUES (
        p_uuid,
        NULLIF(p_id_producto, 0),
        TRIM(p_nombre),
        NULLIF(TRIM(IFNULL(p_descripcion, '')), ''),
        p_rendimiento,
        p_unidad_rendimiento,
        NULLIF(p_precio_venta, 0),
        'activo',
        NOW(), NOW(),
        p_creado_por
    );

    SET p_id_receta = LAST_INSERT_ID();

    -- ── Insertar detalles desde la tabla temporal ─────────────
    INSERT INTO detalle_recetas
        (id_receta, id_materia, id_unidad_presentacion,
         cantidad_presentacion, cantidad_requerida, orden)
    SELECT
        p_id_receta,
        id_materia,
        id_unidad_presentacion,
        cantidad_presentacion,
        cantidad_requerida,
        orden
    FROM tmp_insumos_receta;

    -- ── Auditoría ─────────────────────────────────────────────
    INSERT INTO logs_sistema (
        tipo, nivel, id_usuario, modulo, accion, descripcion, creado_en
    ) VALUES (
        'produccion', 'INFO', p_creado_por, 'recetas',
        'CREAR',
        CONCAT('Receta creada: ', TRIM(p_nombre)),
        NOW()
    );

    -- ── Limpiar tabla temporal ────────────────────────────────
    DROP TEMPORARY TABLE IF EXISTS tmp_insumos_receta;
END$$
DELIMITER ;


-- ============================================================
-- sp_editar_receta
-- Igual: recibe insumos vía tmp_insumos_receta,
-- reemplaza todos los detalles en una sola operación.
-- ============================================================

DROP PROCEDURE IF EXISTS `sp_editar_receta`;
DELIMITER $$
CREATE PROCEDURE `sp_editar_receta`(
    IN p_id_receta          INT,
    IN p_id_producto        INT,
    IN p_nombre             VARCHAR(120),
    IN p_descripcion        TEXT,
    IN p_rendimiento        DECIMAL(10,2),
    IN p_unidad_rendimiento VARCHAR(20),
    IN p_precio_venta       DECIMAL(10,2),
    IN p_ejecutado_por      INT
)
BEGIN
    -- ── Validaciones ──────────────────────────────────────────
    IF NOT EXISTS (SELECT 1 FROM recetas WHERE id_receta = p_id_receta) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La receta no existe.';
    END IF;

    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre de la receta es obligatorio.';
    END IF;

    IF p_rendimiento IS NULL OR p_rendimiento <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El rendimiento debe ser mayor a 0.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM recetas
        WHERE  CONVERT(nombre USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
             = CONVERT(TRIM(p_nombre) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
          AND  id_receta <> p_id_receta
        LIMIT 1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe otra receta con ese nombre.';
    END IF;

    -- ── Actualizar encabezado ─────────────────────────────────
    UPDATE recetas SET
        id_producto        = NULLIF(p_id_producto, 0),
        nombre             = TRIM(p_nombre),
        descripcion        = NULLIF(TRIM(IFNULL(p_descripcion, '')), ''),
        rendimiento        = p_rendimiento,
        unidad_rendimiento = p_unidad_rendimiento,
        precio_venta       = NULLIF(p_precio_venta, 0),
        actualizado_en     = NOW()
    WHERE id_receta = p_id_receta;

    -- ── Reemplazar detalles ───────────────────────────────────
    DELETE FROM detalle_recetas WHERE id_receta = p_id_receta;

    INSERT INTO detalle_recetas
        (id_receta, id_materia, id_unidad_presentacion,
         cantidad_presentacion, cantidad_requerida, orden)
    SELECT
        p_id_receta,
        id_materia,
        id_unidad_presentacion,
        cantidad_presentacion,
        cantidad_requerida,
        orden
    FROM tmp_insumos_receta;

    -- ── Auditoría ─────────────────────────────────────────────
    INSERT INTO logs_sistema (
        tipo, nivel, id_usuario, modulo, accion, descripcion, creado_en
    ) VALUES (
        'produccion', 'INFO', p_ejecutado_por, 'recetas',
        'EDITAR',
        CONCAT('Receta editada: ', TRIM(p_nombre)),
        NOW()
    );

    -- ── Limpiar tabla temporal ────────────────────────────────
    DROP TEMPORARY TABLE IF EXISTS tmp_insumos_receta;
END$$
DELIMITER ;