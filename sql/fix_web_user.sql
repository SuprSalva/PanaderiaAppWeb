-- ═══════════════════════════════════════════════════════════
--  Reparar permisos de web_user
--  Ejecutar como root en MySQL Workbench
-- ═══════════════════════════════════════════════════════════

USE dulce_migaja;

-- Dar todos los permisos necesarios a web_user
-- (SELECT para lecturas del ORM, INSERT/UPDATE/DELETE para
--  escrituras directas del ORM, EXECUTE para llamar SPs)
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.* TO 'web_user'@'localhost';

-- EXECUTE en todos los procedimientos almacenados
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_usuario           TO 'web_user'@'localhost';
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_usuario          TO 'web_user'@'localhost';
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cambiar_estatus_usuario TO 'web_user'@'localhost';

FLUSH PRIVILEGES;

-- Verificar que quedó correcto
SHOW GRANTS FOR 'web_user'@'localhost';
