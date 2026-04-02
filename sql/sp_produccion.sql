-- ── Corregir sp_aprobar_pedido ─────────────────────────────
DROP PROCEDURE IF EXISTS `sp_aprobar_pedido`;
DELIMITER $$
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
    SET p_error = CONCAT('Solo se pueden aprobar pedidos pendientes. Estado actual: ', v_estado);
    LEAVE sp_main;
  END IF;
  START TRANSACTION;
  UPDATE pedidos SET estado='aprobado', atendido_por=p_user, actualizado_en=NOW()
   WHERE id_pedido = v_id_pedido;
  INSERT INTO historial_pedidos (id_pedido,estado_antes,estado_despues,nota,realizado_por,creado_en)
  VALUES (v_id_pedido,'pendiente','aprobado',COALESCE(p_nota,'Pedido aprobado'),p_user,NOW());
  INSERT INTO notificaciones_pedidos (id_pedido,id_usuario,folio,tipo,mensaje,leida,creado_en)
  VALUES (v_id_pedido,v_id_cliente,p_folio,'aprobado',
    CONCAT('Tu pedido ',p_folio,' ha sido aprobado. Pronto comenzará su producción.'),0,NOW());
  COMMIT;
  SET p_ok = 1;
END$$
DELIMITER ;


-- ── Corregir sp_rechazar_pedido ────────────────────────────
DROP PROCEDURE IF EXISTS `sp_rechazar_pedido`;
DELIMITER $$
CREATE PROCEDURE `sp_rechazar_pedido`(
  IN  p_folio  VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN  p_user   INT,
  IN  p_motivo TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  OUT p_ok     TINYINT(1),
  OUT p_error  VARCHAR(300)
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
  IF v_estado NOT IN ('pendiente','aprobado') THEN
    SET p_error = CONCAT('No se puede rechazar un pedido en estado: ', v_estado);
    LEAVE sp_main;
  END IF;
  IF p_motivo IS NULL OR TRIM(p_motivo) = '' THEN
    SET p_error = 'Debes indicar el motivo del rechazo.';
    LEAVE sp_main;
  END IF;
  START TRANSACTION;
  UPDATE pedidos SET estado='rechazado', motivo_rechazo=p_motivo,
         atendido_por=p_user, actualizado_en=NOW()
   WHERE id_pedido = v_id_pedido;
  INSERT INTO historial_pedidos (id_pedido,estado_antes,estado_despues,nota,realizado_por,creado_en)
  VALUES (v_id_pedido,v_estado,'rechazado',p_motivo,p_user,NOW());
  INSERT INTO notificaciones_pedidos (id_pedido,id_usuario,folio,tipo,mensaje,leida,creado_en)
  VALUES (v_id_pedido,v_id_cliente,p_folio,'rechazado',
    CONCAT('Tu pedido ',p_folio,' no pudo ser aceptado. Motivo: ',p_motivo),0,NOW());
  COMMIT;
  SET p_ok = 1;
END$$
DELIMITER ;


-- ── Corregir sp_verificar_insumos_pedido ───────────────────
DROP PROCEDURE IF EXISTS `sp_verificar_insumos_pedido`;
DELIMITER $$
CREATE PROCEDURE `sp_verificar_insumos_pedido`(
  IN  p_folio VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  OUT p_ok    TINYINT(1),
  OUT p_error VARCHAR(300)
)
sp_main: BEGIN
  DECLARE v_id_pedido  INT;
  DECLARE v_estado     VARCHAR(30);
  DECLARE v_id_tamanio INT;
  SET p_ok = 0; SET p_error = NULL;
  SELECT id_pedido, estado, id_tamanio
    INTO v_id_pedido, v_estado, v_id_tamanio
    FROM pedidos WHERE folio = p_folio LIMIT 1;
  IF v_id_pedido IS NULL THEN
    SET p_error = CONCAT('Pedido ', p_folio, ' no encontrado.');
    LEAVE sp_main;
  END IF;
  SET p_ok = 1;
  SELECT
    mp.id_materia, mp.nombre AS nombre_materia,
    mp.unidad_base, mp.categoria,
    ROUND(SUM((dp.cantidad / r.rendimiento) * dr.cantidad_requerida), 4) AS cantidad_requerida,
    mp.stock_actual, mp.stock_minimo,
    CASE WHEN mp.stock_actual >= ROUND(SUM((dp.cantidad / r.rendimiento) * dr.cantidad_requerida), 4)
         THEN 1 ELSE 0 END AS stock_suficiente,
    LEAST(100, ROUND(mp.stock_actual /
      NULLIF(ROUND(SUM((dp.cantidad / r.rendimiento) * dr.cantidad_requerida), 4), 0) * 100, 1))
      AS pct_disponible
  FROM detalle_pedidos dp
  JOIN recetas r ON r.id_producto = dp.id_producto AND r.estatus = 'activo'
               AND ((v_id_tamanio IS NOT NULL AND r.id_tamanio = v_id_tamanio)
                    OR (v_id_tamanio IS NULL AND r.id_tamanio IS NULL))
  JOIN detalle_recetas dr ON dr.id_receta = r.id_receta
  JOIN materias_primas mp ON mp.id_materia = dr.id_materia
  WHERE dp.id_pedido = v_id_pedido
  GROUP BY mp.id_materia, mp.nombre, mp.unidad_base, mp.categoria, mp.stock_actual, mp.stock_minimo
  ORDER BY mp.nombre;
END$$
DELIMITER ;


-- ── Corregir sp_iniciar_produccion_pedido ──────────────────
DROP PROCEDURE IF EXISTS `sp_iniciar_produccion_pedido`;
DELIMITER $$
CREATE PROCEDURE `sp_iniciar_produccion_pedido`(
  IN  p_folio        VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN  p_user         INT,
  OUT p_ok           TINYINT(1),
  OUT p_estado_nuevo VARCHAR(30),
  OUT p_error        VARCHAR(500),
  OUT p_faltantes    TEXT
)
sp_main: BEGIN
  DECLARE v_id_pedido   INT;
  DECLARE v_estado      VARCHAR(30);
  DECLARE v_id_tamanio  INT;
  DECLARE v_faltantes   INT     DEFAULT 0;
  DECLARE v_detalle_f   TEXT    DEFAULT '';
  DECLARE v_folio_prod  VARCHAR(20);
  DECLARE v_max_prod    INT     DEFAULT 0;
  DECLARE v_id_prod     INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    DROP TEMPORARY TABLE IF EXISTS _tmp_ins_pedido;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
    SET p_estado_nuevo = NULL;
  END;
  SET p_ok=0; SET p_error=NULL; SET p_faltantes=NULL; SET p_estado_nuevo=NULL;
  SELECT id_pedido, estado, id_tamanio
    INTO v_id_pedido, v_estado, v_id_tamanio
    FROM pedidos WHERE folio = p_folio LIMIT 1;
  IF v_id_pedido IS NULL THEN
    SET p_error = CONCAT('Pedido ', p_folio, ' no encontrado.');
    LEAVE sp_main;
  END IF;
  IF v_estado NOT IN ('aprobado','pendiente_insumos') THEN
    SET p_error = CONCAT('Estado inválido para iniciar: ', v_estado);
    LEAVE sp_main;
  END IF;
  DROP TEMPORARY TABLE IF EXISTS _tmp_ins_pedido;
  CREATE TEMPORARY TABLE _tmp_ins_pedido (
    id_materia INT NOT NULL, cantidad_requerida DECIMAL(14,4) NOT NULL, PRIMARY KEY(id_materia)
  ) ENGINE=MEMORY;
  INSERT INTO _tmp_ins_pedido (id_materia, cantidad_requerida)
  SELECT dr.id_materia,
         ROUND(SUM((dp.cantidad / r.rendimiento) * dr.cantidad_requerida), 4)
    FROM detalle_pedidos dp
    JOIN recetas r ON r.id_producto = dp.id_producto AND r.estatus = 'activo'
                  AND ((v_id_tamanio IS NOT NULL AND r.id_tamanio = v_id_tamanio)
                       OR (v_id_tamanio IS NULL AND r.id_tamanio IS NULL))
    JOIN detalle_recetas dr ON dr.id_receta = r.id_receta
   WHERE dp.id_pedido = v_id_pedido
   GROUP BY dr.id_materia;
  IF (SELECT COUNT(*) FROM _tmp_ins_pedido) = 0 THEN
    DROP TEMPORARY TABLE IF EXISTS _tmp_ins_pedido;
    SET p_error = 'No se encontraron recetas para los productos del pedido.';
    LEAVE sp_main;
  END IF;
  SELECT COUNT(*) INTO v_faltantes
    FROM _tmp_ins_pedido t JOIN materias_primas mp ON mp.id_materia = t.id_materia
   WHERE mp.stock_actual < t.cantidad_requerida;
  IF v_faltantes > 0 THEN
    SELECT GROUP_CONCAT(
      CONCAT(mp.nombre,': necesita ',ROUND(t.cantidad_requerida,2),' ',mp.unidad_base,
             ', disponible: ',ROUND(mp.stock_actual,2),' ',mp.unidad_base,
             ' (faltan ',ROUND(t.cantidad_requerida-mp.stock_actual,2),')')
      ORDER BY mp.nombre SEPARATOR ' | ')
      INTO v_detalle_f
      FROM _tmp_ins_pedido t JOIN materias_primas mp ON mp.id_materia = t.id_materia
     WHERE mp.stock_actual < t.cantidad_requerida;
    START TRANSACTION;
    UPDATE pedidos SET estado='pendiente_insumos', actualizado_en=NOW() WHERE id_pedido=v_id_pedido;
    INSERT INTO historial_pedidos(id_pedido,estado_antes,estado_despues,nota,realizado_por,creado_en)
    VALUES(v_id_pedido,v_estado,'pendiente_insumos',
           CONCAT('Insumos insuficientes: ',v_detalle_f),p_user,NOW());
    COMMIT;
    DROP TEMPORARY TABLE IF EXISTS _tmp_ins_pedido;
    SET p_ok=1; SET p_estado_nuevo='pendiente_insumos'; SET p_faltantes=v_detalle_f;
    LEAVE sp_main;
  END IF;
  START TRANSACTION;
  SELECT id_materia FROM materias_primas
   WHERE id_materia IN (SELECT id_materia FROM _tmp_ins_pedido) FOR UPDATE;
  SELECT COUNT(*) INTO v_faltantes
    FROM _tmp_ins_pedido t JOIN materias_primas mp ON mp.id_materia=t.id_materia
   WHERE mp.stock_actual < t.cantidad_requerida;
  IF v_faltantes > 0 THEN
    ROLLBACK; DROP TEMPORARY TABLE IF EXISTS _tmp_ins_pedido;
    SET p_ok=0; SET p_error='El stock cambió durante el proceso. Intenta nuevamente.';
    LEAVE sp_main;
  END IF;
  UPDATE materias_primas mp JOIN _tmp_ins_pedido t ON t.id_materia=mp.id_materia
     SET mp.stock_actual=mp.stock_actual-t.cantidad_requerida, mp.actualizado_en=NOW();
  SELECT COALESCE(MAX(id_produccion),0) INTO v_max_prod FROM produccion;
  SET v_folio_prod = CONCAT('L-',LPAD(v_max_prod+1,4,'0'));
  WHILE EXISTS(SELECT 1 FROM produccion WHERE folio_lote=v_folio_prod) DO
    SET v_max_prod=v_max_prod+1;
    SET v_folio_prod=CONCAT('L-',LPAD(v_max_prod+1,4,'0'));
  END WHILE;
  INSERT INTO produccion(folio_lote,id_producto,id_receta,cantidad_lotes,piezas_esperadas,
    piezas_producidas,estado,fecha_inicio,operario_id,observaciones,creado_en,creado_por)
  SELECT v_folio_prod,dp.id_producto,r.id_receta,
    ROUND(dp.cantidad/r.rendimiento,4),dp.cantidad,
    NULL,'en_proceso',NOW(),p_user,CONCAT('Pedido ',p_folio),NOW(),p_user
  FROM detalle_pedidos dp
  JOIN recetas r ON r.id_producto=dp.id_producto AND r.estatus='activo'
               AND ((v_id_tamanio IS NOT NULL AND r.id_tamanio=v_id_tamanio)
                    OR (v_id_tamanio IS NULL AND r.id_tamanio IS NULL))
  WHERE dp.id_pedido=v_id_pedido LIMIT 1;
  SET v_id_prod=LAST_INSERT_ID();
  INSERT INTO detalle_produccion(id_produccion,id_materia,cantidad_requerida,cantidad_descontada)
  SELECT v_id_prod,id_materia,cantidad_requerida,cantidad_requerida FROM _tmp_ins_pedido;
  UPDATE pedidos SET estado='en_produccion',atendido_por=p_user,actualizado_en=NOW()
   WHERE id_pedido=v_id_pedido;
  INSERT INTO historial_pedidos(id_pedido,estado_antes,estado_despues,nota,realizado_por,creado_en)
  VALUES(v_id_pedido,v_estado,'en_produccion',
         CONCAT('Producción iniciada. Lote: ',v_folio_prod),p_user,NOW());
  INSERT INTO logs_sistema(tipo,nivel,id_usuario,modulo,accion,descripcion,
    referencia_id,referencia_tipo,creado_en)
  VALUES('produccion','INFO',p_user,'Pedidos','iniciar_produccion',
    CONCAT('Pedido ',p_folio,' → en_produccion. Lote: ',v_folio_prod),
    v_id_pedido,'pedidos',NOW());
  COMMIT;
  DROP TEMPORARY TABLE IF EXISTS _tmp_ins_pedido;
  SET p_ok=1; SET p_estado_nuevo='en_produccion';
END$$
DELIMITER ;


-- ── Corregir sp_terminar_produccion_pedido ─────────────────
DROP PROCEDURE IF EXISTS `sp_terminar_produccion_pedido`;
DELIMITER $$
CREATE PROCEDURE `sp_terminar_produccion_pedido`(
  IN  p_folio VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN  p_user  INT,
  OUT p_ok    TINYINT(1),
  OUT p_error VARCHAR(300)
)
sp_main: BEGIN
  DECLARE v_id_pedido  INT;
  DECLARE v_estado     VARCHAR(30);
  DECLARE v_id_cliente INT;
  DECLARE v_folio_txt  VARCHAR(30);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
  END;

  SET p_ok = 0; SET p_error = NULL;

  SET v_folio_txt = CONVERT(p_folio USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;

  SELECT id_pedido, estado, id_cliente
    INTO v_id_pedido, v_estado, v_id_cliente
    FROM pedidos WHERE folio = p_folio LIMIT 1;

  IF v_id_pedido IS NULL THEN
    SET p_error = CONCAT('Pedido ', p_folio, ' no encontrado.');
    LEAVE sp_main;
  END IF;

  IF v_estado != 'en_produccion' THEN
    SET p_error = CONCAT('Solo se pueden terminar pedidos en producción. Estado actual: ', v_estado);
    LEAVE sp_main;
  END IF;

  START TRANSACTION;

  UPDATE pedidos
     SET estado = 'listo', actualizado_en = NOW()
   WHERE id_pedido = v_id_pedido;

  UPDATE produccion
     SET estado             = 'finalizado',
         fecha_fin_real     = NOW(),
         piezas_producidas  = piezas_esperadas
   WHERE observaciones = CONCAT('Pedido ', v_folio_txt)
     AND estado        = 'en_proceso';

  INSERT INTO historial_pedidos (id_pedido, estado_antes, estado_despues, nota, realizado_por, creado_en)
  VALUES (v_id_pedido, 'en_produccion', 'listo',
          'Producción terminada. Pedido listo para recoger.', p_user, NOW());

  INSERT INTO notificaciones_pedidos (id_pedido, id_usuario, folio, tipo, mensaje, leida, creado_en)
  VALUES (v_id_pedido, v_id_cliente, p_folio, 'listo',
          CONCAT('🎉 ¡Tu pedido ', p_folio, ' está listo! Pasa a recogerlo cuando quieras.'),
          0, NOW());

  INSERT INTO logs_sistema (tipo, nivel, id_usuario, modulo, accion, descripcion,
    referencia_id, referencia_tipo, creado_en)
  VALUES ('produccion', 'INFO', p_user, 'Pedidos', 'terminar_produccion',
    CONCAT('Pedido ', p_folio, ' terminado → listo. Cliente notificado.'),
    v_id_pedido, 'pedidos', NOW());

  COMMIT;
  SET p_ok = 1;
END$$
DELIMITER ;