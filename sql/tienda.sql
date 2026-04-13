ALTER TABLE logs_sistema
  MODIFY COLUMN tipo
    ENUM(
      'error','acceso','cambio_usuario','venta','compra','produccion',
      'ajuste_inv','solicitud','salida_efectivo','seguridad','pedido'
    )
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
    NOT NULL;

DROP TRIGGER IF EXISTS trg_pedido_entregado_venta;

DELIMITER ;;
CREATE TRIGGER `trg_pedido_entregado_venta`
AFTER UPDATE ON `pedidos`
FOR EACH ROW
BEGIN
    DECLARE v_folio_venta VARCHAR(30);
    DECLARE v_total       DECIMAL(10,2);
    DECLARE v_id_venta    INT;
    DECLARE v_next_seq    INT;
    DECLARE v_metodo      VARCHAR(20);

    IF NEW.estado = 'entregado' AND OLD.estado != 'entregado' THEN

        IF NOT EXISTS (
            SELECT 1 FROM logs_sistema
             WHERE referencia_id   = NEW.id_pedido
               AND referencia_tipo = 'pedido'
               AND accion          = 'venta_automatica'
        ) THEN

            -- Total del pedido
            SELECT COALESCE(SUM(subtotal), 0)
              INTO v_total
              FROM detalle_pedidos
             WHERE id_pedido = NEW.id_pedido;

            -- Método de pago
            SET v_metodo = COALESCE(NEW.metodo_pago, 'efectivo');

            -- Siguiente folio del día
            SELECT COUNT(*) + 1
              INTO v_next_seq
              FROM ventas
             WHERE DATE(fecha_venta) = CURDATE();

            SET v_folio_venta = CONCAT('VTA-', DATE_FORMAT(NOW(),'%Y%m%d'),
                                       '-', LPAD(v_next_seq, 3, '0'));

            -- Cabecera de venta
            INSERT INTO ventas (
                folio_venta, fecha_venta, total, metodo_pago, cambio,
                requiere_ticket, estado, vendedor_id, creado_en
            ) VALUES (
                v_folio_venta, NOW(), v_total, v_metodo, 0,
                1, 'completada', NEW.atendido_por, NOW()
            );

            SET v_id_venta = LAST_INSERT_ID();

            -- Detalle de venta
            INSERT INTO detalle_ventas (
                id_venta, id_producto, cantidad,
                precio_unitario, descuento_pct, subtotal
            )
            SELECT v_id_venta, id_producto, cantidad,
                   precio_unitario, 0, subtotal
              FROM detalle_pedidos
             WHERE id_pedido = NEW.id_pedido;

            -- Log de venta automática
            INSERT INTO logs_sistema (
                tipo, nivel, id_usuario, modulo, accion,
                descripcion, referencia_id, referencia_tipo, creado_en
            ) VALUES (
                'venta', 'INFO', NEW.atendido_por, 'ventas', 'venta_automatica',
                CONCAT('Venta automática desde pedido ', NEW.folio,
                       ' | Folio venta: ', v_folio_venta),
                NEW.id_pedido, 'pedido', NOW()
            );

        END IF;
    END IF;
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `sp_catalogo_tienda`;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_catalogo_tienda`()
BEGIN
  SELECT
    p.id_producto,
    p.uuid_producto,
    p.nombre,
    p.descripcion,
    p.precio_venta,
    COALESCE(i.stock_actual, 0)   AS stock_actual,
    COALESCE(i.stock_minimo, 0)   AS stock_minimo,
    CASE
      WHEN COALESCE(i.stock_actual, 0) = 0                         THEN 'agotado'
      WHEN COALESCE(i.stock_actual, 0) <= COALESCE(i.stock_minimo * 0.25, 3) THEN 'critico'
      WHEN COALESCE(i.stock_actual, 0) < COALESCE(i.stock_minimo, 0)         THEN 'bajo'
      ELSE 'ok'
    END                           AS nivel_stock,
    p.imagen_url
  FROM productos p
  LEFT JOIN inventario_pt i ON i.id_producto = p.id_producto
  WHERE p.estatus = 'activo'
  ORDER BY
    CASE WHEN COALESCE(i.stock_actual, 0) = 0 THEN 1 ELSE 0 END,
    p.nombre;
END ;;
DELIMITER ;

-- ── 0. Migrar registros con estados obsoletos ────────────────
UPDATE pedidos SET estado = 'aprobado' WHERE estado IN ('en_produccion','pendiente_insumos');

-- ── 1. Modificar ENUM de estado ──────────────────────────────
ALTER TABLE `pedidos`
  MODIFY COLUMN `estado`
    ENUM('pendiente','aprobado','listo','entregado','rechazado')
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
    NOT NULL DEFAULT 'pendiente';

-- ── 2. Agregar columna metodo_pago ───────────────────────────
ALTER TABLE `pedidos`
  ADD COLUMN `metodo_pago`
    ENUM('efectivo','tarjeta','transferencia')
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
    NOT NULL DEFAULT 'efectivo'
    AFTER `notas_cliente`;

-- ── 3. Índice para consultas por método de pago ─────────────
ALTER TABLE `pedidos`
  ADD KEY `idx_pedidos_metodo_pago` (`metodo_pago`);

-- ── 4. Trigger: auditar cambio de metodo_pago ───────────────
DROP TRIGGER IF EXISTS `trg_pedido_metodo_pago_auditoria`;
DELIMITER ;;
CREATE TRIGGER `trg_pedido_metodo_pago_auditoria`
AFTER UPDATE ON `pedidos`
FOR EACH ROW
BEGIN
  IF OLD.metodo_pago <> NEW.metodo_pago THEN
    INSERT INTO logs_sistema
      (tipo, nivel, id_usuario, modulo, accion, descripcion,
       referencia_id, referencia_tipo, creado_en)
    VALUES
      ('pedido', 'INFO', NEW.atendido_por, 'Pedidos', 'cambio_metodo_pago',
       CONCAT('Pedido ', NEW.folio, ': método de pago cambió de ',
              OLD.metodo_pago, ' a ', NEW.metodo_pago),
       NEW.id_pedido, 'pedidos', NOW());
  END IF;
END;;
DELIMITER ;

-- ============================================================
--  SP: sp_pedido_express  (ahora guarda metodo_pago)
-- ============================================================
DROP PROCEDURE IF EXISTS `sp_pedido_express`;
DELIMITER ;;
CREATE PROCEDURE `sp_pedido_express`(
    IN  p_id_cliente     INT,
    IN  p_hora_recogida  TIME,
    IN  p_metodo_pago    VARCHAR(20),
    IN  p_notas          TEXT,
    IN  p_productos_json JSON,
    OUT p_id_pedido      INT,
    OUT p_folio          VARCHAR(15),
    OUT p_error          VARCHAR(255)
)
BEGIN
    DECLARE v_total     DECIMAL(10,2) DEFAULT 0;
    DECLARE v_i         INT DEFAULT 0;
    DECLARE v_n         INT;
    DECLARE v_id_prod   INT;
    DECLARE v_qty       DECIMAL(10,2);
    DECLARE v_precio    DECIMAL(10,2);
    DECLARE v_sub       DECIMAL(12,2);
    DECLARE v_stock     DECIMAL(12,2);
    DECLARE v_nombre    VARCHAR(120);
    DECLARE v_uuid      VARCHAR(36);
    DECLARE v_fecha_rec DATETIME;
    DECLARE v_msg       VARCHAR(255);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
        SET p_id_pedido = NULL;
        SET p_folio     = NULL;
    END;

    SET p_error = NULL;

    -- Validar cliente activo
    IF NOT EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.id_usuario = p_id_cliente
          AND CONVERT(u.estatus USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = 'activo'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El cliente no existe o no está activo.';
    END IF;

    -- Validar método de pago
    IF p_metodo_pago NOT IN ('efectivo','tarjeta','transferencia') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Método de pago inválido.';
    END IF;

    -- Validar JSON
    SET v_n = JSON_LENGTH(p_productos_json);
    IF v_n IS NULL OR v_n = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El pedido debe tener al menos un producto.';
    END IF;

    -- Validar horario
    IF p_hora_recogida < '09:00:00' OR p_hora_recogida > '21:00:00' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La hora de recogida debe estar entre 9:00 y 21:00.';
    END IF;

    SET v_fecha_rec = TIMESTAMP(DATE(NOW()), p_hora_recogida);

    -- Validar stock y calcular total
    WHILE v_i < v_n DO
        SET v_id_prod = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].id')));
        SET v_qty     = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].qty')));
        SET v_precio  = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].precio')));

        SET v_nombre = NULL;
        SELECT nombre INTO v_nombre
          FROM productos
         WHERE id_producto = v_id_prod
           AND CONVERT(estatus USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = 'activo'
         LIMIT 1;

        IF v_nombre IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Uno o más productos no están disponibles.';
        END IF;

        SET v_stock = 0;
        SELECT COALESCE(stock_actual, 0) INTO v_stock
          FROM inventario_pt
         WHERE id_producto = v_id_prod
         LIMIT 1;

        IF v_stock < v_qty THEN
            SET v_msg = CONCAT('Stock insuficiente para "', v_nombre,
                               '". Disponible: ', FLOOR(v_stock), ' pzas.');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
        END IF;

        SET v_total = v_total + (v_qty * v_precio);
        SET v_i     = v_i + 1;
    END WHILE;

    START TRANSACTION;

        CALL sp_siguiente_folio_pedido(p_folio);
        SET v_uuid = UUID();

        INSERT INTO pedidos (
            uuid_pedido, folio, id_cliente, tipo, estado,
            fecha_recogida, metodo_pago, notas_cliente, total_estimado,
            creado_en, actualizado_en
        ) VALUES (
            v_uuid, p_folio, p_id_cliente, 'simple', 'pendiente',
            v_fecha_rec, p_metodo_pago, p_notas, ROUND(v_total, 2),
            NOW(), NOW()
        );

        SET p_id_pedido = LAST_INSERT_ID();

        SET v_i = 0;
        WHILE v_i < v_n DO
            SET v_id_prod = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].id')));
            SET v_qty     = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].qty')));
            SET v_precio  = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].precio')));
            SET v_sub     = ROUND(v_qty * v_precio, 2);

            INSERT INTO detalle_pedidos
                (id_pedido, id_producto, cantidad, precio_unitario, subtotal)
            VALUES
                (p_id_pedido, v_id_prod, v_qty, v_precio, v_sub);

            SET v_i = v_i + 1;
        END WHILE;

        INSERT INTO historial_pedidos
            (id_pedido, estado_antes, estado_despues, nota, realizado_por, creado_en)
        VALUES
            (p_id_pedido, 'nuevo', 'pendiente',
             CONCAT('Pedido express. Pago: ', p_metodo_pago), p_id_cliente, NOW());

    COMMIT;
END;;
DELIMITER ;

-- ============================================================
--  SP: sp_aprobar_pedido  (descuenta stock al aprobar)
-- ============================================================
DROP PROCEDURE IF EXISTS `sp_aprobar_pedido`;
DELIMITER ;;
CREATE PROCEDURE `sp_aprobar_pedido`(
  IN  p_folio  VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN  p_user   INT,
  IN  p_nota   TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  OUT p_ok     TINYINT(1),
  OUT p_error  VARCHAR(300)
)
sp_main: BEGIN
  DECLARE v_id_pedido  INT;
  DECLARE v_estado     VARCHAR(30);
  DECLARE v_id_cliente INT;
  DECLARE v_id_prod    INT;
  DECLARE v_qty        DECIMAL(10,2);
  DECLARE v_stock      DECIMAL(12,2);
  DECLARE v_nombre     VARCHAR(120);
  DECLARE v_msg        VARCHAR(255);
  DECLARE done         INT DEFAULT 0;

  -- Cursor sobre el detalle del pedido
  DECLARE cur_detalle CURSOR FOR
    SELECT dp.id_producto, dp.cantidad, p.nombre, COALESCE(i.stock_actual,0)
      FROM detalle_pedidos dp
      JOIN productos p ON p.id_producto = dp.id_producto
      LEFT JOIN inventario_pt i ON i.id_producto = dp.id_producto
     WHERE dp.id_pedido = v_id_pedido;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
  END;

  SET p_ok = 0; SET p_error = NULL;

  SELECT id_pedido, estado, id_cliente
    INTO v_id_pedido, v_estado, v_id_cliente
    FROM pedidos WHERE folio = p_folio LIMIT 1;

  IF v_id_pedido IS NULL THEN
    SET p_error = CONCAT('Pedido ', p_folio, ' no encontrado.');
    LEAVE sp_main;
  END IF;

  IF v_estado != 'pendiente' THEN
    SET p_error = CONCAT('Solo se pueden aprobar pedidos pendientes. Estado: ', v_estado);
    LEAVE sp_main;
  END IF;

  START TRANSACTION;

    -- Verificar y descontar stock producto a producto
    OPEN cur_detalle;
    leer: LOOP
      FETCH cur_detalle INTO v_id_prod, v_qty, v_nombre, v_stock;
      IF done THEN LEAVE leer; END IF;

      IF v_stock < v_qty THEN
        SET v_msg = CONCAT('Stock insuficiente para "', v_nombre,
                           '". Disponible: ', FLOOR(v_stock), ' pzas.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
      END IF;

      UPDATE inventario_pt
         SET stock_actual = stock_actual - v_qty,
             ultima_actualizacion = NOW()
       WHERE id_producto = v_id_prod;
    END LOOP;
    CLOSE cur_detalle;

    UPDATE pedidos
       SET estado = 'aprobado', atendido_por = p_user, actualizado_en = NOW()
     WHERE id_pedido = v_id_pedido;

    INSERT INTO historial_pedidos
      (id_pedido, estado_antes, estado_despues, nota, realizado_por, creado_en)
    VALUES
      (v_id_pedido, 'pendiente', 'aprobado', COALESCE(p_nota,'Pedido aprobado.'), p_user, NOW());

    INSERT INTO notificaciones_pedidos
      (id_pedido, id_usuario, folio, tipo, mensaje, leida, creado_en)
    VALUES
      (v_id_pedido, v_id_cliente, p_folio, 'aprobado',
       CONCAT('✅ Tu pedido ', p_folio, ' fue aprobado y está siendo preparado.'),
       0, NOW());

  COMMIT;
  SET p_ok = 1;
END;;
DELIMITER ;

-- ============================================================
--  SP: sp_marcar_listo_pedido  (aprobado → listo, notifica)
-- ============================================================
DROP PROCEDURE IF EXISTS `sp_marcar_listo_pedido`;
DELIMITER ;;
CREATE PROCEDURE `sp_marcar_listo_pedido`(
  IN  p_folio VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN  p_user  INT,
  OUT p_ok    TINYINT(1),
  OUT p_error VARCHAR(300)
)
sp_main: BEGIN
  DECLARE v_id_pedido  INT;
  DECLARE v_estado     VARCHAR(30);
  DECLARE v_id_cliente INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
  END;

  SET p_ok = 0; SET p_error = NULL;

  SELECT id_pedido, estado, id_cliente
    INTO v_id_pedido, v_estado, v_id_cliente
    FROM pedidos WHERE folio = p_folio LIMIT 1;

  IF v_id_pedido IS NULL THEN
    SET p_error = CONCAT('Pedido ', p_folio, ' no encontrado.');
    LEAVE sp_main;
  END IF;

  IF v_estado != 'aprobado' THEN
    SET p_error = CONCAT('Solo se pueden marcar como listos los pedidos aprobados. Estado: ', v_estado);
    LEAVE sp_main;
  END IF;

  START TRANSACTION;

    UPDATE pedidos
       SET estado = 'listo', actualizado_en = NOW()
     WHERE id_pedido = v_id_pedido;

    INSERT INTO historial_pedidos
      (id_pedido, estado_antes, estado_despues, nota, realizado_por, creado_en)
    VALUES
      (v_id_pedido, 'aprobado', 'listo', 'Pedido listo para recoger.', p_user, NOW());

    INSERT INTO notificaciones_pedidos
      (id_pedido, id_usuario, folio, tipo, mensaje, leida, creado_en)
    VALUES
      (v_id_pedido, v_id_cliente, p_folio, 'listo',
       CONCAT('🎉 ¡Tu pedido ', p_folio, ' está listo! Pasa a recogerlo.'),
       0, NOW());

    INSERT INTO logs_sistema
      (tipo, nivel, id_usuario, modulo, accion, descripcion,
       referencia_id, referencia_tipo, creado_en)
    VALUES
      ('pedido', 'INFO', p_user, 'Pedidos', 'marcar_listo',
       CONCAT('Pedido ', p_folio, ' marcado como listo.'),
       v_id_pedido, 'pedidos', NOW());

  COMMIT;
  SET p_ok = 1;
END;;
DELIMITER ;

-- ============================================================
--  SP: sp_marcar_entregado_pedido  (listo → entregado)
-- ============================================================
DROP PROCEDURE IF EXISTS `sp_marcar_entregado_pedido`;
DELIMITER ;;
CREATE PROCEDURE `sp_marcar_entregado_pedido`(
  IN  p_folio VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN  p_user  INT,
  OUT p_ok    TINYINT(1),
  OUT p_error VARCHAR(300)
)
sp_main: BEGIN
  DECLARE v_id_pedido  INT;
  DECLARE v_estado     VARCHAR(30);
  DECLARE v_id_cliente INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
  END;

  SET p_ok = 0; SET p_error = NULL;

  SELECT id_pedido, estado, id_cliente
    INTO v_id_pedido, v_estado, v_id_cliente
    FROM pedidos WHERE folio = p_folio LIMIT 1;

  IF v_id_pedido IS NULL THEN
    SET p_error = CONCAT('Pedido ', p_folio, ' no encontrado.');
    LEAVE sp_main;
  END IF;

  IF v_estado != 'listo' THEN
    SET p_error = CONCAT('Solo se pueden entregar pedidos listos. Estado: ', v_estado);
    LEAVE sp_main;
  END IF;

  START TRANSACTION;

    UPDATE pedidos
       SET estado = 'entregado', actualizado_en = NOW()
     WHERE id_pedido = v_id_pedido;

    INSERT INTO historial_pedidos
      (id_pedido, estado_antes, estado_despues, nota, realizado_por, creado_en)
    VALUES
      (v_id_pedido, 'listo', 'entregado', 'Pedido entregado al cliente.', p_user, NOW());

    INSERT INTO notificaciones_pedidos
      (id_pedido, id_usuario, folio, tipo, mensaje, leida, creado_en)
    VALUES
      (v_id_pedido, v_id_cliente, p_folio, 'entregado',
       CONCAT('📦 Tu pedido ', p_folio, ' ha sido entregado. ¡Gracias!'),
       0, NOW());

  COMMIT;
  SET p_ok = 1;
END;;
DELIMITER ;

-- ============================================================
--  Vista: v_conteo_pedidos_por_estado (sin estados obsoletos)
-- ============================================================
DROP VIEW IF EXISTS `v_conteo_pedidos_por_estado`;
CREATE VIEW `v_conteo_pedidos_por_estado` AS
  SELECT
    CONVERT(estado USING utf8mb4) COLLATE utf8mb4_unicode_ci AS estado,
    COUNT(*) AS total
  FROM pedidos
  WHERE estado IN ('pendiente','aprobado','listo','entregado','rechazado')
  GROUP BY estado;

DROP PROCEDURE IF EXISTS `sp_mis_pedidos_cliente`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_mis_pedidos_cliente`(IN p_cliente INT)
BEGIN
  -- RS1: pedidos del cliente con detalle de productos
  SELECT
    p.id_pedido,
    p.folio,
    p.estado,
    p.fecha_recogida,
    p.total_estimado,
    p.motivo_rechazo,
    p.creado_en,
    p.metodo_pago,
    GROUP_CONCAT(
      CONCAT(pr.nombre, ' ×', CAST(dp.cantidad AS SIGNED))
      ORDER BY dp.id_detalle
      SEPARATOR ', '
    ) COLLATE utf8mb4_unicode_ci AS panes_resumen,
    IFNULL(SUM(dp.cantidad), 0) AS total_piezas
  FROM  pedidos p
  LEFT JOIN detalle_pedidos dp ON dp.id_pedido   = p.id_pedido
  LEFT JOIN productos       pr ON pr.id_producto = dp.id_producto
  WHERE p.id_cliente = p_cliente
  GROUP BY
    p.id_pedido, p.folio, p.estado, p.fecha_recogida,
    p.total_estimado, p.motivo_rechazo, p.creado_en, p.metodo_pago
  ORDER BY p.creado_en DESC;

  -- RS2: notificaciones del cliente
  SELECT id_notif, id_pedido, folio, mensaje, leida, creado_en
  FROM   v_notificaciones_cliente
  WHERE  id_usuario = p_cliente
  LIMIT  50;
END;;
DELIMITER ;