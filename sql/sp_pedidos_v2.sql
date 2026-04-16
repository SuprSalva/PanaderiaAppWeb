-- ═══════════════════════════════════════════════════════════════
--  FEATURE: referencia_pago en pedidos
--  Ejecutar como root@localhost en MySQL Workbench
--  Fecha: 2026-04-16
-- ═══════════════════════════════════════════════════════════════
USE dulce_migaja;

ALTER TABLE pedidos
  ADD COLUMN referencia_pago VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
      DEFAULT NULL
      COMMENT 'Número de referencia para pagos con tarjeta o transferencia'
  AFTER metodo_pago;
 
CREATE INDEX idx_pedidos_referencia_pago ON pedidos(referencia_pago);
 
-- ─────────────────────────────────────────────
--  2. RECREAR sp_pedido_express  (+ p_referencia_pago)
--     Nuevo param IN entre p_productos_json y los OUT
-- ─────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_pedido_express;
DELIMITER ;;
CREATE PROCEDURE sp_pedido_express(
    IN  p_id_cliente       INT,
    IN  p_hora_recogida    TIME,
    IN  p_metodo_pago      VARCHAR(20),
    IN  p_notas            TEXT,
    IN  p_productos_json   JSON,
    IN  p_referencia_pago  VARCHAR(100),
    OUT p_id_pedido        INT,
    OUT p_folio            VARCHAR(15),
    OUT p_error            VARCHAR(255)
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

    -- Validar referencia obligatoria si pago no es efectivo
    IF p_metodo_pago IN ('tarjeta','transferencia')
       AND (p_referencia_pago IS NULL OR TRIM(p_referencia_pago) = '') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La referencia de pago es obligatoria para tarjeta o transferencia.';
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
            fecha_recogida, metodo_pago, referencia_pago,
            notas_cliente, total_estimado,
            creado_en, actualizado_en
        ) VALUES (
            v_uuid, p_folio, p_id_cliente, 'simple', 'pendiente',
            v_fecha_rec, p_metodo_pago,
            IF(p_metodo_pago IN ('tarjeta','transferencia'), TRIM(p_referencia_pago), NULL),
            p_notas, ROUND(v_total, 2),
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
             CONCAT('Pedido express. Pago: ', p_metodo_pago,
                    IF(p_referencia_pago IS NOT NULL AND TRIM(p_referencia_pago) != '',
                       CONCAT(' | Ref: ', TRIM(p_referencia_pago)), '')),
             p_id_cliente, NOW());

    COMMIT;
END ;;
DELIMITER ;


-- ─────────────────────────────────────────────
--  3. RECREAR sp_pedido_futuro  (+ p_referencia_pago)
--     Nuevo param IN entre p_productos_json y los OUT
-- ─────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_pedido_futuro;
DELIMITER ;;
CREATE PROCEDURE sp_pedido_futuro(
    IN  p_id_cliente      INT,
    IN  p_fecha_dt        DATETIME,
    IN  p_metodo_pago     VARCHAR(20),
    IN  p_notas           TEXT,
    IN  p_es_inmediato    TINYINT,
    IN  p_productos_json  JSON,
    IN  p_referencia_pago VARCHAR(100),
    OUT p_id_pedido       INT,
    OUT p_folio           VARCHAR(15),
    OUT p_error           TEXT
)
sp_main: BEGIN
    DECLARE v_next_id     INT;
    DECLARE v_n           INT;
    DECLARE v_i           INT DEFAULT 0;
    DECLARE v_id_prod     INT;
    DECLARE v_qty         DECIMAL(10,2);
    DECLARE v_precio      DECIMAL(10,2);
    DECLARE v_subtotal    DECIMAL(12,2);
    DECLARE v_total       DECIMAL(12,2) DEFAULT 0;
    DECLARE v_uuid        VARCHAR(36);
    DECLARE v_notas_full  TEXT;
    DECLARE v_tipo        VARCHAR(30);

    SET p_id_pedido = NULL;
    SET p_folio     = NULL;
    SET p_error     = NULL;

    IF NOT EXISTS (
        SELECT 1 FROM usuarios WHERE id_usuario = p_id_cliente AND estatus = 'activo'
    ) THEN
        SET p_error = 'Cliente no encontrado o inactivo.';
        LEAVE sp_main;
    END IF;

    -- Validar referencia obligatoria si pago no es efectivo
    IF p_metodo_pago IN ('tarjeta','transferencia')
       AND (p_referencia_pago IS NULL OR TRIM(p_referencia_pago) = '') THEN
        SET p_error = 'La referencia de pago es obligatoria para tarjeta o transferencia.';
        LEAVE sp_main;
    END IF;

    IF p_es_inmediato = 0 AND p_fecha_dt < DATE_ADD(NOW(), INTERVAL 24 HOUR) THEN
        SET p_error = 'La fecha de entrega debe ser al menos 24 horas desde ahora.';
        LEAVE sp_main;
    END IF;

    IF p_es_inmediato = 1 AND p_fecha_dt < NOW() THEN
        SET p_error = 'La hora de recogida no puede ser en el pasado.';
        LEAVE sp_main;
    END IF;

    SET v_n = JSON_LENGTH(p_productos_json);
    IF v_n IS NULL OR v_n = 0 THEN
        SET p_error = 'Debes agregar al menos un producto.';
        LEAVE sp_main;
    END IF;

    WHILE v_i < v_n DO
        SET v_id_prod = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].id'))) AS UNSIGNED);
        SET v_qty     = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].qty'))) AS DECIMAL(10,2));
        SET v_precio  = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].precio'))) AS DECIMAL(10,2));

        IF v_qty <= 0 THEN
            SET p_error = CONCAT('Cantidad inválida para producto #', v_id_prod, '.'); LEAVE sp_main;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = v_id_prod AND estatus = 'activo') THEN
            SET p_error = CONCAT('Producto #', v_id_prod, ' no encontrado.'); LEAVE sp_main;
        END IF;
        SET v_total = v_total + (v_qty * v_precio);
        SET v_i = v_i + 1;
    END WHILE;

    -- Folio único
    SELECT IFNULL(MAX(id_pedido), 0) + 1 INTO v_next_id FROM pedidos;
    SET p_folio = CONCAT('PED-', LPAD(v_next_id, 4, '0'));
    WHILE EXISTS (SELECT 1 FROM pedidos WHERE folio = p_folio) DO
        SET v_next_id = v_next_id + 1;
        SET p_folio   = CONCAT('PED-', LPAD(v_next_id, 4, '0'));
    END WHILE;

    SET v_uuid = UUID();
    SET v_tipo = IF(p_es_inmediato = 1, 'Compra inmediata', 'Pedido programado');
    SET v_notas_full = CONCAT(
        '[', v_tipo, '. Pago: ', IFNULL(p_metodo_pago, 'efectivo'),
        IF(p_referencia_pago IS NOT NULL AND TRIM(p_referencia_pago) != '',
           CONCAT(' | Ref: ', TRIM(p_referencia_pago)), ''),
        ']',
        IF(p_notas IS NOT NULL AND TRIM(p_notas) != '', CONCAT(' ', TRIM(p_notas)), '')
    );

    INSERT INTO pedidos (
        uuid_pedido, folio, id_cliente, id_tamanio, tipo,
        estado, fecha_recogida, notas_cliente, metodo_pago,
        referencia_pago, total_estimado, creado_en, actualizado_en
    ) VALUES (
        v_uuid, p_folio, p_id_cliente, NULL, 'mixta',
        'pendiente', p_fecha_dt, v_notas_full,
        IFNULL(p_metodo_pago, 'efectivo'),
        IF(p_metodo_pago IN ('tarjeta','transferencia'), TRIM(p_referencia_pago), NULL),
        v_total, NOW(), NOW()
    );
    SET p_id_pedido = LAST_INSERT_ID();

    SET v_i = 0;
    WHILE v_i < v_n DO
        SET v_id_prod = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].id'))) AS UNSIGNED);
        SET v_qty     = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].qty'))) AS DECIMAL(10,2));
        SET v_precio  = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].precio'))) AS DECIMAL(10,2));
        SET v_subtotal = v_qty * v_precio;
        INSERT INTO detalle_pedidos (id_pedido, id_producto, cantidad, precio_unitario, subtotal)
        VALUES (p_id_pedido, v_id_prod, v_qty, v_precio, v_subtotal);
        SET v_i = v_i + 1;
    END WHILE;

    INSERT INTO historial_pedidos
        (id_pedido, estado_antes, estado_despues, nota, realizado_por, creado_en)
    VALUES (
        p_id_pedido, 'nuevo', 'pendiente',
        CONCAT(v_tipo, ': ', v_n, ' producto(s). Total: $', ROUND(v_total,2),
               '. Recogida: ', DATE_FORMAT(p_fecha_dt, '%d/%m/%Y %H:%i'),
               IF(p_referencia_pago IS NOT NULL AND TRIM(p_referencia_pago) != '',
                  CONCAT('. Ref pago: ', TRIM(p_referencia_pago)), '')),
        p_id_cliente, NOW()
    );

    INSERT INTO logs_sistema
        (tipo, nivel, id_usuario, modulo, accion, descripcion,
         referencia_id, referencia_tipo, creado_en)
    VALUES (
        'venta', 'INFO', p_id_cliente, 'tienda', 'crear_pedido',
        CONCAT(p_folio, ' (', v_tipo, ') | $', ROUND(v_total,2)),
        p_id_pedido, 'pedido', NOW()
    );

    SET p_error = NULL;
END ;;
DELIMITER ;


-- ─────────────────────────────────────────────
--  4. RECREAR sp_mis_pedidos_cliente (+ referencia_pago en RS1)
-- ─────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_mis_pedidos_cliente;
DELIMITER ;;
CREATE PROCEDURE sp_mis_pedidos_cliente(IN p_cliente INT)
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
    IFNULL(SUM(dp.cantidad), 0) AS total_piezas,
    p.referencia_pago
  FROM  pedidos p
  LEFT JOIN detalle_pedidos dp ON dp.id_pedido   = p.id_pedido
  LEFT JOIN productos       pr ON pr.id_producto = dp.id_producto
  WHERE p.id_cliente = p_cliente
  GROUP BY
    p.id_pedido, p.folio, p.estado, p.fecha_recogida,
    p.total_estimado, p.motivo_rechazo, p.creado_en,
    p.metodo_pago, p.referencia_pago
  ORDER BY p.creado_en DESC;

  -- RS2: notificaciones del cliente
  SELECT id_notif, id_pedido, folio, mensaje, leida, creado_en
  FROM   v_notificaciones_cliente
  WHERE  id_usuario = p_cliente
  LIMIT  50;
END ;;
DELIMITER ;


-- ─────────────────────────────────────────────
--  5. ACTUALIZAR vista v_pedidos_resumen (+ metodo_pago + referencia_pago)
-- ─────────────────────────────────────────────
DROP VIEW IF EXISTS v_pedidos_resumen;
CREATE VIEW v_pedidos_resumen AS
SELECT
    p.id_pedido,  p.folio,  p.estado,  p.fecha_recogida,
    p.total_estimado,  p.motivo_rechazo,  p.creado_en,
    p.actualizado_en,  p.id_cliente,  p.tipo AS tipo_caja,
    (t.nombre COLLATE utf8mb4_unicode_ci) AS tamanio_nombre,
    t.capacidad,
    u.id_usuario,  u.nombre_completo AS cliente_nombre,
    u.username AS cliente_username,
    COUNT(dp.id_detalle) AS num_productos,
    IFNULL(SUM(dp.cantidad), 0) AS total_piezas,
    a.nombre_completo AS atendido_por_nombre,
    p.metodo_pago,
    p.referencia_pago
FROM pedidos p
JOIN usuarios u ON u.id_usuario = p.id_cliente
LEFT JOIN tamanios_charola t ON t.id_tamanio = p.id_tamanio
LEFT JOIN detalle_pedidos dp ON dp.id_pedido = p.id_pedido
LEFT JOIN usuarios a ON a.id_usuario = p.atendido_por
GROUP BY
    p.id_pedido, p.folio, p.estado, p.fecha_recogida,
    p.total_estimado, p.motivo_rechazo, p.creado_en,
    p.actualizado_en, p.id_cliente, p.tipo,
    t.nombre, t.capacidad, u.id_usuario, u.nombre_completo,
    u.username, a.nombre_completo, p.metodo_pago, p.referencia_pago;

DROP PROCEDURE IF EXISTS sp_marcar_entregado_pedido;
DELIMITER ;;
CREATE PROCEDURE sp_marcar_entregado_pedido(
  IN  p_folio           VARCHAR(20)  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN  p_user            INT,
  IN  p_referencia_pago VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  OUT p_ok              TINYINT(1),
  OUT p_error           VARCHAR(300)
)
sp_main: BEGIN
  DECLARE v_id_pedido   INT;
  DECLARE v_estado      VARCHAR(30);
  DECLARE v_id_cliente  INT;
  DECLARE v_metodo_pago VARCHAR(20);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
  END;

  SET p_ok = 0; SET p_error = NULL;

  SELECT id_pedido, estado, id_cliente, metodo_pago
    INTO v_id_pedido, v_estado, v_id_cliente, v_metodo_pago
    FROM pedidos WHERE folio = p_folio LIMIT 1;

  IF v_id_pedido IS NULL THEN
    SET p_error = CONCAT('Pedido ', p_folio, ' no encontrado.');
    LEAVE sp_main;
  END IF;

  IF v_estado != 'listo' THEN
    SET p_error = CONCAT('Solo se pueden entregar pedidos listos. Estado: ', v_estado);
    LEAVE sp_main;
  END IF;

  IF v_metodo_pago IN ('tarjeta','transferencia')
     AND (p_referencia_pago IS NULL OR TRIM(p_referencia_pago) = '') THEN
    SET p_error = 'La referencia de pago es obligatoria para tarjeta o transferencia.';
    LEAVE sp_main;
  END IF;

  START TRANSACTION;

    UPDATE pedidos
       SET estado          = 'entregado',
           referencia_pago = IF(v_metodo_pago IN ('tarjeta','transferencia'),
                                TRIM(p_referencia_pago), NULL),
           atendido_por    = p_user,
           actualizado_en  = NOW()
     WHERE id_pedido = v_id_pedido;

    INSERT INTO historial_pedidos
      (id_pedido, estado_antes, estado_despues, nota, realizado_por, creado_en)
    VALUES
      (v_id_pedido, 'listo', 'entregado',
       CONCAT('Pedido entregado al cliente.',
              IF(v_metodo_pago IN ('tarjeta','transferencia') AND TRIM(p_referencia_pago) != '',
                 CONCAT(' Ref. pago: ', TRIM(p_referencia_pago)), '')),
       p_user, NOW());

    INSERT INTO notificaciones_pedidos
      (id_pedido, id_usuario, folio, tipo, mensaje, leida, creado_en)
    VALUES
      (v_id_pedido, v_id_cliente, p_folio, 'entregado',
       CONCAT('📦 Tu pedido ', p_folio, ' ha sido entregado. ¡Gracias!'),
       0, NOW());

  COMMIT;
  SET p_ok = 1;
END ;;
DELIMITER ;

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_marcar_entregado_pedido TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_marcar_entregado_pedido TO rol_empleado;
FLUSH PRIVILEGES;


-- ─────────────────────────────────────────────
--  6. RECREAR sp_detalle_pedido (+ metodo_pago + referencia_pago en RS1)
-- ─────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_detalle_pedido;
DELIMITER ;;
CREATE PROCEDURE sp_detalle_pedido(
  IN p_folio VARCHAR(20) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
)
BEGIN
  -- RS1: cabecera del pedido (ahora incluye metodo_pago y referencia_pago)
  SELECT v.id_pedido, v.folio, v.estado, v.fecha_recogida,
         v.total_estimado, v.motivo_rechazo, v.creado_en,
         v.id_cliente, v.cliente_nombre,
         u.telefono,
         v.atendido_por_nombre,
         v.tipo_caja, v.tamanio_nombre, v.capacidad,
         v.metodo_pago, v.referencia_pago
  FROM v_pedidos_resumen v
  JOIN usuarios u ON u.id_usuario = v.id_cliente
  WHERE v.folio = p_folio
  LIMIT 1;

  -- RS2: info de la caja
  SELECT vc.tipo, vc.tamanio, vc.nombre_caja, vc.capacidad, vc.precio_venta
  FROM   v_caja_pedido vc
  JOIN   pedidos       p  ON p.id_pedido = vc.id_pedido
  WHERE  p.folio = p_folio
  LIMIT  1;

  -- RS3: líneas de productos
  SELECT vd.producto_nombre, vd.producto_descripcion,
         vd.cantidad, vd.precio_unitario, vd.subtotal
  FROM   v_detalle_pedido vd
  JOIN   pedidos          p ON p.id_pedido = vd.id_pedido
  WHERE  p.folio = p_folio
  ORDER  BY vd.producto_nombre;

  -- RS4: historial
  SELECT vh.estado_antes, vh.estado_despues, vh.nota,
         vh.creado_en, vh.usuario_nombre
  FROM   v_historial_pedido vh
  JOIN   pedidos            p ON p.id_pedido = vh.id_pedido
  WHERE  p.folio = p_folio
  ORDER  BY vh.creado_en ASC;
END ;;
DELIMITER ;


-- ─────────────────────────────────────────────
--  7. PERMISOS POR ROL (EXECUTE en SPs recreados)
-- ─────────────────────────────────────────────
-- Los SPs se definen con DEFINER=root, así que al ejecutarse
-- usan los privilegios de root. Pero los usuarios de BD necesitan
-- EXECUTE para poder CALL el SP.

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pedido_express        TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pedido_express        TO rol_cliente;

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pedido_futuro         TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pedido_futuro         TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pedido_futuro         TO rol_cliente;

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_mis_pedidos_cliente   TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_mis_pedidos_cliente   TO rol_cliente;

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_detalle_pedido        TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_detalle_pedido        TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_detalle_pedido        TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_detalle_pedido        TO rol_cliente;

-- La vista v_pedidos_resumen usa DEFINER=root, los SELECT grants
-- existentes sobre la tabla pedidos ya cubren la nueva columna.

FLUSH PRIVILEGES;


-- ─────────────────────────────────────────────
--  8. VERIFICACIÓN
-- ─────────────────────────────────────────────
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dulce_migaja'
  AND TABLE_NAME   = 'pedidos'
  AND COLUMN_NAME  = 'referencia_pago';

-- Verificar que los SPs se recrearon bien
SELECT ROUTINE_NAME, ROUTINE_TYPE
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'dulce_migaja'
  AND ROUTINE_NAME IN ('sp_pedido_express','sp_pedido_futuro',
                       'sp_mis_pedidos_cliente','sp_detalle_pedido');