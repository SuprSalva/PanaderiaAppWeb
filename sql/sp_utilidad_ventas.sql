-- ============================================================
-- MÓDULO: UTILIDAD POR VENTAS (HISTÓRICO CON FILTRO DE FECHAS)
-- Acceso exclusivo: dm_admin (rol admin)
-- Incluye: ventas en caja (completadas) + pedidos web (entregados)
-- ============================================================
-- Metodología de costo (REGLA UNIVERSAL — igual en todos los módulos):
--   • CPP (Costo Promedio Ponderado) de los ÚLTIMOS 12 MESES.
--     Σ(cantidad_base × precio_base) / Σ(cantidad_base)
--     Filtrando solo compras finalizadas del último año.
--   • Fallback: si un insumo no tiene compras en 12 meses,
--     se usa el último precio histórico registrado.
--   • El costo unitario del producto = costo_lote_receta / rendimiento.
-- Deduplicación pedidos: se excluyen pedidos que ya generaron una
--   venta automática en caja (accion = 'venta_automatica' en logs_sistema).
-- NOTA: No se usan tablas temporales en queries con UNION ALL porque
--   MySQL error 1137 "Can't reopen table" impide referenciar una temp
--   table más de una vez en la misma consulta. Se usan subqueries inline.
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- VISTA: v_costo_promedio_materia
-- CPP 12 meses con fallback al último precio histórico.
-- Esta vista es la ÚNICA fuente de costo de insumo para todos
-- los módulos: Dashboard, Costo-Utilidad y Utilidad por Ventas.
-- ──────────────────────────────────────────────────────────────
DROP VIEW IF EXISTS v_costo_promedio_materia;

CREATE VIEW v_costo_promedio_materia AS
SELECT
    ult.id_materia,
    -- CPP 12 meses cuando existe; de lo contrario, último precio histórico
    COALESCE(cpp.costo_base_12m, ult.costo_base) AS costo_base_promedio
FROM v_ultimo_costo_materia ult          -- todos los insumos con al menos 1 compra
LEFT JOIN (
    -- CPP ponderado por cantidad_base de los últimos 12 meses
    SELECT
        dc.id_materia,
        ROUND(
            SUM(dc.cantidad_base * (dc.costo_unitario / dc.factor_conversion))
            / NULLIF(SUM(dc.cantidad_base), 0),
        6) AS costo_base_12m
    FROM detalle_compras dc
    INNER JOIN compras c ON c.id_compra = dc.id_compra
    WHERE c.estatus          = 'finalizado'
      AND dc.factor_conversion > 0
      AND dc.cantidad_base    > 0
      AND c.fecha_compra     >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    GROUP BY dc.id_materia
) cpp ON cpp.id_materia = ult.id_materia;

-- ──────────────────────────────────────────────────────────────
-- SP: sp_reporte_utilidad_ventas
-- Devuelve 3 result-sets para el período solicitado:
--   SET 1 → KPIs globales del período (ventas caja + pedidos entregados)
--   SET 2 → Resumen por producto (agrupado)
--   SET 3 → Detalle línea a línea
--
-- IMPORTANTE: Se usan subqueries inline para el costo unitario en
-- lugar de tablas temporales, porque MySQL no permite referenciar una
-- tabla temporal más de una vez en la misma query (UNION ALL cuenta
-- como una sola query → error 1137 "Can't reopen table").
-- ──────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_reporte_utilidad_ventas;

DELIMITER $$

CREATE PROCEDURE sp_reporte_utilidad_ventas(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin    DATE
)
BEGIN

    -- ── SET 1: KPIs del período ─────────────────────────────────
    -- Combina ventas en caja + pedidos entregados sin duplicar los
    -- pedidos que ya generaron una venta automática.
    SELECT
        COUNT(DISTINCT t.origen_key)                                            AS total_ventas,
        COUNT(DISTINCT t.id_producto)                                           AS total_productos,
        ROUND(SUM(t.subtotal), 2)                                               AS total_ingresos,
        ROUND(SUM(t.cantidad * t.costo_unitario), 2)                           AS total_costo,
        ROUND(SUM(t.subtotal) - SUM(t.cantidad * t.costo_unitario), 2)        AS total_utilidad,
        ROUND(
            (1 - SUM(t.cantidad * t.costo_unitario) / NULLIF(SUM(t.subtotal), 0)) * 100,
        2)                                                                      AS margen_prom
    FROM (
        -- Ventas en caja
        SELECT
            CONVERT(CONCAT('v-', v.id_venta) USING utf8mb4) COLLATE utf8mb4_general_ci AS origen_key,
            dv.id_producto,
            dv.cantidad,
            dv.subtotal,
            COALESCE(cu.costo_unitario, 0)              AS costo_unitario
        FROM ventas v
        INNER JOIN detalle_ventas dv ON dv.id_venta    = v.id_venta
        LEFT JOIN (
            SELECT r.id_producto,
                   MIN(ROUND(COALESCE(lote.costo_total_lote, 0) / NULLIF(r.rendimiento, 0), 4)) AS costo_unitario
            FROM recetas r
            LEFT JOIN (
                SELECT dr.id_receta,
                       ROUND(SUM(dr.cantidad_requerida * COALESCE(cpm.costo_base_promedio, 0)), 4) AS costo_total_lote
                FROM detalle_recetas dr
                LEFT JOIN v_costo_promedio_materia cpm ON cpm.id_materia = dr.id_materia
                GROUP BY dr.id_receta
            ) lote ON lote.id_receta = r.id_receta
            WHERE r.estatus = 'activo'
            GROUP BY r.id_producto
        ) cu ON cu.id_producto = dv.id_producto
        WHERE DATE(v.fecha_venta) BETWEEN p_fecha_inicio AND p_fecha_fin
          AND v.estado = 'completada'

        UNION ALL

        -- Pedidos web entregados (excluir los que ya generaron venta automática en caja)
        SELECT
            CONVERT(CONCAT('p-', pe.id_pedido) USING utf8mb4) COLLATE utf8mb4_general_ci AS origen_key,
            dp.id_producto,
            dp.cantidad,
            dp.subtotal,
            COALESCE(cu.costo_unitario, 0)              AS costo_unitario
        FROM pedidos pe
        INNER JOIN detalle_pedidos dp ON dp.id_pedido  = pe.id_pedido
        LEFT JOIN (
            SELECT r.id_producto,
                   MIN(ROUND(COALESCE(lote.costo_total_lote, 0) / NULLIF(r.rendimiento, 0), 4)) AS costo_unitario
            FROM recetas r
            LEFT JOIN (
                SELECT dr.id_receta,
                       ROUND(SUM(dr.cantidad_requerida * COALESCE(cpm.costo_base_promedio, 0)), 4) AS costo_total_lote
                FROM detalle_recetas dr
                LEFT JOIN v_costo_promedio_materia cpm ON cpm.id_materia = dr.id_materia
                GROUP BY dr.id_receta
            ) lote ON lote.id_receta = r.id_receta
            WHERE r.estatus = 'activo'
            GROUP BY r.id_producto
        ) cu ON cu.id_producto = dp.id_producto
        WHERE DATE(pe.actualizado_en) BETWEEN p_fecha_inicio AND p_fecha_fin
          AND pe.estado = 'entregado'
          AND NOT EXISTS (
              SELECT 1 FROM logs_sistema l
              WHERE l.referencia_id   = pe.id_pedido
                AND l.referencia_tipo = 'pedido'
                AND l.accion          = 'venta_automatica'
          )
    ) t;

    -- ── SET 2: Resumen por producto ─────────────────────────────
    SELECT
        t.id_producto,
        MAX(t.nombre_producto)                                                  AS nombre_producto,
        ROUND(SUM(t.cantidad), 2)                                               AS total_piezas,
        ROUND(AVG(t.precio_unitario), 2)                                        AS precio_prom_venta,
        ROUND(MAX(t.costo_unitario), 4)                                         AS costo_unitario,
        ROUND(AVG(t.precio_unitario) - MAX(t.costo_unitario), 4)               AS utilidad_unitaria,
        ROUND(
            CASE WHEN AVG(t.precio_unitario) > 0 THEN
                (AVG(t.precio_unitario) - MAX(t.costo_unitario))
                / AVG(t.precio_unitario) * 100
            ELSE 0 END,
        2)                                                                      AS margen_pct,
        ROUND(SUM(t.subtotal - t.cantidad * t.costo_unitario), 2)              AS utilidad_total,
        ROUND(SUM(t.subtotal), 2)                                               AS ingresos_total
    FROM (
        -- Ventas en caja
        SELECT
            dv.id_producto,
            CONVERT(p.nombre USING utf8mb4) COLLATE utf8mb4_general_ci AS nombre_producto,
            dv.cantidad,
            dv.precio_unitario,
            dv.subtotal,
            COALESCE(cu.costo_unitario, 0)              AS costo_unitario
        FROM ventas v
        INNER JOIN detalle_ventas dv ON dv.id_venta    = v.id_venta
        INNER JOIN productos       p  ON p.id_producto  = dv.id_producto
        LEFT JOIN (
            SELECT r.id_producto,
                   MIN(ROUND(COALESCE(lote.costo_total_lote, 0) / NULLIF(r.rendimiento, 0), 4)) AS costo_unitario
            FROM recetas r
            LEFT JOIN (
                SELECT dr.id_receta,
                       ROUND(SUM(dr.cantidad_requerida * COALESCE(cpm.costo_base_promedio, 0)), 4) AS costo_total_lote
                FROM detalle_recetas dr
                LEFT JOIN v_costo_promedio_materia cpm ON cpm.id_materia = dr.id_materia
                GROUP BY dr.id_receta
            ) lote ON lote.id_receta = r.id_receta
            WHERE r.estatus = 'activo'
            GROUP BY r.id_producto
        ) cu ON cu.id_producto = dv.id_producto
        WHERE DATE(v.fecha_venta) BETWEEN p_fecha_inicio AND p_fecha_fin
          AND v.estado = 'completada'

        UNION ALL

        -- Pedidos web entregados
        SELECT
            dp.id_producto,
            CONVERT(pr.nombre USING utf8mb4) COLLATE utf8mb4_general_ci AS nombre_producto,
            dp.cantidad,
            dp.precio_unitario,
            dp.subtotal,
            COALESCE(cu.costo_unitario, 0)              AS costo_unitario
        FROM pedidos pe
        INNER JOIN detalle_pedidos dp ON dp.id_pedido  = pe.id_pedido
        INNER JOIN productos       pr ON pr.id_producto = dp.id_producto
        LEFT JOIN (
            SELECT r.id_producto,
                   MIN(ROUND(COALESCE(lote.costo_total_lote, 0) / NULLIF(r.rendimiento, 0), 4)) AS costo_unitario
            FROM recetas r
            LEFT JOIN (
                SELECT dr.id_receta,
                       ROUND(SUM(dr.cantidad_requerida * COALESCE(cpm.costo_base_promedio, 0)), 4) AS costo_total_lote
                FROM detalle_recetas dr
                LEFT JOIN v_costo_promedio_materia cpm ON cpm.id_materia = dr.id_materia
                GROUP BY dr.id_receta
            ) lote ON lote.id_receta = r.id_receta
            WHERE r.estatus = 'activo'
            GROUP BY r.id_producto
        ) cu ON cu.id_producto = dp.id_producto
        WHERE DATE(pe.actualizado_en) BETWEEN p_fecha_inicio AND p_fecha_fin
          AND pe.estado = 'entregado'
          AND NOT EXISTS (
              SELECT 1 FROM logs_sistema l
              WHERE l.referencia_id   = pe.id_pedido
                AND l.referencia_tipo = 'pedido'
                AND l.accion          = 'venta_automatica'
          )
    ) t
    GROUP BY t.id_producto
    ORDER BY utilidad_total DESC;

    -- ── SET 3: Detalle por línea ────────────────────────────────
    SELECT
        folio_venta,
        fecha_venta,
        hora_venta,
        nombre_producto,
        cantidad,
        precio_venta,
        costo_unitario,
        utilidad_unitaria,
        utilidad_total,
        ingreso_total
    FROM (
        -- Ventas en caja
        SELECT
            CONVERT(v.folio_venta USING utf8mb4) COLLATE utf8mb4_general_ci    AS folio_venta,
            DATE(v.fecha_venta)                                                 AS fecha_venta,
            TIME(v.fecha_venta)                                                 AS hora_venta,
            CONVERT(p.nombre USING utf8mb4) COLLATE utf8mb4_general_ci         AS nombre_producto,
            ROUND(dv.cantidad, 2)                                               AS cantidad,
            ROUND(dv.precio_unitario, 2)                                        AS precio_venta,
            ROUND(COALESCE(cu.costo_unitario, 0), 4)                           AS costo_unitario,
            ROUND(dv.precio_unitario - COALESCE(cu.costo_unitario, 0), 4)     AS utilidad_unitaria,
            ROUND(dv.subtotal - dv.cantidad * COALESCE(cu.costo_unitario, 0), 2) AS utilidad_total,
            ROUND(dv.subtotal, 2)                                               AS ingreso_total,
            v.fecha_venta                                                       AS _sort
        FROM ventas v
        INNER JOIN detalle_ventas dv ON dv.id_venta    = v.id_venta
        INNER JOIN productos       p  ON p.id_producto  = dv.id_producto
        LEFT JOIN (
            SELECT r.id_producto,
                   MIN(ROUND(COALESCE(lote.costo_total_lote, 0) / NULLIF(r.rendimiento, 0), 4)) AS costo_unitario
            FROM recetas r
            LEFT JOIN (
                SELECT dr.id_receta,
                       ROUND(SUM(dr.cantidad_requerida * COALESCE(cpm.costo_base_promedio, 0)), 4) AS costo_total_lote
                FROM detalle_recetas dr
                LEFT JOIN v_costo_promedio_materia cpm ON cpm.id_materia = dr.id_materia
                GROUP BY dr.id_receta
            ) lote ON lote.id_receta = r.id_receta
            WHERE r.estatus = 'activo'
            GROUP BY r.id_producto
        ) cu ON cu.id_producto = dv.id_producto
        WHERE DATE(v.fecha_venta) BETWEEN p_fecha_inicio AND p_fecha_fin
          AND v.estado = 'completada'

        UNION ALL

        -- Pedidos web entregados
        SELECT
            CONVERT(pe.folio USING utf8mb4) COLLATE utf8mb4_general_ci         AS folio_venta,
            DATE(pe.actualizado_en)                                             AS fecha_venta,
            TIME(pe.actualizado_en)                                             AS hora_venta,
            CONVERT(pr.nombre USING utf8mb4) COLLATE utf8mb4_general_ci        AS nombre_producto,
            ROUND(dp.cantidad, 2)                                               AS cantidad,
            ROUND(dp.precio_unitario, 2)                                        AS precio_venta,
            ROUND(COALESCE(cu.costo_unitario, 0), 4)                           AS costo_unitario,
            ROUND(dp.precio_unitario - COALESCE(cu.costo_unitario, 0), 4)     AS utilidad_unitaria,
            ROUND(dp.subtotal - dp.cantidad * COALESCE(cu.costo_unitario, 0), 2) AS utilidad_total,
            ROUND(dp.subtotal, 2)                                               AS ingreso_total,
            pe.actualizado_en                                                   AS _sort
        FROM pedidos pe
        INNER JOIN detalle_pedidos dp ON dp.id_pedido  = pe.id_pedido
        INNER JOIN productos       pr ON pr.id_producto = dp.id_producto
        LEFT JOIN (
            SELECT r.id_producto,
                   MIN(ROUND(COALESCE(lote.costo_total_lote, 0) / NULLIF(r.rendimiento, 0), 4)) AS costo_unitario
            FROM recetas r
            LEFT JOIN (
                SELECT dr.id_receta,
                       ROUND(SUM(dr.cantidad_requerida * COALESCE(cpm.costo_base_promedio, 0)), 4) AS costo_total_lote
                FROM detalle_recetas dr
                LEFT JOIN v_costo_promedio_materia cpm ON cpm.id_materia = dr.id_materia
                GROUP BY dr.id_receta
            ) lote ON lote.id_receta = r.id_receta
            WHERE r.estatus = 'activo'
            GROUP BY r.id_producto
        ) cu ON cu.id_producto = dp.id_producto
        WHERE DATE(pe.actualizado_en) BETWEEN p_fecha_inicio AND p_fecha_fin
          AND pe.estado = 'entregado'
          AND NOT EXISTS (
              SELECT 1 FROM logs_sistema l
              WHERE l.referencia_id   = pe.id_pedido
                AND l.referencia_tipo = 'pedido'
                AND l.accion          = 'venta_automatica'
          )
    ) combined
    ORDER BY _sort DESC, folio_venta, nombre_producto;

END$$

DELIMITER ;
