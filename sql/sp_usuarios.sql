-- ═══════════════════════════════════════════════════════════
--  Procedimientos almacenados — Módulo Usuarios
--  Base de datos: dulce_migaja
--  Ejecutar como root en MySQL Workbench
-- ═══════════════════════════════════════════════════════════

USE dulce_migaja;

ALTER TABLE usuarios
    ADD COLUMN telefono VARCHAR(20) NULL AFTER nombre_completo;

-- ─────────────────────────────────────────────
--  SP: sp_crear_usuario
-- ─────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_crear_usuario;

DELIMITER $$

CREATE PROCEDURE sp_crear_usuario(
    IN  p_uuid            VARCHAR(36)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_nombre_completo VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_username        VARCHAR(60)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_password_hash   VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_id_rol          SMALLINT,
    IN  p_estatus         VARCHAR(10)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_creado_por      INT
)
BEGIN
    -- Verificar que el username no esté duplicado
    IF EXISTS (SELECT 1 FROM usuarios WHERE username = p_username) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre de usuario ya esta en uso.';
    END IF;

    -- Verificar que el rol exista
    IF NOT EXISTS (SELECT 1 FROM roles WHERE id_rol = p_id_rol) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El rol seleccionado no es valido.';
    END IF;

    INSERT INTO usuarios (
        uuid_usuario,
        nombre_completo,
        username,
        password_hash,
        id_rol,
        estatus,
        intentos_fallidos,
        cambio_pwd_req,
        creado_en,
        actualizado_en,
        creado_por
    ) VALUES (
        p_uuid,
        p_nombre_completo,
        p_username,
        p_password_hash,
        p_id_rol,
        p_estatus,
        0,
        0,
        NOW(),
        NOW(),
        p_creado_por
    );
END$$

DELIMITER ;


-- ─────────────────────────────────────────────
--  SP: sp_editar_usuario
--  Actualiza datos de un usuario existente.
--  Si p_password_hash es NULL no cambia la contraseña.
-- ─────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_editar_usuario;

DELIMITER $$

CREATE PROCEDURE sp_editar_usuario(
    IN  p_id_usuario      INT,
    IN  p_nombre_completo VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_username        VARCHAR(60)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_id_rol          SMALLINT,
    IN  p_estatus         VARCHAR(10)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_password_hash   VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci
)
BEGIN
    -- Verificar que el usuario exista
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id_usuario = p_id_usuario) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El usuario no existe.';
    END IF;

    -- Verificar que el username no lo use OTRO usuario
    IF EXISTS (SELECT 1 FROM usuarios WHERE username = p_username AND id_usuario <> p_id_usuario) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre de usuario ya esta en uso.';
    END IF;

    -- Verificar que el rol exista
    IF NOT EXISTS (SELECT 1 FROM roles WHERE id_rol = p_id_rol) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El rol seleccionado no es valido.';
    END IF;

    IF p_password_hash IS NOT NULL THEN
        UPDATE usuarios
        SET nombre_completo = p_nombre_completo,
            username        = p_username,
            id_rol          = p_id_rol,
            estatus         = p_estatus,
            password_hash   = p_password_hash,
            actualizado_en  = NOW()
        WHERE id_usuario = p_id_usuario;
    ELSE
        UPDATE usuarios
        SET nombre_completo = p_nombre_completo,
            username        = p_username,
            id_rol          = p_id_rol,
            estatus         = p_estatus,
            actualizado_en  = NOW()
        WHERE id_usuario = p_id_usuario;
    END IF;
END$$

DELIMITER ;

-- ─────────────────────────────────────────────
--  SP: sp_cambiar_estatus_usuario
--  Activa o desactiva un usuario (baja lógica).
--  Impide que un usuario se desactive a sí mismo.
-- ─────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_cambiar_estatus_usuario;

DELIMITER $$

CREATE PROCEDURE sp_cambiar_estatus_usuario(
    IN  p_id_usuario     INT,
    IN  p_nuevo_estatus  VARCHAR(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_ejecutado_por  INT
)
BEGIN
    -- No permitir que el usuario se desactive a sí mismo
    IF p_id_usuario = p_ejecutado_por AND p_nuevo_estatus <> 'activo' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No puedes desactivar tu propia cuenta.';
    END IF;

    -- Verificar que el usuario exista
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id_usuario = p_id_usuario) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El usuario no existe.';
    END IF;

    UPDATE usuarios
    SET estatus        = p_nuevo_estatus,
        actualizado_en = NOW()
    WHERE id_usuario = p_id_usuario;
END$$

DELIMITER ;


-- ─────────────────────────────────────────────
--  SP: sp_cambiar_password
--  Cambia la contraseña de cualquier usuario
--  autenticado, recibiendo el nuevo hash ya
--  generado desde Python.
-- ─────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_cambiar_password;

DELIMITER $$

CREATE PROCEDURE sp_cambiar_password(
    IN p_id_usuario    INT,
    IN p_password_hash VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id_usuario = p_id_usuario) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El usuario no existe.';
    END IF;

    UPDATE usuarios
    SET password_hash  = p_password_hash,
        actualizado_en = NOW()
    WHERE id_usuario = p_id_usuario;
END$$

DELIMITER ;


-- ─────────────────────────────────────────────
--  SP: sp_actualizar_perfil_cliente
--  Permite al propio cliente actualizar su
--  nombre, username y teléfono.
-- ─────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_actualizar_perfil_cliente;

DELIMITER $$

CREATE PROCEDURE sp_actualizar_perfil_cliente(
    IN p_id_usuario      INT,
    IN p_nombre_completo VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN p_username        VARCHAR(60)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN p_telefono        VARCHAR(20)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id_usuario = p_id_usuario) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El usuario no existe.';
    END IF;

    IF EXISTS (SELECT 1 FROM usuarios WHERE username = p_username AND id_usuario <> p_id_usuario) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre de usuario ya esta en uso.';
    END IF;

    UPDATE usuarios
    SET nombre_completo = p_nombre_completo,
        username        = p_username,
        telefono        = p_telefono,
        actualizado_en  = NOW()
    WHERE id_usuario = p_id_usuario;
END$$

DELIMITER ;


-- ─────────────────────────────────────────────
--  Usuario: admin / administrator!
-- ─────────────────────────────────────────────
INSERT IGNORE INTO usuarios (
    uuid_usuario, nombre_completo, username, password_hash,
    id_rol, estatus, intentos_fallidos, cambio_pwd_req,
    creado_en, actualizado_en, creado_por
) VALUES (
    'a2cf04f0-823d-4d4f-abfa-c3ffd1821cc4',
    'Administrador',
    'admin',
    'scrypt:32768:8:1$VTbsJzqVU7Cj9e38$898472743fa2138b164b21a3cd295d6aa0b6346049e5542befe91744c803746a7327fc5280b12e34467d0ef7e554e72f62b1b8019bf1db484f9a207428741628',
    1,
    'activo',
    0,
    0,
    NOW(),
    NOW(),
    NULL
);


-- ═══════════════════════════════════════════════════════════
--  VIEW: vw_usuarios
--  Lista de usuarios con datos del rol ya unidos.
--  Ejecutar como root en MySQL Workbench.
-- ═══════════════════════════════════════════════════════════


-- Actualizar la view para incluir telefono
CREATE OR REPLACE VIEW vw_usuarios AS
SELECT
    u.id_usuario,
    u.nombre_completo,
    u.telefono,
    u.username,
    u.id_rol,
    r.nombre_rol,
    r.clave_rol,
    u.estatus,
    u.ultimo_login,
    u.creado_en
FROM usuarios u
LEFT JOIN roles r ON u.id_rol = r.id_rol;




