-- ============================================================
-- MÓDULO: UTILIDAD POR VENTAS (HISTÓRICO CON FILTRO DE FECHAS)
-- Acceso exclusivo: dm_admin (rol admin)
-- ============================================================
-- Metodología de costo (REGLA UNIVERSAL — igual en todos los módulos):
--   • CPP (Costo Promedio Ponderado) de los ÚLTIMOS 12 MESES.
--     Σ(cantidad_base × precio_base) / Σ(cantidad_base)
--     Filtrando solo compras finalizadas del último año.
--   • Fallback: si un insumo no tiene compras en 12 meses,
--     se usa el último precio histórico registrado.
--   • El costo unitario del producto = costo_lote_receta / rendimiento.
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
--   SET 1 → KPIs globales del período
--   SET 2 → Resumen por producto (agrupado)
--   SET 3 → Detalle línea a línea (por venta)
-- ──────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_reporte_utilidad_ventas;

DELIMITER $$

CREATE PROCEDURE sp_reporte_utilidad_ventas(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin    DATE
)
BEGIN

    -- 1. Costo total de lote por receta usando precios PROMEDIO
    DROP TEMPORARY TABLE IF EXISTS tmp_uv_costo_lote;
    CREATE TEMPORARY TABLE tmp_uv_costo_lote AS
    SELECT
        dr.id_receta,
        ROUND(
            SUM(dr.cantidad_requerida * COALESCE(cpm.costo_base_promedio, 0)),
        4) AS costo_total_lote
    FROM detalle_recetas dr
    LEFT JOIN v_costo_promedio_materia cpm ON cpm.id_materia = dr.id_materia
    GROUP BY dr.id_receta;

    -- 2. Costo unitario por producto (se usa la primera receta activa en caso
    --    de que el producto tenga varias; la de id_tamanio IS NULL tiene prioridad)
    DROP TEMPORARY TABLE IF EXISTS tmp_uv_costo_unit;
    CREATE TEMPORARY TABLE tmp_uv_costo_unit AS
    SELECT
        r.id_producto,
        ROUND(
            COALESCE(tcl.costo_total_lote, 0) / NULLIF(r.rendimiento, 0),
        4) AS costo_unitario
    FROM recetas r
    LEFT JOIN tmp_uv_costo_lote tcl ON tcl.id_receta = r.id_receta
    WHERE r.estatus = 'activo'
    ORDER BY r.id_producto, (r.id_tamanio IS NULL) DESC, r.id_receta ASC
    LIMIT 18446744073709551615;   -- workaround para ORDER BY dentro de subconsulta

    -- Si un producto tiene más de una receta activa conservamos solo la primera
    DROP TEMPORARY TABLE IF EXISTS tmp_uv_costo_final;
    CREATE TEMPORARY TABLE tmp_uv_costo_final AS
    SELECT id_producto, MIN(costo_unitario) AS costo_unitario
    FROM tmp_uv_costo_unit
    GROUP BY id_producto;

    -- ── SET 1: KPIs del período ─────────────────────────────────
    SELECT
        COUNT(DISTINCT v.id_venta)                                              AS total_ventas,
        COUNT(DISTINCT dv.id_producto)                                          AS total_productos,
        ROUND(SUM(dv.subtotal), 2)                                              AS total_ingresos,
        ROUND(SUM(dv.cantidad * COALESCE(cu.costo_unitario, 0)), 2)            AS total_costo,
        ROUND(
            SUM(dv.subtotal)
            - SUM(dv.cantidad * COALESCE(cu.costo_unitario, 0)),
        2)                                                                      AS total_utilidad,
        ROUND(
            (1 - SUM(dv.cantidad * COALESCE(cu.costo_unitario, 0))
                   / NULLIF(SUM(dv.subtotal), 0)) * 100,
        2)                                                                      AS margen_prom
    FROM ventas v
    INNER JOIN detalle_ventas dv ON dv.id_venta    = v.id_venta
    LEFT  JOIN tmp_uv_costo_final cu ON cu.id_producto = dv.id_producto
    WHERE DATE(v.fecha_venta) BETWEEN p_fecha_inicio AND p_fecha_fin
      AND v.estado = 'completada';

    -- ── SET 2: Resumen por producto ─────────────────────────────
    SELECT
        p.id_producto,
        p.nombre                                                                AS nombre_producto,
        ROUND(SUM(dv.cantidad), 2)                                             AS total_piezas,
        ROUND(AVG(dv.precio_unitario), 2)                                      AS precio_prom_venta,
        ROUND(MAX(COALESCE(cu.costo_unitario, 0)), 4)                          AS costo_unitario,
        ROUND(AVG(dv.precio_unitario) - MAX(COALESCE(cu.costo_unitario, 0)), 4) AS utilidad_unitaria,
        ROUND(
            CASE WHEN AVG(dv.precio_unitario) > 0 THEN
                (AVG(dv.precio_unitario) - MAX(COALESCE(cu.costo_unitario, 0)))
                / AVG(dv.precio_unitario) * 100
            ELSE 0 END,
        2)                                                                      AS margen_pct,
        ROUND(SUM(dv.subtotal - dv.cantidad * COALESCE(cu.costo_unitario, 0)), 2) AS utilidad_total,
        ROUND(SUM(dv.subtotal), 2)                                             AS ingresos_total
    FROM ventas v
    INNER JOIN detalle_ventas dv ON dv.id_venta    = v.id_venta
    INNER JOIN productos       p  ON p.id_producto  = dv.id_producto
    LEFT  JOIN tmp_uv_costo_final cu ON cu.id_producto = dv.id_producto
    WHERE DATE(v.fecha_venta) BETWEEN p_fecha_inicio AND p_fecha_fin
      AND v.estado = 'completada'
    GROUP BY p.id_producto, p.nombre
    ORDER BY utilidad_total DESC;

    -- ── SET 3: Detalle por línea de venta ───────────────────────
    SELECT
        v.id_venta,
        v.folio_venta,
        DATE(v.fecha_venta)                                                     AS fecha_venta,
        TIME(v.fecha_venta)                                                     AS hora_venta,
        p.nombre                                                                AS nombre_producto,
        ROUND(dv.cantidad, 2)                                                  AS cantidad,
        ROUND(dv.precio_unitario, 2)                                           AS precio_venta,
        ROUND(COALESCE(cu.costo_unitario, 0), 4)                               AS costo_unitario,
        ROUND(dv.precio_unitario - COALESCE(cu.costo_unitario, 0), 4)         AS utilidad_unitaria,
        ROUND(dv.subtotal - dv.cantidad * COALESCE(cu.costo_unitario, 0), 2)  AS utilidad_total,
        ROUND(dv.subtotal, 2)                                                  AS ingreso_total
    FROM ventas v
    INNER JOIN detalle_ventas dv ON dv.id_venta    = v.id_venta
    INNER JOIN productos       p  ON p.id_producto  = dv.id_producto
    LEFT  JOIN tmp_uv_costo_final cu ON cu.id_producto = dv.id_producto
    WHERE DATE(v.fecha_venta) BETWEEN p_fecha_inicio AND p_fecha_fin
      AND v.estado = 'completada'
    ORDER BY v.fecha_venta DESC, v.folio_venta, p.nombre;

    -- Limpieza
    DROP TEMPORARY TABLE IF EXISTS tmp_uv_costo_lote;
    DROP TEMPORARY TABLE IF EXISTS tmp_uv_costo_unit;
    DROP TEMPORARY TABLE IF EXISTS tmp_uv_costo_final;

END$$

DELIMITER ;

-- ──────────────────────────────────────────────────────────────
-- PERMISOS
-- ──────────────────────────────────────────────────────────────
GRANT SELECT    ON dulce_migaja.v_costo_promedio_materia      TO 'dm_admin'@'localhost';
GRANT EXECUTE   ON PROCEDURE dulce_migaja.sp_reporte_utilidad_ventas TO 'dm_admin'@'localhost';

FLUSH PRIVILEGES;
