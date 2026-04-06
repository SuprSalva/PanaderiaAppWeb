DROP PROCEDURE IF EXISTS sp_iniciar_produccion_pedido;
DELIMITER ;;

CREATE PROCEDURE sp_iniciar_produccion_pedido(
  IN  p_folio        VARCHAR(20),
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
    SET p_error = CONCAT('Error en paso: ', @debug_step);
    SET p_estado_nuevo = NULL;
  END;

  SET p_ok=0; 
  SET p_error=NULL; 
  SET p_faltantes=NULL; 
  SET p_estado_nuevo=NULL;

  -- Paso 1
  SET @debug_step = '1 - Buscando pedido';

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

  -- Paso 2
  SET @debug_step = '2 - Creando tabla temporal';

  DROP TEMPORARY TABLE IF EXISTS _tmp_ins_pedido;

  CREATE TEMPORARY TABLE _tmp_ins_pedido (
    id_materia INT NOT NULL,
    cantidad_requerida DECIMAL(14,4) NOT NULL,
    PRIMARY KEY(id_materia)
  );

  -- Paso 3
  SET @debug_step = '3 - Insertando insumos';

  INSERT INTO _tmp_ins_pedido (id_materia, cantidad_requerida)
  SELECT dr.id_materia,
         ROUND(SUM((dp.cantidad / r.rendimiento) * dr.cantidad_requerida), 4)
    FROM detalle_pedidos dp
    JOIN recetas r ON r.id_producto = dp.id_producto 
                  AND r.estatus = 'activo'
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

  -- Paso 4
  SET @debug_step = '4 - Validando stock inicial';

  SELECT COUNT(*) INTO v_faltantes
    FROM _tmp_ins_pedido t 
    JOIN materias_primas mp ON mp.id_materia = t.id_materia
   WHERE mp.stock_actual < t.cantidad_requerida;

  IF v_faltantes > 0 THEN
    SET @debug_step = '4.1 - Generando detalle faltantes';

    SELECT GROUP_CONCAT(
      CONCAT(mp.nombre,': necesita ',ROUND(t.cantidad_requerida,2),' ',mp.unidad_base,
             ', disponible: ',ROUND(mp.stock_actual,2),' ',mp.unidad_base,
             ' (faltan ',ROUND(t.cantidad_requerida-mp.stock_actual,2),')')
      ORDER BY mp.nombre SEPARATOR ' | ')
      INTO v_detalle_f
      FROM _tmp_ins_pedido t 
      JOIN materias_primas mp ON mp.id_materia = t.id_materia
     WHERE mp.stock_actual < t.cantidad_requerida;

    START TRANSACTION;

    SET @debug_step = '4.2 - Actualizando pedido a pendiente';

    UPDATE pedidos 
       SET estado='pendiente_insumos', actualizado_en=NOW() 
     WHERE id_pedido=v_id_pedido;

    INSERT INTO historial_pedidos(id_pedido,estado_antes,estado_despues,nota,realizado_por,creado_en)
    VALUES(v_id_pedido,v_estado,'pendiente_insumos',
           CONCAT('Insumos insuficientes: ',v_detalle_f),p_user,NOW());

    COMMIT;

    DROP TEMPORARY TABLE IF EXISTS _tmp_ins_pedido;

    SET p_ok=1; 
    SET p_estado_nuevo='pendiente_insumos'; 
    SET p_faltantes=v_detalle_f;

    LEAVE sp_main;
  END IF;

  -- Paso 5
  SET @debug_step = '5 - Iniciando transacción';

  START TRANSACTION;

  SET @debug_step = '5.1 - Lock de materias';

  SELECT id_materia FROM materias_primas
   WHERE id_materia IN (SELECT id_materia FROM _tmp_ins_pedido)
   FOR UPDATE;

  SET @debug_step = '5.2 - Revalidando stock';

  SELECT COUNT(*) INTO v_faltantes
    FROM _tmp_ins_pedido t 
    JOIN materias_primas mp ON mp.id_materia=t.id_materia
   WHERE mp.stock_actual < t.cantidad_requerida;

  IF v_faltantes > 0 THEN
    ROLLBACK;
    DROP TEMPORARY TABLE IF EXISTS _tmp_ins_pedido;
    SET p_ok=0; 
    SET p_error='El stock cambió durante el proceso. Intenta nuevamente.';
    LEAVE sp_main;
  END IF;

  -- Paso 6
  SET @debug_step = '6 - Descontando stock';

  UPDATE materias_primas mp 
  JOIN _tmp_ins_pedido t ON t.id_materia=mp.id_materia
     SET mp.stock_actual=mp.stock_actual-t.cantidad_requerida,
         mp.actualizado_en=NOW();

  -- Paso 7
SET @debug_step = '7 - Generando folio producción';

-- Validar que la tabla tenga datos válidos
SELECT IFNULL(MAX(id_produccion), 0) INTO v_max_prod FROM produccion;

-- Generar folio directamente
SET v_folio_prod = CONCAT('L-', LPAD(v_max_prod + 1, 4, '0'));

  -- Paso 8
  SET @debug_step = '8 - Insertando producción';

  INSERT INTO produccion(
    folio_lote,id_producto,id_receta,cantidad_lotes,
    piezas_esperadas,piezas_producidas,estado,
    fecha_inicio,operario_id,observaciones,creado_en,creado_por
  )
  SELECT v_folio_prod,dp.id_producto,r.id_receta,
    ROUND(dp.cantidad/r.rendimiento,4),dp.cantidad,
    NULL,'en_proceso',NOW(),p_user,
    CONCAT('Pedido ',p_folio),NOW(),p_user
  FROM detalle_pedidos dp
  JOIN recetas r ON r.id_producto=dp.id_producto 
               AND r.estatus='activo'
               AND ((v_id_tamanio IS NOT NULL AND r.id_tamanio=v_id_tamanio)
                    OR (v_id_tamanio IS NULL AND r.id_tamanio IS NULL))
  WHERE dp.id_pedido=v_id_pedido 
  LIMIT 1;

  SET v_id_prod=LAST_INSERT_ID();

  -- Paso 9
  SET @debug_step = '9 - Insertando detalle producción';

  INSERT INTO detalle_produccion(id_produccion,id_materia,cantidad_requerida,cantidad_descontada)
  SELECT v_id_prod,id_materia,cantidad_requerida,cantidad_requerida 
  FROM _tmp_ins_pedido;

  -- Paso 10
  SET @debug_step = '10 - Actualizando pedido';

  UPDATE pedidos 
     SET estado='en_produccion',
         atendido_por=p_user,
         actualizado_en=NOW()
   WHERE id_pedido=v_id_pedido;

  INSERT INTO historial_pedidos(id_pedido,estado_antes,estado_despues,nota,realizado_por,creado_en)
  VALUES(v_id_pedido,v_estado,'en_produccion',
         CONCAT('Producción iniciada. Lote: ',v_folio_prod),p_user,NOW());

  -- Paso 11
  SET @debug_step = '11 - Insertando logs';

  INSERT INTO logs_sistema(tipo,nivel,id_usuario,modulo,accion,descripcion,
    referencia_id,referencia_tipo,creado_en)
  VALUES('produccion','INFO',p_user,'Pedidos','iniciar_produccion',
    CONCAT('Pedido ',p_folio,' → en_produccion. Lote: ',v_folio_prod),
    v_id_pedido,'pedidos',NOW());

  COMMIT;

  DROP TEMPORARY TABLE IF EXISTS _tmp_ins_pedido;

  SET p_ok=1; 
  SET p_estado_nuevo='en_produccion';

END ;;
DELIMITER ;