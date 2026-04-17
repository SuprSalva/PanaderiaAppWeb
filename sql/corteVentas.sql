CREATE INDEX idx_cortes_estado_fecha
    ON cortes_diarios (estado, fecha_corte);

CREATE OR REPLACE VIEW vw_corte_ventas_dia AS

    SELECT
        'caja' COLLATE utf8mb4_0900_ai_ci                       AS origen,
        v.id_venta                                              AS id_transaccion,
        v.folio_venta                                           AS folio,
        DATE(v.fecha_venta)                                     AS fecha,
        TIME(v.fecha_venta)                                     AS hora,
        v.total,
        CONVERT(v.metodo_pago USING utf8mb4)
            COLLATE utf8mb4_0900_ai_ci                          AS metodo_pago,
        CONVERT(v.estado USING utf8mb4)
            COLLATE utf8mb4_0900_ai_ci                          AS estado,
        u.nombre_completo                                       AS vendedor,
        COALESCE(SUM(dv.cantidad), 0)                           AS total_piezas
    FROM ventas v
    JOIN  usuarios u       ON u.id_usuario = v.vendedor_id
    LEFT JOIN detalle_ventas dv ON dv.id_venta = v.id_venta
    WHERE v.estado IN ('completada', 'cancelada')
    GROUP BY
        v.id_venta, v.folio_venta, v.fecha_venta,
        v.total, v.metodo_pago, v.estado, u.nombre_completo

UNION ALL

    SELECT
        'pedido_web' COLLATE utf8mb4_0900_ai_ci                 AS origen,
        p.id_pedido                                             AS id_transaccion,
        CONVERT(p.folio USING utf8mb4)
            COLLATE utf8mb4_0900_ai_ci                          AS folio,
        DATE(p.actualizado_en)                                  AS fecha,
        TIME(p.actualizado_en)                                  AS hora,
        p.total_estimado                                        AS total,
        CONVERT(p.metodo_pago USING utf8mb4)
            COLLATE utf8mb4_0900_ai_ci                          AS metodo_pago,
        'completada' COLLATE utf8mb4_0900_ai_ci                 AS estado,
        u.nombre_completo                                       AS vendedor,
        COALESCE(SUM(dp.cantidad), 0)                           AS total_piezas
    FROM pedidos p
    JOIN  usuarios u       ON u.id_usuario = COALESCE(p.atendido_por, 1)
    LEFT JOIN detalle_pedidos dp ON dp.id_pedido = p.id_pedido
    WHERE CONVERT(p.estado USING utf8mb4)
              COLLATE utf8mb4_0900_ai_ci = 'entregado' COLLATE utf8mb4_0900_ai_ci
      AND NOT EXISTS (
              SELECT 1 FROM logs_sistema l
              WHERE l.referencia_id   = p.id_pedido
                AND l.referencia_tipo = 'pedido'
                AND l.accion          = 'venta_automatica'
          )
    GROUP BY
        p.id_pedido, p.folio, p.actualizado_en,
        p.total_estimado, p.metodo_pago, p.estado, u.nombre_completo;


DROP PROCEDURE IF EXISTS sp_corte_resumen;

DELIMITER ;;
CREATE PROCEDURE sp_corte_resumen (
    IN p_fecha DATE
)
BEGIN

    SELECT
        COUNT(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                   THEN 1 END)                                          AS num_ventas,
        COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                          THEN total END), 0)                           AS total_vendido,
        COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                          THEN total_piezas END), 0)                    AS total_piezas,
        COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                           AND metodo_pago = 'efectivo' COLLATE utf8mb4_0900_ai_ci
                          THEN total END), 0)                           AS efectivo,
        COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                           AND metodo_pago = 'tarjeta' COLLATE utf8mb4_0900_ai_ci
                          THEN total END), 0)                           AS tarjeta,
        COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                           AND metodo_pago = 'transferencia' COLLATE utf8mb4_0900_ai_ci
                          THEN total END), 0)                           AS transferencia,
        COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                           AND metodo_pago NOT IN (
                               'efectivo' COLLATE utf8mb4_0900_ai_ci,
                               'tarjeta'  COLLATE utf8mb4_0900_ai_ci,
                               'transferencia' COLLATE utf8mb4_0900_ai_ci)
                          THEN total END), 0)                           AS otro,
        COUNT(CASE WHEN estado = 'cancelada' COLLATE utf8mb4_0900_ai_ci
                   THEN 1 END)                                          AS cancelaciones
    FROM vw_corte_ventas_dia
    WHERE fecha = p_fecha;

    SELECT
        origen,
        folio,
        hora,
        ROUND(total, 2)           AS total,
        metodo_pago,
        estado,
        vendedor,
        ROUND(total_piezas, 0)    AS total_piezas
    FROM vw_corte_ventas_dia
    WHERE fecha = p_fecha
    ORDER BY hora ASC;

    SELECT
        p.nombre                        AS producto,
        ROUND(SUM(det.cantidad), 0)     AS piezas_vendidas,
        ROUND(SUM(det.subtotal), 2)     AS total_generado
    FROM (
      SELECT dv.id_producto, dv.cantidad, dv.subtotal
      FROM ventas v
      JOIN detalle_ventas dv ON dv.id_venta = v.id_venta
      WHERE DATE(v.fecha_venta) = p_fecha
        AND v.estado = 'completada'

      UNION ALL

      SELECT dp.id_producto, dp.cantidad, dp.subtotal
      FROM pedidos p
      JOIN detalle_pedidos dp ON dp.id_pedido = p.id_pedido
      WHERE DATE(p.actualizado_en) = p_fecha
        AND CONVERT(p.estado USING utf8mb4)
            COLLATE utf8mb4_0900_ai_ci = 'entregado'
        AND NOT EXISTS (
            SELECT 1
            FROM logs_sistema l
            WHERE l.referencia_id   = p.id_pedido
              AND l.referencia_tipo = 'pedido'
              AND l.accion          = 'venta_automatica'
        )
    ) AS det
    JOIN productos p ON p.id_producto = det.id_producto
    GROUP BY p.id_producto, p.nombre
    ORDER BY piezas_vendidas DESC
    LIMIT 5;

    SELECT
        cd.id_corte,
        cd.estado,
        cd.total_ventas,
        cd.total_tickets,
        cd.total_piezas,
        cd.efectivo,
        cd.tarjeta,
        cd.transferencia,
        cd.cancelaciones,
        cd.cerrado_en,
        u.nombre_completo   AS cerrado_por_nombre
    FROM cortes_diarios cd
    LEFT JOIN usuarios u ON u.id_usuario = cd.cerrado_por
    WHERE cd.fecha_corte = p_fecha
    LIMIT 1;

END ;;
DELIMITER ;


ALTER TABLE cortes_diarios 
ADD COLUMN efectivo_declarado DECIMAL(12,2) DEFAULT 0 AFTER efectivo,
ADD COLUMN diferencia_efectivo DECIMAL(12,2) DEFAULT 0 AFTER efectivo_declarado;

DROP PROCEDURE IF EXISTS sp_corte_generar;

DELIMITER ;;
CREATE PROCEDURE sp_corte_generar (
    IN  p_fecha              DATE,
    IN  p_usuario_id         INT,
    IN  p_efectivo_declarado DECIMAL(12,2),
    OUT p_ok                 TINYINT,
    OUT p_mensaje            VARCHAR(200)
)
BEGIN
    DECLARE v_id_corte      INT           DEFAULT NULL;
    DECLARE v_estado_actual VARCHAR(10)   DEFAULT NULL;
    DECLARE v_num_ventas    INT           DEFAULT 0;
    DECLARE v_total         DECIMAL(12,2) DEFAULT 0;
    DECLARE v_piezas        DECIMAL(12,2) DEFAULT 0;
    DECLARE v_efectivo      DECIMAL(12,2) DEFAULT 0;
    DECLARE v_tarjeta       DECIMAL(12,2) DEFAULT 0;
    DECLARE v_transf        DECIMAL(12,2) DEFAULT 0;
    DECLARE v_cancelaciones INT           DEFAULT 0;
    DECLARE v_diferencia    DECIMAL(12,2) DEFAULT 0;
    DECLARE v_msg           VARCHAR(200);

    SELECT id_corte, estado
      INTO v_id_corte, v_estado_actual
      FROM cortes_diarios
     WHERE fecha_corte = p_fecha
     LIMIT 1;

    IF v_estado_actual = 'cerrado' THEN
        SET p_ok = 0;
        SET v_msg = 'El corte para esta fecha ya fue cerrado anteriormente.';
        SET p_mensaje = v_msg;
    ELSE
        SELECT
            COUNT(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci THEN 1 END),
            COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci THEN total END), 0),
            COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci THEN total_piezas END), 0),
            COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                               AND metodo_pago = 'efectivo' COLLATE utf8mb4_0900_ai_ci THEN total END), 0),
            COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                               AND metodo_pago = 'tarjeta' COLLATE utf8mb4_0900_ai_ci THEN total END), 0),
            COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                               AND metodo_pago = 'transferencia' COLLATE utf8mb4_0900_ai_ci THEN total END), 0),
            COUNT(CASE WHEN estado = 'cancelada' COLLATE utf8mb4_0900_ai_ci THEN 1 END)
        INTO
            v_num_ventas, v_total, v_piezas,
            v_efectivo,   v_tarjeta, v_transf,
            v_cancelaciones
        FROM vw_corte_ventas_dia
        WHERE fecha = p_fecha;

        SET v_diferencia = p_efectivo_declarado - v_efectivo;

        IF v_id_corte IS NULL THEN
            INSERT INTO cortes_diarios (
                fecha_corte, total_ventas, total_tickets, total_piezas,
                efectivo, efectivo_declarado, diferencia_efectivo,
                tarjeta, transferencia, cancelaciones,
                estado, cerrado_por, cerrado_en, creado_en
            ) VALUES (
                p_fecha, v_total, v_num_ventas, v_piezas,
                v_efectivo, p_efectivo_declarado, v_diferencia,
                v_tarjeta, v_transf, v_cancelaciones,
                'cerrado', p_usuario_id, NOW(), NOW()
            );
            SET v_id_corte = LAST_INSERT_ID();
        ELSE
            UPDATE cortes_diarios
               SET total_ventas        = v_total,
                   total_tickets       = v_num_ventas,
                   total_piezas        = v_piezas,
                   efectivo            = v_efectivo,
                   efectivo_declarado  = p_efectivo_declarado,
                   diferencia_efectivo = v_diferencia,
                   tarjeta             = v_tarjeta,
                   transferencia       = v_transf,
                   cancelaciones       = v_cancelaciones,
                   estado              = 'cerrado',
                   cerrado_por         = p_usuario_id,
                   cerrado_en          = NOW()
             WHERE id_corte = v_id_corte;
        END IF;

        UPDATE ventas
           SET id_corte = v_id_corte
         WHERE DATE(fecha_venta) = p_fecha
           AND estado            = 'completada'
           AND id_corte          IS NULL;

        INSERT INTO logs_sistema
            (tipo, nivel, id_usuario, modulo, accion, descripcion,
             referencia_id, referencia_tipo, creado_en)
        VALUES
            ('venta', 'INFO', p_usuario_id, 'corte', 'corte_generado',
             CONCAT('Corte cerrado | Dif: $', v_diferencia, 
                    ' | Teórico: $', v_efectivo, 
                    ' | Declarado: $', p_efectivo_declarado),
             v_id_corte, 'corte', NOW());

        SET p_ok = 1;
        
        IF v_diferencia = 0 THEN
            SET v_msg = CONCAT('Corte cerrado para el ', p_fecha, '.');
        ELSEIF v_diferencia < 0 THEN
            SET v_msg = CONCAT('Corte cerrado con un FALTANTE de $', ABS(v_diferencia), '.');
        ELSE
            SET v_msg = CONCAT('Corte cerrado con un SOBRANTE de $', v_diferencia, '.');
        END IF;
        
        SET p_mensaje = v_msg;
    END IF;
END ;;
DELIMITER ;

GRANT SELECT  ON dulce_migaja.vw_corte_ventas_dia       TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_corte_resumen TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_corte_generar TO rol_admin;

GRANT SELECT  ON dulce_migaja.vw_corte_ventas_dia       TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_corte_resumen TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_corte_generar TO rol_empleado;

FLUSH PRIVILEGES;