-- ═══════════════════════════════════════════════════════════
--  Módulo: Proveedores — Índices, Trigger, SPs y Permisos
--  Base de datos: dulce_migaja
--  Ejecutar como root en MySQL Workbench
--
--  Contenido:
--    1. Índices adicionales en `proveedores`
--    2. Trigger  — trg_prov_before_delete
--    3. SP       — sp_crear_proveedor
--    4. SP       — sp_editar_proveedor
--    5. SP       — sp_toggle_proveedor
--    6. Permisos — GRANT EXECUTE solo a rol_admin
-- ═══════════════════════════════════════════════════════════

USE dulce_migaja;

-- ─────────────────────────────────────────────────────────
--  1. ÍNDICES
--     • idx_prov_nombre  → búsqueda/ordenamiento por nombre
--     • idx_prov_estatus → filtrado activo/inactivo
--     (uuid y rfc ya tienen índice UNIQUE en la tabla)
-- ─────────────────────────────────────────────────────────
	CREATE INDEX idx_prov_nombre ON proveedores (nombre);
	CREATE INDEX idx_prov_estatus ON proveedores (estatus);


-- ─────────────────────────────────────────────────────────
--  2. TRIGGER — trg_prov_before_delete
--     Regla de negocio: un proveedor con compras registradas
--     NO puede eliminarse (solo desactivarse con toggle).
-- ─────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS trg_prov_before_delete;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` TRIGGER trg_prov_before_delete
BEFORE DELETE ON proveedores
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM compras
        WHERE  id_proveedor = OLD.id_proveedor
        LIMIT  1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede eliminar un proveedor con compras registradas. Usa desactivar en su lugar.';
    END IF;
END ;;
DELIMITER ;


-- ─────────────────────────────────────────────────────────
--  3. SP — sp_crear_proveedor
--     Alta de un nuevo proveedor.
--     Valida: nombre obligatorio · RFC único.
--     Inserta en proveedores y deja traza en logs_sistema.
--     Retorna: id_proveedor del registro creado.
-- ─────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_crear_proveedor;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_crear_proveedor(
    IN  p_uuid        VARCHAR(36)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_nombre      VARCHAR(150)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_rfc         VARCHAR(13)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_contacto    VARCHAR(120)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_telefono    VARCHAR(20)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_email       VARCHAR(150)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_direccion   TEXT          CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_creado_por  INT
)
BEGIN
    -- Validar nombre obligatorio
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre del proveedor es obligatorio.';
    END IF;

    -- Validar RFC único (si viene informado)
    IF p_rfc IS NOT NULL AND TRIM(p_rfc) <> '' AND
       EXISTS (SELECT 1 FROM proveedores WHERE rfc = TRIM(p_rfc)) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe un proveedor registrado con ese RFC.';
    END IF;

    -- Insertar proveedor
    INSERT INTO proveedores (
        uuid_proveedor, nombre,        rfc,
        contacto,       telefono,      email,
        direccion,      estatus,       creado_en,
        actualizado_en, creado_por
    ) VALUES (
        p_uuid,
        TRIM(p_nombre),
        NULLIF(TRIM(p_rfc),       ''),
        NULLIF(TRIM(p_contacto),  ''),
        NULLIF(TRIM(p_telefono),  ''),
        NULLIF(TRIM(p_email),     ''),
        NULLIF(TRIM(p_direccion), ''),
        'activo',
        NOW(),
        NOW(),
        p_creado_por
    );

    -- Auditoría en logs_sistema
    INSERT INTO logs_sistema (
        tipo,    nivel,  id_usuario,   modulo,
        accion,  descripcion,          creado_en
    ) VALUES (
        'compra', 'INFO', p_creado_por, 'proveedores',
        'CREAR',
        CONCAT('Proveedor creado: ', TRIM(p_nombre)),
        NOW()
    );

    -- Retornar el id generado para que Flask pueda usarlo
    SELECT LAST_INSERT_ID() AS id_proveedor;
END ;;
DELIMITER ;


-- ─────────────────────────────────────────────────────────
--  4. SP — sp_editar_proveedor
--     Actualiza datos de un proveedor existente.
--     Valida: existencia · nombre obligatorio · RFC único.
-- ─────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_editar_proveedor;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_editar_proveedor(
    IN  p_id_proveedor  INT,
    IN  p_nombre        VARCHAR(150)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_rfc           VARCHAR(13)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_contacto      VARCHAR(120)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_telefono      VARCHAR(20)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_email         VARCHAR(150)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_direccion     TEXT          CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_ejecutado_por INT
)
BEGIN
    -- Verificar que el proveedor exista
    IF NOT EXISTS (SELECT 1 FROM proveedores WHERE id_proveedor = p_id_proveedor) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El proveedor no existe.';
    END IF;

    -- Validar nombre obligatorio
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre del proveedor es obligatorio.';
    END IF;

    -- Validar RFC único excluyendo el propio registro
    IF p_rfc IS NOT NULL AND TRIM(p_rfc) <> '' AND
       EXISTS (
           SELECT 1 FROM proveedores
           WHERE  rfc = TRIM(p_rfc)
             AND  id_proveedor <> p_id_proveedor
       ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe otro proveedor con ese RFC.';
    END IF;

    UPDATE proveedores
    SET nombre         = TRIM(p_nombre),
        rfc            = NULLIF(TRIM(p_rfc),       ''),
        contacto       = NULLIF(TRIM(p_contacto),  ''),
        telefono       = NULLIF(TRIM(p_telefono),  ''),
        email          = NULLIF(TRIM(p_email),     ''),
        direccion      = NULLIF(TRIM(p_direccion), ''),
        actualizado_en = NOW()
    WHERE id_proveedor = p_id_proveedor;

    -- Auditoría
    INSERT INTO logs_sistema (
        tipo,    nivel,  id_usuario,     modulo,
        accion,  descripcion,            creado_en
    ) VALUES (
        'compra', 'INFO', p_ejecutado_por, 'proveedores',
        'EDITAR',
        CONCAT('Proveedor editado: ', TRIM(p_nombre), ' (id=', p_id_proveedor, ')'),
        NOW()
    );
END ;;
DELIMITER ;


-- ─────────────────────────────────────────────────────────
--  5. SP — sp_toggle_proveedor
--     Alterna estatus activo ↔ inactivo de un proveedor.
--     No permite eliminar; solo desactivar.
--     Retorna: nuevo_estatus y nombre para el flash message.
-- ─────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_toggle_proveedor;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_toggle_proveedor(
    IN  p_id_proveedor  INT,
    IN  p_ejecutado_por INT
)
BEGIN
    DECLARE v_estatus_actual VARCHAR(10);
    DECLARE v_nombre         VARCHAR(150);
    DECLARE v_nuevo_estatus  VARCHAR(10);

    -- Leer estado actual
    SELECT estatus, nombre
    INTO   v_estatus_actual, v_nombre
    FROM   proveedores
    WHERE  id_proveedor = p_id_proveedor;

    IF v_estatus_actual IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El proveedor no existe.';
    END IF;

    SET v_nuevo_estatus = IF(v_estatus_actual = 'activo', 'inactivo', 'activo');

    UPDATE proveedores
    SET estatus        = v_nuevo_estatus,
        actualizado_en = NOW()
    WHERE id_proveedor = p_id_proveedor;

    -- Auditoría
    INSERT INTO logs_sistema (
        tipo,    nivel,  id_usuario,     modulo,
        accion,  descripcion,            creado_en
    ) VALUES (
        'compra', 'INFO', p_ejecutado_por, 'proveedores',
        'TOGGLE_ESTATUS',
        CONCAT('Proveedor "', v_nombre, '" cambiado a ', v_nuevo_estatus),
        NOW()
    );

    -- Retornar resultado para uso en Flask
    SELECT v_nuevo_estatus AS nuevo_estatus,
           v_nombre        AS nombre;
END ;;
DELIMITER ;


-- ─────────────────────────────────────────────────────────
--  6. PERMISOS
--     Solo rol_admin puede ejecutar los SPs de proveedores.
--     rol_vendedor y rol_panadero ya tienen SELECT en la tabla
--     (lectura de catálogo), pero NO pueden crear/editar.
-- ─────────────────────────────────────────────────────────
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_proveedor  TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_proveedor TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_toggle_proveedor TO rol_admin;

FLUSH PRIVILEGES;

-- Verificar
SHOW GRANTS FOR rol_admin;
