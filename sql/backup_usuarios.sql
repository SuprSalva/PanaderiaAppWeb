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

GRANT RELOAD, PROCESS
    ON *.*
    TO 'dm_restore'@'localhost';

FLUSH PRIVILEGES;

-- ── Verificación ─────────────────────────────────────────────
-- SHOW GRANTS FOR 'dm_backup'@'localhost';
-- SHOW GRANTS FOR 'dm_restore'@'localhost';
