USE dulce_migaja;


DROP USER IF EXISTS 'dm_admin'@'localhost';
DROP USER IF EXISTS 'dm_empleado'@'localhost';
DROP USER IF EXISTS 'dm_panadero'@'localhost';
DROP USER IF EXISTS 'dm_cliente'@'localhost';

DROP ROLE IF EXISTS rol_admin;
DROP ROLE IF EXISTS rol_empleado;
DROP ROLE IF EXISTS rol_panadero;
DROP ROLE IF EXISTS rol_cliente;

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

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_usuario           TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_usuario          TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cambiar_estatus_usuario TO rol_admin;
GRANT SELECT ON dulce_migaja.vw_usuarios TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cambiar_password TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_pedido_compra    TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_agregar_detalle_compra TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cancelar_compra        TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_finalizar_compra       TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_unidad_compra TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_limpiar_detalles_compra TO rol_admin;
GRANT SELECT ON dulce_migaja.vw_compras TO rol_admin;
GRANT SELECT ON dulce_migaja.vw_salidas_efectivo TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_registrar_salida_manual TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_aprobar_salida TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_corregir_precio_compra TO rol_admin;
SHOW GRANTS FOR rol_admin;

CREATE ROLE rol_empleado;

GRANT SELECT ON dulce_migaja.roles                TO rol_empleado;
GRANT SELECT ON dulce_migaja.usuarios             TO rol_empleado;
GRANT SELECT ON dulce_migaja.productos            TO rol_empleado;
GRANT SELECT ON dulce_migaja.inventario_pt        TO rol_empleado;
GRANT SELECT ON dulce_migaja.recetas              TO rol_empleado;
GRANT SELECT ON dulce_migaja.proveedores          TO rol_empleado;
GRANT SELECT ON dulce_migaja.materias_primas      TO rol_empleado;

GRANT SELECT, INSERT, UPDATE ON dulce_migaja.ventas           TO rol_empleado;
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.detalle_ventas   TO rol_empleado;
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.cortes_diarios   TO rol_empleado;
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.salidas_efectivo TO rol_empleado;
GRANT SELECT, INSERT         ON dulce_migaja.tickets          TO rol_empleado;
GRANT SELECT, INSERT         ON dulce_migaja.logs_sistema     TO rol_empleado;

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cambiar_password TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_pedido_compra    TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_agregar_detalle_compra TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cancelar_compra        TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_finalizar_compra       TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_unidad_compra TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_limpiar_detalles_compra TO rol_empleado;
GRANT SELECT ON dulce_migaja.vw_compras TO rol_empleado;
GRANT SELECT ON dulce_migaja.vw_salidas_efectivo TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_registrar_salida_manual TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_corregir_precio_compra TO rol_empleado;

SHOW GRANTS FOR rol_empleado;

CREATE ROLE rol_panadero;

GRANT SELECT ON dulce_migaja.roles                 TO rol_panadero;
GRANT SELECT ON dulce_migaja.usuarios              TO rol_panadero;
GRANT SELECT ON dulce_migaja.productos             TO rol_panadero;
GRANT SELECT ON dulce_migaja.recetas               TO rol_panadero;
GRANT SELECT ON dulce_migaja.detalle_recetas       TO rol_panadero;
GRANT SELECT ON dulce_migaja.materias_primas       TO rol_panadero;
GRANT SELECT ON dulce_migaja.unidades_presentacion TO rol_panadero;
GRANT SELECT ON dulce_migaja.compras               TO rol_panadero;
GRANT SELECT ON dulce_migaja.detalle_compras       TO rol_panadero;

GRANT SELECT, INSERT, UPDATE         ON dulce_migaja.produccion          TO rol_panadero;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.detalle_produccion  TO rol_panadero;
GRANT SELECT, INSERT                 ON dulce_migaja.mermas              TO rol_panadero;
GRANT SELECT, UPDATE                 ON dulce_migaja.inventario_pt       TO rol_panadero;
GRANT SELECT, INSERT                 ON dulce_migaja.logs_sistema        TO rol_panadero;

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cambiar_password TO rol_panadero;

SHOW GRANTS FOR rol_panadero;


CREATE ROLE rol_cliente;

GRANT SELECT ON dulce_migaja.productos    TO rol_cliente;
GRANT SELECT ON dulce_migaja.inventario_pt TO rol_cliente;

GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cambiar_password         TO rol_cliente;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_actualizar_perfil_cliente TO rol_cliente;

SHOW GRANTS FOR rol_cliente;


CREATE USER 'dm_admin'@'localhost'    IDENTIFIED BY 'Gujtuc-zitny5-gyskuv';
CREATE USER 'dm_empleado'@'localhost' IDENTIFIED BY 'fomzoh-Poqcoz-0wytqe';
CREATE USER 'dm_panadero'@'localhost' IDENTIFIED BY 'bIdfyq-vycfof-pivwo3';
CREATE USER 'dm_cliente'@'localhost'  IDENTIFIED BY 'vixpam-jidjim-5geDto';


GRANT rol_admin    TO 'dm_admin'@'localhost';
GRANT rol_empleado TO 'dm_empleado'@'localhost';
GRANT rol_panadero TO 'dm_panadero'@'localhost';
GRANT rol_cliente  TO 'dm_cliente'@'localhost';


SET DEFAULT ROLE rol_admin    TO 'dm_admin'@'localhost';
SET DEFAULT ROLE rol_empleado TO 'dm_empleado'@'localhost';
SET DEFAULT ROLE rol_panadero TO 'dm_panadero'@'localhost';
SET DEFAULT ROLE rol_cliente  TO 'dm_cliente'@'localhost';

FLUSH PRIVILEGES;


SHOW GRANTS FOR 'dm_admin'@'localhost';
SHOW GRANTS FOR 'dm_empleado'@'localhost';
SHOW GRANTS FOR 'dm_panadero'@'localhost';
SHOW GRANTS FOR 'dm_cliente'@'localhost';