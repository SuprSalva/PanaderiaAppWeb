-- =============================================================
--  DulceMigaja – Módulo Producción Diaria  v2
--  Migración: de cajas/charolas → panes individuales por producto
--  EJECUTAR DESPUÉS de migration_produccion_diaria.sql
-- =============================================================

USE dulce_migaja;
-- ─────────────────────────────────────────────────────────────
-- 0. LIMPIAR DATOS EXISTENTES (evita errores de FK en ALTER)
-- ─────────────────────────────────────────────────────────────
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE produccion_diaria_insumos;
TRUNCATE TABLE produccion_diaria_linea_prod;
TRUNCATE TABLE produccion_diaria_detalle;
TRUNCATE TABLE produccion_diaria;
TRUNCATE TABLE plantillas_produccion_linea_prod;
TRUNCATE TABLE plantillas_produccion_detalle;
TRUNCATE TABLE plantillas_produccion;

SET FOREIGN_KEY_CHECKS = 1;

-- ─────────────────────────────────────────────────────────────
-- 1. ELIMINAR TABLAS DE SUB-DETALLE YA INNECESARIAS
-- ─────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS plantillas_produccion_linea_prod;
DROP TABLE IF EXISTS produccion_diaria_linea_prod;


-- ─────────────────────────────────────────────────────────────
-- 2. REDISEÑAR produccion_diaria_detalle
--    Antes: id_tamanio, tipo, cantidad_cajas, piezas_esperadas, piezas_producidas
--    Ahora: id_producto, id_receta, cantidad_piezas
-- ─────────────────────────────────────────────────────────────
ALTER TABLE produccion_diaria_detalle
  DROP FOREIGN KEY  fk_pdd_tam,
  DROP INDEX        idx_pdd_tam,
  DROP COLUMN       id_tamanio,
  DROP COLUMN       tipo,
  DROP COLUMN       cantidad_cajas,
  DROP COLUMN       piezas_producidas,
  CHANGE COLUMN     piezas_esperadas  cantidad_piezas INT NOT NULL
                    COMMENT 'Piezas de este producto a producir',
  ADD COLUMN        id_producto INT NOT NULL AFTER id_pd,
  ADD COLUMN        id_receta   INT NOT NULL AFTER id_producto,
  ADD KEY           idx_pdd_prod   (id_producto),
  ADD KEY           idx_pdd_receta (id_receta),
  ADD CONSTRAINT    fk_pdd_prod   FOREIGN KEY (id_producto) REFERENCES productos (id_producto),
  ADD CONSTRAINT    fk_pdd_receta FOREIGN KEY (id_receta)   REFERENCES recetas   (id_receta);


-- ─────────────────────────────────────────────────────────────
-- 3. REDISEÑAR plantillas_produccion_detalle
--    Antes: id_tamanio, tipo, cantidad_cajas
--    Ahora: id_producto, id_receta, cantidad_piezas
-- ─────────────────────────────────────────────────────────────
ALTER TABLE plantillas_produccion_detalle
  DROP FOREIGN KEY  fk_ppd_tam,
  DROP COLUMN       id_tamanio,
  DROP COLUMN       tipo,
  CHANGE COLUMN     cantidad_cajas  cantidad_piezas INT NOT NULL,
  ADD COLUMN        id_producto INT NOT NULL AFTER id_plantilla,
  ADD COLUMN        id_receta   INT NOT NULL AFTER id_producto,
  ADD CONSTRAINT    fk_ppd_prod  FOREIGN KEY (id_producto) REFERENCES productos (id_producto),
  ADD CONSTRAINT    fk_ppd_rec   FOREIGN KEY (id_receta)   REFERENCES recetas   (id_receta);


-- ─────────────────────────────────────────────────────────────
-- 4. ACTUALIZAR produccion_diaria (total_cajas ya no aplica)
-- ─────────────────────────────────────────────────────────────
ALTER TABLE produccion_diaria
  MODIFY COLUMN total_cajas INT NOT NULL DEFAULT 0
    COMMENT 'Deprecated v2 – siempre 0';


-- ─────────────────────────────────────────────────────────────
-- 5. ACTUALIZAR STORED PROCEDURES
-- ─────────────────────────────────────────────────────────────

-- ── 5.1 sp_pd_calcular_insumos  (simplificado, sin linea_prod)
DROP PROCEDURE IF EXISTS sp_pd_calcular_insumos;
DELIMITER ;;
CREATE PROCEDURE sp_pd_calcular_insumos(
  IN  p_id_pd   INT,
  OUT p_ok      TINYINT(1),
  OUT p_mensaje VARCHAR(500)
)
proc: BEGIN
  DECLARE v_folio           VARCHAR(20);
  DECLARE v_estado          VARCHAR(20);
  DECLARE v_tiene_faltantes TINYINT(1) DEFAULT 0;
  DECLARE v_total_piezas    INT        DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_mensaje = MESSAGE_TEXT;
  END;

  SET p_ok = 0;

  SELECT estado, folio INTO v_estado, v_folio
  FROM   produccion_diaria WHERE id_pd = p_id_pd LIMIT 1;

  IF v_estado IS NULL THEN
    SET p_mensaje = 'Producción no encontrada.'; LEAVE proc;
  END IF;

  IF v_estado <> 'pendiente' THEN
    SET p_mensaje = CONCAT('Solo se pueden calcular insumos en estado pendiente. Estado: ', v_estado);
    LEAVE proc;
  END IF;

  START TRANSACTION;

  -- Total de piezas (suma directa de cantidad_piezas)
  SELECT COALESCE(SUM(cantidad_piezas), 0)
    INTO v_total_piezas
    FROM produccion_diaria_detalle
   WHERE id_pd = p_id_pd;

  -- Borrar cálculo anterior (idempotente)
  DELETE FROM produccion_diaria_insumos WHERE id_pd = p_id_pd;

  -- Calcular insumos: piezas × (cantidad_requerida / rendimiento) por materia
  INSERT INTO produccion_diaria_insumos
    (id_pd, id_materia, cantidad_requerida, cantidad_descontada)
  SELECT
    p_id_pd,
    dr.id_materia,
    ROUND(SUM(pdd.cantidad_piezas * dr.cantidad_requerida / r.rendimiento), 4),
    0
  FROM  produccion_diaria_detalle pdd
  JOIN  recetas                   r   ON r.id_receta  = pdd.id_receta
  JOIN  detalle_recetas           dr  ON dr.id_receta = r.id_receta
  WHERE pdd.id_pd = p_id_pd
  GROUP BY dr.id_materia;

  -- ¿Hay algún insumo insuficiente?
  SELECT 1 INTO v_tiene_faltantes
  FROM   produccion_diaria_insumos pdi
  JOIN   materias_primas mp ON mp.id_materia = pdi.id_materia
  WHERE  pdi.id_pd = p_id_pd
    AND  mp.stock_actual < pdi.cantidad_requerida
  LIMIT  1;

  -- Actualizar encabezado
  UPDATE produccion_diaria
  SET    alerta_insumos         = COALESCE(v_tiene_faltantes, 0),
         total_cajas            = 0,
         total_piezas_esperadas = v_total_piezas
  WHERE  id_pd = p_id_pd;

  COMMIT;

  SET p_ok = 1;
  SET p_mensaje = IF(
    COALESCE(v_tiene_faltantes, 0) = 1,
    CONCAT('Producción ', v_folio, ' registrada con ALERTA de insumos insuficientes.'),
    CONCAT('Producción ', v_folio, ' lista. Stock suficiente para todos los insumos.')
  );
END;;
DELIMITER ;


-- ── 5.2 sp_pd_finalizar  (sin linea_prod; acredita directo de detalle)
DROP PROCEDURE IF EXISTS sp_pd_finalizar;
DELIMITER ;;
CREATE PROCEDURE sp_pd_finalizar(
  IN  p_id_pd   INT,
  IN  p_usuario INT,
  OUT p_ok      TINYINT(1),
  OUT p_mensaje VARCHAR(500)
)
proc: BEGIN
  DECLARE v_estado VARCHAR(20);
  DECLARE v_folio  VARCHAR(20);
  DECLARE v_piezas INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_mensaje = MESSAGE_TEXT;
  END;

  SET p_ok = 0;

  SELECT estado, folio, total_piezas_esperadas
    INTO v_estado, v_folio, v_piezas
    FROM produccion_diaria WHERE id_pd = p_id_pd LIMIT 1;

  IF v_estado IS NULL THEN
    SET p_mensaje = 'Producción no encontrada.'; LEAVE proc;
  END IF;

  IF v_estado <> 'en_proceso' THEN
    SET p_mensaje = CONCAT('La producción ', v_folio,
      ' no está en proceso. Estado actual: ', v_estado, '.');
    LEAVE proc;
  END IF;

  START TRANSACTION;

  -- Acreditar inventario de producto terminado por producto
  INSERT INTO inventario_pt (id_producto, stock_actual, stock_minimo, ultima_actualizacion)
  SELECT pdd.id_producto, SUM(pdd.cantidad_piezas), 0, NOW()
  FROM   produccion_diaria_detalle pdd
  WHERE  pdd.id_pd = p_id_pd
  GROUP  BY pdd.id_producto
  ON DUPLICATE KEY UPDATE
    stock_actual         = stock_actual + VALUES(stock_actual),
    ultima_actualizacion = NOW();

  -- Actualizar encabezado
  UPDATE produccion_diaria
  SET    estado                = 'finalizado',
         fecha_fin_real        = NOW(),
         inventario_acreditado = 1
  WHERE  id_pd = p_id_pd;

  COMMIT;

  SET p_ok     = 1;
  SET p_mensaje = CONCAT('Producción ', v_folio, ' finalizada. ',
    v_piezas, ' piezas acreditadas al inventario.');
END;;
DELIMITER ;


-- ── 5.3 sp_pd_guardar_plantilla  (copia directa detalle → plantilla)
DROP PROCEDURE IF EXISTS sp_pd_guardar_plantilla;
DELIMITER ;;
CREATE PROCEDURE sp_pd_guardar_plantilla(
  IN  p_id_pd       INT,
  IN  p_nombre      VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  IN  p_descripcion TEXT        CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  IN  p_usuario     INT,
  OUT p_id_plant    INT,
  OUT p_ok          TINYINT(1),
  OUT p_mensaje     VARCHAR(500)
)
proc: BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_mensaje = MESSAGE_TEXT;
  END;

  SET p_ok = 0;

  IF NOT EXISTS (SELECT 1 FROM produccion_diaria WHERE id_pd = p_id_pd) THEN
    SET p_mensaje = 'Producción no encontrada.'; LEAVE proc;
  END IF;

  IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
    SET p_mensaje = 'El nombre de la plantilla es obligatorio.'; LEAVE proc;
  END IF;

  START TRANSACTION;

  INSERT INTO plantillas_produccion (nombre, descripcion, creado_por, creado_en)
  VALUES (TRIM(p_nombre), NULLIF(TRIM(COALESCE(p_descripcion, '')), ''), p_usuario, NOW());

  SET p_id_plant = LAST_INSERT_ID();

  -- Copiar líneas directamente (id_producto, id_receta, cantidad_piezas)
  INSERT INTO plantillas_produccion_detalle
    (id_plantilla, id_producto, id_receta, cantidad_piezas)
  SELECT p_id_plant, id_producto, id_receta, cantidad_piezas
  FROM   produccion_diaria_detalle
  WHERE  id_pd = p_id_pd;

  COMMIT;

  SET p_ok     = 1;
  SET p_mensaje = CONCAT('Plantilla "', TRIM(p_nombre), '" guardada correctamente.');
END;;
DELIMITER ;


-- ── 5.4 Recrear sp_pd_crear_cabecera (sin cambio de lógica, asegurar consistencia)
DROP PROCEDURE IF EXISTS sp_pd_crear_cabecera;
DELIMITER ;;
CREATE PROCEDURE sp_pd_crear_cabecera(
  IN  p_nombre        VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  IN  p_observaciones TEXT        CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  IN  p_operario_id   INT,
  IN  p_creado_por    INT,
  OUT p_id_pd         INT,
  OUT p_folio         VARCHAR(20),
  OUT p_ok            TINYINT(1),
  OUT p_mensaje       VARCHAR(500)
)
proc: BEGIN
  DECLARE v_siguiente INT DEFAULT 1;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_mensaje = MESSAGE_TEXT;
  END;

  SET p_ok = 0;

  IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
    SET p_mensaje = 'El nombre de la producción es obligatorio.';
    LEAVE proc;
  END IF;

  SELECT COALESCE(MAX(CAST(SUBSTRING(folio, 4) AS UNSIGNED)), 0) + 1
    INTO v_siguiente
    FROM produccion_diaria;

  SET p_folio = CONCAT('PD-', LPAD(v_siguiente, 4, '0'));

  START TRANSACTION;

  INSERT INTO produccion_diaria
    (folio, nombre, observaciones, operario_id, creado_por, creado_en, actualizado_en)
  VALUES
    (p_folio, TRIM(p_nombre),
     NULLIF(TRIM(COALESCE(p_observaciones, '')), ''),
     NULLIF(p_operario_id, 0),
     p_creado_por, NOW(), NOW());

  SET p_id_pd = LAST_INSERT_ID();

  COMMIT;

  SET p_ok      = 1;
  SET p_mensaje = CONCAT('Cabecera creada con folio ', p_folio, '.');
END;;
DELIMITER ;


-- ─────────────────────────────────────────────────────────────
-- 6. ACTUALIZAR VISTA
-- ─────────────────────────────────────────────────────────────
DROP VIEW IF EXISTS vw_produccion_diaria;
CREATE VIEW vw_produccion_diaria AS
SELECT
  pd.id_pd,
  pd.folio,
  pd.nombre,
  pd.estado,
  pd.total_piezas_esperadas,
  pd.alerta_insumos,
  pd.insumos_descontados,
  pd.inventario_acreditado,
  pd.observaciones,
  pd.motivo_cancelacion,
  pd.fecha_inicio,
  pd.fecha_fin_real,
  pd.creado_en,
  pd.actualizado_en,
  pd.operario_id,
  u_op.nombre_completo AS operario,
  pd.creado_por,
  u_cr.nombre_completo AS creado_por_nombre,
  COUNT(DISTINCT pdd.id_pdd)       AS total_lineas,
  COALESCE(SUM(pdd.cantidad_piezas), 0) AS total_piezas_calc
FROM produccion_diaria pd
LEFT JOIN usuarios u_op ON u_op.id_usuario = pd.operario_id
LEFT JOIN usuarios u_cr ON u_cr.id_usuario = pd.creado_por
LEFT JOIN produccion_diaria_detalle pdd ON pdd.id_pd = pd.id_pd
GROUP BY
  pd.id_pd, pd.folio, pd.nombre, pd.estado,
  pd.total_piezas_esperadas, pd.alerta_insumos, pd.insumos_descontados,
  pd.inventario_acreditado, pd.observaciones, pd.motivo_cancelacion,
  pd.fecha_inicio, pd.fecha_fin_real, pd.creado_en, pd.actualizado_en,
  pd.operario_id, u_op.nombre_completo, pd.creado_por, u_cr.nombre_completo;


-- ─────────────────────────────────────────────────────────────
-- 7. ACTUALIZAR PERMISOS (eliminar refs a tablas borradas)
-- ─────────────────────────────────────────────────────────────
DROP USER  IF EXISTS 'dm_admin'@'localhost';
DROP USER  IF EXISTS 'dm_vendedor'@'localhost';
DROP USER  IF EXISTS 'dm_panadero'@'localhost';
DROP USER  IF EXISTS 'dm_cliente'@'localhost';
DROP ROLE  IF EXISTS rol_admin;
DROP ROLE  IF EXISTS rol_vendedor;
DROP ROLE  IF EXISTS rol_panadero;
DROP ROLE  IF EXISTS rol_cliente;

CREATE ROLE rol_admin;
CREATE ROLE rol_vendedor;
CREATE ROLE rol_panadero;
CREATE ROLE rol_cliente;

-- rol_admin: acceso completo
GRANT ALL PRIVILEGES ON dulce_migaja.* TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_crear_cabecera    TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_calcular_insumos  TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_iniciar           TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_finalizar         TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_cancelar          TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_lista             TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_guardar_plantilla TO rol_admin;

-- rol_vendedor: solo lectura
GRANT SELECT ON dulce_migaja.vw_produccion_diaria          TO rol_vendedor;
GRANT SELECT ON dulce_migaja.produccion_diaria             TO rol_vendedor;
GRANT SELECT ON dulce_migaja.produccion_diaria_detalle     TO rol_vendedor;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_lista        TO rol_vendedor;

-- rol_panadero: ver + operar
GRANT SELECT ON dulce_migaja.produccion_diaria             TO rol_panadero;
GRANT SELECT ON dulce_migaja.produccion_diaria_detalle     TO rol_panadero;
GRANT SELECT ON dulce_migaja.produccion_diaria_insumos     TO rol_panadero;
GRANT SELECT ON dulce_migaja.vw_produccion_diaria          TO rol_panadero;
GRANT SELECT ON dulce_migaja.plantillas_produccion         TO rol_panadero;
GRANT SELECT ON dulce_migaja.plantillas_produccion_detalle TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_iniciar      TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_finalizar    TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_lista        TO rol_panadero;

-- rol_cliente: sin acceso a producción

CREATE USER 'dm_admin'@'localhost'    IDENTIFIED BY 'DmAdmin_2026#Seg!';
CREATE USER 'dm_vendedor'@'localhost' IDENTIFIED BY 'DmVendedor_2026#';
CREATE USER 'dm_panadero'@'localhost' IDENTIFIED BY 'DmPanadero_2026#';
CREATE USER 'dm_cliente'@'localhost'  IDENTIFIED BY 'DmCliente_2026#';

GRANT rol_admin    TO 'dm_admin'@'localhost';
GRANT rol_vendedor TO 'dm_vendedor'@'localhost';
GRANT rol_panadero TO 'dm_panadero'@'localhost';
GRANT rol_cliente  TO 'dm_cliente'@'localhost';

SET DEFAULT ROLE rol_admin    TO 'dm_admin'@'localhost';
SET DEFAULT ROLE rol_vendedor TO 'dm_vendedor'@'localhost';
SET DEFAULT ROLE rol_panadero TO 'dm_panadero'@'localhost';
SET DEFAULT ROLE rol_cliente  TO 'dm_cliente'@'localhost';

FLUSH PRIVILEGES;