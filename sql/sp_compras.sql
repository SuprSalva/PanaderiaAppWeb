-- ═══════════════════════════════════════════════════════════
--  Stored Procedures — Módulo Compras
--  Base de datos: dulce_migaja
--  Ejecutar como root en MySQL Workbench
-- ═══════════════════════════════════════════════════════════

USE dulce_migaja;

-- ─────────────────────────────────────────────
--  SP: sp_crear_pedido_compra
--  Crea un pedido de compra en estatus 'ordenado'.
--  Los detalles se insertan línea por línea desde
--  Python antes de llamar a este SP, o bien se
--  pasa el JSON de ítems y se itera aquí.
--  Optamos por: primero insertar la cabecera y
--  devolver el id, luego Python inserta los detalles.
-- ─────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_crear_pedido_compra;

DELIMITER $$

CREATE PROCEDURE sp_crear_pedido_compra(
    IN  p_folio          VARCHAR(20)  CHARACTER SET utf8mb4,
    IN  p_folio_factura  VARCHAR(60)  CHARACTER SET utf8mb4,
    IN  p_id_proveedor   INT,
    IN  p_fecha_compra   DATE,
    IN  p_observaciones  TEXT         CHARACTER SET utf8mb4,
    IN  p_creado_por     INT,
    OUT p_id_compra      INT
)
BEGIN
    -- Proveedor debe existir y estar activo
    IF NOT EXISTS (
        SELECT 1 FROM proveedores
        WHERE id_proveedor = p_id_proveedor AND estatus = 'activo'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El proveedor no existe o está inactivo.';
    END IF;

    -- Folio duplicado
    IF EXISTS (SELECT 1 FROM compras WHERE folio = p_folio) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El folio de compra ya existe.';
    END IF;

    INSERT INTO compras (
        folio, folio_factura, id_proveedor, fecha_compra,
        total, estatus, observaciones, creado_en, creado_por
    ) VALUES (
        p_folio, NULLIF(p_folio_factura,''), p_id_proveedor, p_fecha_compra,
        0, 'ordenado', NULLIF(p_observaciones,''), NOW(), p_creado_por
    );

    SET p_id_compra = LAST_INSERT_ID();
END$$

DELIMITER ;


-- ─────────────────────────────────────────────
--  SP: sp_agregar_detalle_compra
--  Inserta una línea de detalle a un pedido
--  en estatus 'ordenado' y recalcula el total.
--  La conversión ya viene calculada desde Python:
--    cantidad_base = cantidad_comprada * factor_conversion
-- ─────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_agregar_detalle_compra;

DELIMITER $$

CREATE PROCEDURE sp_agregar_detalle_compra(
    IN p_id_compra              INT,
    IN p_id_materia             INT,
    IN p_id_unidad_presentacion INT,      -- NULL si unidad libre
    IN p_cantidad_comprada      DECIMAL(12,4),
    IN p_unidad_compra          VARCHAR(20) CHARACTER SET utf8mb4,
    IN p_factor_conversion      DECIMAL(12,4),
    IN p_cantidad_base          DECIMAL(12,4),
    IN p_costo_unitario         DECIMAL(12,4)
)
BEGIN
    -- Solo se puede modificar un pedido en estatus ordenado
    IF NOT EXISTS (
        SELECT 1 FROM compras
        WHERE id_compra = p_id_compra AND estatus = 'ordenado'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Solo se pueden agregar detalles a pedidos en estatus ordenado.';
    END IF;

    INSERT INTO detalle_compras (
        id_compra, id_materia, id_unidad_presentacion,
        cantidad_comprada, unidad_compra,
        factor_conversion, cantidad_base, costo_unitario
    ) VALUES (
        p_id_compra, p_id_materia,
        NULLIF(p_id_unidad_presentacion, 0),
        p_cantidad_comprada, p_unidad_compra,
        p_factor_conversion, p_cantidad_base, p_costo_unitario
    );

    -- Recalcular total de la cabecera
    UPDATE compras
    SET total = (
        SELECT COALESCE(SUM(cantidad_comprada * costo_unitario), 0)
        FROM detalle_compras
        WHERE id_compra = p_id_compra
    )
    WHERE id_compra = p_id_compra;
END$$

DELIMITER ;


-- ─────────────────────────────────────────────
--  SP: sp_cancelar_compra
--  Cambia el estatus a 'cancelado' y guarda motivo.
--  Solo aplica a pedidos 'ordenado'.
-- ─────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_cancelar_compra;

DELIMITER $$

CREATE PROCEDURE sp_cancelar_compra(
    IN p_id_compra          INT,
    IN p_motivo_cancelacion TEXT CHARACTER SET utf8mb4,
    IN p_ejecutado_por      INT
)
BEGIN
    DECLARE v_estatus VARCHAR(20);

    SELECT estatus INTO v_estatus
    FROM compras WHERE id_compra = p_id_compra;

    IF v_estatus IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El pedido de compra no existe.';
    END IF;

    IF v_estatus <> 'ordenado' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Solo se pueden cancelar pedidos en estatus ordenado.';
    END IF;

    IF p_motivo_cancelacion IS NULL OR TRIM(p_motivo_cancelacion) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Debes indicar el motivo de cancelación.';
    END IF;

    UPDATE compras
    SET estatus            = 'cancelado',
        motivo_cancelacion = p_motivo_cancelacion
    WHERE id_compra = p_id_compra;
END$$

DELIMITER ;


-- ─────────────────────────────────────────────
--  SP: sp_finalizar_compra
--  Cambia estatus a 'finalizado', suma al stock
--  de cada materia prima y genera una salida de
--  efectivo hacia el proveedor.
--  Solo aplica a pedidos 'ordenado'.
-- ─────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_finalizar_compra;

DELIMITER $$

CREATE PROCEDURE sp_finalizar_compra(
    IN p_id_compra     INT,
    IN p_ejecutado_por INT,
    IN p_folio_salida  VARCHAR(20) CHARACTER SET utf8mb4
)
BEGIN
    DECLARE v_estatus      VARCHAR(20);
    DECLARE v_total        DECIMAL(12,2);
    DECLARE v_id_proveedor INT;
    DECLARE v_fecha        DATE;

    -- Verificar existencia y estatus
    SELECT estatus, total, id_proveedor, fecha_compra
    INTO   v_estatus, v_total, v_id_proveedor, v_fecha
    FROM   compras WHERE id_compra = p_id_compra;

    IF v_estatus IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El pedido de compra no existe.';
    END IF;

    IF v_estatus <> 'ordenado' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Solo se pueden finalizar pedidos en estatus ordenado.';
    END IF;

    -- ── 1. Actualizar stock de cada materia prima ──────────
    UPDATE materias_primas mp
    JOIN detalle_compras dc ON dc.id_materia = mp.id_materia
    SET mp.stock_actual = mp.stock_actual + dc.cantidad_base
    WHERE dc.id_compra = p_id_compra;

    -- ── 2. Cambiar estatus del pedido ──────────────────────
    UPDATE compras
    SET estatus = 'finalizado'
    WHERE id_compra = p_id_compra;

    -- ── 3. Registrar salida de efectivo ────────────────────
    INSERT INTO salidas_efectivo (
        folio_salida, id_proveedor, categoria,
        descripcion, monto, fecha_salida,
        estado, registrado_por, creado_en, actualizado_en
    ) VALUES (
        p_folio_salida,
        v_id_proveedor,
        'compra_insumos',
        CONCAT('Pago pedido compra #', p_id_compra),
        v_total,
        v_fecha,
        'aprobada',
        p_ejecutado_por,
        NOW(),
        NOW()
    );
END$$

DELIMITER ;

-- ─────────────────────────────────────────────
--  SP: sp_limpiar_detalles_compra
--  Elimina todos los renglones de un pedido en
--  estatus 'ordenado' para poder re-insertarlos.
-- ─────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_limpiar_detalles_compra;

DELIMITER $$
CREATE PROCEDURE sp_limpiar_detalles_compra(
    IN p_id_compra INT
)
BEGIN
    DECLARE v_estatus VARCHAR(20);
    SELECT estatus INTO v_estatus FROM compras WHERE id_compra = p_id_compra;
    IF v_estatus IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pedido no encontrado.';
    END IF;
    IF v_estatus != 'ordenado' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se pueden editar pedidos en estatus Ordenado.';
    END IF;
    DELETE FROM detalle_compras WHERE id_compra = p_id_compra;
    UPDATE compras SET total = 0 WHERE id_compra = p_id_compra;
END$$

DELIMITER ;

-- ─────────────────────────────────────────────
--  SP: sp_crear_unidad_compra
--  Inserta una nueva unidad de presentación para
--  compras (uso = 'compra' o 'ambos').
-- ─────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_crear_unidad_compra;

DELIMITER $$
CREATE PROCEDURE sp_crear_unidad_compra(
    IN  p_id_materia    INT,
    IN  p_nombre        VARCHAR(80),
    IN  p_simbolo       VARCHAR(20),
    IN  p_factor_a_base DECIMAL(14,6),
    IN  p_uso           VARCHAR(10),
    OUT p_id_unidad     INT
)
BEGIN
    IF p_factor_a_base <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El factor debe ser mayor a 0.';
    END IF;
    IF p_uso NOT IN ('compra','ambos') THEN
        SET p_uso = 'compra';
    END IF;

    -- Verificar duplicado antes de insertar
    IF EXISTS (
        SELECT 1 FROM unidades_presentacion
        WHERE id_materia = p_id_materia
          AND simbolo COLLATE utf8mb4_0900_ai_ci = p_simbolo COLLATE utf8mb4_0900_ai_ci
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe una unidad con ese símbolo para esta materia prima. Usa un símbolo diferente (ej. caja360, saco50).';
    END IF;

    INSERT INTO unidades_presentacion (id_materia, nombre, simbolo, factor_a_base, uso, activo, creado_en)
    VALUES (p_id_materia, p_nombre, p_simbolo, p_factor_a_base, p_uso, TRUE, NOW());

    SET p_id_unidad = LAST_INSERT_ID();
END$$

DELIMITER ;


