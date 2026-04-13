-- ============================================================
--  MIGRACIÓN: Imágenes de Productos
--  Ejecutar sobre la BD dulcemigaja
-- ============================================================

USE dulce_migaja;

-- ── 1. Columna imagen_url en productos ──────────────────────
ALTER TABLE productos
    ADD COLUMN imagen_url VARCHAR(255) NULL DEFAULT NULL
        COMMENT 'Ruta relativa desde static/: uploads/productos/<uuid>.webp'
    AFTER descripcion;

-- Índice para búsquedas "productos con/sin imagen"
CREATE INDEX idx_productos_imagen ON productos (imagen_url(50));

-- ── 2. Tabla de auditoría de imágenes ───────────────────────
CREATE TABLE IF NOT EXISTS log_imagen_producto (
    id_log        INT            NOT NULL AUTO_INCREMENT,
    id_producto   INT            NOT NULL,
    imagen_ant    VARCHAR(255)       NULL,
    imagen_nueva  VARCHAR(255)       NULL,
    accion        ENUM('subida','eliminada') NOT NULL,
    cambiado_por  VARCHAR(60)        NULL,
    cambiado_en   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_log),
    INDEX idx_log_prod (id_producto),
    CONSTRAINT fk_log_img_prod FOREIGN KEY (id_producto)
        REFERENCES productos (id_producto) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 3. Trigger de auditoría ─────────────────────────────────
DROP TRIGGER IF EXISTS trg_productos_imagen_audit;

DELIMITER $$
CREATE TRIGGER trg_productos_imagen_audit
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
    -- Solo actúa cuando imagen_url cambia
    IF NOT (OLD.imagen_url <=> NEW.imagen_url) THEN
        IF NEW.imagen_url IS NOT NULL THEN
            INSERT INTO log_imagen_producto
                (id_producto, imagen_ant, imagen_nueva, accion, cambiado_en)
            VALUES
                (NEW.id_producto, OLD.imagen_url, NEW.imagen_url, 'subida', NOW());
        ELSE
            INSERT INTO log_imagen_producto
                (id_producto, imagen_ant, imagen_nueva, accion, cambiado_en)
            VALUES
                (NEW.id_producto, OLD.imagen_url, NULL, 'eliminada', NOW());
        END IF;
    END IF;
END$$
DELIMITER ;

-- ── 4. SP: actualizar imagen de producto ────────────────────
DROP PROCEDURE IF EXISTS sp_actualizar_imagen_producto;

DELIMITER $$
CREATE PROCEDURE sp_actualizar_imagen_producto(
    IN p_id_producto  INT,
    IN p_imagen_url   VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    SELECT COUNT(*) INTO v_existe
      FROM productos
     WHERE id_producto = p_id_producto;

    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Producto no encontrado.';
    END IF;

    UPDATE productos
       SET imagen_url      = p_imagen_url,
           actualizado_en  = NOW()
     WHERE id_producto = p_id_producto;
END$$
DELIMITER ;

-- ── 5. Permisos por rol de BD ────────────────────────────────
-- rol_admin: lectura/escritura total en productos + log
GRANT SELECT, INSERT, UPDATE ON dulce_migaja.log_imagen_producto TO rol_admin;
GRANT EXECUTE ON PROCEDURE dulce_migaja.sp_actualizar_imagen_producto TO rol_admin;

-- rol_vendedor: solo SELECT en productos (para catálogo / costos)
-- ya tenía SELECT en productos; no necesita SP de imagen

-- rol_panadero: SELECT en productos (para producción / insumos)
-- ya tenía SELECT; sin acceso al SP de imagen

FLUSH PRIVILEGES;