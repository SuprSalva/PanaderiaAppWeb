-- =============================================================
--  DulceMigaja – Módulo Producción Diaria (Tienda Física)
--  Migration: tablas, vistas, SPs, triggers, índices, usuarios
--  Charset: utf8mb4 / Collation: utf8mb4_0900_ai_ci (consistente con la BD)
-- =============================================================

USE dulce_migaja;

-- ─────────────────────────────────────────────────────────────
-- 1. TABLAS NUEVAS
-- ─────────────────────────────────────────────────────────────

-- Encabezado de producción diaria (tienda física)
CREATE TABLE IF NOT EXISTS produccion_diaria (
  id_pd                  INT           NOT NULL AUTO_INCREMENT,
  folio                  VARCHAR(20)   NOT NULL,
  nombre                 VARCHAR(120)  NOT NULL
    COMMENT 'Nombre descriptivo, ej: Producción Mañanera Lunes',
  estado                 ENUM('pendiente','en_proceso','finalizado','cancelado')
                                       NOT NULL DEFAULT 'pendiente',
  operario_id            INT           DEFAULT NULL,
  total_cajas            INT           NOT NULL DEFAULT 0,
  total_piezas_esperadas INT           NOT NULL DEFAULT 0,
  alerta_insumos         TINYINT(1)    NOT NULL DEFAULT 0
    COMMENT '1 si había faltantes al crear',
  insumos_descontados    TINYINT(1)    NOT NULL DEFAULT 0,
  inventario_acreditado  TINYINT(1)    NOT NULL DEFAULT 0,
  observaciones          TEXT          DEFAULT NULL,
  motivo_cancelacion     TEXT          DEFAULT NULL,
  fecha_inicio           DATETIME      DEFAULT NULL,
  fecha_fin_real         DATETIME      DEFAULT NULL,
  creado_por             INT           DEFAULT NULL,
  creado_en              DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                       ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY             (id_pd),
  UNIQUE  KEY uq_pd_folio (folio),
  KEY idx_pd_estado_fecha (estado, creado_en),
  KEY idx_pd_operario     (operario_id),
  KEY idx_pd_creado_por   (creado_por),

  CONSTRAINT fk_pd_operario    FOREIGN KEY (operario_id)
    REFERENCES usuarios (id_usuario) ON DELETE SET NULL,
  CONSTRAINT fk_pd_creado_por2 FOREIGN KEY (creado_por)
    REFERENCES usuarios (id_usuario) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Encabezado de producción diaria para tienda física';


-- Líneas de la producción: cada tipo de caja con su cantidad
CREATE TABLE IF NOT EXISTS produccion_diaria_detalle (
  id_pdd           INT  NOT NULL AUTO_INCREMENT,
  id_pd            INT  NOT NULL,
  id_tamanio       INT  NOT NULL
    COMMENT 'FK a tamanios_charola',
  tipo             ENUM('simple','mixta','triple') NOT NULL,
  cantidad_cajas   INT  NOT NULL,
  piezas_esperadas INT  NOT NULL
    COMMENT 'capacidad × cantidad_cajas',
  piezas_producidas INT  DEFAULT NULL,

  PRIMARY KEY      (id_pdd),
  KEY idx_pdd_pd   (id_pd),
  KEY idx_pdd_tam  (id_tamanio),

  CONSTRAINT fk_pdd_pd  FOREIGN KEY (id_pd)
    REFERENCES produccion_diaria (id_pd) ON DELETE CASCADE,
  CONSTRAINT fk_pdd_tam FOREIGN KEY (id_tamanio)
    REFERENCES tamanios_charola (id_tamanio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Líneas de cajas en una producción diaria';


-- Sub-detalle: productos concretos por cada línea de caja
CREATE TABLE IF NOT EXISTS produccion_diaria_linea_prod (
  id_pdlp          INT         NOT NULL AUTO_INCREMENT,
  id_pdd           INT         NOT NULL,
  id_producto      INT         NOT NULL,
  id_receta        INT         NOT NULL
    COMMENT 'Receta usada (producto + tamaño correcto)',
  piezas_por_caja  TINYINT     NOT NULL
    COMMENT 'Cantidad de piezas de este producto en CADA caja',

  PRIMARY KEY         (id_pdlp),
  KEY idx_pdlp_pdd    (id_pdd),
  KEY idx_pdlp_prod   (id_producto),
  KEY idx_pdlp_receta (id_receta),

  CONSTRAINT fk_pdlp_pdd     FOREIGN KEY (id_pdd)
    REFERENCES produccion_diaria_detalle (id_pdd) ON DELETE CASCADE,
  CONSTRAINT fk_pdlp_prod    FOREIGN KEY (id_producto)
    REFERENCES productos (id_producto),
  CONSTRAINT fk_pdlp_receta  FOREIGN KEY (id_receta)
    REFERENCES recetas (id_receta)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Productos concretos por línea de caja';


-- Insumos totales calculados para la producción
CREATE TABLE IF NOT EXISTS produccion_diaria_insumos (
  id_pdi              INT           NOT NULL AUTO_INCREMENT,
  id_pd               INT           NOT NULL,
  id_materia          INT           NOT NULL,
  cantidad_requerida  DECIMAL(12,4) NOT NULL,
  cantidad_descontada DECIMAL(12,4) NOT NULL DEFAULT 0,

  PRIMARY KEY          (id_pdi),
  UNIQUE KEY uq_pdi_pm (id_pd, id_materia),
  KEY idx_pdi_pd       (id_pd),
  KEY idx_pdi_mat      (id_materia),

  CONSTRAINT fk_pdi_pd  FOREIGN KEY (id_pd)
    REFERENCES produccion_diaria (id_pd) ON DELETE CASCADE,
  CONSTRAINT fk_pdi_mat FOREIGN KEY (id_materia)
    REFERENCES materias_primas (id_materia)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Insumos totales de una producción diaria';


-- Plantillas guardadas para reutilización rápida
CREATE TABLE IF NOT EXISTS plantillas_produccion (
  id_plantilla INT          NOT NULL AUTO_INCREMENT,
  nombre       VARCHAR(120) NOT NULL,
  descripcion  TEXT         DEFAULT NULL,
  creado_por   INT          DEFAULT NULL,
  creado_en    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY          (id_plantilla),
  KEY idx_plant_usr    (creado_por),

  CONSTRAINT fk_plant_usr FOREIGN KEY (creado_por)
    REFERENCES usuarios (id_usuario) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Plantillas reutilizables de producción diaria';


-- Líneas de cada plantilla
CREATE TABLE IF NOT EXISTS plantillas_produccion_detalle (
  id_ppd         INT NOT NULL AUTO_INCREMENT,
  id_plantilla   INT NOT NULL,
  id_tamanio     INT NOT NULL,
  tipo           ENUM('simple','mixta','triple') NOT NULL,
  cantidad_cajas INT NOT NULL,

  PRIMARY KEY       (id_ppd),
  KEY idx_ppd_plant (id_plantilla),

  CONSTRAINT fk_ppd_plant FOREIGN KEY (id_plantilla)
    REFERENCES plantillas_produccion (id_plantilla) ON DELETE CASCADE,
  CONSTRAINT fk_ppd_tam   FOREIGN KEY (id_tamanio)
    REFERENCES tamanios_charola (id_tamanio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- Productos por línea de plantilla
CREATE TABLE IF NOT EXISTS plantillas_produccion_linea_prod (
  id_pplp         INT         NOT NULL AUTO_INCREMENT,
  id_ppd          INT         NOT NULL,
  id_producto     INT         NOT NULL,
  id_receta       INT         NOT NULL,
  piezas_por_caja TINYINT     NOT NULL,

  PRIMARY KEY         (id_pplp),
  KEY idx_pplp_ppd    (id_ppd),

  CONSTRAINT fk_pplp_ppd   FOREIGN KEY (id_ppd)
    REFERENCES plantillas_produccion_detalle (id_ppd) ON DELETE CASCADE,
  CONSTRAINT fk_pplp_prod  FOREIGN KEY (id_producto) REFERENCES productos (id_producto),
  CONSTRAINT fk_pplp_rec   FOREIGN KEY (id_receta)   REFERENCES recetas   (id_receta)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- ─────────────────────────────────────────────────────────────
-- 2. VISTA
-- ─────────────────────────────────────────────────────────────

DROP VIEW IF EXISTS vw_produccion_diaria;
CREATE VIEW vw_produccion_diaria AS
SELECT
  pd.id_pd,
  pd.folio,
  pd.nombre,
  pd.estado,
  pd.total_cajas,
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
  COUNT(DISTINCT pdd.id_pdd) AS total_lineas
FROM produccion_diaria pd
LEFT JOIN usuarios u_op ON u_op.id_usuario = pd.operario_id
LEFT JOIN usuarios u_cr ON u_cr.id_usuario = pd.creado_por
LEFT JOIN produccion_diaria_detalle pdd ON pdd.id_pd = pd.id_pd
GROUP BY
  pd.id_pd, pd.folio, pd.nombre, pd.estado,
  pd.total_cajas, pd.total_piezas_esperadas,
  pd.alerta_insumos, pd.insumos_descontados, pd.inventario_acreditado,
  pd.observaciones, pd.motivo_cancelacion, pd.fecha_inicio, pd.fecha_fin_real,
  pd.creado_en, pd.actualizado_en, pd.operario_id, u_op.nombre_completo,
  pd.creado_por, u_cr.nombre_completo;


-- ─────────────────────────────────────────────────────────────
-- 3. TRIGGERS
-- ─────────────────────────────────────────────────────────────

DROP TRIGGER IF EXISTS trg_pd_estado_log;
DELIMITER ;;
CREATE TRIGGER trg_pd_estado_log
AFTER UPDATE ON produccion_diaria
FOR EACH ROW
BEGIN
  -- Registra en logs_sistema cuando cambia el estado
  IF NEW.estado <> OLD.estado THEN
    INSERT INTO logs_sistema
      (tipo, nivel, id_usuario, modulo, accion, descripcion,
       referencia_id, referencia_tipo, creado_en)
    VALUES
      ('produccion', 'INFO', NEW.creado_por, 'ProduccionDiaria',
       CONCAT('estado_', NEW.estado),
       CONCAT('Producción ', NEW.folio, ' cambió de "', OLD.estado,
              '" a "', NEW.estado, '"'),
       NEW.id_pd, 'produccion_diaria', NOW());
  END IF;
END;;
DELIMITER ;


DROP TRIGGER IF EXISTS trg_pd_alerta_insumos_log;
DELIMITER ;;
CREATE TRIGGER trg_pd_alerta_insumos_log
AFTER INSERT ON produccion_diaria
FOR EACH ROW
BEGIN
  -- Si se creó con alerta de insumos, advertir en log
  IF NEW.alerta_insumos = 1 THEN
    INSERT INTO logs_sistema
      (tipo, nivel, id_usuario, modulo, accion, descripcion,
       referencia_id, referencia_tipo, creado_en)
    VALUES
      ('produccion', 'WARNING', NEW.creado_por, 'ProduccionDiaria',
       'alerta_insumos',
       CONCAT('Producción ', NEW.folio,
              ' creada con alerta de insumos insuficientes.'),
       NEW.id_pd, 'produccion_diaria', NOW());
  END IF;
END;;
DELIMITER ;


-- ─────────────────────────────────────────────────────────────
-- 4. STORED PROCEDURES
-- ─────────────────────────────────────────────────────────────

-- ── 4.1 sp_pd_crear_cabecera ──────────────────────────────────
DROP PROCEDURE IF EXISTS sp_pd_crear_cabecera;
DELIMITER ;;
CREATE PROCEDURE sp_pd_crear_cabecera(
  IN  p_nombre       VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  IN  p_observaciones TEXT        CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  IN  p_operario_id  INT,
  IN  p_creado_por   INT,
  OUT p_id_pd        INT,
  OUT p_folio        VARCHAR(20),
  OUT p_ok           TINYINT(1),
  OUT p_mensaje      VARCHAR(500)
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

  -- Validaciones básicas
  IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
    SET p_mensaje = 'El nombre de la producción es obligatorio.';
    LEAVE proc;
  END IF;

  -- Generar folio correlativo  PD-0001, PD-0002 …
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
     p_creado_por,
     NOW(), NOW());

  SET p_id_pd = LAST_INSERT_ID();

  COMMIT;

  SET p_ok     = 1;
  SET p_mensaje = CONCAT('Cabecera creada con folio ', p_folio, '.');
END;;
DELIMITER ;


-- ── 4.2 sp_pd_calcular_insumos ───────────────────────────────
-- Llamar DESPUÉS de insertar todos los detalle/linea_prod.
-- Calcula los insumos totales, detecta faltantes y actualiza alerta_insumos.
DROP PROCEDURE IF EXISTS sp_pd_calcular_insumos;
DELIMITER ;;
CREATE PROCEDURE sp_pd_calcular_insumos(
  IN  p_id_pd    INT,
  OUT p_ok       TINYINT(1),
  OUT p_mensaje  VARCHAR(500)
)
proc: BEGIN
  DECLARE v_folio           VARCHAR(20);
  DECLARE v_estado          VARCHAR(20);
  DECLARE v_tiene_faltantes TINYINT(1) DEFAULT 0;
  DECLARE v_total_cajas     INT DEFAULT 0;
  DECLARE v_total_piezas    INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_mensaje = MESSAGE_TEXT;
  END;

  SET p_ok = 0;

  SELECT estado, folio INTO v_estado, v_folio
  FROM produccion_diaria WHERE id_pd = p_id_pd LIMIT 1;

  IF v_estado IS NULL THEN
    SET p_mensaje = 'Producción no encontrada.'; LEAVE proc;
  END IF;

  IF v_estado <> 'pendiente' THEN
    SET p_mensaje = CONCAT('Solo se pueden calcular insumos en estado pendiente. Estado: ', v_estado);
    LEAVE proc;
  END IF;

  START TRANSACTION;

  -- Totales de cajas y piezas
  SELECT COALESCE(SUM(cantidad_cajas), 0),
         COALESCE(SUM(piezas_esperadas), 0)
    INTO v_total_cajas, v_total_piezas
    FROM produccion_diaria_detalle
   WHERE id_pd = p_id_pd;

  -- Borrar cálculo anterior (idempotente)
  DELETE FROM produccion_diaria_insumos WHERE id_pd = p_id_pd;

  -- Calcular e insertar insumos totales
  -- Fórmula: cantidad_cajas × piezas_por_caja × (dr.cantidad_requerida / r.rendimiento)
  INSERT INTO produccion_diaria_insumos
    (id_pd, id_materia, cantidad_requerida, cantidad_descontada)
  SELECT
    p_id_pd,
    dr.id_materia,
    ROUND(SUM(pdd.cantidad_cajas * pdlp.piezas_por_caja
              * dr.cantidad_requerida / r.rendimiento), 4),
    0
  FROM produccion_diaria_detalle   pdd
  JOIN produccion_diaria_linea_prod pdlp ON pdlp.id_pdd    = pdd.id_pdd
  JOIN recetas                      r    ON r.id_receta     = pdlp.id_receta
  JOIN detalle_recetas              dr   ON dr.id_receta    = r.id_receta
  WHERE pdd.id_pd = p_id_pd
  GROUP BY dr.id_materia;

  -- ¿Hay algún insumo con stock insuficiente?
  SELECT 1 INTO v_tiene_faltantes
  FROM   produccion_diaria_insumos pdi
  JOIN   materias_primas mp ON mp.id_materia = pdi.id_materia
  WHERE  pdi.id_pd = p_id_pd
    AND  mp.stock_actual < pdi.cantidad_requerida
  LIMIT  1;

  -- Actualizar encabezado
  UPDATE produccion_diaria
  SET alerta_insumos         = COALESCE(v_tiene_faltantes, 0),
      total_cajas            = v_total_cajas,
      total_piezas_esperadas = v_total_piezas
  WHERE id_pd = p_id_pd;

  COMMIT;

  SET p_ok = 1;
  SET p_mensaje = IF(
    COALESCE(v_tiene_faltantes, 0) = 1,
    CONCAT('Producción ', v_folio,
           ' registrada con ALERTA de insumos insuficientes.',
           ' Verifica el almacén antes de iniciar.'),
    CONCAT('Producción ', v_folio,
           ' lista. Stock suficiente para todos los insumos.')
  );
END;;
DELIMITER ;


-- ── 4.3 sp_pd_iniciar ────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_pd_iniciar;
DELIMITER ;;
CREATE PROCEDURE sp_pd_iniciar(
  IN  p_id_pd   INT,
  IN  p_usuario INT,
  OUT p_ok      TINYINT(1),
  OUT p_mensaje VARCHAR(500)
)
proc: BEGIN
  DECLARE v_estado VARCHAR(20);
  DECLARE v_folio  VARCHAR(20);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_mensaje = MESSAGE_TEXT;
  END;

  SET p_ok = 0;

  SELECT estado, folio INTO v_estado, v_folio
  FROM produccion_diaria WHERE id_pd = p_id_pd LIMIT 1;

  IF v_estado IS NULL THEN
    SET p_mensaje = 'Producción no encontrada.'; LEAVE proc;
  END IF;

  IF v_estado <> 'pendiente' THEN
    SET p_mensaje = CONCAT('La producción ', v_folio,
      ' no está pendiente. Estado actual: ', v_estado, '.');
    LEAVE proc;
  END IF;

  -- Verificar que tiene insumos calculados
  IF NOT EXISTS (SELECT 1 FROM produccion_diaria_insumos WHERE id_pd = p_id_pd LIMIT 1) THEN
    SET p_mensaje = 'No hay insumos calculados para esta producción.';
    LEAVE proc;
  END IF;

  START TRANSACTION;

  -- Descontar insumos del almacén y registrar descuento
  UPDATE materias_primas mp
  JOIN   produccion_diaria_insumos pdi ON pdi.id_materia = mp.id_materia
  SET    mp.stock_actual          = mp.stock_actual - pdi.cantidad_requerida,
         mp.actualizado_en        = NOW(),
         pdi.cantidad_descontada  = pdi.cantidad_requerida
  WHERE  pdi.id_pd = p_id_pd;

  -- Cambiar estado
  UPDATE produccion_diaria
  SET    estado             = 'en_proceso',
         fecha_inicio       = NOW(),
         insumos_descontados = 1
  WHERE  id_pd = p_id_pd;

  COMMIT;

  SET p_ok     = 1;
  SET p_mensaje = CONCAT('Producción ', v_folio,
    ' iniciada. Insumos descontados del almacén.');
END;;
DELIMITER ;


-- ── 4.4 sp_pd_finalizar ──────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_pd_finalizar;
DELIMITER ;;
CREATE PROCEDURE sp_pd_finalizar(
  IN  p_id_pd          INT,
  IN  p_usuario        INT,
  IN  p_piezas_totales INT,   -- NULL o 0 => usar total_piezas_esperadas
  OUT p_ok             TINYINT(1),
  OUT p_mensaje        VARCHAR(500)
)
proc: BEGIN
  DECLARE v_estado    VARCHAR(20);
  DECLARE v_folio     VARCHAR(20);
  DECLARE v_esp       INT;
  DECLARE v_finales   INT;
  DECLARE v_factor    DECIMAL(8,4) DEFAULT 1.0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_mensaje = MESSAGE_TEXT;
  END;

  SET p_ok = 0;

  SELECT estado, folio, total_piezas_esperadas
    INTO v_estado, v_folio, v_esp
    FROM produccion_diaria WHERE id_pd = p_id_pd LIMIT 1;

  IF v_estado IS NULL THEN
    SET p_mensaje = 'Producción no encontrada.'; LEAVE proc;
  END IF;

  IF v_estado <> 'en_proceso' THEN
    SET p_mensaje = CONCAT('La producción ', v_folio,
      ' no está en proceso. Estado actual: ', v_estado, '.');
    LEAVE proc;
  END IF;

  SET v_finales = COALESCE(NULLIF(p_piezas_totales, 0), v_esp);
  SET v_factor  = IF(v_esp > 0, v_finales / v_esp, 1.0);

  START TRANSACTION;

  -- Actualizar piezas producidas por línea (proporcional)
  UPDATE produccion_diaria_detalle
  SET    piezas_producidas = ROUND(piezas_esperadas * v_factor)
  WHERE  id_pd = p_id_pd;

  -- Acreditar inventario de producto terminado
  INSERT INTO inventario_pt (id_producto, stock_actual, stock_minimo, ultima_actualizacion)
  SELECT
    pdlp.id_producto,
    ROUND(SUM(pdd.cantidad_cajas * pdlp.piezas_por_caja) * v_factor),
    0,
    NOW()
  FROM  produccion_diaria_detalle    pdd
  JOIN  produccion_diaria_linea_prod pdlp ON pdlp.id_pdd = pdd.id_pdd
  WHERE pdd.id_pd = p_id_pd
  GROUP BY pdlp.id_producto
  ON DUPLICATE KEY UPDATE
    stock_actual        = stock_actual + VALUES(stock_actual),
    ultima_actualizacion = NOW();

  -- Actualizar encabezado
  UPDATE produccion_diaria
  SET    estado                 = 'finalizado',
         fecha_fin_real         = NOW(),
         inventario_acreditado  = 1,
         total_piezas_esperadas = v_finales
  WHERE  id_pd = p_id_pd;

  COMMIT;

  SET p_ok     = 1;
  SET p_mensaje = CONCAT('Producción ', v_folio, ' finalizada. ',
    v_finales, ' piezas acreditadas al inventario.');
END;;
DELIMITER ;


-- ── 4.5 sp_pd_cancelar ───────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_pd_cancelar;
DELIMITER ;;
CREATE PROCEDURE sp_pd_cancelar(
  IN  p_id_pd   INT,
  IN  p_usuario INT,
  IN  p_motivo  TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  OUT p_ok      TINYINT(1),
  OUT p_mensaje VARCHAR(500)
)
proc: BEGIN
  DECLARE v_estado   VARCHAR(20);
  DECLARE v_folio    VARCHAR(20);
  DECLARE v_desc_in  TINYINT(1);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_mensaje = MESSAGE_TEXT;
  END;

  SET p_ok = 0;

  SELECT estado, folio, insumos_descontados
    INTO v_estado, v_folio, v_desc_in
    FROM produccion_diaria WHERE id_pd = p_id_pd LIMIT 1;

  IF v_estado IS NULL THEN
    SET p_mensaje = 'Producción no encontrada.'; LEAVE proc;
  END IF;

  IF v_estado NOT IN ('pendiente', 'en_proceso') THEN
    SET p_mensaje = CONCAT('La producción ', v_folio,
      ' no puede cancelarse. Estado: ', v_estado, '.');
    LEAVE proc;
  END IF;

  START TRANSACTION;

  -- Restaurar insumos si ya fueron descontados
  IF v_desc_in = 1 THEN
    UPDATE materias_primas mp
    JOIN   produccion_diaria_insumos pdi ON pdi.id_materia = mp.id_materia
    SET    mp.stock_actual   = mp.stock_actual + pdi.cantidad_descontada,
           mp.actualizado_en = NOW()
    WHERE  pdi.id_pd = p_id_pd AND pdi.cantidad_descontada > 0;
  END IF;

  -- Actualizar encabezado
  UPDATE produccion_diaria
  SET    estado              = 'cancelado',
         motivo_cancelacion  = COALESCE(NULLIF(TRIM(p_motivo), ''), 'Sin motivo'),
         insumos_descontados = IF(v_desc_in = 1, 0, 0)  -- marcar restaurados
  WHERE  id_pd = p_id_pd;

  COMMIT;

  SET p_ok     = 1;
  SET p_mensaje = CONCAT('Producción ', v_folio, ' cancelada.',
    IF(v_desc_in = 1, ' Insumos restaurados al almacén.', ''));
END;;
DELIMITER ;


-- ── 4.6 sp_pd_lista (paginado) ───────────────────────────────
DROP PROCEDURE IF EXISTS sp_pd_lista;
DELIMITER ;;
CREATE PROCEDURE sp_pd_lista(
  IN p_estado    VARCHAR(20)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  IN p_fecha_ini DATE,
  IN p_fecha_fin DATE,
  IN p_limite    INT,
  IN p_offset    INT
)
BEGIN
  SELECT
    pd.id_pd,
    pd.folio,
    pd.nombre,
    pd.estado,
    pd.total_cajas,
    pd.total_piezas_esperadas,
    pd.alerta_insumos,
    pd.insumos_descontados,
    pd.inventario_acreditado,
    pd.fecha_inicio,
    pd.fecha_fin_real,
    pd.creado_en,
    u_op.nombre_completo AS operario,
    u_cr.nombre_completo AS creado_por_nombre
  FROM  produccion_diaria pd
  LEFT JOIN usuarios u_op ON u_op.id_usuario = pd.operario_id
  LEFT JOIN usuarios u_cr ON u_cr.id_usuario = pd.creado_por
  WHERE (p_estado IS NULL OR pd.estado = CONVERT(p_estado USING utf8mb4) COLLATE utf8mb4_0900_ai_ci)
    AND (p_fecha_ini IS NULL OR DATE(pd.creado_en) >= p_fecha_ini)
    AND (p_fecha_fin IS NULL OR DATE(pd.creado_en) <= p_fecha_fin)
  ORDER BY pd.creado_en DESC
  LIMIT  p_limite OFFSET p_offset;
END;;
DELIMITER ;


-- ── 4.7 sp_pd_guardar_plantilla ──────────────────────────────
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

  -- Crear plantilla
  INSERT INTO plantillas_produccion (nombre, descripcion, creado_por, creado_en)
  VALUES (TRIM(p_nombre), NULLIF(TRIM(COALESCE(p_descripcion,'')), ''), p_usuario, NOW());

  SET p_id_plant = LAST_INSERT_ID();

  -- Copiar líneas de detalle
  INSERT INTO plantillas_produccion_detalle (id_plantilla, id_tamanio, tipo, cantidad_cajas)
  SELECT p_id_plant, id_tamanio, tipo, cantidad_cajas
  FROM   produccion_diaria_detalle
  WHERE  id_pd = p_id_pd;

  -- Copiar sub-detalle de productos
  INSERT INTO plantillas_produccion_linea_prod
    (id_ppd, id_producto, id_receta, piezas_por_caja)
  SELECT ppd.id_ppd, pdlp.id_producto, pdlp.id_receta, pdlp.piezas_por_caja
  FROM   produccion_diaria_linea_prod pdlp
  JOIN   produccion_diaria_detalle pdd ON pdd.id_pdd = pdlp.id_pdd
  JOIN   plantillas_produccion_detalle ppd
         ON ppd.id_plantilla = p_id_plant
         AND ppd.id_tamanio  = pdd.id_tamanio
         AND ppd.tipo        = pdd.tipo
  WHERE  pdd.id_pd = p_id_pd;

  COMMIT;

  SET p_ok     = 1;
  SET p_mensaje = CONCAT('Plantilla "', TRIM(p_nombre), '" guardada correctamente.');
END;;
DELIMITER ;


-- ─────────────────────────────────────────────────────────────
-- 5. USUARIOS, ROLES Y PERMISOS
-- ─────────────────────────────────────────────────────────────

-- 5.1 Limpiar usuarios y roles anteriores
DROP USER  IF EXISTS 'dm_admin'@'localhost';
DROP USER  IF EXISTS 'dm_vendedor'@'localhost';
DROP USER  IF EXISTS 'dm_panadero'@'localhost';
DROP USER  IF EXISTS 'dm_cliente'@'localhost';
DROP ROLE  IF EXISTS rol_admin;
DROP ROLE  IF EXISTS rol_vendedor;
DROP ROLE  IF EXISTS rol_panadero;
DROP ROLE  IF EXISTS rol_cliente;


-- 5.2 Crear roles
CREATE ROLE rol_admin;
CREATE ROLE rol_vendedor;
CREATE ROLE rol_panadero;
CREATE ROLE rol_cliente;


-- 5.3 Permisos para rol_admin (acceso total)
GRANT ALL PRIVILEGES ON dulce_migaja.* TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_crear_cabecera    TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_calcular_insumos  TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_iniciar           TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_finalizar         TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_cancelar          TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_lista             TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_guardar_plantilla TO rol_admin;


-- 5.4 Permisos para rol_vendedor
--     Puede ver la lista de producciones pero no modificar
GRANT SELECT ON dulce_migaja.vw_produccion_diaria              TO rol_vendedor;
GRANT SELECT ON dulce_migaja.produccion_diaria                 TO rol_vendedor;
GRANT SELECT ON dulce_migaja.produccion_diaria_detalle         TO rol_vendedor;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_lista            TO rol_vendedor;


-- 5.5 Permisos para rol_panadero
--     Puede ver y ejecutar/finalizar producciones asignadas
GRANT SELECT ON dulce_migaja.produccion_diaria                 TO rol_panadero;
GRANT SELECT ON dulce_migaja.produccion_diaria_detalle         TO rol_panadero;
GRANT SELECT ON dulce_migaja.produccion_diaria_linea_prod      TO rol_panadero;
GRANT SELECT ON dulce_migaja.produccion_diaria_insumos         TO rol_panadero;
GRANT SELECT ON dulce_migaja.vw_produccion_diaria              TO rol_panadero;
GRANT SELECT ON dulce_migaja.plantillas_produccion             TO rol_panadero;
GRANT SELECT ON dulce_migaja.plantillas_produccion_detalle     TO rol_panadero;
GRANT SELECT ON dulce_migaja.plantillas_produccion_linea_prod  TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_iniciar          TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_finalizar        TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_lista            TO rol_panadero;


-- 5.6 rol_cliente: sin acceso a producción
--     (no se otorgan permisos sobre las tablas del módulo)


-- 5.7 Crear usuarios de BD y asignar roles
CREATE USER 'dm_admin'@'localhost'    IDENTIFIED BY 'DmAdmin_2026#Seg!';
CREATE USER 'dm_vendedor'@'localhost' IDENTIFIED BY 'DmVendedor_2026#';
CREATE USER 'dm_panadero'@'localhost' IDENTIFIED BY 'DmPanadero_2026#';
CREATE USER 'dm_cliente'@'localhost'  IDENTIFIED BY 'DmCliente_2026#';

GRANT rol_admin    TO 'dm_admin'@'localhost';
GRANT rol_vendedor TO 'dm_vendedor'@'localhost';
GRANT rol_panadero TO 'dm_panadero'@'localhost';
GRANT rol_cliente  TO 'dm_cliente'@'localhost';

-- Activar rol por defecto al conectarse
SET DEFAULT ROLE rol_admin    TO 'dm_admin'@'localhost';
SET DEFAULT ROLE rol_vendedor TO 'dm_vendedor'@'localhost';
SET DEFAULT ROLE rol_panadero TO 'dm_panadero'@'localhost';
SET DEFAULT ROLE rol_cliente  TO 'dm_cliente'@'localhost';

FLUSH PRIVILEGES;