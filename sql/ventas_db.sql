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
        CONCAT(p.folio) AS folio_venta,
        p.actualizado_en AS fecha_venta,
        p.total_estimado AS total,
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