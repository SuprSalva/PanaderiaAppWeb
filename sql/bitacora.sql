-- ============================================================
-- bitacora.sql  –  Auditoría completa de acciones del sistema
-- DulceMigaja  –  MySQL 8.0+
-- ============================================================
-- Ejecutar DESPUÉS de DulceMigaja.sql y db_roles_permisos_v2.sql
--
-- Estrategia:
--   • Triggers AFTER INSERT/UPDATE/DELETE capturan cambios en BD
--     sin depender de que el código Python recuerde llamar nada.
--   • La variable de sesión @dm_user_id (inyectada por Flask en
--     cada role_connection()) identifica al usuario autenticado.
--   • sp_bitacora_log permite registrar eventos que los triggers
--     no pueden capturar (login, logout, errores de aplicación).
-- ============================================================
-- Nota: ip_address fue eliminada del diseño.

USE dulce_migaja;

-- ──────────────────────────────────────────────────────────────
-- 1. TABLA BITÁCORA
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bitacora (
    id_log        BIGINT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,
    id_usuario    INT              NULL                           COMMENT 'FK a usuarios; NULL = sistema/anónimo',
    fecha_hora    DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    modulo        VARCHAR(60)      NOT NULL                       COMMENT 'Nombre visible: Compras, Pedidos, …',
    tabla         VARCHAR(60)      NOT NULL                       COMMENT 'Nombre real de la tabla afectada',
    accion        VARCHAR(30)      NOT NULL                       COMMENT 'CREAR, EDITAR, ELIMINAR, ACTIVAR, APROBAR, …',
    id_registro   VARCHAR(100)     NULL                           COMMENT 'PK del registro afectado (como string)',
    descripcion   TEXT             NULL                           COMMENT 'Resumen legible para el panel',
    datos_ant     JSON             NULL                           COMMENT 'Campos relevantes ANTES del cambio (UPDATE/DELETE)',
    datos_nuevo   JSON             NULL                           COMMENT 'Campos relevantes DESPUÉS del cambio (INSERT/UPDATE)',

    INDEX idx_bit_usuario  (id_usuario),
    INDEX idx_bit_fecha    (fecha_hora),
    INDEX idx_bit_modulo   (modulo),
    INDEX idx_bit_tabla    (tabla),
    INDEX idx_bit_accion   (accion),

    CONSTRAINT fk_bit_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Bitácora de auditoría — todos los cambios relevantes del sistema';


-- ──────────────────────────────────────────────────────────────
-- 2. VISTA ENRIQUECIDA  (panel de administración)
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_bitacora AS
SELECT
    b.id_log,
    b.fecha_hora,
    COALESCE(u.nombre_completo, '(sistema)')  AS nombre_usuario,
    u.username,
    COALESCE(r.nombre_rol, '—')               AS rol,
    b.modulo,
    b.tabla,
    b.accion,
    b.id_registro,
    b.descripcion,
    b.datos_ant,
    b.datos_nuevo
FROM  bitacora b
LEFT  JOIN usuarios u ON u.id_usuario = b.id_usuario
LEFT  JOIN roles    r ON r.id_rol     = u.id_rol
ORDER BY b.fecha_hora DESC;


-- ──────────────────────────────────────────────────────────────
-- 3. SP HELPER  (llamable desde Flask o desde otros SPs)
--    Lee @dm_user_id que Flask inyecta en cada role_connection()
-- ──────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_bitacora_log;
DELIMITER //
CREATE PROCEDURE sp_bitacora_log(
    IN p_modulo      VARCHAR(60),
    IN p_tabla       VARCHAR(60),
    IN p_accion      VARCHAR(30),
    IN p_id_registro VARCHAR(100),
    IN p_descripcion TEXT,
    IN p_datos_ant   JSON,
    IN p_datos_nuevo JSON
)
BEGIN
    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_ant, datos_nuevo)
    VALUES
        (@dm_user_id, p_modulo, p_tabla, p_accion,
         p_id_registro, p_descripcion, p_datos_ant, p_datos_nuevo);
END //
DELIMITER ;


-- ──────────────────────────────────────────────────────────────
-- 4. SP DE CONSULTA CON FILTROS  (para el panel admin)
--    Devuelve dos result-sets: filas + total para paginación
-- ──────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_bitacora_consultar;
DELIMITER //
CREATE PROCEDURE sp_bitacora_consultar(
    IN p_id_usuario  INT,          -- filtrar por usuario  (NULL = todos)
    IN p_modulo      VARCHAR(60),  -- filtrar por módulo   (NULL = todos)
    IN p_accion      VARCHAR(30),  -- filtrar por acción   (NULL = todas)
    IN p_fecha_ini   DATE,         -- desde fecha          (NULL = sin límite)
    IN p_fecha_fin   DATE,         -- hasta fecha          (NULL = sin límite)
    IN p_buscar      VARCHAR(200), -- texto libre          (NULL = sin filtro)
    IN p_limit       INT,
    IN p_offset      INT
)
BEGIN
    -- ── Resultado paginado ──
    SELECT
        b.id_log,
        b.fecha_hora,
        COALESCE(u.nombre_completo, '(sistema)') AS nombre_usuario,
        u.username,
        COALESCE(r.nombre_rol, '—')              AS rol,
        b.modulo,
        b.tabla,
        b.accion,
        b.id_registro,
        b.descripcion,
        b.datos_ant,
        b.datos_nuevo
    FROM bitacora b
    LEFT JOIN usuarios u ON u.id_usuario = b.id_usuario
    LEFT JOIN roles    r ON r.id_rol     = u.id_rol
    WHERE
        (p_id_usuario IS NULL OR b.id_usuario = p_id_usuario)
        AND (p_modulo   IS NULL OR b.modulo    = p_modulo)
        AND (p_accion   IS NULL OR b.accion    = p_accion)
        AND (p_fecha_ini IS NULL OR DATE(b.fecha_hora) >= p_fecha_ini)
        AND (p_fecha_fin IS NULL OR DATE(b.fecha_hora) <= p_fecha_fin)
        AND (p_buscar IS NULL
             OR b.descripcion        LIKE CONCAT('%', p_buscar, '%')
             OR u.nombre_completo    LIKE CONCAT('%', p_buscar, '%')
             OR b.id_registro        LIKE CONCAT('%', p_buscar, '%'))
    ORDER BY b.fecha_hora DESC
    LIMIT  p_limit
    OFFSET p_offset;

    -- ── Total para paginación ──
    SELECT COUNT(*) AS total
    FROM bitacora b
    LEFT JOIN usuarios u ON u.id_usuario = b.id_usuario
    WHERE
        (p_id_usuario IS NULL OR b.id_usuario = p_id_usuario)
        AND (p_modulo   IS NULL OR b.modulo    = p_modulo)
        AND (p_accion   IS NULL OR b.accion    = p_accion)
        AND (p_fecha_ini IS NULL OR DATE(b.fecha_hora) >= p_fecha_ini)
        AND (p_fecha_fin IS NULL OR DATE(b.fecha_hora) <= p_fecha_fin)
        AND (p_buscar IS NULL
             OR b.descripcion        LIKE CONCAT('%', p_buscar, '%')
             OR u.nombre_completo    LIKE CONCAT('%', p_buscar, '%')
             OR b.id_registro        LIKE CONCAT('%', p_buscar, '%'));
END //
DELIMITER ;


-- ──────────────────────────────────────────────────────────────
-- 5. TRIGGERS
-- ──────────────────────────────────────────────────────────────
-- Convención:   tr_<tabla>_<ins|upd|del>
-- @dm_user_id = variable de sesión MySQL inyectada por Flask
--               en cada role_connection().  Puede ser NULL si la
--               operación la ejecuta un job/script sin sesión.
-- Los triggers se ejecutan con DEFINER=root (SQL SECURITY DEFINER)
-- por lo que no necesitan que los usuarios de rol tengan INSERT
-- directo en la tabla bitacora.
-- ──────────────────────────────────────────────────────────────


-- ═══════════════ USUARIOS ════════════════════════════════════
DROP TRIGGER IF EXISTS tr_usuarios_ins;
DELIMITER //
CREATE TRIGGER tr_usuarios_ins
AFTER INSERT ON usuarios FOR EACH ROW
BEGIN
    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Usuarios', 'usuarios', 'CREAR',
        NEW.id_usuario,
        CONCAT('Nuevo usuario: ', NEW.username, ' — ', NEW.nombre_completo),
        JSON_OBJECT(
            'username',        NEW.username,
            'nombre_completo', NEW.nombre_completo,
            'id_rol',          NEW.id_rol,
            'estatus',         NEW.estatus
        )
    );
END //
DELIMITER ;

DROP TRIGGER IF EXISTS tr_usuarios_upd;
DELIMITER //
CREATE TRIGGER tr_usuarios_upd
AFTER UPDATE ON usuarios FOR EACH ROW
BEGIN
    DECLARE v_accion VARCHAR(30);

    SET v_accion = CASE
        WHEN OLD.estatus != NEW.estatus
            THEN IF(NEW.estatus = 'activo', 'ACTIVAR', 'DESACTIVAR')
        WHEN OLD.id_rol != NEW.id_rol
            THEN 'CAMBIAR ROL'
        ELSE 'EDITAR'
    END;

    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_ant, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Usuarios', 'usuarios', v_accion,
        NEW.id_usuario,
        CONCAT('Usuario actualizado: ', NEW.username, ' — acción: ', v_accion),
        JSON_OBJECT(
            'username',        OLD.username,
            'nombre_completo', OLD.nombre_completo,
            'id_rol',          OLD.id_rol,
            'estatus',         OLD.estatus
        ),
        JSON_OBJECT(
            'username',        NEW.username,
            'nombre_completo', NEW.nombre_completo,
            'id_rol',          NEW.id_rol,
            'estatus',         NEW.estatus
        )
    );
END //
DELIMITER ;

DROP TRIGGER IF EXISTS tr_usuarios_del;
DELIMITER //
CREATE TRIGGER tr_usuarios_del
AFTER DELETE ON usuarios FOR EACH ROW
BEGIN
    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_ant)
    VALUES (
        @dm_user_id,
        'Usuarios', 'usuarios', 'ELIMINAR',
        OLD.id_usuario,
        CONCAT('Usuario eliminado: ', OLD.username, ' — ', OLD.nombre_completo),
        JSON_OBJECT(
            'username',        OLD.username,
            'nombre_completo', OLD.nombre_completo,
            'id_rol',          OLD.id_rol,
            'estatus',         OLD.estatus
        )
    );
END //
DELIMITER ;


-- ═══════════════ MATERIAS PRIMAS ═════════════════════════════
DROP TRIGGER IF EXISTS tr_mat_prima_ins;
DELIMITER //
CREATE TRIGGER tr_mat_prima_ins
AFTER INSERT ON materias_primas FOR EACH ROW
BEGIN
    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Materias Primas', 'materias_primas', 'CREAR',
        NEW.id_materia,
        CONCAT('Nueva materia prima: ', NEW.nombre),
        JSON_OBJECT(
            'nombre',       NEW.nombre,
            'categoria',    NEW.categoria,
            'unidad_base',  NEW.unidad_base,
            'stock_minimo', NEW.stock_minimo,
            'estatus',      NEW.estatus
        )
    );
END //
DELIMITER ;

DROP TRIGGER IF EXISTS tr_mat_prima_upd;
DELIMITER //
CREATE TRIGGER tr_mat_prima_upd
AFTER UPDATE ON materias_primas FOR EACH ROW
BEGIN
    DECLARE v_accion VARCHAR(30);
    DECLARE v_desc   TEXT;

    IF OLD.estatus != NEW.estatus THEN
        SET v_accion = IF(NEW.estatus = 'activo', 'ACTIVAR', 'DESACTIVAR');
        SET v_desc   = CONCAT('Cambio estatus MP: ', NEW.nombre, ' → ', NEW.estatus);
    ELSEIF OLD.stock_actual != NEW.stock_actual THEN
        SET v_accion = 'ACTUALIZAR STOCK';
        SET v_desc   = CONCAT('Stock MP: ', NEW.nombre,
                              '  ', OLD.stock_actual, ' → ', NEW.stock_actual,
                              ' ', NEW.unidad_base);
    ELSE
        SET v_accion = 'EDITAR';
        SET v_desc   = CONCAT('Actualización MP: ', NEW.nombre);
    END IF;

    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_ant, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Materias Primas', 'materias_primas', v_accion,
        NEW.id_materia, v_desc,
        JSON_OBJECT(
            'nombre',       OLD.nombre,
            'estatus',      OLD.estatus,
            'stock_actual', OLD.stock_actual,
            'stock_minimo', OLD.stock_minimo
        ),
        JSON_OBJECT(
            'nombre',       NEW.nombre,
            'estatus',      NEW.estatus,
            'stock_actual', NEW.stock_actual,
            'stock_minimo', NEW.stock_minimo
        )
    );
END //
DELIMITER ;


-- ═══════════════ PROVEEDORES ══════════════════════════════════
DROP TRIGGER IF EXISTS tr_proveedores_ins;
DELIMITER //
CREATE TRIGGER tr_proveedores_ins
AFTER INSERT ON proveedores FOR EACH ROW
BEGIN
    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Proveedores', 'proveedores', 'CREAR',
        NEW.id_proveedor,
        CONCAT('Nuevo proveedor: ', NEW.nombre),
        JSON_OBJECT(
            'nombre',   NEW.nombre,
            'telefono', NEW.telefono,
            'estatus',  NEW.estatus
        )
    );
END //
DELIMITER ;

DROP TRIGGER IF EXISTS tr_proveedores_upd;
DELIMITER //
CREATE TRIGGER tr_proveedores_upd
AFTER UPDATE ON proveedores FOR EACH ROW
BEGIN
    DECLARE v_accion VARCHAR(30);

    SET v_accion = IF(OLD.estatus != NEW.estatus,
                      IF(NEW.estatus = 'activo', 'ACTIVAR', 'DESACTIVAR'),
                      'EDITAR');

    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_ant, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Proveedores', 'proveedores', v_accion,
        NEW.id_proveedor,
        CONCAT('Proveedor actualizado: ', NEW.nombre),
        JSON_OBJECT('nombre', OLD.nombre, 'telefono', OLD.telefono, 'estatus', OLD.estatus),
        JSON_OBJECT('nombre', NEW.nombre, 'telefono', NEW.telefono, 'estatus', NEW.estatus)
    );
END //
DELIMITER ;


-- ═══════════════ PRODUCTOS ════════════════════════════════════
DROP TRIGGER IF EXISTS tr_productos_ins;
DELIMITER //
CREATE TRIGGER tr_productos_ins
AFTER INSERT ON productos FOR EACH ROW
BEGIN
    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Productos', 'productos', 'CREAR',
        NEW.id_producto,
        CONCAT('Nuevo producto: ', NEW.nombre),
        JSON_OBJECT(
            'nombre',       NEW.nombre,
            'precio_venta', NEW.precio_venta,
            'estatus',      NEW.estatus
        )
    );
END //
DELIMITER ;

DROP TRIGGER IF EXISTS tr_productos_upd;
DELIMITER //
CREATE TRIGGER tr_productos_upd
AFTER UPDATE ON productos FOR EACH ROW
BEGIN
    DECLARE v_accion VARCHAR(30);

    SET v_accion = CASE
        WHEN OLD.estatus != NEW.estatus
            THEN IF(NEW.estatus = 'activo', 'ACTIVAR', 'DESACTIVAR')
        WHEN OLD.precio_venta != NEW.precio_venta
            THEN 'CAMBIAR PRECIO'
        ELSE 'EDITAR'
    END;

    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_ant, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Productos', 'productos', v_accion,
        NEW.id_producto,
        CONCAT('Producto actualizado: ', NEW.nombre),
        JSON_OBJECT('nombre', OLD.nombre, 'precio_venta', OLD.precio_venta, 'estatus', OLD.estatus),
        JSON_OBJECT('nombre', NEW.nombre, 'precio_venta', NEW.precio_venta, 'estatus', NEW.estatus)
    );
END //
DELIMITER ;


-- ═══════════════ RECETAS ═════════════════════════════════════
DROP TRIGGER IF EXISTS tr_recetas_ins;
DELIMITER //
CREATE TRIGGER tr_recetas_ins
AFTER INSERT ON recetas FOR EACH ROW
BEGIN
    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Recetas', 'recetas', 'CREAR',
        NEW.id_receta,
        CONCAT('Nueva receta: ', NEW.nombre),
        JSON_OBJECT(
            'nombre',              NEW.nombre,
            'id_producto',         NEW.id_producto,
            'rendimiento',         NEW.rendimiento,
            'unidad_rendimiento',  NEW.unidad_rendimiento,
            'precio_venta',        NEW.precio_venta,
            'estatus',             NEW.estatus
        )
    );
END //
DELIMITER ;

DROP TRIGGER IF EXISTS tr_recetas_upd;
DELIMITER //
CREATE TRIGGER tr_recetas_upd
AFTER UPDATE ON recetas FOR EACH ROW
BEGIN
    DECLARE v_accion VARCHAR(30);

    SET v_accion = IF(OLD.estatus != NEW.estatus,
                      IF(NEW.estatus = 'activo', 'ACTIVAR', 'DESACTIVAR'),
                      'EDITAR');

    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_ant, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Recetas', 'recetas', v_accion,
        NEW.id_receta,
        CONCAT('Receta actualizada: ', NEW.nombre),
        JSON_OBJECT('nombre', OLD.nombre, 'rendimiento', OLD.rendimiento,
                    'precio_venta', OLD.precio_venta, 'estatus', OLD.estatus),
        JSON_OBJECT('nombre', NEW.nombre, 'rendimiento', NEW.rendimiento,
                    'precio_venta', NEW.precio_venta, 'estatus', NEW.estatus)
    );
END //
DELIMITER ;


-- ═══════════════ COMPRAS ═════════════════════════════════════
DROP TRIGGER IF EXISTS tr_compras_ins;
DELIMITER //
CREATE TRIGGER tr_compras_ins
AFTER INSERT ON compras FOR EACH ROW
BEGIN
    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Compras', 'compras', 'CREAR',
        NEW.id_compra,
        CONCAT('Nueva compra: ', NEW.folio),
        JSON_OBJECT(
            'folio',         NEW.folio,
            'id_proveedor',  NEW.id_proveedor,
            'fecha_compra',  NEW.fecha_compra,
            'total',         NEW.total,
            'estatus',       NEW.estatus
        )
    );
END //
DELIMITER ;

DROP TRIGGER IF EXISTS tr_compras_upd;
DELIMITER //
CREATE TRIGGER tr_compras_upd
AFTER UPDATE ON compras FOR EACH ROW
BEGIN
    DECLARE v_accion VARCHAR(30);
    DECLARE v_desc   TEXT;

    IF OLD.estatus != NEW.estatus THEN
        SET v_accion = CASE NEW.estatus
            WHEN 'finalizado' THEN 'FINALIZAR'
            WHEN 'cancelado'  THEN 'CANCELAR'
            ELSE                   'EDITAR'
        END;
        SET v_desc = CONCAT('Compra ', v_accion, ': ', NEW.folio);
    ELSE
        SET v_accion = 'EDITAR';
        SET v_desc   = CONCAT('Compra editada: ', NEW.folio);
    END IF;

    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_ant, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Compras', 'compras', v_accion,
        NEW.id_compra, v_desc,
        JSON_OBJECT('folio', OLD.folio, 'estatus', OLD.estatus, 'total', OLD.total),
        JSON_OBJECT('folio', NEW.folio, 'estatus', NEW.estatus, 'total', NEW.total)
    );
END //
DELIMITER ;


-- ═══════════════ PEDIDOS ═════════════════════════════════════
DROP TRIGGER IF EXISTS tr_pedidos_ins;
DELIMITER //
CREATE TRIGGER tr_pedidos_ins
AFTER INSERT ON pedidos FOR EACH ROW
BEGIN
    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Pedidos', 'pedidos', 'CREAR',
        NEW.id_pedido,
        CONCAT('Nuevo pedido: ', NEW.folio),
        JSON_OBJECT(
            'folio',           NEW.folio,
            'id_cliente',      NEW.id_cliente,
            'estado',          NEW.estado,
            'total_estimado',  NEW.total_estimado,
            'fecha_recogida',  NEW.fecha_recogida,
            'metodo_pago',     NEW.metodo_pago
        )
    );
END //
DELIMITER ;

DROP TRIGGER IF EXISTS tr_pedidos_upd;
DELIMITER //
CREATE TRIGGER tr_pedidos_upd
AFTER UPDATE ON pedidos FOR EACH ROW
BEGIN
    DECLARE v_accion VARCHAR(30);
    DECLARE v_desc   TEXT;

    IF OLD.estado != NEW.estado THEN
        SET v_accion = CASE NEW.estado
            WHEN 'aprobado'          THEN 'APROBAR'
            WHEN 'rechazado'         THEN 'RECHAZAR'
            WHEN 'en_produccion'     THEN 'INICIAR PRODUCCIÓN'
            WHEN 'pendiente_insumos' THEN 'PENDIENTE INSUMOS'
            WHEN 'listo'             THEN 'MARCAR LISTO'
            WHEN 'entregado'         THEN 'ENTREGAR'
            ELSE                          'EDITAR'
        END;
        SET v_desc = CONCAT('Pedido ', v_accion, ': ', NEW.folio,
                            '  ', OLD.estado, ' → ', NEW.estado);
    ELSE
        SET v_accion = 'EDITAR';
        SET v_desc   = CONCAT('Pedido editado: ', NEW.folio);
    END IF;

    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_ant, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Pedidos', 'pedidos', v_accion,
        NEW.id_pedido, v_desc,
        JSON_OBJECT('folio', OLD.folio, 'estado', OLD.estado,
                    'total_estimado', OLD.total_estimado),
        JSON_OBJECT('folio', NEW.folio, 'estado', NEW.estado,
                    'total_estimado', NEW.total_estimado)
    );
END //
DELIMITER ;


-- ═══════════════ PRODUCCIÓN DIARIA ═══════════════════════════
DROP TRIGGER IF EXISTS tr_prod_diaria_ins;
DELIMITER //
CREATE TRIGGER tr_prod_diaria_ins
AFTER INSERT ON produccion_diaria FOR EACH ROW
BEGIN
    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Producción Diaria', 'produccion_diaria', 'CREAR',
        NEW.id_pd,
        CONCAT('Nueva producción diaria: ', NEW.folio, ' — ', NEW.nombre),
        JSON_OBJECT(
            'folio',   NEW.folio,
            'nombre',  NEW.nombre,
            'estado',  NEW.estado,
            'operario_id', NEW.operario_id
        )
    );
END //
DELIMITER ;

DROP TRIGGER IF EXISTS tr_prod_diaria_upd;
DELIMITER //
CREATE TRIGGER tr_prod_diaria_upd
AFTER UPDATE ON produccion_diaria FOR EACH ROW
BEGIN
    DECLARE v_accion VARCHAR(30);

    IF OLD.estado != NEW.estado THEN
        SET v_accion = CASE NEW.estado
            WHEN 'en_proceso'  THEN 'INICIAR'
            WHEN 'finalizado'  THEN 'FINALIZAR'
            WHEN 'cancelado'   THEN 'CANCELAR'
            ELSE                    'EDITAR'
        END;
    ELSE
        SET v_accion = 'EDITAR';
    END IF;

    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_ant, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Producción Diaria', 'produccion_diaria', v_accion,
        NEW.id_pd,
        CONCAT('Producción ', v_accion, ': ', NEW.folio,
               IF(OLD.estado != NEW.estado,
                  CONCAT('  ', OLD.estado, ' → ', NEW.estado), '')),
        JSON_OBJECT('folio', OLD.folio, 'estado', OLD.estado,
                    'motivo_cancelacion', OLD.motivo_cancelacion),
        JSON_OBJECT('folio', NEW.folio, 'estado', NEW.estado,
                    'motivo_cancelacion', NEW.motivo_cancelacion)
    );
END //
DELIMITER ;


-- ═══════════════ SALIDAS DE EFECTIVO ════════════════════════
DROP TRIGGER IF EXISTS tr_salidas_efectivo_ins;
DELIMITER //
CREATE TRIGGER tr_salidas_efectivo_ins
AFTER INSERT ON salidas_efectivo FOR EACH ROW
BEGIN
    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Salida de Efectivo', 'salidas_efectivo', 'CREAR',
        NEW.id_salida,
        CONCAT('Nueva salida efectivo: ', NEW.folio_salida,
               '  $', NEW.monto, ' — ', NEW.descripcion),
        JSON_OBJECT(
            'folio_salida', NEW.folio_salida,
            'categoria',    NEW.categoria,
            'monto',        NEW.monto,
            'descripcion',  NEW.descripcion,
            'estado',       NEW.estado
        )
    );
END //
DELIMITER ;

DROP TRIGGER IF EXISTS tr_salidas_efectivo_upd;
DELIMITER //
CREATE TRIGGER tr_salidas_efectivo_upd
AFTER UPDATE ON salidas_efectivo FOR EACH ROW
BEGIN
    DECLARE v_accion VARCHAR(30);

    SET v_accion = CASE
        WHEN OLD.estado != NEW.estado AND NEW.estado = 'aprobada'  THEN 'APROBAR'
        WHEN OLD.estado != NEW.estado AND NEW.estado = 'rechazada' THEN 'RECHAZAR'
        ELSE 'EDITAR'
    END;

    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_ant, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Salida de Efectivo', 'salidas_efectivo', v_accion,
        NEW.id_salida,
        CONCAT('Salida efectivo ', v_accion, ': ', NEW.folio_salida),
        JSON_OBJECT('folio_salida', OLD.folio_salida, 'monto', OLD.monto, 'estado', OLD.estado),
        JSON_OBJECT('folio_salida', NEW.folio_salida, 'monto', NEW.monto, 'estado', NEW.estado)
    );
END //
DELIMITER ;


-- ═══════════════ MERMAS ══════════════════════════════════════
DROP TRIGGER IF EXISTS tr_mermas_ins;
DELIMITER //
CREATE TRIGGER tr_mermas_ins
AFTER INSERT ON mermas FOR EACH ROW
BEGIN
    INSERT INTO bitacora
        (id_usuario, modulo, tabla, accion, id_registro, descripcion, datos_nuevo)
    VALUES (
        @dm_user_id,
        'Mermas', 'mermas', 'REGISTRAR',
        NEW.id_merma,
        CONCAT('Merma registrada — tipo: ', NEW.tipo_objeto,
               '  id_ref: ', NEW.id_referencia,
               '  cantidad: ', NEW.cantidad, ' ', NEW.unidad,
               '  causa: ', NEW.causa),
        JSON_OBJECT(
            'tipo_objeto',   NEW.tipo_objeto,
            'id_referencia', NEW.id_referencia,
            'cantidad',      NEW.cantidad,
            'unidad',        NEW.unidad,
            'causa',         NEW.causa
        )
    );
END //
DELIMITER ;


-- ──────────────────────────────────────────────────────────────
-- 6. PERMISOS
-- Triggers: DEFINER=root, SQL SECURITY DEFINER → los usuarios de
--   rol no necesitan INSERT en bitacora; los triggers se ejecutan
--   con los privilegios del creador (root).
-- SPs: ejecutados por Flask bajo el usuario de rol; necesitan EXECUTE.
-- Vistas: solo el admin necesita SELECT para el panel.
-- ──────────────────────────────────────────────────────────────

-- SELECT en tabla + vista solo para admin
GRANT SELECT ON dulce_migaja.bitacora    TO rol_admin;
GRANT SELECT ON dulce_migaja.vw_bitacora TO rol_admin;

-- SP de consulta: solo admin
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_bitacora_consultar TO rol_admin;

-- SP helper de registro: todos los roles (para login/logout y eventos manuales)
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_bitacora_log TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_bitacora_log TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_bitacora_log TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_bitacora_log TO rol_cliente;

FLUSH PRIVILEGES;
