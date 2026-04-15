DROP PROCEDURE IF EXISTS `sp_editar_producto`;

DELIMITER $$
CREATE PROCEDURE `sp_editar_producto`(
    IN  p_id_producto   INT,
    IN  p_nombre        VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    IN  p_descripcion   TEXT         CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    IN  p_precio_venta  DECIMAL(10,2),
    IN  p_ejecutado_por INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = p_id_producto) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El producto no existe.';
    END IF;

    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre del producto es obligatorio.';
    END IF;

    IF p_precio_venta IS NULL OR p_precio_venta <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El precio de venta debe ser mayor a 0.';
    END IF;

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

    INSERT INTO logs_sistema (
        tipo,    nivel,  id_usuario,     modulo,
        accion,  descripcion,            creado_en
    ) VALUES (
        'venta', 'INFO', p_ejecutado_por, 'productos',
        'EDITAR',
        CONCAT('Producto editado: ', TRIM(p_nombre), ' (id=', p_id_producto, ')'),
        NOW()
    );
END$$
DELIMITER ;