-- Modificar el trigger para que solo registre en logs, sin crear venta
DROP TRIGGER IF EXISTS trg_pedido_entregado_venta;
DELIMITER ;;
CREATE TRIGGER trg_pedido_entregado_venta
AFTER UPDATE ON pedidos
FOR EACH ROW
BEGIN
    -- Cuando el estado cambia a 'entregado'
    IF NEW.estado = 'entregado' AND OLD.estado != 'entregado' THEN
        -- Solo registrar en logs, sin crear venta automática
        INSERT INTO logs_sistema (
            tipo, nivel, id_usuario, modulo, accion, descripcion,
            referencia_id, referencia_tipo, creado_en
        ) VALUES (
            'pedido', 'INFO', NEW.atendido_por, 'pedidos', 'entregado',
            CONCAT('Pedido ', NEW.folio, ' marcado como entregado'),
            NEW.id_pedido, 'pedido', NOW()
        );
    END IF;
END;;
DELIMITER ;


-- También eliminar el procedimiento asociado (opcional)
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



