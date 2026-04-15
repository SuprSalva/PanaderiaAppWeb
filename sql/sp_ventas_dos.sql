-- ============================================================
-- VISTAS PARA VENTAS EN CAJA (PUNTO DE VENTA)
-- Versión corregida con collations consistentes
-- ============================================================

-- Vista: Productos con stock disponible para venta
DROP VIEW IF EXISTS `vw_productos_stock`;
CREATE VIEW `vw_productos_stock` AS
SELECT 
    p.id_producto,
    p.uuid_producto,
    p.nombre,
    p.descripcion,
    p.imagen_url,
    p.precio_venta,
    p.estatus,
    COALESCE(i.stock_actual, 0) AS stock_actual,
    COALESCE(i.stock_minimo, 0) AS stock_minimo,
    CASE 
        WHEN COALESCE(i.stock_actual, 0) <= 0 THEN 'agotado'
        WHEN COALESCE(i.stock_actual, 0) <= COALESCE(i.stock_minimo, 0) THEN 'bajo'
        ELSE 'disponible'
    END AS estado_stock
FROM productos p
LEFT JOIN inventario_pt i ON i.id_producto = p.id_producto
WHERE p.estatus = 'activo';

-- Vista: Resumen de ventas en caja (físicas)
DROP VIEW IF EXISTS `vw_ventas_caja`;
CREATE VIEW `vw_ventas_caja` AS
SELECT 
    v.id_venta,
    v.folio_venta,
    v.fecha_venta,
    v.total,
    v.metodo_pago,
    v.cambio,
    v.estado,
    v.vendedor_id,
    u.nombre_completo AS vendedor_nombre,
    COUNT(dv.id_detalle_venta) AS num_productos,
    COALESCE(SUM(dv.cantidad), 0) AS total_piezas,
    COALESCE(SUM(dv.subtotal), 0) AS total_venta,
    CASE 
        WHEN EXISTS (SELECT 1 FROM tickets t WHERE t.id_venta = v.id_venta) 
        THEN 1 ELSE 0 
    END AS ticket_impreso
FROM ventas v
JOIN usuarios u ON u.id_usuario = v.vendedor_id
LEFT JOIN detalle_ventas dv ON dv.id_venta = v.id_venta
WHERE v.estado = 'completada'
GROUP BY v.id_venta, v.folio_venta, v.fecha_venta, v.total, 
         v.metodo_pago, v.cambio, v.estado, v.vendedor_id, u.nombre_completo;

-- Vista: Dashboard ventas consolidadas (caja + pedidos web)
-- Corregir vista para evitar duplicados
DROP VIEW IF EXISTS `vw_ventas_consolidadas`;
CREATE VIEW `vw_ventas_consolidadas` AS
-- Ventas de caja (físicas) - SOLO de la tabla ventas que NO vienen de pedidos
SELECT 
    'caja' AS origen,
    v.id_venta AS id,
    v.folio_venta AS folio,
    v.fecha_venta AS fecha,
    v.total AS total,
    CONVERT(v.metodo_pago USING utf8mb4) COLLATE utf8mb4_unicode_ci AS metodo_pago,
    CONVERT(v.estado USING utf8mb4) COLLATE utf8mb4_unicode_ci AS estado,
    u.nombre_completo AS responsable,
    NULL AS pedido_origen
FROM ventas v
JOIN usuarios u ON u.id_usuario = v.vendedor_id
WHERE v.estado = 'completada'
  -- Excluir ventas que fueron generadas automáticamente desde pedidos
  AND NOT EXISTS (
    SELECT 1 FROM logs_sistema l 
    WHERE l.referencia_id = v.id_venta 
      AND l.referencia_tipo = 'venta' 
      AND l.accion = 'venta_automatica'
  )

UNION ALL

-- Ventas de pedidos web (entregados) - SOLO los que NO tienen venta automática
SELECT 
    'pedido_web' AS origen,
    p.id_pedido AS id,
    CONCAT('PED-', LPAD(p.id_pedido, 4, '0')) AS folio,
    p.actualizado_en AS fecha,
    p.total_estimado AS total,
    CONVERT(p.metodo_pago USING utf8mb4) COLLATE utf8mb4_unicode_ci AS metodo_pago,
    CONVERT(p.estado USING utf8mb4) COLLATE utf8mb4_unicode_ci AS estado,
    u.nombre_completo AS responsable,
    p.folio AS pedido_origen
FROM pedidos p
JOIN usuarios u ON u.id_usuario = COALESCE(p.atendido_por, 1)
WHERE p.estado = 'entregado'
  -- Excluir pedidos que ya generaron venta automática
  AND NOT EXISTS (
    SELECT 1 FROM logs_sistema l 
    WHERE l.referencia_id = p.id_pedido 
      AND l.referencia_tipo = 'pedido' 
      AND l.accion = 'venta_automatica'
  )

ORDER BY fecha DESC;


-- Vista: Top productos más vendidos (caja + web)
DROP VIEW IF EXISTS `vw_top_productos_vendidos`;
CREATE VIEW `vw_top_productos_vendidos` AS
SELECT 
    p.id_producto,
    p.nombre,
    p.precio_venta,
    COALESCE(SUM(dv.cantidad), 0) AS ventas_caja,
    COALESCE(web_vendidos.total_web, 0) AS ventas_web,
    COALESCE(SUM(dv.cantidad), 0) + COALESCE(web_vendidos.total_web, 0) AS total_vendido
FROM productos p
LEFT JOIN detalle_ventas dv ON dv.id_producto = p.id_producto
LEFT JOIN ventas v ON v.id_venta = dv.id_venta AND v.estado = 'completada'
LEFT JOIN (
    SELECT dp.id_producto, SUM(dp.cantidad) AS total_web
    FROM detalle_pedidos dp
    JOIN pedidos p2 ON p2.id_pedido = dp.id_pedido
    WHERE p2.estado = 'entregado'
    GROUP BY dp.id_producto
) web_vendidos ON web_vendidos.id_producto = p.id_producto
WHERE p.estatus = 'activo'
GROUP BY p.id_producto, p.nombre, p.precio_venta, web_vendidos.total_web
ORDER BY total_vendido DESC;

-- Procedimiento: Registrar venta en caja con descuento de inventario
DROP PROCEDURE IF EXISTS sp_registrar_venta_caja;
DELIMITER ;;
CREATE PROCEDURE sp_registrar_venta_caja(
    IN p_productos_json JSON,
    IN p_metodo_pago VARCHAR(20),
    IN p_efectivo_recibido DECIMAL(10,2),
    IN p_vendedor_id INT,
    OUT p_id_venta INT,
    OUT p_folio_venta VARCHAR(20),
    OUT p_cambio DECIMAL(10,2),
    OUT p_total DECIMAL(10,2)
)
BEGIN
    DECLARE v_next_seq INT;
    DECLARE v_total_venta DECIMAL(10,2) DEFAULT 0;
    DECLARE v_cambio DECIMAL(10,2) DEFAULT 0;
    DECLARE v_idx INT DEFAULT 0;
    DECLARE v_productos_len INT;
    DECLARE v_producto_id INT;
    DECLARE v_cantidad DECIMAL(10,2);
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_subtotal DECIMAL(10,2);
    DECLARE v_stock_actual DECIMAL(12,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Calcular total de la venta
    SET v_productos_len = JSON_LENGTH(p_productos_json);
    
    WHILE v_idx < v_productos_len DO
        SET v_producto_id = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[', v_idx, '].id_producto')));
        SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[', v_idx, '].cantidad')));
        SET v_precio = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[', v_idx, '].precio')));
        
        -- Validar stock suficiente
        SELECT stock_actual INTO v_stock_actual
        FROM inventario_pt
        WHERE id_producto = v_producto_id;
        
        IF v_stock_actual < v_cantidad THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Stock insuficiente para uno o más productos';
        END IF;
        
        SET v_subtotal = v_cantidad * v_precio;
        SET v_total_venta = v_total_venta + v_subtotal;
        SET v_idx = v_idx + 1;
    END WHILE;
    
    -- Calcular cambio si es efectivo
    IF p_metodo_pago = 'efectivo' AND p_efectivo_recibido IS NOT NULL THEN
        SET v_cambio = p_efectivo_recibido - v_total_venta;
        IF v_cambio < 0 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'El efectivo recibido es insuficiente';
        END IF;
    END IF;
    
    -- Generar folio de venta
    SELECT COALESCE(COUNT(*), 0) + 1 INTO v_next_seq
    FROM ventas
    WHERE DATE(fecha_venta) = CURDATE();
    
    SET p_folio_venta = CONCAT('VTA-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(v_next_seq, 3, '0'));
    SET p_total = v_total_venta;
    SET p_cambio = v_cambio;
    
    -- Insertar cabecera de venta
    INSERT INTO ventas (
        folio_venta, fecha_venta, total, metodo_pago, cambio,
        requiere_ticket, estado, vendedor_id, creado_en
    ) VALUES (
        p_folio_venta, NOW(), v_total_venta, p_metodo_pago, v_cambio,
        1, 'completada', p_vendedor_id, NOW()
    );
    
    SET p_id_venta = LAST_INSERT_ID();
    
    -- Insertar detalles y descontar inventario
    SET v_idx = 0;
    WHILE v_idx < v_productos_len DO
        SET v_producto_id = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[', v_idx, '].id_producto')));
        SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[', v_idx, '].cantidad')));
        SET v_precio = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[', v_idx, '].precio')));
        SET v_subtotal = v_cantidad * v_precio;
        
        -- Insertar detalle
        INSERT INTO detalle_ventas (
            id_venta, id_producto, cantidad, precio_unitario, 
            descuento_pct, subtotal
        ) VALUES (
            p_id_venta, v_producto_id, v_cantidad, v_precio, 0, v_subtotal
        );
        
        -- Descontar inventario
        UPDATE inventario_pt 
        SET stock_actual = stock_actual - v_cantidad,
            ultima_actualizacion = NOW()
        WHERE id_producto = v_producto_id;
        
        SET v_idx = v_idx + 1;
    END WHILE;
    
    -- Registrar en logs
    INSERT INTO logs_sistema (
        tipo, nivel, id_usuario, modulo, accion, descripcion,
        referencia_id, referencia_tipo, creado_en
    ) VALUES (
        'venta', 'INFO', p_vendedor_id, 'ventas', 'venta_caja',
        CONCAT('Venta en caja registrada: ', p_folio_venta, ' | Total: $', v_total_venta),
        p_id_venta, 'venta', NOW()
    );
    
    COMMIT;
END;;
DELIMITER ;


-- Modificar el trigger para que registre correctamente la relación
DROP TRIGGER IF EXISTS trg_pedido_entregado_venta;
DELIMITER ;;
CREATE TRIGGER trg_pedido_entregado_venta
AFTER UPDATE ON pedidos
FOR EACH ROW
BEGIN
    DECLARE v_id_venta INT;
    
    -- Cuando el estado cambia a 'entregado'
    IF NEW.estado = 'entregado' AND OLD.estado != 'entregado' THEN
        -- Verificar que no exista ya una venta para este pedido
        IF NOT EXISTS (SELECT 1 FROM logs_sistema 
                       WHERE referencia_id = NEW.id_pedido 
                         AND referencia_tipo = 'pedido' 
                         AND accion = 'venta_automatica') THEN
            
            -- Crear la venta automática
            CALL sp_crear_venta_desde_pedido(NEW.id_pedido, NEW.atendido_por, @v_id_venta);
            
            -- Registrar que este pedido generó una venta
            INSERT INTO logs_sistema (tipo, nivel, modulo, accion, descripcion, 
                                      referencia_id, referencia_tipo, creado_en)
            VALUES ('venta', 'INFO', 'pedidos', 'venta_automatica', 
                    CONCAT('Pedido ', NEW.folio, ' convertido a venta automáticamente'),
                    NEW.id_pedido, 'pedido', NOW());
            
            -- También registrar la relación inversa (para excluir de la vista)
            INSERT INTO logs_sistema (tipo, nivel, modulo, accion, descripcion,
                                      referencia_id, referencia_tipo, creado_en)
            VALUES ('venta', 'INFO', 'ventas', 'venta_automatica',
                    CONCAT('Venta generada desde pedido ', NEW.folio),
                    @v_id_venta, 'venta', NOW());
        END IF;
    END IF;
END;;
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_crear_venta_desde_pedido;
DELIMITER ;;
CREATE PROCEDURE sp_crear_venta_desde_pedido(
    IN p_id_pedido INT,
    IN p_vendedor_id INT,
    OUT p_id_venta INT
)
BEGIN
    DECLARE v_folio VARCHAR(20);
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_next_seq INT;
    
    -- Calcular total del pedido
    SELECT SUM(subtotal) INTO v_total
    FROM detalle_pedidos
    WHERE id_pedido = p_id_pedido;
    
    -- Generar folio
    SELECT COUNT(*) + 1 INTO v_next_seq
    FROM ventas
    WHERE DATE(fecha_venta) = CURDATE();
    
    SET v_folio = CONCAT('VTA-', DATE_FORMAT(NOW(),'%Y%m%d'), '-', LPAD(v_next_seq, 3, '0'));
    
    -- Insertar cabecera de venta
    INSERT INTO ventas (folio_venta, fecha_venta, total, metodo_pago, cambio,
                        requiere_ticket, estado, vendedor_id, creado_en)
    VALUES (v_folio, NOW(), v_total, 'transferencia', 0,
            1, 'completada', p_vendedor_id, NOW());
    
    SET p_id_venta = LAST_INSERT_ID();
    
    -- Insertar detalles de venta desde el pedido
    INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, 
                                precio_unitario, descuento_pct, subtotal)
    SELECT p_id_venta, id_producto, cantidad, precio_unitario, 0, subtotal
    FROM detalle_pedidos
    WHERE id_pedido = p_id_pedido;
    
    -- Descontar inventario
    UPDATE inventario_pt i
    JOIN detalle_pedidos dp ON dp.id_producto = i.id_producto
    SET i.stock_actual = i.stock_actual - dp.cantidad
    WHERE dp.id_pedido = p_id_pedido;
END;;
DELIMITER ;