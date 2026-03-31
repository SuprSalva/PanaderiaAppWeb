DROP PROCEDURE IF EXISTS `sp_catalogo_pedido`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_catalogo_pedido`()
BEGIN
  SELECT id_tamanio, nombre, capacidad, descripcion
  FROM   tamanios_charola
  WHERE  estatus = 'activo'
  ORDER  BY capacidad;

  SELECT p.id_producto, p.nombre, p.descripcion, p.precio_venta
  FROM   productos p
  WHERE  p.estatus = 'activo'

    AND EXISTS (
      SELECT 1 FROM recetas r
      WHERE  r.id_producto = p.id_producto
        AND  r.estatus     = 'activo'
        AND  r.id_tamanio  = 1
    )
    AND EXISTS (
      SELECT 1 FROM recetas r
      WHERE  r.id_producto = p.id_producto
        AND  r.estatus     = 'activo'
        AND  r.id_tamanio  = 2
    )
    AND EXISTS (
      SELECT 1 FROM recetas r
      WHERE  r.id_producto = p.id_producto
        AND  r.estatus     = 'activo'
        AND  r.id_tamanio  = 3
    )
    AND EXISTS (
      SELECT 1 FROM recetas r
      WHERE  r.id_producto  = p.id_producto
        AND  r.estatus      = 'activo'
        AND  r.id_tamanio   IS NULL
        AND  r.rendimiento  = 6
    )

  ORDER BY p.nombre;
END ;;
DELIMITER ;