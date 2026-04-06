-- Crear venta automática cuando pedido cambia a 'entregado'
DROP PROCEDURE IF EXISTS sp_crear_venta_desde_pedido;
DELIMITER ;;
CREATE PROCEDURE sp_crear_venta_desde_pedido(
    IN p_id_pedido INT,
    IN p_vendedor_id INT
)
BEGIN
    DECLARE v_folio VARCHAR(20);
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_id_venta INT;
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
    
    SET v_id_venta = LAST_INSERT_ID();
    
    -- Insertar detalles de venta desde el pedido
    INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, 
                                precio_unitario, descuento_pct, subtotal)
    SELECT v_id_venta, id_producto, cantidad, precio_unitario, 0, subtotal
    FROM detalle_pedidos
    WHERE id_pedido = p_id_pedido;
    
    -- Descontar inventario
    UPDATE inventario_pt i
    JOIN detalle_pedidos dp ON dp.id_producto = i.id_producto
    SET i.stock_actual = i.stock_actual - dp.cantidad
    WHERE dp.id_pedido = p_id_pedido;
    
    -- Log
    INSERT INTO logs_sistema (tipo, nivel, id_usuario, modulo, accion, descripcion, creado_en)
    VALUES ('venta', 'INFO', p_vendedor_id, 'ventas', 'venta_automatica',
            CONCAT('Venta automática generada desde pedido ID ', p_id_pedido, ' | Folio: ', v_folio), NOW());
    
    SELECT v_id_venta AS id_venta, v_folio AS folio;
END;;
DELIMITER ;

DROP TRIGGER IF EXISTS trg_pedido_entregado_venta;
DELIMITER ;;
CREATE TRIGGER trg_pedido_entregado_venta
AFTER UPDATE ON pedidos
FOR EACH ROW
BEGIN
    -- Cuando el estado cambia a 'entregado'
    IF NEW.estado = 'entregado' AND OLD.estado != 'entregado' THEN
        -- Verificar que no exista ya una venta para este pedido
        IF NOT EXISTS (SELECT 1 FROM logs_sistema 
                       WHERE referencia_id = NEW.id_pedido 
                         AND referencia_tipo = 'pedido' 
                         AND accion = 'venta_automatica') THEN
            
            CALL sp_crear_venta_desde_pedido(NEW.id_pedido, NEW.atendido_por);
            
            -- Marcar el pedido como procesado
            INSERT INTO logs_sistema (tipo, nivel, modulo, accion, descripcion, referencia_id, referencia_tipo, creado_en)
            VALUES ('venta', 'INFO', 'pedidos', 'venta_automatica', 
                    CONCAT('Pedido ', NEW.folio, ' convertido a venta automáticamente'),
                    NEW.id_pedido, 'pedido', NOW());
        END IF;
    END IF;
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_lista_ventas;
DELIMITER ;;
CREATE PROCEDURE sp_lista_ventas(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin    DATE,
    IN p_metodo_pago  VARCHAR(20),
    IN p_estado       VARCHAR(20),
    IN p_vendedor_id  INT,
    IN p_offset       INT,
    IN p_limit        INT
)
BEGIN
    -- Ventas registradas (de la tabla ventas)
    SELECT
        v.id_venta,
        v.folio_venta,
        v.fecha_venta,
        v.total,
        v.metodo_pago,
        v.cambio,
        v.estado,
        v.requiere_ticket,
        u.nombre_completo AS vendedor_nombre,
        COUNT(dv.id_detalle_venta) AS num_productos,
        COUNT(*) OVER () AS total_filas,
        NULL AS pedido_origen
    FROM ventas v
    JOIN usuarios u ON u.id_usuario = v.vendedor_id
    LEFT JOIN detalle_ventas dv ON dv.id_venta = v.id_venta
    WHERE (p_fecha_inicio IS NULL OR DATE(v.fecha_venta) >= p_fecha_inicio)
      AND (p_fecha_fin    IS NULL OR DATE(v.fecha_venta) <= p_fecha_fin)
      AND (p_metodo_pago  IS NULL OR p_metodo_pago = '' OR v.metodo_pago = p_metodo_pago)
      AND (p_estado       IS NULL OR p_estado      = '' OR v.estado = p_estado)
      AND (p_vendedor_id  IS NULL OR p_vendedor_id = 0  OR v.vendedor_id = p_vendedor_id)
    GROUP BY v.id_venta
    UNION ALL
    -- Pedidos entregados que aún no tienen venta registrada
    SELECT
        NULL AS id_venta,
        CONCAT('PED-', p.folio) AS folio_venta,
        p.actualizado_en AS fecha_venta,
        p.total_estimado AS total,
        'transferencia' AS metodo_pago,
        0 AS cambio,
        'completada' AS estado,
        1 AS requiere_ticket,
        u.nombre_completo AS vendedor_nombre,
        COUNT(dp.id_detalle) AS num_productos,
        0 AS total_filas,
        p.folio AS pedido_origen
    FROM pedidos p
    JOIN usuarios u ON u.id_usuario = p.atendido_por
    LEFT JOIN detalle_pedidos dp ON dp.id_pedido = p.id_pedido
    WHERE p.estado = 'entregado'
      AND NOT EXISTS (
          SELECT 1 FROM logs_sistema 
          WHERE referencia_id = p.id_pedido 
            AND referencia_tipo = 'pedido' 
            AND accion = 'venta_automatica'
      )
      AND (p_fecha_inicio IS NULL OR DATE(p.actualizado_en) >= p_fecha_inicio)
      AND (p_fecha_fin    IS NULL OR DATE(p.actualizado_en) <= p_fecha_fin)
    GROUP BY p.id_pedido
    ORDER BY fecha_venta DESC
    LIMIT p_limit OFFSET p_offset;
END;;
DELIMITER ;