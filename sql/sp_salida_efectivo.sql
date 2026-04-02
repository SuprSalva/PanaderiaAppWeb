-- ═══════════════════════════════════════════════════════════
--  Vista y Stored Procedures — Módulo Salida de Efectivo
--  Base de datos: dulce_migaja
--  Ejecutar como root en MySQL Workbench
-- ═══════════════════════════════════════════════════════════

USE dulce_migaja;

-- ── 1. Agregar columna id_compra ─────────────────────────────
ALTER TABLE salidas_efectivo
    ADD COLUMN id_compra INT NULL AFTER id_proveedor,
    ADD CONSTRAINT fk_salida_compra
        FOREIGN KEY (id_compra) REFERENCES compras(id_compra)
        ON DELETE SET NULL;

-- ─────────────────────────────────────────────
--  Vista: vw_salidas_efectivo
--  Joins salidas con proveedores y usuarios
--  (registrador y aprobador).
-- ─────────────────────────────────────────────
DROP VIEW IF EXISTS vw_salidas_efectivo;

CREATE VIEW vw_salidas_efectivo AS
SELECT
    s.id_salida,
    s.folio_salida,
    s.id_proveedor,
    p.nombre           AS nombre_proveedor,
    s.id_compra,
    c.folio            AS folio_compra,
    s.categoria,
    s.descripcion,
    s.monto,
    s.fecha_salida,
    s.estado,
    s.registrado_por,
    u1.nombre_completo AS nombre_registrador,
    s.aprobado_por,
    u2.nombre_completo AS nombre_aprobador,
    s.creado_en,
    s.actualizado_en
FROM salidas_efectivo s
LEFT JOIN proveedores p  ON s.id_proveedor  = p.id_proveedor
LEFT JOIN compras     c  ON s.id_compra     = c.id_compra
JOIN  usuarios       u1  ON s.registrado_por = u1.id_usuario
LEFT JOIN usuarios   u2  ON s.aprobado_por   = u2.id_usuario;


-- ─────────────────────────────────────────────
--  SP: sp_registrar_salida_manual
--  Registra una salida de efectivo manual.
--  Toda salida queda en 'pendiente' hasta que
--  el administrador la autorice.
-- ─────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_registrar_salida_manual;

DELIMITER $$

CREATE PROCEDURE sp_registrar_salida_manual(
    IN p_folio          VARCHAR(20),
    IN p_id_proveedor   INT,          -- NULL si no aplica proveedor
    IN p_categoria      VARCHAR(30),
    IN p_descripcion    VARCHAR(255),
    IN p_monto          DECIMAL(12,2),
    IN p_fecha_salida   DATE,
    IN p_registrado_por INT
)
BEGIN
    IF p_monto <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El monto debe ser mayor a cero.';
    END IF;

    IF p_descripcion IS NULL OR TRIM(p_descripcion) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La descripción es obligatoria.';
    END IF;

    IF p_categoria NOT IN ('compra_insumos','servicios_utilities','mantenimiento','otros') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Categoría no válida.';
    END IF;

    INSERT INTO salidas_efectivo (
        folio_salida, id_proveedor, categoria,
        descripcion, monto, fecha_salida,
        estado, registrado_por, creado_en, actualizado_en
    ) VALUES (
        p_folio,
        p_id_proveedor,
        p_categoria,
        p_descripcion,
        p_monto,
        p_fecha_salida,
        'pendiente',
        p_registrado_por,
        NOW(), NOW()
    );
END$$

DELIMITER ;


-- ─────────────────────────────────────────────
--  SP: sp_aprobar_salida
--  Aprueba o rechaza una salida pendiente.
--  Solo el administrador debe ejecutar este SP.
-- ─────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_aprobar_salida;

DELIMITER $$

CREATE PROCEDURE sp_aprobar_salida(
    IN p_id_salida    INT,
    IN p_decision     VARCHAR(10),   -- 'aprobada' | 'rechazada'
    IN p_aprobado_por INT
)
BEGIN
    DECLARE v_estado VARCHAR(10);

    SELECT estado INTO v_estado
    FROM salidas_efectivo
    WHERE id_salida = p_id_salida;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La salida de efectivo no existe.';
    END IF;

    IF v_estado <> 'pendiente' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Solo se pueden gestionar salidas en estado pendiente.';
    END IF;

    IF p_decision NOT IN ('aprobada', 'rechazada') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Decisión no válida. Use aprobada o rechazada.';
    END IF;

    UPDATE salidas_efectivo
       SET estado         = p_decision,
           aprobado_por   = p_aprobado_por,
           actualizado_en = NOW()
     WHERE id_salida = p_id_salida;
END$$

DELIMITER ;


