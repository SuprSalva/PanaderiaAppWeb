-- ============================================================
-- MÓDULO: COSTOS Y UTILIDAD POR PRODUCTO
-- Acceso exclusivo: dm_admin (rol admin)
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- ÍNDICES (mejoran rendimiento de las consultas del módulo)
-- ──────────────────────────────────────────────────────────────

-- Índice en detalle_recetas para búsquedas por receta
CREATE INDEX idx_det_recetas_id_receta
    ON detalle_recetas (id_receta);

-- Índice en detalle_compras para obtener el último costo por materia
CREATE INDEX idx_det_compras_materia_fecha
    ON detalle_compras (id_materia, id_compra);

-- Índice en recetas para filtrar por producto activo
CREATE INDEX idx_recetas_producto_estatus
    ON recetas (id_producto, estatus);

-- ──────────────────────────────────────────────────────────────
-- VISTA: v_ultimo_costo_materia
-- Obtiene el último costo unitario (en unidad base) de cada
-- materia prima a partir de la compra más reciente.
-- ──────────────────────────────────────────────────────────────
DROP VIEW IF EXISTS v_ultimo_costo_materia;

CREATE VIEW v_ultimo_costo_materia AS
SELECT
    dc.id_materia,
    dc.costo_unitario        AS costo_por_unidad_base,
    dc.unidad_compra,
    dc.factor_conversion,
    -- Costo real en unidad base = costo_unitario / factor_conversion
    ROUND(dc.costo_unitario / dc.factor_conversion, 6) AS costo_base
FROM detalle_compras dc
INNER JOIN (
    SELECT dc2.id_materia, MAX(dc2.id_compra) AS max_compra
    FROM detalle_compras dc2
    GROUP BY dc2.id_materia
) ult ON dc.id_materia = ult.id_materia
      AND dc.id_compra = ult.max_compra;

-- ================================================================
-- AJUSTES: Módulo Costos y Utilidad por Producto
-- Cambios:
--   1. sp_kpi_costo_utilidad  → agrega costo_prom
--   2. sp_reporte_costo_utilidad → agrega p_util_min, p_util_max
-- ================================================================

-- ──────────────────────────────────────────────────────────────
-- 1. sp_kpi_costo_utilidad — agrega costo_prom al resultado
-- ──────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_kpi_costo_utilidad;

DELIMITER $$

CREATE PROCEDURE sp_kpi_costo_utilidad()
BEGIN
    -- Precio real: promedio de ventas últimos 30 días; fallback precio catálogo
    DROP TEMPORARY TABLE IF EXISTS _tmp_kpi_precio_real;
    CREATE TEMPORARY TABLE _tmp_kpi_precio_real AS
    SELECT dv.id_producto, ROUND(AVG(dv.precio_unitario), 2) AS precio_real
    FROM detalle_ventas dv
    INNER JOIN ventas v ON v.id_venta = dv.id_venta
    WHERE v.estado = 'completada'
      AND DATE(v.fecha_venta) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY dv.id_producto;

    -- MySQL no permite referenciar la misma tabla temporal dos veces en un SELECT.
    -- Se crea una copia para usarla dentro de la subconsulta interna (mc).
    DROP TEMPORARY TABLE IF EXISTS _tmp_kpi_precio_real2;
    CREATE TEMPORARY TABLE _tmp_kpi_precio_real2 AS
    SELECT * FROM _tmp_kpi_precio_real;

    SELECT
        COUNT(DISTINCT p.id_producto)                             AS total_productos,
        ROUND(AVG(mc.margen_pct), 2)                             AS margen_prom,
        ROUND(AVG(mc.costo_unitario), 2)                         AS costo_prom,
        ROUND(AVG(COALESCE(pvr.precio_real, p.precio_venta)), 2) AS precio_prom,
        SUM(CASE WHEN mc.margen_pct < 20 THEN 1 ELSE 0 END)     AS productos_margen_bajo
    FROM productos p
    INNER JOIN recetas r
           ON  r.id_producto = p.id_producto
           AND r.estatus     = 'activo'
    LEFT JOIN _tmp_kpi_precio_real pvr ON pvr.id_producto = p.id_producto
    INNER JOIN (
        SELECT
            r2.id_receta,
            r2.id_producto,
            ROUND(
                COALESCE(tcr.costo_total_lote, 0) / r2.rendimiento,
                4
            )                                                         AS costo_unitario,
            CASE
                WHEN COALESCE(pvr2.precio_real, p2.precio_venta) > 0 THEN
                    ROUND(
                        (COALESCE(pvr2.precio_real, p2.precio_venta)
                            - COALESCE(tcr.costo_total_lote, 0) / r2.rendimiento)
                        / COALESCE(pvr2.precio_real, p2.precio_venta) * 100,
                        2
                    )
                ELSE 0
            END                                                       AS margen_pct
        FROM recetas r2
        INNER JOIN productos p2
               ON  p2.id_producto = r2.id_producto
               AND p2.estatus     = 'activo'
        LEFT JOIN _tmp_kpi_precio_real2 pvr2 ON pvr2.id_producto = p2.id_producto
        LEFT JOIN (
            SELECT
                dr.id_receta,
                ROUND(SUM(dr.cantidad_requerida * COALESCE(cpm.costo_base_promedio, 0)), 4)
                    AS costo_total_lote
            FROM detalle_recetas dr
            LEFT JOIN v_costo_promedio_materia cpm
                   ON cpm.id_materia = dr.id_materia
            GROUP BY dr.id_receta
        ) tcr ON tcr.id_receta = r2.id_receta
        WHERE r2.estatus = 'activo'
    ) mc ON mc.id_receta = r.id_receta
    WHERE p.estatus = 'activo';

    DROP TEMPORARY TABLE IF EXISTS _tmp_kpi_precio_real;
    DROP TEMPORARY TABLE IF EXISTS _tmp_kpi_precio_real2;
END$$

DELIMITER ;

-- ──────────────────────────────────────────────────────────────
-- 2. sp_reporte_costo_utilidad — agrega filtro por rango de utilidad
-- ──────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_reporte_costo_utilidad;

DELIMITER $$

CREATE PROCEDURE sp_reporte_costo_utilidad(
    IN p_buscar    VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    IN p_orden     VARCHAR(30),
    IN p_util_min  DECIMAL(12,4),
    IN p_util_max  DECIMAL(12,4)
)
BEGIN
    -- Paso 1: Costo total de insumos por receta — promedio ponderado histórico
    DROP TEMPORARY TABLE IF EXISTS tmp_costo_receta;

    CREATE TEMPORARY TABLE tmp_costo_receta AS
    SELECT
        dr.id_receta,
        ROUND(
            SUM(dr.cantidad_requerida * COALESCE(cpm.costo_base_promedio, 0)),
            4
        ) AS costo_total_lote
    FROM detalle_recetas dr
    LEFT JOIN v_costo_promedio_materia cpm ON cpm.id_materia = dr.id_materia
    GROUP BY dr.id_receta;

    -- Precio real: promedio ventas últimos 30 días; fallback precio catálogo
    DROP TEMPORARY TABLE IF EXISTS tmp_precio_real;
    CREATE TEMPORARY TABLE tmp_precio_real AS
    SELECT dv.id_producto, ROUND(AVG(dv.precio_unitario), 2) AS precio_real
    FROM detalle_ventas dv
    INNER JOIN ventas v ON v.id_venta = dv.id_venta
    WHERE v.estado = 'completada'
      AND DATE(v.fecha_venta) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY dv.id_producto;

    -- Paso 2: Resultado completo en tabla temporal (permite filtrar por utilidad)
    DROP TEMPORARY TABLE IF EXISTS tmp_resultado_cu;

    CREATE TEMPORARY TABLE tmp_resultado_cu AS
    SELECT
        p.id_producto,
        p.nombre                                                    AS nombre_producto,
        COALESCE(pvr.precio_real, p.precio_venta)                  AS precio_venta,
        r.id_receta,
        r.nombre                                                    AS nombre_receta,
        r.rendimiento,
        r.unidad_rendimiento,
        ROUND(
            COALESCE(tcr.costo_total_lote, 0) / r.rendimiento,
            4
        )                                                           AS costo_unitario,
        ROUND(
            COALESCE(pvr.precio_real, p.precio_venta)
                - (COALESCE(tcr.costo_total_lote, 0) / r.rendimiento),
            4
        )                                                           AS utilidad_unitaria,
        CASE
            WHEN COALESCE(pvr.precio_real, p.precio_venta) > 0 THEN
                ROUND(
                    (COALESCE(pvr.precio_real, p.precio_venta)
                        - (COALESCE(tcr.costo_total_lote, 0) / r.rendimiento))
                    / COALESCE(pvr.precio_real, p.precio_venta) * 100,
                    2
                )
            ELSE 0
        END                                                         AS margen_pct
    FROM productos p
    INNER JOIN recetas r
           ON  r.id_producto = p.id_producto
           AND r.estatus     = 'activo'
    LEFT JOIN tmp_costo_receta tcr ON tcr.id_receta = r.id_receta
    LEFT JOIN tmp_precio_real  pvr ON pvr.id_producto = p.id_producto
    WHERE p.estatus = 'activo'
      AND (
          p_buscar IS NULL
          OR p_buscar = ''
          OR p.nombre LIKE CONCAT('%', p_buscar COLLATE utf8mb4_unicode_ci, '%')
      );

    -- Paso 3: Devolver resultado con filtro de rango de utilidad y ordenamiento
    SELECT *
    FROM tmp_resultado_cu
    WHERE (p_util_min IS NULL OR utilidad_unitaria >= p_util_min)
      AND (p_util_max IS NULL OR utilidad_unitaria <= p_util_max)
    ORDER BY
        CASE WHEN p_orden = 'margen_asc'  THEN margen_pct     END ASC,
        CASE WHEN p_orden = 'margen_desc' THEN margen_pct     END DESC,
        CASE WHEN p_orden = 'costo_asc'   THEN costo_unitario END ASC,
        CASE WHEN p_orden = 'costo_desc'  THEN costo_unitario END DESC,
        nombre_producto ASC;

    -- Limpieza
    DROP TEMPORARY TABLE IF EXISTS tmp_resultado_cu;
    DROP TEMPORARY TABLE IF EXISTS tmp_costo_receta;
    DROP TEMPORARY TABLE IF EXISTS tmp_precio_real;
END$$

DELIMITER ;

-- ──────────────────────────────────────────────────────────────
-- SP: sp_detalle_costo_producto
-- Detalla el costo insumo a insumo de un producto/receta
-- ──────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_detalle_costo_producto;

DELIMITER $$

CREATE PROCEDURE sp_detalle_costo_producto(
    IN p_id_receta INT
)
BEGIN
    SELECT
        mp.nombre                                   AS materia_nombre,
        mp.unidad_base,
        dr.cantidad_requerida,
        COALESCE(cpm.costo_base_promedio, 0)       AS costo_base_unitario,
        ROUND(dr.cantidad_requerida * COALESCE(cpm.costo_base_promedio, 0), 4) AS subtotal_costo,
        -- Peso % sobre el total
        ROUND(
            (dr.cantidad_requerida * COALESCE(cpm.costo_base_promedio, 0))
            / NULLIF(
                (SELECT SUM(dr2.cantidad_requerida * COALESCE(cpm2.costo_base_promedio, 0))
                 FROM detalle_recetas dr2
                 LEFT JOIN v_costo_promedio_materia cpm2 ON cpm2.id_materia = dr2.id_materia
                 WHERE dr2.id_receta = p_id_receta),
            0) * 100, 2
        )                                           AS pct_del_costo
    FROM detalle_recetas dr
    INNER JOIN materias_primas mp ON mp.id_materia = dr.id_materia
    LEFT JOIN v_costo_promedio_materia cpm ON cpm.id_materia = dr.id_materia
    WHERE dr.id_receta = p_id_receta
    ORDER BY subtotal_costo DESC;
END$$

DELIMITER ;

-- ──────────────────────────────────────────────────────────────
-- PERMISOS: solo dm_admin puede usar los objetos de este módulo
-- ──────────────────────────────────────────────────────────────

-- Vista
GRANT SELECT ON dulce_migaja.v_ultimo_costo_materia TO 'dm_admin'@'localhost';

-- Stored procedures
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_reporte_costo_utilidad  TO 'dm_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_detalle_costo_producto   TO 'dm_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_kpi_costo_utilidad       TO 'dm_admin'@'localhost';

FLUSH PRIVILEGES;