-- ============================================================
--  MÓDULO VENTAS  –  Índices · Stored Procedures · Triggers
--  Base de datos: dulce_migaja
--  Fecha: 2026-04-04
-- ============================================================

-- ─────────────────────────────────────────────────────────────
--  1. ÍNDICES
-- ─────────────────────────────────────────────────────────────

-- Búsquedas frecuentes por fecha en la lista de ventas
ALTER TABLE ventas
    ADD INDEX IF NOT EXISTS idx_ventas_fecha        (fecha_venta),
    ADD INDEX IF NOT EXISTS idx_ventas_estado_fecha (estado, fecha_venta),
    ADD INDEX IF NOT EXISTS idx_ventas_vendedor_fecha(vendedor_id, fecha_venta);

-- Consultas de detalle por venta
ALTER TABLE detalle_ventas
    ADD INDEX IF NOT EXISTS idx_dv_venta_producto (id_venta, id_producto);

-- Consultas de stock bajo / alertas
ALTER TABLE inventario_pt
    ADD INDEX IF NOT EXISTS idx_inv_stock_minimo (stock_actual, stock_minimo);


-- ─────────────────────────────────────────────────────────────
--  2. STORED PROCEDURES
-- ─────────────────────────────────────────────────────────────

-- ── 2.1  sp_catalogo_ventas ──────────────────────────────────
DROP PROCEDURE IF EXISTS sp_catalogo_ventas;
DELIMITER ;;
CREATE PROCEDURE sp_catalogo_ventas(
    IN p_busqueda VARCHAR(120)
)
BEGIN
    SELECT  p.id_producto,
            p.nombre,
            p.descripcion,
            p.precio_venta,
            COALESCE(i.stock_actual, 0)  AS stock_actual,
            COALESCE(i.stock_minimo, 0)  AS stock_minimo,
            CASE WHEN COALESCE(i.stock_actual, 0) <= 0              THEN 'agotado'
                 WHEN COALESCE(i.stock_actual, 0) <= COALESCE(i.stock_minimo, 0) THEN 'bajo'
                 ELSE 'disponible'
            END AS estado_stock
    FROM    productos    p
    LEFT JOIN inventario_pt i ON i.id_producto = p.id_producto
    WHERE   p.estatus = 'activo'
      AND   (p_busqueda IS NULL
             OR p_busqueda = ''
             OR p.nombre LIKE CONCAT('%', p_busqueda, '%'))
    ORDER BY p.nombre;
END;;
DELIMITER ;


-- ── 2.2  sp_crear_venta ──────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_crear_venta;
DELIMITER ;;
CREATE PROCEDURE sp_crear_venta(
    IN  p_vendedor_id     INT,
    IN  p_metodo_pago     VARCHAR(20),
    IN  p_monto_recibido  DECIMAL(12,2),   -- NULL si no es efectivo
    IN  p_requiere_ticket TINYINT(1),
    IN  p_items           JSON,
    -- [{id_producto, cantidad, precio_unitario, descuento_pct}]
    OUT p_id_venta        INT,
    OUT p_folio           VARCHAR(20),
    OUT p_cambio          DECIMAL(10,2),
    OUT p_error           VARCHAR(255)
)
sp_main: BEGIN
    DECLARE v_n          INT;
    DECLARE v_i          INT DEFAULT 0;
    DECLARE v_id_prod    INT;
    DECLARE v_cantidad   DECIMAL(10,2);
    DECLARE v_precio     DECIMAL(10,2);
    DECLARE v_desc_pct   DECIMAL(5,2);
    DECLARE v_subtotal   DECIMAL(12,2);
    DECLARE v_total      DECIMAL(12,2) DEFAULT 0;
    DECLARE v_stock      DECIMAL(12,2);
    DECLARE v_nombre_prod VARCHAR(120);
    DECLARE v_next_seq   INT;
    DECLARE v_folio      VARCHAR(20);
    DECLARE v_cambio     DECIMAL(10,2) DEFAULT 0;
    DECLARE v_ticket_json JSON;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
        SET p_id_venta = NULL;
        SET p_folio    = NULL;
        SET p_cambio   = NULL;
    END;

    SET p_error    = NULL;
    SET p_id_venta = NULL;
    SET p_folio    = NULL;
    SET p_cambio   = 0;

    -- Validar método de pago
    IF p_metodo_pago NOT IN ('efectivo','tarjeta','transferencia','otro') THEN
        SET p_error = 'Método de pago inválido.';
        LEAVE sp_main;
    END IF;

    -- Validar que haya items
    SET v_n = JSON_LENGTH(p_items);
    IF v_n IS NULL OR v_n = 0 THEN
        SET p_error = 'La venta debe incluir al menos un producto.';
        LEAVE sp_main;
    END IF;

    -- ── Validar stock de cada item antes de tocar nada ──────
    SET v_i = 0;
    WHILE v_i < v_n DO
        SET v_id_prod  = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[',v_i,'].id_producto')))  AS UNSIGNED);
        SET v_cantidad = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[',v_i,'].cantidad')))       AS DECIMAL(10,2));

        SELECT nombre INTO v_nombre_prod
        FROM   productos
        WHERE  id_producto = v_id_prod AND estatus = 'activo';

        IF v_nombre_prod IS NULL THEN
            SET p_error = CONCAT('Producto ID ', v_id_prod, ' no existe o está inactivo.');
            LEAVE sp_main;
        END IF;

        SELECT COALESCE(stock_actual, 0) INTO v_stock
        FROM   inventario_pt
        WHERE  id_producto = v_id_prod;

        IF v_stock < v_cantidad THEN
            SET p_error = CONCAT('Stock insuficiente para "', v_nombre_prod,
                                 '". Disponible: ', v_stock, ', solicitado: ', v_cantidad);
            LEAVE sp_main;
        END IF;

        SET v_i = v_i + 1;
    END WHILE;

    -- ── Generar folio ────────────────────────────────────────
    SELECT COUNT(*) + 1 INTO v_next_seq
    FROM   ventas
    WHERE  DATE(fecha_venta) = CURDATE();

    SET v_folio = CONCAT('VTA-', DATE_FORMAT(NOW(),'%Y%m%d'), '-', LPAD(v_next_seq, 3, '0'));

    START TRANSACTION;

    -- Cabecera (estado abierta mientras se insertan detalles)
    INSERT INTO ventas (folio_venta, fecha_venta, total, metodo_pago, cambio,
                        requiere_ticket, estado, vendedor_id, creado_en)
    VALUES (v_folio, NOW(), 0, p_metodo_pago, 0,
            p_requiere_ticket, 'abierta', p_vendedor_id, NOW());

    SET p_id_venta = LAST_INSERT_ID();

    -- ── Insertar renglones y descontar inventario ────────────
    SET v_i     = 0;
    SET v_total = 0;

    WHILE v_i < v_n DO
        SET v_id_prod  = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[',v_i,'].id_producto')))  AS UNSIGNED);
        SET v_cantidad = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[',v_i,'].cantidad')))       AS DECIMAL(10,2));
        SET v_precio   = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[',v_i,'].precio_unitario'))) AS DECIMAL(10,2));
        SET v_desc_pct = CAST(COALESCE(JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[',v_i,'].descuento_pct'))), 0) AS DECIMAL(5,2));
        SET v_subtotal = ROUND(v_cantidad * v_precio * (1 - v_desc_pct / 100), 2);
        SET v_total    = v_total + v_subtotal;

        INSERT INTO detalle_ventas (id_venta, id_producto, cantidad,
                                    precio_unitario, descuento_pct, subtotal)
        VALUES (p_id_venta, v_id_prod, v_cantidad, v_precio, v_desc_pct, v_subtotal);

        -- Descuento de inventario (el trigger impide negativos)
        UPDATE inventario_pt
        SET    stock_actual = stock_actual - v_cantidad
        WHERE  id_producto  = v_id_prod;

        SET v_i = v_i + 1;
    END WHILE;

    -- ── Calcular cambio (efectivo) ───────────────────────────
    IF p_metodo_pago = 'efectivo' THEN
        IF p_monto_recibido IS NULL OR p_monto_recibido < v_total THEN
            ROLLBACK;
            SET p_error    = CONCAT('Monto recibido (', COALESCE(p_monto_recibido,'—'),
                                    ') insuficiente. Total: ', v_total);
            SET p_id_venta = NULL;
            SET p_folio    = NULL;
            LEAVE sp_main;
        END IF;
        SET v_cambio = p_monto_recibido - v_total;
    END IF;

    -- Actualizar cabecera a completada
    UPDATE ventas
    SET    total  = v_total,
           cambio = v_cambio,
           estado = 'completada'
    WHERE  id_venta = p_id_venta;

    -- ── Generar ticket (JSON enriquecido) ────────────────────
    IF p_requiere_ticket = 1 THEN
        SELECT JSON_OBJECT(
                    'folio',        v_folio,
                    'fecha',        DATE_FORMAT(NOW(), '%d/%m/%Y %H:%i'),
                    'metodo_pago',  p_metodo_pago,
                    'total',        v_total,
                    'cambio',       v_cambio,
                    'monto_recibido', p_monto_recibido,
                    'items', (
                        SELECT JSON_ARRAYAGG(
                                   JSON_OBJECT(
                                       'nombre',      pr.nombre,
                                       'cantidad',    dv.cantidad,
                                       'precio',      dv.precio_unitario,
                                       'descuento',   dv.descuento_pct,
                                       'subtotal',    dv.subtotal
                                   )
                               )
                        FROM detalle_ventas dv
                        JOIN productos      pr ON pr.id_producto = dv.id_producto
                        WHERE dv.id_venta = p_id_venta
                    )
               ) INTO v_ticket_json;

        INSERT INTO tickets (id_venta, contenido_json, impreso, generado_en)
        VALUES (p_id_venta, v_ticket_json, 0, NOW());
    END IF;

    -- Log de auditoría
    INSERT INTO logs_sistema (tipo, nivel, id_usuario, modulo, accion, descripcion, creado_en)
    VALUES ('venta', 'INFO', p_vendedor_id, 'ventas', 'crear_venta',
            CONCAT('Venta registrada: ', v_folio, ' | Total: $', v_total), NOW());

    COMMIT;

    SET p_folio  = v_folio;
    SET p_cambio = v_cambio;
END;;
DELIMITER ;


-- ── 2.3  sp_cancelar_venta ───────────────────────────────────
DROP PROCEDURE IF EXISTS sp_cancelar_venta;
DELIMITER ;;
CREATE PROCEDURE sp_cancelar_venta(
    IN  p_id_venta    INT,
    IN  p_cancelado_por INT,
    OUT p_error       VARCHAR(255)
)
sp_main: BEGIN
    DECLARE v_estado    VARCHAR(20);
    DECLARE v_folio     VARCHAR(20);
    DECLARE v_id_prod   INT;
    DECLARE v_cantidad  DECIMAL(10,2);
    DECLARE v_done      INT DEFAULT 0;

    DECLARE cur_det CURSOR FOR
        SELECT id_producto, cantidad
        FROM   detalle_ventas
        WHERE  id_venta = p_id_venta;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
    END;

    SET p_error = NULL;

    SELECT estado, folio_venta INTO v_estado, v_folio
    FROM   ventas
    WHERE  id_venta = p_id_venta;

    IF v_estado IS NULL THEN
        SET p_error = 'Venta no encontrada.';
        LEAVE sp_main;
    END IF;

    IF v_estado != 'completada' THEN
        SET p_error = CONCAT('Solo se pueden cancelar ventas completadas. Estado actual: ', v_estado);
        LEAVE sp_main;
    END IF;

    START TRANSACTION;

    -- Restaurar inventario por cada renglón
    OPEN cur_det;
    loop_det: LOOP
        FETCH cur_det INTO v_id_prod, v_cantidad;
        IF v_done THEN LEAVE loop_det; END IF;

        UPDATE inventario_pt
        SET    stock_actual = stock_actual + v_cantidad
        WHERE  id_producto  = v_id_prod;
    END LOOP;
    CLOSE cur_det;

    -- Marcar venta cancelada
    UPDATE ventas
    SET    estado = 'cancelada'
    WHERE  id_venta = p_id_venta;

    -- Log
    INSERT INTO logs_sistema (tipo, nivel, id_usuario, modulo, accion, descripcion, creado_en)
    VALUES ('venta', 'WARNING', p_cancelado_por, 'ventas', 'cancelar_venta',
            CONCAT('Venta cancelada: ', v_folio), NOW());

    COMMIT;
END;;
DELIMITER ;


-- ── 2.4  sp_lista_ventas ─────────────────────────────────────
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
    -- RS1: registros paginados con total_filas como ventana
    SELECT
        v.id_venta,
        v.folio_venta,
        v.fecha_venta,
        v.total,
        v.metodo_pago,
        v.cambio,
        v.estado,
        v.requiere_ticket,
        u.nombre_completo                      AS vendedor_nombre,
        COUNT(dv.id_detalle_venta)             AS num_productos,
        COUNT(*) OVER ()                       AS total_filas
    FROM   ventas         v
    JOIN   usuarios       u  ON u.id_usuario = v.vendedor_id
    LEFT JOIN detalle_ventas dv ON dv.id_venta = v.id_venta
    WHERE  (p_fecha_inicio IS NULL OR DATE(v.fecha_venta) >= p_fecha_inicio)
      AND  (p_fecha_fin    IS NULL OR DATE(v.fecha_venta) <= p_fecha_fin)
      AND  (p_metodo_pago  IS NULL OR p_metodo_pago = '' OR v.metodo_pago = p_metodo_pago)
      AND  (p_estado       IS NULL OR p_estado      = '' OR v.estado      = p_estado)
      AND  (p_vendedor_id  IS NULL OR p_vendedor_id = 0  OR v.vendedor_id = p_vendedor_id)
    GROUP  BY v.id_venta, v.folio_venta, v.fecha_venta, v.total,
              v.metodo_pago, v.cambio, v.estado, v.requiere_ticket, u.nombre_completo
    ORDER  BY v.fecha_venta DESC
    LIMIT  p_limit OFFSET p_offset;

    -- RS2: estadísticas del día (siempre, independiente de filtros)
    SELECT
        COALESCE(SUM(CASE WHEN DATE(fecha_venta) = CURDATE() AND estado = 'completada'
                          THEN total ELSE 0 END), 0)                               AS total_hoy,
        COUNT(CASE WHEN DATE(fecha_venta) = CURDATE() AND estado = 'completada'
                   THEN 1 END)                                                     AS ventas_hoy,
        COALESCE(SUM(CASE WHEN YEARWEEK(fecha_venta,1) = YEARWEEK(CURDATE(),1)
                               AND estado = 'completada'
                          THEN total ELSE 0 END), 0)                               AS total_semana,
        COALESCE(SUM(CASE WHEN DATE(fecha_venta) = CURDATE() AND estado = 'completada'
                               AND metodo_pago = 'efectivo'
                          THEN total ELSE 0 END), 0)                               AS efectivo_hoy,
        COALESCE(SUM(CASE WHEN DATE(fecha_venta) = CURDATE() AND estado = 'completada'
                               AND metodo_pago = 'tarjeta'
                          THEN total ELSE 0 END), 0)                               AS tarjeta_hoy
    FROM ventas;
END;;
DELIMITER ;


-- ── 2.5  sp_detalle_venta ────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_detalle_venta;
DELIMITER ;;
CREATE PROCEDURE sp_detalle_venta(
    IN p_folio VARCHAR(20)
)
BEGIN
    -- RS1: cabecera de la venta
    SELECT  v.id_venta,
            v.folio_venta,
            v.fecha_venta,
            v.total,
            v.metodo_pago,
            v.cambio,
            v.requiere_ticket,
            v.estado,
            u.nombre_completo AS vendedor_nombre
    FROM    ventas   v
    JOIN    usuarios u ON u.id_usuario = v.vendedor_id
    WHERE   v.folio_venta = p_folio
    LIMIT   1;

    -- RS2: renglones de detalle
    SELECT  dv.id_detalle_venta,
            p.nombre             AS producto_nombre,
            p.descripcion        AS producto_descripcion,
            dv.cantidad,
            dv.precio_unitario,
            dv.descuento_pct,
            dv.subtotal
    FROM    detalle_ventas dv
    JOIN    productos      p  ON p.id_producto  = dv.id_producto
    JOIN    ventas         v  ON v.id_venta     = dv.id_venta
    WHERE   v.folio_venta = p_folio
    ORDER   BY dv.id_detalle_venta;

    -- RS3: ticket (si existe)
    SELECT  t.id_ticket,
            t.contenido_json,
            t.impreso,
            t.generado_en
    FROM    tickets t
    JOIN    ventas  v ON v.id_venta = t.id_venta
    WHERE   v.folio_venta = p_folio
    LIMIT   1;
END;;
DELIMITER ;


-- ─────────────────────────────────────────────────────────────
--  3. TRIGGERS
-- ─────────────────────────────────────────────────────────────

-- ── 3.1  Evitar stock negativo (integridad, red-de-seguridad) ─
DROP TRIGGER IF EXISTS trg_inventario_no_negativo;
DELIMITER ;;
CREATE TRIGGER trg_inventario_no_negativo
BEFORE UPDATE ON inventario_pt
FOR EACH ROW
BEGIN
    IF NEW.stock_actual < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede llevar el stock a un valor negativo.';
    END IF;
END;;
DELIMITER ;


-- ── 3.2  Alerta de stock bajo (log automático) ───────────────
DROP TRIGGER IF EXISTS trg_inventario_stock_bajo;
DELIMITER ;;
CREATE TRIGGER trg_inventario_stock_bajo
AFTER UPDATE ON inventario_pt
FOR EACH ROW
BEGIN
    -- Solo dispara cuando el stock acaba de bajar del mínimo
    IF NEW.stock_actual <= NEW.stock_minimo AND OLD.stock_actual > OLD.stock_minimo THEN
        INSERT INTO logs_sistema
            (tipo, nivel, modulo, accion, descripcion, creado_en)
        VALUES
            ('ajuste_inv', 'WARNING', 'inventario', 'stock_bajo',
             CONCAT('Stock bajo para producto ID ', NEW.id_producto,
                    '. Stock actual: ', NEW.stock_actual,
                    ' / Mínimo: ', NEW.stock_minimo),
             NOW());
    END IF;
END;;
DELIMITER ;


-- ── 3.3  Audit log automático al completar una venta ─────────
DROP TRIGGER IF EXISTS trg_venta_completada_log;
DELIMITER ;;
CREATE TRIGGER trg_venta_completada_log
AFTER UPDATE ON ventas
FOR EACH ROW
BEGIN
    -- Dispara solo cuando el estado cambia A 'completada'
    IF NEW.estado = 'completada' AND OLD.estado != 'completada' THEN
        INSERT INTO logs_sistema
            (tipo, nivel, id_usuario, modulo, accion, descripcion, creado_en)
        VALUES
            ('venta', 'INFO', NEW.vendedor_id, 'ventas', 'venta_completada',
             CONCAT('Venta completada: ', NEW.folio_venta,
                    ' | Total: $', NEW.total,
                    ' | Método: ', NEW.metodo_pago),
             NOW());
    END IF;
END;;
DELIMITER ;
