USE dulce_migaja;

ALTER TABLE compras
  ADD COLUMN folio_factura       VARCHAR(60)  NULL    AFTER folio,
  ADD COLUMN estatus             ENUM('ordenado','cancelado','finalizado')
                                 NOT NULL DEFAULT 'ordenado' AFTER total,
  ADD COLUMN motivo_cancelacion  TEXT         NULL    AFTER estatus;