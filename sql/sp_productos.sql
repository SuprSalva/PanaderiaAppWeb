-- ═══════════════════════════════════════════════════════════
--  Módulo: Productos — Vista y SPs
--  Base de datos: dulce_migaja
--  Ejecutar como root en MySQL Workbench
--
--  NOTA: sp_actualizar_imagen_producto ya existe en
--        productos_imagenes.sql — no se redefine aquí.
--
--  Contenido:
--    1. Índices adicionales en `productos`
--    2. Vista  — vw_productos
--    3. SP     — sp_crear_producto
--    4. SP     — sp_editar_producto
--    5. SP     — sp_toggle_producto
--    6. Permisos
-- ═══════════════════════════════════════════════════════════

USE dulce_migaja;

-- ─────────────────────────────────────────────────────────
--  1. ÍNDICES
-- ─────────────────────────────────────────────────────────
CREATE INDEX idx_prod_nombre  ON productos (nombre);
CREATE INDEX idx_prod_estatus ON productos (estatus);


-- ─────────────────────────────────────────────────────────
--  2. VISTA — vw_productos
--     Une productos con:
--       · inventario_pt  → stock_actual, stock_minimo
--       · recetas        → cantidad de recetas asociadas
-- ─────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_productos AS
SELECT
    p.id_producto,
    p.uuid_producto,
    p.nombre,
    p.descripcion,
    p.imagen_url,
    p.precio_venta,
    p.estatus,
    p.creado_en,
    p.actualizado_en,
    IFNULL(inv.stock_actual, 0)          AS stock_actual,
    IFNULL(inv.stock_minimo, 0)          AS stock_minimo,
    IFNULL(rec.total_recetas, 0)         AS total_recetas
FROM productos p
LEFT JOIN inventario_pt inv ON inv.id_producto = p.id_producto
LEFT JOIN (
    SELECT id_producto, COUNT(*) AS total_recetas
    FROM   recetas
    WHERE  id_producto IS NOT NULL
    GROUP  BY id_producto
) rec ON rec.id_producto = p.id_producto;


-- ─────────────────────────────────────────────────────────
--  3. SP — sp_crear_producto
--     Alta de un nuevo producto.
--     Valida: nombre obligatorio · precio > 0 · nombre único.
--     Inserta en `productos` e inicializa su registro en
--     `inventario_pt` (stock en 0).
--     Retorna: id_producto generado.
-- ─────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_crear_producto;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_crear_producto(
    IN  p_uuid        VARCHAR(36)    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_nombre      VARCHAR(120)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_descripcion TEXT           CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_precio_venta DECIMAL(10,2),
    IN  p_imagen_url  VARCHAR(255)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_creado_por  INT
)
BEGIN
    DECLARE v_id INT;

    -- Validar nombre obligatorio
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre del producto es obligatorio.';
    END IF;

    -- Validar precio > 0
    IF p_precio_venta IS NULL OR p_precio_venta <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El precio de venta debe ser mayor a 0.';
    END IF;

    -- Validar nombre único (case-insensitive)
    IF EXISTS (
        SELECT 1 FROM productos
        WHERE  LOWER(nombre) = LOWER(TRIM(p_nombre))
        LIMIT  1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe un producto con ese nombre.';
    END IF;

    -- Insertar producto
    INSERT INTO productos (
        uuid_producto,  nombre,         descripcion,
        imagen_url,     precio_venta,   estatus,
        creado_en,      actualizado_en, creado_por
    ) VALUES (
        p_uuid,
        TRIM(p_nombre),
        NULLIF(TRIM(IFNULL(p_descripcion, '')), ''),
        p_imagen_url,
        p_precio_venta,
        'activo',
        NOW(),
        NOW(),
        p_creado_por
    );

    SET v_id = LAST_INSERT_ID();

    -- Inicializar inventario (stock en 0)
    INSERT INTO inventario_pt (
        id_producto, stock_actual, stock_minimo, ultima_actualizacion
    ) VALUES (
        v_id, 0, 0, NOW()
    );

    -- Auditoría
    INSERT INTO logs_sistema (
        tipo,    nivel,  id_usuario,  modulo,
        accion,  descripcion,         creado_en
    ) VALUES (
        'venta', 'INFO', p_creado_por, 'productos',
        'CREAR',
        CONCAT('Producto creado: ', TRIM(p_nombre)),
        NOW()
    );

    SELECT v_id AS id_producto;
END ;;
DELIMITER ;


-- ─────────────────────────────────────────────────────────
--  4. SP — sp_editar_producto
--     Actualiza datos de un producto existente.
--     La imagen se gestiona por separado con
--     sp_actualizar_imagen_producto (ya existente).
--     Valida: existencia · nombre obligatorio ·
--             precio > 0 · nombre único.
-- ─────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_editar_producto;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_editar_producto(
    IN  p_id_producto  INT,
    IN  p_nombre       VARCHAR(120)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_descripcion  TEXT           CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_precio_venta DECIMAL(10,2),
    IN  p_ejecutado_por INT
)
BEGIN
    -- Verificar existencia
    IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = p_id_producto) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El producto no existe.';
    END IF;

    -- Validar nombre obligatorio
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre del producto es obligatorio.';
    END IF;

    -- Validar precio > 0
    IF p_precio_venta IS NULL OR p_precio_venta <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El precio de venta debe ser mayor a 0.';
    END IF;

    -- Validar nombre único excluyendo el propio registro
    IF EXISTS (
        SELECT 1 FROM productos
        WHERE  LOWER(nombre) = LOWER(TRIM(p_nombre))
          AND  id_producto   <> p_id_producto
        LIMIT  1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe otro producto con ese nombre.';
    END IF;

    UPDATE productos
    SET nombre         = TRIM(p_nombre),
        descripcion    = NULLIF(TRIM(IFNULL(p_descripcion, '')), ''),
        precio_venta   = p_precio_venta,
        actualizado_en = NOW()
    WHERE id_producto = p_id_producto;

    -- Auditoría
    INSERT INTO logs_sistema (
        tipo,    nivel,  id_usuario,     modulo,
        accion,  descripcion,            creado_en
    ) VALUES (
        'venta', 'INFO', p_ejecutado_por, 'productos',
        'EDITAR',
        CONCAT('Producto editado: ', TRIM(p_nombre), ' (id=', p_id_producto, ')'),
        NOW()
    );
END ;;
DELIMITER ;


-- ─────────────────────────────────────────────────────────
--  5. SP — sp_toggle_producto
--     Alterna estatus activo ↔ inactivo de un producto.
--     Retorna: nuevo_estatus y nombre para el flash message.
-- ─────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_toggle_producto;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_toggle_producto(
    IN  p_id_producto   INT,
    IN  p_ejecutado_por INT
)
BEGIN
    DECLARE v_estatus_actual VARCHAR(10);
    DECLARE v_nombre         VARCHAR(120);
    DECLARE v_nuevo_estatus  VARCHAR(10);

    -- Leer estado actual
    SELECT estatus, nombre
    INTO   v_estatus_actual, v_nombre
    FROM   productos
    WHERE  id_producto = p_id_producto;

    IF v_estatus_actual IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El producto no existe.';
    END IF;

    SET v_nuevo_estatus = IF(v_estatus_actual = 'activo', 'inactivo', 'activo');

    UPDATE productos
    SET estatus        = v_nuevo_estatus,
        actualizado_en = NOW()
    WHERE id_producto = p_id_producto;

    -- Auditoría
    INSERT INTO logs_sistema (
        tipo,    nivel,  id_usuario,     modulo,
        accion,  descripcion,            creado_en
    ) VALUES (
        'venta', 'INFO', p_ejecutado_por, 'productos',
        'TOGGLE_ESTATUS',
        CONCAT('Producto "', v_nombre, '" cambiado a ', v_nuevo_estatus),
        NOW()
    );

    SELECT v_nuevo_estatus AS nuevo_estatus,
           v_nombre        AS nombre;
END ;;
DELIMITER ;


-- ─────────────────────────────────────────────────────────
--  6. PERMISOS
-- ─────────────────────────────────────────────────────────
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_producto  TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_producto TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_toggle_producto TO rol_admin;

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_producto  TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_producto TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_toggle_producto TO rol_empleado;

FLUSH PRIVILEGES;

SHOW GRANTS FOR rol_admin;
SHOW GRANTS FOR rol_empleado;
