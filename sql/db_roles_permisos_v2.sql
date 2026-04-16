-- ═══════════════════════════════════════════════════════════════════════════
--  Dulce Migaja — Roles y Permisos de Base de Datos  (v2 — COMPLETO)
--  Fecha: 2026-04-16
--  Referencia: análisis de seguridad con principio de mínimo privilegio
--
--  INSTRUCCIONES: Ejecutar como root en MySQL Workbench.
--  Este script cubre la totalidad de tablas, vistas y procedimientos
--  almacenados del esquema dulce_migaja.
--
--  Roles:
--    · rol_admin    → Administrador del sistema (acceso total)
--    · rol_empleado → Operativo (ventas, compras, pedidos, inventario)
--    · rol_panadero → Producción y recetas (sin ventas ni finanzas)
--    · rol_cliente  → Tienda en línea (solo su experiencia de compra)
--
--  Cambios respecto a v1:
--    · Cobertura de TODAS las tablas del esquema (cajas, tamanios_charola,
--      pedido_productos, productos_terminados, log_imagen_producto, etc.)
--    · Cobertura de TODAS las vistas (v_*, vw_*)
--    · Cobertura de TODOS los stored procedures
--    · Separación más estricta: KPIs financieros solo admin
--    · Mermas: UPDATE/DELETE exclusivo del administrador
--    · Sesiones: solo administrador
-- ═══════════════════════════════════════════════════════════════════════════

USE dulce_migaja;


-- ─────────────────────────────────────────────────────────────────────────────
-- 0. LIMPIEZA PREVIA
-- ─────────────────────────────────────────────────────────────────────────────

DROP USER IF EXISTS 'dm_admin'@'localhost';
DROP USER IF EXISTS 'dm_empleado'@'localhost';
DROP USER IF EXISTS 'dm_panadero'@'localhost';
DROP USER IF EXISTS 'dm_cliente'@'localhost';

DROP ROLE IF EXISTS rol_admin;
DROP ROLE IF EXISTS rol_empleado;
DROP ROLE IF EXISTS rol_panadero;
DROP ROLE IF EXISTS rol_cliente;


-- ═══════════════════════════════════════════════════════════════════════════
-- 1. ROL: ADMINISTRADOR
--    Acceso total al sistema. Único que puede:
--      · Gestionar usuarios, roles y sesiones
--      · Aprobar salidas de efectivo
--      · Activar/desactivar/eliminar registros (UPDATE estatus / DELETE)
--      · Consultar análisis financiero completo (costo-utilidad, KPIs)
--      · Gestionar cajas, charolas y configuración de catálogos
-- ═══════════════════════════════════════════════════════════════════════════

CREATE ROLE rol_admin;

-- ── Usuarios, roles y sesiones (solo admin gestiona cuentas y sesiones) ──────
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.usuarios              TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.roles                 TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.sesiones              TO rol_admin;

-- ── Proveedores (sin DELETE físico — baja lógica vía UPDATE estatus) ─────────
GRANT SELECT, INSERT, UPDATE         ON dulce_migaja.proveedores           TO rol_admin;

-- ── Materias primas e inventario MP ──────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.materias_primas       TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.unidades_presentacion TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.ajustes_inventario    TO rol_admin;

-- ── Mermas: admin es el ÚNICO con UPDATE/DELETE ───────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.mermas                TO rol_admin;

-- ── Compras ───────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.compras               TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.detalle_compras       TO rol_admin;

-- ── Productos terminados e inventario PT ──────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.productos             TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.inventario_pt         TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.productos_terminados  TO rol_admin;

-- ── Cajas y catálogo de venta en charola ──────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.cajas                 TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.caja_productos        TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.tamanios_charola      TO rol_admin;

-- ── Recetas ───────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.recetas               TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.detalle_recetas       TO rol_admin;

-- ── Producción diaria ─────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.produccion_diaria               TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.produccion_diaria_detalle       TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.produccion_diaria_linea_prod    TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.produccion_diaria_insumos       TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.plantillas_produccion           TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.plantillas_produccion_detalle   TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.plantillas_produccion_linea_prod TO rol_admin;

-- ── Producción clásica (lotes desde pedidos) ──────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.produccion             TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.detalle_produccion     TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.lotes_produccion_caja  TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.insumos_lote_caja      TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.salida_inventario_lote TO rol_admin;

-- ── Ventas y punto de venta ───────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.ventas                TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.detalle_ventas        TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.cortes_diarios        TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.tickets               TO rol_admin;

-- ── Pedidos ───────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.pedidos                TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.detalle_pedidos        TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.pedido_productos       TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.historial_pedidos      TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.notificaciones_pedidos TO rol_admin;

-- ── Efectivo: admin puede registrar Y aprobar ─────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.salidas_efectivo      TO rol_admin;

-- ── Logs e imágenes (auditoría: solo lectura e inserción, nunca borrar) ───────
GRANT SELECT, INSERT ON dulce_migaja.logs_sistema        TO rol_admin;
GRANT SELECT, INSERT ON dulce_migaja.log_imagen_producto TO rol_admin;

-- ── Stored Procedures — admin ─────────────────────────────────────────────────

-- Usuarios
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_usuario             TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_usuario            TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cambiar_estatus_usuario   TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cambiar_password          TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_registrar_cliente         TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_actualizar_perfil_cliente TO rol_admin;

-- Compras
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_pedido_compra       TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_agregar_detalle_compra    TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cancelar_compra           TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_finalizar_compra          TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_unidad_compra       TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_limpiar_detalles_compra   TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_corregir_precio_compra    TO rol_admin;

-- Efectivo
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_registrar_salida_manual   TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_aprobar_salida            TO rol_admin;

-- Proveedores
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_proveedor           TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_proveedor          TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_toggle_proveedor          TO rol_admin;

-- Materias primas
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_materia_prima       TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_materia_prima      TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_toggle_materia_prima      TO rol_admin;

-- Productos terminados
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_producto            TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_producto           TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_toggle_producto           TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_actualizar_imagen_producto TO rol_admin;

-- Recetas
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_receta              TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_receta             TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_toggle_receta             TO rol_admin;

-- Producción diaria
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_crear_cabecera         TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_calcular_insumos       TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_iniciar                TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_finalizar              TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_cancelar               TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_lista                  TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_guardar_plantilla      TO rol_admin;

-- Producción clásica (órdenes y lotes desde pedidos)
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_orden_produccion     TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_iniciar_orden_produccion   TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_finalizar_orden_produccion TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cancelar_orden_produccion  TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_detalle_orden_produccion   TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_lista_ordenes_produccion   TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_registrar_produccion       TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_iniciar_produccion_pedido  TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_terminar_produccion_pedido TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_verificar_insumos_pedido   TO rol_admin;

-- Ventas y cortes
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_venta               TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cancelar_venta            TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_detalle_venta             TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_lista_ventas              TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_catalogo_ventas           TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_venta_desde_pedido  TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_registrar_venta_caja      TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_corte_generar             TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_corte_resumen             TO rol_admin;

-- Pedidos (flujo logístico completo)
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_catalogo_tienda           TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_catalogo_pedido           TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_pedido              TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_pedido_caja         TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pedido_express            TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_aprobar_pedido            TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_rechazar_pedido           TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_marcar_listo_pedido       TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_marcar_entregado_pedido   TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cambiar_estado_pedido     TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_detalle_pedido            TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_lista_pedidos_interna     TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_siguiente_folio_pedido    TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_mis_pedidos_cliente       TO rol_admin;

-- Mermas
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_registrar_merma              TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_registrar_merma_producto     TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_listar_mermas                TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_listar_mermas_productos      TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_mermas_materias_primas       TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_mermas_productos_terminados  TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_estadisticas_mermas          TO rol_admin;

-- Dashboard y KPIs financieros (exclusivo administrador)
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_dash_mp_criticas             TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_dash_salidas_efectivo        TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_dash_top_productos           TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_dash_utilidad_por_producto   TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_dash_ventas_totales          TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_kpi_costo_utilidad           TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_reporte_costo_utilidad       TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_reporte_utilidad_ventas      TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_detalle_costo_producto       TO rol_admin;

-- Notificaciones
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_badge_notifs                 TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_notificaciones_cliente       TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_marcar_notifs_leidas         TO rol_admin;

-- ── Vistas — admin ────────────────────────────────────────────────────────────

-- Usuarios
GRANT SELECT ON dulce_migaja.vw_usuarios                     TO rol_admin;
-- Compras y efectivo
GRANT SELECT ON dulce_migaja.vw_compras                      TO rol_admin;
GRANT SELECT ON dulce_migaja.vw_salidas_efectivo             TO rol_admin;
-- Producción
GRANT SELECT ON dulce_migaja.vw_produccion_diaria            TO rol_admin;
-- Materias primas
GRANT SELECT ON dulce_migaja.vw_materias_primas              TO rol_admin;
GRANT SELECT ON dulce_migaja.v_costo_promedio_materia        TO rol_admin;
GRANT SELECT ON dulce_migaja.v_ultimo_costo_materia          TO rol_admin;
-- Productos
GRANT SELECT ON dulce_migaja.vw_productos                    TO rol_admin;
GRANT SELECT ON dulce_migaja.vw_productos_stock              TO rol_admin;
-- Recetas
GRANT SELECT ON dulce_migaja.vw_recetas                      TO rol_admin;
GRANT SELECT ON dulce_migaja.v_recetas_explosion             TO rol_admin;
GRANT SELECT ON dulce_migaja.v_recetas_por_tamanio           TO rol_admin;
-- Ventas y cortes
GRANT SELECT ON dulce_migaja.vw_ventas_caja                  TO rol_admin;
GRANT SELECT ON dulce_migaja.vw_ventas_consolidadas          TO rol_admin;
GRANT SELECT ON dulce_migaja.vw_corte_ventas_dia             TO rol_admin;
GRANT SELECT ON dulce_migaja.vw_top_productos_vendidos       TO rol_admin;
-- Dashboard financiero
GRANT SELECT ON dulce_migaja.vw_dash_ventas_consolidadas     TO rol_admin;
GRANT SELECT ON dulce_migaja.vw_dash_piezas_vendidas         TO rol_admin;
GRANT SELECT ON dulce_migaja.vw_dash_mp_criticas             TO rol_admin;
-- Pedidos
GRANT SELECT ON dulce_migaja.v_conteo_pedidos_por_estado     TO rol_admin;
GRANT SELECT ON dulce_migaja.v_pedidos_resumen               TO rol_admin;
GRANT SELECT ON dulce_migaja.v_detalle_pedido                TO rol_admin;
GRANT SELECT ON dulce_migaja.v_historial_pedido              TO rol_admin;
GRANT SELECT ON dulce_migaja.v_notificaciones_cliente        TO rol_admin;
GRANT SELECT ON dulce_migaja.v_pedido_detalle_completo       TO rol_admin;
-- Cajas
GRANT SELECT ON dulce_migaja.v_cajas_detalle                 TO rol_admin;
GRANT SELECT ON dulce_migaja.v_caja_pedido                   TO rol_admin;

SHOW GRANTS FOR rol_admin;


-- ═══════════════════════════════════════════════════════════════════════════
-- 2. ROL: EMPLEADO
--    Acceso operativo: ventas, compras, proveedores, pedidos, inventario.
--    Puede crear y ver producción diaria (NO iniciarla ni finalizarla).
--    NO puede: aprobar salidas, gestionar usuarios, ver sesiones,
--              acceder a KPIs financieros (costo-utilidad).
-- ═══════════════════════════════════════════════════════════════════════════

CREATE ROLE rol_empleado;

-- ── Catálogos: solo lectura ───────────────────────────────────────────────────
GRANT SELECT ON dulce_migaja.roles    TO rol_empleado;
GRANT SELECT ON dulce_migaja.usuarios TO rol_empleado;
-- NOTA: sesiones solo admin

-- ── Proveedores: gestión completa (sin DELETE físico) ────────────────────────
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.proveedores           TO rol_empleado;

-- ── Materias primas: gestión completa (alertas de stock, análisis) ───────────
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.materias_primas       TO rol_empleado;
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.unidades_presentacion TO rol_empleado;
GRANT SELECT, INSERT         ON dulce_migaja.ajustes_inventario    TO rol_empleado;

-- ── Mermas: registrar y consultar (UPDATE/DELETE exclusivo de admin) ──────────
GRANT SELECT, INSERT         ON dulce_migaja.mermas                TO rol_empleado;

-- ── Compras ───────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.compras               TO rol_empleado;
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.detalle_compras       TO rol_empleado;

-- ── Productos e inventario PT ─────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.productos             TO rol_empleado;
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.inventario_pt         TO rol_empleado;
GRANT SELECT                 ON dulce_migaja.productos_terminados  TO rol_empleado;

-- ── Cajas y charolas (catálogo de venta en caja) ──────────────────────────────
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.cajas                 TO rol_empleado;
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.caja_productos        TO rol_empleado;
GRANT SELECT                 ON dulce_migaja.tamanios_charola      TO rol_empleado;

-- ── Recetas: solo lectura ─────────────────────────────────────────────────────
GRANT SELECT ON dulce_migaja.recetas         TO rol_empleado;
GRANT SELECT ON dulce_migaja.detalle_recetas TO rol_empleado;

-- ── Producción diaria: VER + CREAR lote + ver historial/insumos ──────────────
-- NO puede iniciar, actualizar piezas ni finalizar/cancelar (es del panadero)
GRANT SELECT, INSERT ON dulce_migaja.produccion_diaria                TO rol_empleado;
GRANT SELECT, INSERT ON dulce_migaja.produccion_diaria_detalle        TO rol_empleado;
GRANT SELECT, INSERT ON dulce_migaja.produccion_diaria_linea_prod     TO rol_empleado;
GRANT SELECT         ON dulce_migaja.produccion_diaria_insumos        TO rol_empleado;
GRANT SELECT         ON dulce_migaja.plantillas_produccion            TO rol_empleado;
GRANT SELECT         ON dulce_migaja.plantillas_produccion_detalle    TO rol_empleado;
GRANT SELECT         ON dulce_migaja.plantillas_produccion_linea_prod TO rol_empleado;

-- ── Producción clásica (lotes desde pedidos): solo lectura ───────────────────
GRANT SELECT ON dulce_migaja.produccion             TO rol_empleado;
GRANT SELECT ON dulce_migaja.detalle_produccion     TO rol_empleado;
GRANT SELECT ON dulce_migaja.lotes_produccion_caja  TO rol_empleado;
GRANT SELECT ON dulce_migaja.insumos_lote_caja      TO rol_empleado;
GRANT SELECT ON dulce_migaja.salida_inventario_lote TO rol_empleado;

-- ── Ventas y punto de venta ───────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.ventas          TO rol_empleado;
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.detalle_ventas  TO rol_empleado;
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.cortes_diarios  TO rol_empleado;
GRANT SELECT, INSERT         ON dulce_migaja.tickets         TO rol_empleado;

-- ── Salidas de efectivo: registrar (NO aprobar — exclusivo admin) ─────────────
GRANT SELECT, INSERT ON dulce_migaja.salidas_efectivo TO rol_empleado;

-- ── Pedidos: logística completa ───────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.pedidos                TO rol_empleado;
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.detalle_pedidos        TO rol_empleado;
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.pedido_productos       TO rol_empleado;
GRANT SELECT, INSERT         ON dulce_migaja.historial_pedidos      TO rol_empleado;
GRANT SELECT                 ON dulce_migaja.notificaciones_pedidos TO rol_empleado;

-- ── Logs e imágenes ───────────────────────────────────────────────────────────
GRANT SELECT, INSERT ON dulce_migaja.logs_sistema        TO rol_empleado;
GRANT SELECT, INSERT ON dulce_migaja.log_imagen_producto TO rol_empleado;

-- ── Stored Procedures — empleado ──────────────────────────────────────────────

-- Usuarios (solo cambio de contraseña propia)
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cambiar_password          TO rol_empleado;

-- Proveedores
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_proveedor           TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_proveedor          TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_toggle_proveedor          TO rol_empleado;

-- Materias primas
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_materia_prima       TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_materia_prima      TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_toggle_materia_prima      TO rol_empleado;

-- Productos terminados
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_producto            TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_editar_producto           TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_toggle_producto           TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_actualizar_imagen_producto TO rol_empleado;

-- Compras
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_pedido_compra       TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_agregar_detalle_compra    TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cancelar_compra           TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_finalizar_compra          TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_unidad_compra       TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_limpiar_detalles_compra   TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_corregir_precio_compra    TO rol_empleado;

-- Efectivo (registrar, sin aprobar)
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_registrar_salida_manual   TO rol_empleado;

-- Producción diaria (crear cabecera + calcular insumos + ver lista + plantilla)
-- NO tiene sp_pd_iniciar / sp_pd_finalizar / sp_pd_cancelar (es del panadero)
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_crear_cabecera         TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_calcular_insumos       TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_lista                  TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_guardar_plantilla      TO rol_empleado;

-- Producción clásica (solo consulta)
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_lista_ordenes_produccion  TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_detalle_orden_produccion  TO rol_empleado;

-- Ventas y cortes
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_venta               TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cancelar_venta            TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_detalle_venta             TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_lista_ventas              TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_catalogo_ventas           TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_venta_desde_pedido  TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_registrar_venta_caja      TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_corte_generar             TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_corte_resumen             TO rol_empleado;

-- Pedidos (flujo logístico: aprobar, rechazar, marcar listo/entregado)
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_catalogo_tienda           TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_catalogo_pedido           TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_aprobar_pedido            TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_rechazar_pedido           TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_marcar_listo_pedido       TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_marcar_entregado_pedido   TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cambiar_estado_pedido     TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_detalle_pedido            TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_lista_pedidos_interna     TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_siguiente_folio_pedido    TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_verificar_insumos_pedido  TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_iniciar_produccion_pedido TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_terminar_produccion_pedido TO rol_empleado;

-- Mermas (registrar y consultar, sin activar/desactivar)
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_registrar_merma           TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_listar_mermas             TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_mermas_materias_primas    TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_estadisticas_mermas       TO rol_empleado;

-- Notificaciones
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_badge_notifs              TO rol_empleado;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_marcar_notifs_leidas      TO rol_empleado;

-- ── Vistas — empleado ─────────────────────────────────────────────────────────

GRANT SELECT ON dulce_migaja.vw_usuarios                  TO rol_empleado;
GRANT SELECT ON dulce_migaja.vw_compras                   TO rol_empleado;
GRANT SELECT ON dulce_migaja.vw_salidas_efectivo          TO rol_empleado;
GRANT SELECT ON dulce_migaja.vw_produccion_diaria         TO rol_empleado;
GRANT SELECT ON dulce_migaja.vw_materias_primas           TO rol_empleado;
GRANT SELECT ON dulce_migaja.vw_productos                 TO rol_empleado;
GRANT SELECT ON dulce_migaja.vw_productos_stock           TO rol_empleado;
GRANT SELECT ON dulce_migaja.vw_recetas                   TO rol_empleado;
GRANT SELECT ON dulce_migaja.vw_ventas_caja               TO rol_empleado;
GRANT SELECT ON dulce_migaja.vw_ventas_consolidadas       TO rol_empleado;
GRANT SELECT ON dulce_migaja.vw_corte_ventas_dia          TO rol_empleado;
GRANT SELECT ON dulce_migaja.vw_top_productos_vendidos    TO rol_empleado;
GRANT SELECT ON dulce_migaja.vw_dash_piezas_vendidas      TO rol_empleado;
GRANT SELECT ON dulce_migaja.vw_dash_mp_criticas          TO rol_empleado;
GRANT SELECT ON dulce_migaja.v_conteo_pedidos_por_estado  TO rol_empleado;
GRANT SELECT ON dulce_migaja.v_pedidos_resumen            TO rol_empleado;
GRANT SELECT ON dulce_migaja.v_detalle_pedido             TO rol_empleado;
GRANT SELECT ON dulce_migaja.v_historial_pedido           TO rol_empleado;
GRANT SELECT ON dulce_migaja.v_pedido_detalle_completo    TO rol_empleado;
GRANT SELECT ON dulce_migaja.v_recetas_explosion          TO rol_empleado;
GRANT SELECT ON dulce_migaja.v_recetas_por_tamanio        TO rol_empleado;
GRANT SELECT ON dulce_migaja.v_costo_promedio_materia     TO rol_empleado;
GRANT SELECT ON dulce_migaja.v_ultimo_costo_materia       TO rol_empleado;
GRANT SELECT ON dulce_migaja.v_cajas_detalle              TO rol_empleado;
GRANT SELECT ON dulce_migaja.v_caja_pedido                TO rol_empleado;
-- NO: vw_dash_ventas_consolidadas (KPI financiero — exclusivo admin)

SHOW GRANTS FOR rol_empleado;


-- ═══════════════════════════════════════════════════════════════════════════
-- 3. ROL: PANADERO
--    Acceso exclusivo al área de producción, recetas e insumos.
--    Solo CONSULTA compras (sin crear ni modificar).
--    Acceso COMPLETO a producción diaria: crear, iniciar, finalizar,
--    cancelar lotes.
--    NO accede a: ventas, efectivo, usuarios, análisis financiero.
-- ═══════════════════════════════════════════════════════════════════════════

CREATE ROLE rol_panadero;

-- ── Catálogos necesarios para producir: solo lectura ─────────────────────────
GRANT SELECT ON dulce_migaja.roles                 TO rol_panadero;
GRANT SELECT ON dulce_migaja.usuarios              TO rol_panadero;
GRANT SELECT ON dulce_migaja.productos             TO rol_panadero;
GRANT SELECT ON dulce_migaja.inventario_pt         TO rol_panadero;
GRANT SELECT ON dulce_migaja.recetas               TO rol_panadero;
GRANT SELECT ON dulce_migaja.detalle_recetas       TO rol_panadero;
GRANT SELECT ON dulce_migaja.materias_primas       TO rol_panadero;
GRANT SELECT ON dulce_migaja.unidades_presentacion TO rol_panadero;
GRANT SELECT ON dulce_migaja.tamanios_charola      TO rol_panadero;

-- ── Compras: SOLO CONSULTA (principio mínimo privilegio) ─────────────────────
GRANT SELECT ON dulce_migaja.compras               TO rol_panadero;
GRANT SELECT ON dulce_migaja.detalle_compras       TO rol_panadero;

-- ── Producción diaria: ACCESO COMPLETO ───────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.produccion_diaria                TO rol_panadero;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.produccion_diaria_detalle        TO rol_panadero;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.produccion_diaria_linea_prod     TO rol_panadero;
GRANT SELECT, INSERT, UPDATE         ON dulce_migaja.produccion_diaria_insumos        TO rol_panadero;
GRANT SELECT                         ON dulce_migaja.plantillas_produccion            TO rol_panadero;
GRANT SELECT                         ON dulce_migaja.plantillas_produccion_detalle    TO rol_panadero;
GRANT SELECT                         ON dulce_migaja.plantillas_produccion_linea_prod TO rol_panadero;

-- ── Producción clásica (lotes desde pedidos): ACCESO COMPLETO ────────────────
GRANT SELECT, INSERT, UPDATE         ON dulce_migaja.produccion             TO rol_panadero;
GRANT SELECT, INSERT, UPDATE, DELETE ON dulce_migaja.detalle_produccion     TO rol_panadero;
GRANT SELECT, INSERT, UPDATE         ON dulce_migaja.lotes_produccion_caja  TO rol_panadero;
GRANT SELECT, INSERT, UPDATE         ON dulce_migaja.insumos_lote_caja      TO rol_panadero;
GRANT SELECT, INSERT, UPDATE         ON dulce_migaja.salida_inventario_lote TO rol_panadero;

-- ── Inventario MP/PT: actualización de stock por proceso productivo ───────────
GRANT SELECT, UPDATE ON dulce_migaja.materias_primas TO rol_panadero;
GRANT SELECT, UPDATE ON dulce_migaja.inventario_pt   TO rol_panadero;

-- ── Mermas: registrar (sin activar/desactivar — exclusivo admin) ──────────────
GRANT SELECT, INSERT ON dulce_migaja.mermas TO rol_panadero;

-- ── Cola de pedidos: solo consulta (para saber qué producir) ─────────────────
GRANT SELECT ON dulce_migaja.pedidos          TO rol_panadero;
GRANT SELECT ON dulce_migaja.detalle_pedidos  TO rol_panadero;
GRANT SELECT ON dulce_migaja.pedido_productos TO rol_panadero;
GRANT SELECT ON dulce_migaja.historial_pedidos TO rol_panadero;

-- ── Logs ──────────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT ON dulce_migaja.logs_sistema TO rol_panadero;

-- ── Stored Procedures — panadero ──────────────────────────────────────────────

-- Contraseña propia
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cambiar_password            TO rol_panadero;

-- Producción diaria: ACCESO COMPLETO
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_crear_cabecera           TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_calcular_insumos         TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_iniciar                  TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_finalizar                TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_cancelar                 TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_lista                    TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pd_guardar_plantilla        TO rol_panadero;

-- Producción clásica (órdenes de producción)
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_orden_produccion      TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_iniciar_orden_produccion    TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_finalizar_orden_produccion  TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cancelar_orden_produccion   TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_detalle_orden_produccion    TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_lista_ordenes_produccion    TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_registrar_produccion        TO rol_panadero;

-- Producción desde pedidos
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_iniciar_produccion_pedido   TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_terminar_produccion_pedido  TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_verificar_insumos_pedido    TO rol_panadero;

-- Mermas (MP y PT)
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_registrar_merma             TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_registrar_merma_producto    TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_listar_mermas               TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_listar_mermas_productos     TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_mermas_materias_primas      TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_mermas_productos_terminados TO rol_panadero;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_estadisticas_mermas         TO rol_panadero;

-- ── Vistas — panadero ─────────────────────────────────────────────────────────

GRANT SELECT ON dulce_migaja.vw_compras                  TO rol_panadero;
GRANT SELECT ON dulce_migaja.vw_produccion_diaria        TO rol_panadero;
GRANT SELECT ON dulce_migaja.vw_materias_primas          TO rol_panadero;
GRANT SELECT ON dulce_migaja.vw_productos                TO rol_panadero;
GRANT SELECT ON dulce_migaja.vw_recetas                  TO rol_panadero;
GRANT SELECT ON dulce_migaja.v_recetas_explosion         TO rol_panadero;
GRANT SELECT ON dulce_migaja.v_recetas_por_tamanio       TO rol_panadero;
GRANT SELECT ON dulce_migaja.v_costo_promedio_materia    TO rol_panadero;
GRANT SELECT ON dulce_migaja.v_ultimo_costo_materia      TO rol_panadero;
GRANT SELECT ON dulce_migaja.v_conteo_pedidos_por_estado TO rol_panadero;
GRANT SELECT ON dulce_migaja.v_pedidos_resumen           TO rol_panadero;

SHOW GRANTS FOR rol_panadero;


-- ═══════════════════════════════════════════════════════════════════════════
-- 4. ROL: CLIENTE
--    Acceso exclusivo a la experiencia de compra en tienda:
--    ver catálogo, crear pedidos, ver seguimiento y notificaciones.
--    El filtro por id_cliente se aplica a nivel de aplicación.
--    NO accede a ningún módulo interno.
-- ═══════════════════════════════════════════════════════════════════════════

CREATE ROLE rol_cliente;

-- ── Catálogo de productos y cajas ────────────────────────────────────────────
GRANT SELECT ON dulce_migaja.productos         TO rol_cliente;
GRANT SELECT ON dulce_migaja.inventario_pt     TO rol_cliente;
GRANT SELECT ON dulce_migaja.cajas             TO rol_cliente;
GRANT SELECT ON dulce_migaja.caja_productos    TO rol_cliente;
GRANT SELECT ON dulce_migaja.tamanios_charola  TO rol_cliente;

-- ── Sus propios pedidos y seguimiento ────────────────────────────────────────
-- (la app filtra por id_cliente en TODAS las consultas)
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.pedidos                TO rol_cliente;
GRANT SELECT                 ON dulce_migaja.detalle_pedidos        TO rol_cliente;
GRANT SELECT                 ON dulce_migaja.pedido_productos       TO rol_cliente;
GRANT SELECT                 ON dulce_migaja.historial_pedidos      TO rol_cliente;
GRANT SELECT, UPDATE         ON dulce_migaja.notificaciones_pedidos TO rol_cliente;

-- ── Stored Procedures — cliente ───────────────────────────────────────────────

-- Contraseña y perfil
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_cambiar_password          TO rol_cliente;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_actualizar_perfil_cliente TO rol_cliente;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_registrar_cliente         TO rol_cliente;

-- Pedidos y catálogo
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_pedido_express            TO rol_cliente;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_mis_pedidos_cliente       TO rol_cliente;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_catalogo_tienda           TO rol_cliente;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_catalogo_pedido           TO rol_cliente;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_detalle_pedido            TO rol_cliente;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_pedido              TO rol_cliente;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_crear_pedido_caja         TO rol_cliente;

-- Notificaciones
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_badge_notifs              TO rol_cliente;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_notificaciones_cliente    TO rol_cliente;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_marcar_notifs_leidas      TO rol_cliente;

-- ── Vistas — cliente ──────────────────────────────────────────────────────────

GRANT SELECT ON dulce_migaja.v_conteo_pedidos_por_estado TO rol_cliente;
GRANT SELECT ON dulce_migaja.v_detalle_pedido            TO rol_cliente;
GRANT SELECT ON dulce_migaja.v_historial_pedido          TO rol_cliente;
GRANT SELECT ON dulce_migaja.v_notificaciones_cliente    TO rol_cliente;
GRANT SELECT ON dulce_migaja.v_pedidos_resumen           TO rol_cliente;
GRANT SELECT ON dulce_migaja.v_cajas_detalle             TO rol_cliente;
GRANT SELECT ON dulce_migaja.v_caja_pedido               TO rol_cliente;

SHOW GRANTS FOR rol_cliente;


-- ═══════════════════════════════════════════════════════════════════════════
-- 5. CREACIÓN DE USUARIOS DE BASE DE DATOS
--    Cambiar contraseñas antes de pasar a producción.
-- ═══════════════════════════════════════════════════════════════════════════

CREATE USER 'dm_admin'@'localhost'    IDENTIFIED BY 'Gujtuc-zitny5-gyskuv';
CREATE USER 'dm_empleado'@'localhost' IDENTIFIED BY 'fomzoh-Poqcoz-0wytqe';
CREATE USER 'dm_panadero'@'localhost' IDENTIFIED BY 'bIdfyq-vycfof-pivwo3';
CREATE USER 'dm_cliente'@'localhost'  IDENTIFIED BY 'vixpam-jidjim-5geDto';


-- ─────────────────────────────────────────────────────────────────────────────
-- 6. ASIGNACIÓN DE ROLES A USUARIOS
-- ─────────────────────────────────────────────────────────────────────────────

GRANT rol_admin    TO 'dm_admin'@'localhost';
GRANT rol_empleado TO 'dm_empleado'@'localhost';
GRANT rol_panadero TO 'dm_panadero'@'localhost';
GRANT rol_cliente  TO 'dm_cliente'@'localhost';


-- ─────────────────────────────────────────────────────────────────────────────
-- 7. ACTIVAR ROL POR DEFECTO EN CADA SESIÓN
-- ─────────────────────────────────────────────────────────────────────────────

SET DEFAULT ROLE rol_admin    TO 'dm_admin'@'localhost';
SET DEFAULT ROLE rol_empleado TO 'dm_empleado'@'localhost';
SET DEFAULT ROLE rol_panadero TO 'dm_panadero'@'localhost';
SET DEFAULT ROLE rol_cliente  TO 'dm_cliente'@'localhost';

FLUSH PRIVILEGES;


-- ─────────────────────────────────────────────────────────────────────────────
-- 8. VERIFICACIÓN FINAL
-- ─────────────────────────────────────────────────────────────────────────────

SHOW GRANTS FOR 'dm_admin'@'localhost';
SHOW GRANTS FOR 'dm_empleado'@'localhost';
SHOW GRANTS FOR 'dm_panadero'@'localhost';
SHOW GRANTS FOR 'dm_cliente'@'localhost';
