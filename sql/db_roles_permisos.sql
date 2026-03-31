-- ═══════════════════════════════════════════════════════════
--  Roles y Usuarios de BD — dulce_migaja
--  Ejecutar como root en MySQL Workbench
--
--  Estructura:
--    1. Eliminar roles y usuarios previos
--    2. Crear ROLES de BD con sus permisos
--    3. Crear USUARIOS de BD
--    4. Asignar ROL a cada USUARIO
--    5. Activar el rol por defecto
-- ═══════════════════════════════════════════════════════════

USE dulce_migaja;

-- ═══════════════════════════════════════════════════════════
--  1. LIMPIAR (eliminar usuarios y roles previos)
-- ═══════════════════════════════════════════════════════════

DROP USER IF EXISTS 'dm_admin'@'localhost';
DROP USER IF EXISTS 'dm_vendedor'@'localhost';
DROP USER IF EXISTS 'dm_panadero'@'localhost';
DROP USER IF EXISTS 'dm_cliente'@'localhost';

DROP ROLE IF EXISTS rol_admin;
DROP ROLE IF EXISTS rol_vendedor;
DROP ROLE IF EXISTS rol_panadero;
DROP ROLE IF EXISTS rol_cliente;


-- ═══════════════════════════════════════════════════════════
--  2. CREAR ROLES Y DARLES PERMISOS
-- ═══════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────
--  ROL: rol_admin
--  Acceso total al sistema + SPs de gestión de usuarios
-- ─────────────────────────────────────────────
CREATE ROLE rol_admin;

GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.usuarios              TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.roles                 TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.proveedores           TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.materias_primas       TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.unidades_presentacion TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.compras               TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.detalle_compras       TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.productos             TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.inventario_pt         TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.recetas               TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.detalle_recetas       TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.produccion            TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.detalle_produccion    TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.ventas                TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.detalle_ventas        TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.cortes_diarios        TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.salidas_efectivo      TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.mermas                TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.ajustes_inventario    TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.tickets               TO rol_admin;
GRANT SELECT, INSERT                 ON dulce_migaja.logs_sistema          TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.sesiones              TO rol_admin;

-- SPs exclusivos del administrador
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_usuario           TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_usuario          TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cambiar_estatus_usuario TO rol_admin;
GRANT SELECT ON dulce_migaja.vw_usuarios TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cambiar_password TO rol_admin;

SHOW GRANTS FOR rol_admin;


-- ─────────────────────────────────────────────
--  ROL: rol_vendedor
--  Ventas, cortes de caja y salidas de efectivo
-- ─────────────────────────────────────────────
CREATE ROLE rol_vendedor;

-- Catálogos (solo lectura)
GRANT SELECT ON dulce_migaja.roles                TO rol_vendedor;
GRANT SELECT ON dulce_migaja.usuarios             TO rol_vendedor;
GRANT SELECT ON dulce_migaja.productos            TO rol_vendedor;
GRANT SELECT ON dulce_migaja.inventario_pt        TO rol_vendedor;
GRANT SELECT ON dulce_migaja.recetas              TO rol_vendedor;
GRANT SELECT ON dulce_migaja.proveedores          TO rol_vendedor;
GRANT SELECT ON dulce_migaja.materias_primas      TO rol_vendedor;

-- Operaciones propias del vendedor
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.ventas           TO rol_vendedor;
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.detalle_ventas   TO rol_vendedor;
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.cortes_diarios   TO rol_vendedor;
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.salidas_efectivo TO rol_vendedor;
GRANT SELECT, INSERT         ON dulce_migaja.tickets          TO rol_vendedor;
GRANT SELECT, INSERT         ON dulce_migaja.logs_sistema     TO rol_vendedor;

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cambiar_password TO rol_vendedor;
-- SPs de ventas (descomentar cuando se creen)
-- GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_venta  TO rol_vendedor;
-- GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cerrar_corte TO rol_vendedor;

SHOW GRANTS FOR rol_vendedor;


-- ─────────────────────────────────────────────
--  ROL: rol_panadero
--  Producción, recetas e inventario de materias primas
-- ─────────────────────────────────────────────
CREATE ROLE rol_panadero;

-- Catálogos (solo lectura)
GRANT SELECT ON dulce_migaja.roles                 TO rol_panadero;
GRANT SELECT ON dulce_migaja.usuarios              TO rol_panadero;
GRANT SELECT ON dulce_migaja.productos             TO rol_panadero;
GRANT SELECT ON dulce_migaja.recetas               TO rol_panadero;
GRANT SELECT ON dulce_migaja.detalle_recetas       TO rol_panadero;
GRANT SELECT ON dulce_migaja.materias_primas       TO rol_panadero;
GRANT SELECT ON dulce_migaja.unidades_presentacion TO rol_panadero;
GRANT SELECT ON dulce_migaja.compras               TO rol_panadero;
GRANT SELECT ON dulce_migaja.detalle_compras       TO rol_panadero;

-- Operaciones propias del panadero
GRANT SELECT, INSERT, UPDATE         ON dulce_migaja.produccion          TO rol_panadero;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.detalle_produccion  TO rol_panadero;
GRANT SELECT, INSERT                 ON dulce_migaja.mermas              TO rol_panadero;
GRANT SELECT, UPDATE                 ON dulce_migaja.inventario_pt       TO rol_panadero;
GRANT SELECT, INSERT                 ON dulce_migaja.logs_sistema        TO rol_panadero;

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cambiar_password TO rol_panadero;
-- SPs de producción (descomentar cuando se creen)
-- GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_iniciar_produccion   TO rol_panadero;
-- GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_finalizar_produccion TO rol_panadero;

SHOW GRANTS FOR rol_panadero;


-- ─────────────────────────────────────────────
--  ROL: rol_cliente
--  Solo catálogo de productos (pedidos en línea)
-- ─────────────────────────────────────────────
CREATE ROLE rol_cliente;

GRANT SELECT ON dulce_migaja.productos    TO rol_cliente;
GRANT SELECT ON dulce_migaja.inventario_pt TO rol_cliente;

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cambiar_password         TO rol_cliente;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_actualizar_perfil_cliente TO rol_cliente;
-- Cuando exista la tabla de pedidos online:
-- GRANT SELECT, INSERT ON dulce_migaja.pedidos_online TO rol_cliente;

SHOW GRANTS FOR rol_cliente;


-- ═══════════════════════════════════════════════════════════
--  3. CREAR USUARIOS DE BD
-- ═══════════════════════════════════════════════════════════

CREATE USER 'dm_admin'@'localhost'    IDENTIFIED BY 'Dm@Admin2025!';
CREATE USER 'dm_vendedor'@'localhost' IDENTIFIED BY 'Dm@Vend2025!';
CREATE USER 'dm_panadero'@'localhost' IDENTIFIED BY 'Dm@Pan2025!';
CREATE USER 'dm_cliente'@'localhost'  IDENTIFIED BY 'Dm@Cli2025!';


-- ═══════════════════════════════════════════════════════════
--  4. ASIGNAR ROL A CADA USUARIO
-- ═══════════════════════════════════════════════════════════

GRANT rol_admin    TO 'dm_admin'@'localhost';
GRANT rol_vendedor TO 'dm_vendedor'@'localhost';
GRANT rol_panadero TO 'dm_panadero'@'localhost';
GRANT rol_cliente  TO 'dm_cliente'@'localhost';


-- ═══════════════════════════════════════════════════════════
--  5. ACTIVAR EL ROL POR DEFECTO EN CADA USUARIO
-- ═══════════════════════════════════════════════════════════

SET DEFAULT ROLE rol_admin    TO 'dm_admin'@'localhost';
SET DEFAULT ROLE rol_vendedor TO 'dm_vendedor'@'localhost';
SET DEFAULT ROLE rol_panadero TO 'dm_panadero'@'localhost';
SET DEFAULT ROLE rol_cliente  TO 'dm_cliente'@'localhost';


-- ═══════════════════════════════════════════════════════════
--  web_user — permisos para el ORM de Flask (lectura + EXECUTE)
--  Los otros módulos (compras, ventas, produccion, etc.) siguen
--  llamando SPs a través de web_user con db.session.execute().
--  Sin EXECUTE, esos módulos no pueden llamar ningún SP.
-- ═══════════════════════════════════════════════════════════
-- GRANT SELECT          ON dulce_migaja.* TO 'web_user'@'localhost';
-- GRANT EXECUTE         ON dulce_migaja.* TO 'web_user'@'localhost';
-- REVOKE SELECT ON dulce_migaja.* FROM 'web_user'@'localhost';
-- REVOKE EXECUTE ON dulce_migaja.* FROM 'web_user'@'localhost';
-- ─────────────────────────────────────────────
--  Refrescar privilegios
-- ─────────────────────────────────────────────
FLUSH PRIVILEGES;


-- ═══════════════════════════════════════════════════════════
--  VERIFICACIÓN
-- ═══════════════════════════════════════════════════════════

-- Ver los permisos de cada usuario
SHOW GRANTS FOR 'dm_admin'@'localhost';
SHOW GRANTS FOR 'dm_vendedor'@'localhost';
SHOW GRANTS FOR 'dm_panadero'@'localhost';
SHOW GRANTS FOR 'dm_cliente'@'localhost';

-- Ver todos los roles del sistema
-- SELECT * FROM mysql.roles_mapping;

-- ─────────────────────────────────────────────
--  PRUEBA CON dm_readonly
--  Conéctate con: dm_readonly / Dm@Read2025!
--  y ejecuta:
--    SELECT id_usuario, nombre_completo, username, id_rol, estatus
--    FROM usuarios;
-- ─────────────────────────────────────────────
