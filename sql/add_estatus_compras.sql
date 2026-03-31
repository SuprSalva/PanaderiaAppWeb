-- ═══════════════════════════════════════════════════════════
--  Migración: agrega columnas de estatus a compras
--  y número de factura del proveedor.
--  Ejecutar como root en MySQL Workbench.
-- ═══════════════════════════════════════════════════════════

USE dulce_migaja;

ALTER TABLE compras
  ADD COLUMN folio_factura       VARCHAR(60)  NULL    AFTER folio,
  ADD COLUMN estatus             ENUM('ordenado','cancelado','finalizado')
                                 NOT NULL DEFAULT 'ordenado' AFTER total,
  ADD COLUMN motivo_cancelacion  TEXT         NULL    AFTER estatus;

-- Permisos nuevas columnas (los roles ya tienen acceso a la tabla,
-- no se necesitan grants adicionales para columnas).
