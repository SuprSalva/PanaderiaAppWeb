USE dulce_migaja;

DROP PROCEDURE IF EXISTS sp_aprobar_pedido;

DELIMITER $$
CREATE PROCEDURE sp_aprobar_pedido(
    IN  p_folio   VARCHAR(15),
    IN  p_usuario INT,
    IN  p_nota    TEXT,
    OUT p_ok      TINYINT,
    OUT p_error   TEXT
)
sp_aprobar_pedido: BEGIN
    DECLARE v_id_pedido  INT;
    DECLARE v_estado     VARCHAR(20);
    DECLARE v_id_cliente INT;
    DECLARE v_msg        VARCHAR(500);

    SET p_ok    = 0;
    SET p_error = NULL;

    SELECT id_pedido, estado, id_cliente
      INTO v_id_pedido, v_estado, v_id_cliente
      FROM pedidos
     WHERE folio = CONVERT(p_folio USING utf8mb4) COLLATE utf8mb4_unicode_ci
     LIMIT 1;

    IF v_id_pedido IS NULL THEN
        SET p_error = CONCAT('Pedido ', p_folio, ' no encontrado.');
        LEAVE sp_aprobar_pedido;
    END IF;

    IF v_estado != 'pendiente' THEN
        SET p_error = CONCAT('El pedido está en "', v_estado, '" y no puede aprobarse.');
        LEAVE sp_aprobar_pedido;
    END IF;

    UPDATE pedidos
       SET estado        = 'aprobado',
           atendido_por  = p_usuario,
           actualizado_en = NOW()
     WHERE id_pedido = v_id_pedido;

    SET v_msg = IFNULL(p_nota, 'Pedido aprobado.');
    INSERT INTO historial_pedidos
        (id_pedido, estado_antes, estado_despues, nota, realizado_por, creado_en)
    VALUES (v_id_pedido, 'pendiente', 'aprobado', v_msg, p_usuario, NOW());

    INSERT INTO notificaciones_pedidos
        (id_pedido, id_usuario, folio, tipo, mensaje, leida, creado_en)
    VALUES (
        v_id_pedido, v_id_cliente, p_folio, 'aprobado',
        CONCAT('✅ Tu pedido ', p_folio, ' fue aprobado y está siendo preparado.'),
        0, NOW()
    );

    INSERT INTO logs_sistema
        (tipo, nivel, id_usuario, modulo, accion, descripcion,
         referencia_id, referencia_tipo, creado_en)
    VALUES (
        'pedido', 'INFO', p_usuario, 'Pedidos', 'aprobar_pedido',
        CONCAT('Pedido ', p_folio, ' aprobado (sin descuento de stock).'),
        v_id_pedido, 'pedidos', NOW()
    );

    SET p_ok = 1;
END$$
DELIMITER ;


GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_aprobar_pedido      TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_aprobar_pedido      TO rol_empleado;
FLUSH PRIVILEGES;


USE dulce_migaja;

DROP PROCEDURE IF EXISTS sp_marcar_listo_pedido;

DELIMITER $$
CREATE PROCEDURE sp_marcar_listo_pedido(
    IN  p_folio   VARCHAR(15),
    IN  p_usuario INT,
    OUT p_ok      TINYINT,
    OUT p_error   TEXT
)
sp_marcar_listo: BEGIN
    DECLARE v_id_pedido  INT;
    DECLARE v_estado     VARCHAR(20);
    DECLARE v_id_cliente INT;
    DECLARE v_faltantes  TEXT DEFAULT '';
    DECLARE v_msg        VARCHAR(500);

    SET p_ok    = 0;
    SET p_error = NULL;

    SELECT id_pedido, estado, id_cliente
      INTO v_id_pedido, v_estado, v_id_cliente
      FROM pedidos
     WHERE folio = CONVERT(p_folio USING utf8mb4) COLLATE utf8mb4_unicode_ci
     LIMIT 1;

    IF v_id_pedido IS NULL THEN
        SET p_error = CONCAT('Pedido ', p_folio, ' no encontrado.');
        LEAVE sp_marcar_listo;
    END IF;

    IF v_estado != 'aprobado' THEN
        SET p_error = CONCAT('El pedido está en "', v_estado,
                             '". Solo se pueden marcar listos los pedidos aprobados.');
        LEAVE sp_marcar_listo;
    END IF;

    SELECT GROUP_CONCAT(
               CONCAT(pr.nombre, ' (necesitas ', dp.cantidad, ', hay ', IFNULL(inv.stock_actual, 0), ')')
               ORDER BY pr.nombre SEPARATOR ', '
           )
      INTO v_faltantes
      FROM detalle_pedidos dp
      JOIN productos pr       ON pr.id_producto  = dp.id_producto
      LEFT JOIN inventario_pt inv ON inv.id_producto = dp.id_producto
     WHERE dp.id_pedido = v_id_pedido
       AND IFNULL(inv.stock_actual, 0) < dp.cantidad;

    IF v_faltantes IS NOT NULL AND v_faltantes != '' THEN
        SET p_error = CONCAT('Stock insuficiente para: ', v_faltantes,
                             '. Realiza una entrada de inventario.');
        LEAVE sp_marcar_listo;
    END IF;

    UPDATE inventario_pt inv
      JOIN detalle_pedidos dp ON dp.id_producto = inv.id_producto
                              AND dp.id_pedido  = v_id_pedido
       SET inv.stock_actual = inv.stock_actual - dp.cantidad;

    UPDATE pedidos
       SET estado        = 'listo',
           actualizado_en = NOW()
     WHERE id_pedido = v_id_pedido;

    -- Historial
    SET v_msg = 'Pedido listo para recoger. Stock descontado correctamente.';
    INSERT INTO historial_pedidos
        (id_pedido, estado_antes, estado_despues, nota, realizado_por, creado_en)
    VALUES (v_id_pedido, 'aprobado', 'listo', v_msg, p_usuario, NOW());

    -- Notificación al cliente
    INSERT INTO notificaciones_pedidos
        (id_pedido, id_usuario, folio, tipo, mensaje, leida, creado_en)
    VALUES (
        v_id_pedido, v_id_cliente, p_folio, 'listo',
        CONCAT('🎉 ¡Tu pedido ', p_folio, ' está listo! Pasa a recogerlo cuando quieras.'),
        0, NOW()
    );

    -- Log
    INSERT INTO logs_sistema
        (tipo, nivel, id_usuario, modulo, accion, descripcion,
         referencia_id, referencia_tipo, creado_en)
    VALUES (
        'pedido', 'INFO', p_usuario, 'Pedidos', 'marcar_listo',
        CONCAT('Pedido ', p_folio, ' marcado listo. Stock descontado.'),
        v_id_pedido, 'pedidos', NOW()
    );

    SET p_ok = 1;
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_marcar_listo_pedido TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_marcar_listo_pedido TO rol_empleado;
FLUSH PRIVILEGES;