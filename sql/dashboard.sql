USE dulce_migaja;

CREATE INDEX idx_pedidos_estado_actualizado
    ON pedidos (estado, actualizado_en);


CREATE INDEX idx_salidas_estado_fecha
    ON salidas_efectivo (estado, fecha_salida);

CREATE INDEX idx_mp_stock_critico
    ON materias_primas (estatus, stock_actual, stock_minimo);


DROP VIEW IF EXISTS vw_dash_ventas_consolidadas;
CREATE VIEW vw_dash_ventas_consolidadas AS

    SELECT
        v.id_venta                            AS origen_id,
        'venta'                               AS origen_tipo,
        DATE(v.fecha_venta)                   AS fecha,
        v.total                               AS monto
    FROM ventas v
    WHERE v.estado = 'completada'

UNION ALL

    SELECT
        p.id_pedido                           AS origen_id,
        'pedido'                              AS origen_tipo,
        DATE(p.actualizado_en)                AS fecha,
        p.total_estimado                      AS monto
    FROM pedidos p
    WHERE CONVERT(p.estado USING utf8mb4)
            COLLATE utf8mb4_0900_ai_ci        = 'entregado'
      AND NOT EXISTS (
              SELECT 1
              FROM   logs_sistema l
              WHERE  l.referencia_id   = p.id_pedido
                AND  l.referencia_tipo = 'pedido'
                AND  l.accion          = 'venta_automatica'
          );

DROP VIEW IF EXISTS vw_dash_mp_criticas;
CREATE VIEW vw_dash_mp_criticas AS
SELECT
    id_materia,
    nombre,
    COALESCE(categoria, 'Sin categoría')      AS categoria,
    unidad_base,
    stock_actual,
    stock_minimo,
    ROUND(
        CASE WHEN stock_minimo > 0
             THEN (stock_actual / stock_minimo) * 100
             ELSE 100
        END, 1
    )                                         AS pct_stock,
    CASE
        WHEN stock_actual = 0                       THEN 'critico'
        WHEN stock_actual < stock_minimo * 0.5      THEN 'bajo'
        ELSE                                             'advertencia'
    END                                       AS nivel
FROM materias_primas
WHERE estatus      = 'activo'
  AND stock_minimo > 0
  AND stock_actual <= stock_minimo
ORDER BY pct_stock ASC;

DROP VIEW IF EXISTS vw_dash_piezas_vendidas;
CREATE VIEW vw_dash_piezas_vendidas AS

    SELECT
        dv.id_producto,
        dv.cantidad,
        dv.subtotal,
        DATE(v.fecha_venta)   AS fecha
    FROM detalle_ventas dv
    JOIN ventas v ON v.id_venta = dv.id_venta
    WHERE v.estado       = 'completada'
      AND dv.id_producto IS NOT NULL

UNION ALL

    SELECT
        dp.id_producto,
        dp.cantidad,
        dp.subtotal,
        DATE(p.actualizado_en) AS fecha
    FROM detalle_pedidos dp
    JOIN pedidos p ON p.id_pedido = dp.id_pedido
    WHERE CONVERT(p.estado USING utf8mb4)
            COLLATE utf8mb4_0900_ai_ci = 'entregado'
      AND NOT EXISTS (
              SELECT 1
              FROM   logs_sistema l
              WHERE  l.referencia_id   = p.id_pedido
                AND  l.referencia_tipo = 'pedido'
                AND  l.accion          = 'venta_automatica'
          );

DROP PROCEDURE IF EXISTS sp_dash_ventas_totales;
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE sp_dash_ventas_totales(IN p_periodo VARCHAR(10))
BEGIN
    DECLARE v_dias     INT;
    DECLARE v_desde    DATE;
    DECLARE v_desde_ant DATE;

    CASE p_periodo
        WHEN 'hoy'     THEN SET v_dias = 1;
        WHEN 'semanal' THEN SET v_dias = 7;
        WHEN 'mensual' THEN SET v_dias = 30;
        WHEN 'anual'   THEN SET v_dias = 365;
        ELSE                SET v_dias = 7;  
    END CASE;

    IF p_periodo = 'hoy' THEN
        SET v_desde     = CURDATE();
        SET v_desde_ant = DATE_SUB(CURDATE(), INTERVAL 1 DAY);
    ELSE
        SET v_desde     = DATE_SUB(CURDATE(), INTERVAL v_dias DAY);
        SET v_desde_ant = DATE_SUB(CURDATE(), INTERVAL v_dias * 2 DAY);
    END IF;

    IF p_periodo = 'hoy' THEN
        SELECT
            COALESCE(SUM(CASE WHEN fecha = v_desde     THEN monto END), 0) AS total_actual,
            COALESCE(SUM(CASE WHEN fecha = v_desde_ant THEN monto END), 0) AS total_anterior,
            COALESCE(COUNT(CASE WHEN fecha = v_desde     THEN 1 END), 0)   AS tickets_actual,
            COALESCE(COUNT(CASE WHEN fecha = v_desde_ant THEN 1 END), 0)   AS tickets_anterior
        FROM vw_dash_ventas_consolidadas
        WHERE fecha >= v_desde_ant;
    ELSE
        SELECT
            COALESCE(SUM(CASE WHEN fecha >= v_desde     THEN monto END), 0) AS total_actual,
            COALESCE(SUM(CASE WHEN fecha >= v_desde_ant AND fecha < v_desde THEN monto END), 0) AS total_anterior,
            COALESCE(COUNT(CASE WHEN fecha >= v_desde     THEN 1 END), 0)   AS tickets_actual,
            COALESCE(COUNT(CASE WHEN fecha >= v_desde_ant AND fecha < v_desde THEN 1 END), 0) AS tickets_anterior
        FROM vw_dash_ventas_consolidadas
        WHERE fecha >= v_desde_ant;
    END IF;

    IF p_periodo = 'hoy' THEN
        SELECT
            fecha,
            COALESCE(SUM(monto), 0) AS total_dia,
            COUNT(*)                 AS tickets
        FROM vw_dash_ventas_consolidadas
        WHERE fecha = v_desde
        GROUP BY fecha
        ORDER BY fecha ASC;
    ELSE
        SELECT
            fecha,
            COALESCE(SUM(monto), 0) AS total_dia,
            COUNT(*)                 AS tickets
        FROM vw_dash_ventas_consolidadas
        WHERE fecha >= v_desde
        GROUP BY fecha
        ORDER BY fecha ASC;
    END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_dash_salidas_efectivo;
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE sp_dash_salidas_efectivo(IN p_periodo VARCHAR(10))
BEGIN
    DECLARE v_dias      INT;
    DECLARE v_desde     DATE;
    DECLARE v_desde_ant DATE;

    CASE p_periodo
        WHEN 'hoy'     THEN SET v_dias = 1;
        WHEN 'semanal' THEN SET v_dias = 7;
        WHEN 'mensual' THEN SET v_dias = 30;
        WHEN 'anual'   THEN SET v_dias = 365;
        ELSE                SET v_dias = 7;
    END CASE;

    IF p_periodo = 'hoy' THEN
        SET v_desde     = CURDATE();
        SET v_desde_ant = DATE_SUB(CURDATE(), INTERVAL 1 DAY);
    ELSE
        SET v_desde     = DATE_SUB(CURDATE(), INTERVAL v_dias DAY);
        SET v_desde_ant = DATE_SUB(CURDATE(), INTERVAL v_dias * 2 DAY);
    END IF;

    IF p_periodo = 'hoy' THEN
        SELECT
            COALESCE(SUM(CASE WHEN fecha_salida = v_desde     THEN monto END), 0) AS total_actual,
            COALESCE(SUM(CASE WHEN fecha_salida = v_desde_ant THEN monto END), 0) AS total_anterior,
            COALESCE(COUNT(CASE WHEN fecha_salida = v_desde     THEN 1 END), 0)   AS movimientos_actual,
            COALESCE(COUNT(CASE WHEN fecha_salida = v_desde_ant THEN 1 END), 0)   AS movimientos_anterior
        FROM salidas_efectivo
        WHERE estado = 'aprobada'
          AND fecha_salida >= v_desde_ant;
    ELSE
        SELECT
            COALESCE(SUM(CASE WHEN fecha_salida >= v_desde     THEN monto END), 0) AS total_actual,
            COALESCE(SUM(CASE WHEN fecha_salida >= v_desde_ant AND fecha_salida < v_desde THEN monto END), 0) AS total_anterior,
            COALESCE(COUNT(CASE WHEN fecha_salida >= v_desde     THEN 1 END), 0)   AS movimientos_actual,
            COALESCE(COUNT(CASE WHEN fecha_salida >= v_desde_ant AND fecha_salida < v_desde THEN 1 END), 0) AS movimientos_anterior
        FROM salidas_efectivo
        WHERE estado = 'aprobada'
          AND fecha_salida >= v_desde_ant;
    END IF;

    IF p_periodo = 'hoy' THEN
        SELECT categoria, COUNT(*) AS movimientos, SUM(monto) AS total_categoria
        FROM salidas_efectivo
        WHERE estado = 'aprobada' AND fecha_salida = v_desde
        GROUP BY categoria ORDER BY total_categoria DESC;
    ELSE
        SELECT categoria, COUNT(*) AS movimientos, SUM(monto) AS total_categoria
        FROM salidas_efectivo
        WHERE estado = 'aprobada' AND fecha_salida >= v_desde
        GROUP BY categoria ORDER BY total_categoria DESC;
    END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_dash_utilidad_por_producto;
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE sp_dash_utilidad_por_producto()
BEGIN
    DROP TEMPORARY TABLE IF EXISTS _tmp_costo_prom_mes;
    CREATE TEMPORARY TABLE _tmp_costo_prom_mes AS
    SELECT
        dc.id_materia,
        ROUND(
            AVG(dc.costo_unitario / dc.factor_conversion),
            6
        ) AS costo_prom_base
    FROM detalle_compras dc
    JOIN compras c ON c.id_compra = dc.id_compra
    WHERE c.estatus      = 'finalizado'
      AND c.fecha_compra >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
      AND dc.factor_conversion > 0
    GROUP BY dc.id_materia;
    DROP TEMPORARY TABLE IF EXISTS _tmp_costo_receta;
    CREATE TEMPORARY TABLE _tmp_costo_receta AS
    SELECT
        dr.id_receta,
        ROUND(
            SUM(
                dr.cantidad_requerida
                * COALESCE(cpm.costo_prom_base, ucm.costo_base, 0)
            ),
            4
        ) AS costo_total_lote
    FROM detalle_recetas dr
    LEFT JOIN _tmp_costo_prom_mes      cpm ON cpm.id_materia = dr.id_materia
    LEFT JOIN v_ultimo_costo_materia   ucm ON ucm.id_materia = dr.id_materia
    GROUP BY dr.id_receta;

    SELECT
        p.id_producto,
        p.nombre                                            AS nombre_producto,
        p.precio_venta,
        r.id_receta,
        r.nombre                                            AS nombre_receta,
        r.rendimiento,
        ROUND(
            COALESCE(tcr.costo_total_lote, 0) / r.rendimiento,
            4
        )                                                   AS costo_unitario,
        ROUND(
            p.precio_venta
                - (COALESCE(tcr.costo_total_lote, 0) / r.rendimiento),
            4
        )                                                   AS utilidad_unitaria,
        CASE
            WHEN p.precio_venta > 0 THEN
                ROUND(
                    (p.precio_venta
                        - COALESCE(tcr.costo_total_lote, 0) / r.rendimiento)
                    / p.precio_venta * 100,
                    2
                )
            ELSE 0
        END                                                 AS margen_pct
    FROM productos p
    INNER JOIN recetas r
            ON r.id_producto = p.id_producto
           AND r.estatus     = 'activo'
    LEFT JOIN _tmp_costo_receta tcr ON tcr.id_receta = r.id_receta
    WHERE p.estatus = 'activo'
    ORDER BY utilidad_unitaria DESC;

    DROP TEMPORARY TABLE IF EXISTS _tmp_costo_prom_mes;
    DROP TEMPORARY TABLE IF EXISTS _tmp_costo_receta;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_dash_top_productos;
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE sp_dash_top_productos()
BEGIN
    DECLARE v_desde DATE DEFAULT DATE_SUB(CURDATE(), INTERVAL 7 DAY);

    SELECT
        pr.nombre                     AS nombre_producto,
        SUM(pv.cantidad)              AS total_piezas,
        ROUND(SUM(pv.subtotal), 2)    AS total_ingresos
    FROM vw_dash_piezas_vendidas pv
    JOIN productos pr ON pr.id_producto = pv.id_producto
    WHERE pv.fecha   >= v_desde
      AND pr.estatus  = 'activo'
    GROUP BY pr.id_producto, pr.nombre
    ORDER BY total_piezas DESC
    LIMIT 5;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_dash_mp_criticas;
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE sp_dash_mp_criticas()
BEGIN
    SELECT
        nombre,
        categoria,
        unidad_base,
        stock_actual,
        stock_minimo,
        pct_stock,
        nivel
    FROM vw_dash_mp_criticas
    ORDER BY pct_stock ASC
    LIMIT 20;
END$$
DELIMITER ;


GRANT SELECT ON dulce_migaja.vw_dash_ventas_consolidadas TO 'dm_admin'@'localhost';
GRANT SELECT ON dulce_migaja.vw_dash_mp_criticas         TO 'dm_admin'@'localhost';
GRANT SELECT ON dulce_migaja.vw_dash_piezas_vendidas     TO 'dm_admin'@'localhost';

GRANT SELECT ON dulce_migaja.vw_dash_ventas_consolidadas TO 'dm_vendedor'@'localhost';
GRANT SELECT ON dulce_migaja.vw_dash_mp_criticas         TO 'dm_vendedor'@'localhost';
GRANT SELECT ON dulce_migaja.vw_dash_piezas_vendidas     TO 'dm_vendedor'@'localhost';

GRANT SELECT ON dulce_migaja.vw_dash_mp_criticas         TO 'dm_panadero'@'localhost';
GRANT SELECT ON dulce_migaja.vw_dash_piezas_vendidas     TO 'dm_panadero'@'localhost';

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_dash_ventas_totales        TO 'dm_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_dash_salidas_efectivo       TO 'dm_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_dash_utilidad_por_producto  TO 'dm_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_dash_top_productos          TO 'dm_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_dash_mp_criticas            TO 'dm_admin'@'localhost';

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_dash_ventas_totales         TO 'dm_vendedor'@'localhost';
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_dash_salidas_efectivo       TO 'dm_vendedor'@'localhost';
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_dash_top_productos          TO 'dm_vendedor'@'localhost';
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_dash_mp_criticas            TO 'dm_vendedor'@'localhost';

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_dash_top_productos          TO 'dm_panadero'@'localhost';
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_dash_mp_criticas            TO 'dm_panadero'@'localhost';

FLUSH PRIVILEGES;