-- ============================================================
-- MÓDULO: RESPALDO Y RESTAURACIÓN DE BASE DE DATOS
-- Usuarios MySQL con permisos mínimos necesarios
-- ============================================================

-- ── Usuario para respaldo (mysqldump) ────────────────────────
-- Necesita: SELECT (leer datos), SHOW VIEW (exportar vistas),
--           TRIGGER (exportar triggers), LOCK TABLES (consistencia),
--           RELOAD (FLUSH TABLES), PROCESS (ver estado del servidor)

DROP USER IF EXISTS 'dm_backup'@'localhost';

CREATE USER 'dm_backup'@'localhost'
    IDENTIFIED BY 'Bkp!DulceMigaja2024#';

-- SELECT: leer todos los datos
-- SHOW VIEW: exportar vistas
-- TRIGGER: exportar triggers
-- LOCK TABLES: consistencia durante el dump
-- RELOAD: FLUSH TABLES
-- PROCESS: ver estado del servidor
-- (EVENT no es necesario — mysqldump usa --no-tablespaces, no --events)
GRANT SELECT, SHOW VIEW, TRIGGER, LOCK TABLES, RELOAD, PROCESS
    ON *.*
    TO 'dm_backup'@'localhost';

-- ── Usuario para restauración (mysql client) ─────────────────
-- Necesita permisos completos sobre la base de datos objetivo
-- más RELOAD y PROCESS para poder ejecutar FLUSH PRIVILEGES

DROP USER IF EXISTS 'dm_restore'@'localhost';

CREATE USER 'dm_restore'@'localhost'
    IDENTIFIED BY 'Rst!DulceMigaja2024#';

GRANT ALL PRIVILEGES
    ON dulce_migaja.*
    TO 'dm_restore'@'localhost';

-- RELOAD, PROCESS: necesarios para operaciones de servidor
-- SYSTEM_VARIABLES_ADMIN: permite SET GLOBAL log_bin_trust_function_creators
--   que es necesario para restaurar stored procedures/triggers con binary log activo
-- RELOAD, PROCESS: operaciones de servidor
-- SYSTEM_VARIABLES_ADMIN: SET GLOBAL log_bin_trust_function_creators
-- SYSTEM_USER: restaurar objetos cuyo DEFINER tiene ese privilegio (MySQL 8+)
GRANT RELOAD, PROCESS, SYSTEM_VARIABLES_ADMIN, SYSTEM_USER
    ON *.*
    TO 'dm_restore'@'localhost';

FLUSH PRIVILEGES;

-- ── Verificación ─────────────────────────────────────────────
-- SHOW GRANTS FOR 'dm_backup'@'localhost';
-- SHOW GRANTS FOR 'dm_restore'@'localhost';
