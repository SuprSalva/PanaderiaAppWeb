-- ============================================================
-- PROCEDIMIENTOS PARA MERMAS DE PRODUCTOS TERMINADOS
-- ============================================================

-- 1. Obtener lista de productos terminados con stock
DROP PROCEDURE IF EXISTS sp_mermas_productos_terminados;
DELIMITER ;;
CREATE PROCEDURE sp_mermas_productos_terminados(
    IN p_busqueda VARCHAR(120)
)
BEGIN
    SELECT 
        p.id_producto,
        p.nombre,
        p.precio_venta,
        COALESCE(i.stock_actual, 0) AS stock_actual,
        COALESCE(i.stock_minimo, 0) AS stock_minimo,
        p.imagen_url
    FROM productos p
    LEFT JOIN inventario_pt i ON i.id_producto = p.id_producto
    WHERE p.estatus = 'activo'
      AND (p_busqueda IS NULL 
           OR p_busqueda = '' 
           OR CONVERT(p.nombre USING utf8mb4) COLLATE utf8mb4_unicode_ci LIKE CONCAT('%', p_busqueda, '%'))
    ORDER BY p.nombre;
END;;
DELIMITER ;

-- 2. Registrar merma de producto terminado
DROP PROCEDURE IF EXISTS sp_registrar_merma_producto;
DELIMITER ;;
CREATE PROCEDURE sp_registrar_merma_producto(
    IN p_id_producto INT,
    IN p_cantidad DECIMAL(12,4),
    IN p_causa VARCHAR(30),
    IN p_descripcion TEXT,
    IN p_registrado_por INT,
    OUT p_id_merma INT,
    OUT p_error VARCHAR(255)
)
sp_main: BEGIN
    DECLARE v_stock_actual DECIMAL(12,4);
    DECLARE v_nombre_producto VARCHAR(120);
    DECLARE v_unidad VARCHAR(20);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
        SET p_id_merma = NULL;
    END;
    
    SET p_error = NULL;
    SET p_id_merma = NULL;
    
    -- Validar causa
    IF p_causa NOT IN ('caducidad', 'quemado_horneado', 'caida_accidente', 'error_produccion', 'rotura_empaque', 'contaminacion', 'otro') THEN
        SET p_error = 'Causa de merma inválida.';
        LEAVE sp_main;
    END IF;
    
    -- Validar cantidad
    IF p_cantidad <= 0 THEN
        SET p_error = 'La cantidad debe ser mayor a cero.';
        LEAVE sp_main;
    END IF;
    
    -- Obtener datos del producto
    SELECT p.nombre, COALESCE(i.stock_actual, 0)
    INTO v_nombre_producto, v_stock_actual
    FROM productos p
    LEFT JOIN inventario_pt i ON i.id_producto = p.id_producto
    WHERE p.id_producto = p_id_producto AND p.estatus = 'activo';
    
    IF v_nombre_producto IS NULL THEN
        SET p_error = 'Producto no encontrado o inactivo.';
        LEAVE sp_main;
    END IF;
    
    -- Validar stock suficiente
    IF v_stock_actual < p_cantidad THEN
        SET p_error = CONCAT('Stock insuficiente. Disponible: ', v_stock_actual, ' piezas');
        LEAVE sp_main;
    END IF;
    
    START TRANSACTION;
    
    -- Insertar registro de merma
    INSERT INTO mermas (
        tipo_objeto, id_referencia, cantidad, unidad, 
        causa, descripcion, registrado_por, fecha_merma, creado_en
    ) VALUES (
        'producto_terminado', p_id_producto, p_cantidad, 'piezas',
        p_causa, p_descripcion, p_registrado_por, NOW(), NOW()
    );
    
    SET p_id_merma = LAST_INSERT_ID();
    
    -- Descontar del inventario de productos terminados
    UPDATE inventario_pt 
    SET stock_actual = stock_actual - p_cantidad,
        ultima_actualizacion = NOW()
    WHERE id_producto = p_id_producto;
    
    -- Registrar en logs
    INSERT INTO logs_sistema (tipo, nivel, id_usuario, modulo, accion, descripcion, creado_en)
    VALUES ('ajuste_inv', 'WARNING', p_registrado_por, 'mermas', 'registrar_merma_producto',
            CONCAT('Merma de producto registrada: ', v_nombre_producto, ' - Cantidad: ', p_cantidad, ' piezas - Causa: ', p_causa), NOW());
    
    COMMIT;
END;;
DELIMITER ;

-- 3. Listar mermas de productos terminados
DROP PROCEDURE IF EXISTS sp_listar_mermas_productos;
DELIMITER ;;
CREATE PROCEDURE sp_listar_mermas_productos(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
    IN p_causa VARCHAR(30),
    IN p_offset INT,
    IN p_limit INT
)
BEGIN
    SELECT 
        m.id_merma,
        p.nombre AS producto_nombre,
        m.cantidad,
        m.unidad,
        m.causa,
        m.descripcion,
        m.fecha_merma,
        u.nombre_completo AS registrado_por_nombre,
        COUNT(*) OVER () AS total_filas
    FROM mermas m
    JOIN productos p ON p.id_producto = m.id_referencia
    JOIN usuarios u ON u.id_usuario = m.registrado_por
    WHERE m.tipo_objeto = 'producto_terminado'
      AND (p_fecha_inicio IS NULL OR DATE(m.fecha_merma) >= p_fecha_inicio)
      AND (p_fecha_fin IS NULL OR DATE(m.fecha_merma) <= p_fecha_fin)
      AND (p_causa IS NULL OR p_causa = '' OR m.causa = p_causa)
    ORDER BY m.fecha_merma DESC
    LIMIT p_limit OFFSET p_offset;
END;;
DELIMITER ;