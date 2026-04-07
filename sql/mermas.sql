-- ============================================================
-- STORED PROCEDURES PARA MERMAS
-- ============================================================

-- 1. Obtener lista de materias primas con stock
DROP PROCEDURE IF EXISTS sp_mermas_materias_primas;
DELIMITER ;;
CREATE PROCEDURE sp_mermas_materias_primas(
    IN p_busqueda VARCHAR(120)
)
BEGIN
    SELECT 
        mp.id_materia,
        mp.nombre,
        mp.unidad_base,
        mp.stock_actual,
        mp.stock_minimo
    FROM materias_primas mp
    WHERE mp.estatus = 'activo'
      AND (p_busqueda IS NULL 
           OR p_busqueda = '' 
           OR CONVERT(mp.nombre USING utf8mb4) COLLATE utf8mb4_unicode_ci LIKE CONCAT('%', p_busqueda, '%'))
    ORDER BY mp.nombre;
END;;
DELIMITER ;


-- 2. Registrar una merma
DROP PROCEDURE IF EXISTS sp_registrar_merma;
DELIMITER ;;
CREATE PROCEDURE sp_registrar_merma(
    IN p_id_materia INT,
    IN p_cantidad DECIMAL(12,4),
    IN p_causa VARCHAR(30),
    IN p_descripcion TEXT,
    IN p_registrado_por INT,
    OUT p_id_merma INT,
    OUT p_error VARCHAR(255)
)
sp_main: BEGIN
    DECLARE v_stock_actual DECIMAL(12,4);
    DECLARE v_nombre_materia VARCHAR(120);
    DECLARE v_unidad VARCHAR(20);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
        SET p_id_merma = NULL;
    END;
    
    SET p_error = NULL;
    SET p_id_merma = NULL;
    
    -- Validar causa
    IF p_causa NOT IN ('caducidad', 'quemado_horneado', 'caida_accidente', 'error_produccion', 'rotura_empaque', 'contaminacion', 'otro') THEN
        SET p_error = 'Causa de merma inválida.';
        LEAVE sp_main;
    END IF;
    
    -- Validar cantidad
    IF p_cantidad <= 0 THEN
        SET p_error = 'La cantidad debe ser mayor a cero.';
        LEAVE sp_main;
    END IF;
    
    -- Obtener datos de la materia prima
    SELECT nombre, unidad_base, stock_actual 
    INTO v_nombre_materia, v_unidad, v_stock_actual
    FROM materias_primas 
    WHERE id_materia = p_id_materia AND estatus = 'activo';
    
    IF v_nombre_materia IS NULL THEN
        SET p_error = 'Materia prima no encontrada o inactiva.';
        LEAVE sp_main;
    END IF;
    
    -- Validar stock suficiente
    IF v_stock_actual < p_cantidad THEN
        SET p_error = CONCAT('Stock insuficiente. Disponible: ', v_stock_actual, ' ', v_unidad);
        LEAVE sp_main;
    END IF;
    
    START TRANSACTION;
    
    -- Insertar registro de merma
    INSERT INTO mermas (
        tipo_objeto, id_referencia, cantidad, unidad, 
        causa, descripcion, registrado_por, fecha_merma, creado_en
    ) VALUES (
        'materia_prima', p_id_materia, p_cantidad, v_unidad,
        p_causa, p_descripcion, p_registrado_por, NOW(), NOW()
    );
    
    SET p_id_merma = LAST_INSERT_ID();
    
    -- Descontar del inventario
    UPDATE materias_primas 
    SET stock_actual = stock_actual - p_cantidad,
        actualizado_en = NOW()
    WHERE id_materia = p_id_materia;
    
    -- Registrar en logs
    INSERT INTO logs_sistema (tipo, nivel, id_usuario, modulo, accion, descripcion, creado_en)
    VALUES ('ajuste_inv', 'WARNING', p_registrado_por, 'mermas', 'registrar_merma',
            CONCAT('Merma registrada: ', v_nombre_materia, ' - Cantidad: ', p_cantidad, ' ', v_unidad, ' - Causa: ', p_causa), NOW());
    
    COMMIT;
END;;
DELIMITER ;


-- 3. Listar mermas con filtros
DROP PROCEDURE IF EXISTS sp_listar_mermas;
DELIMITER ;;
CREATE PROCEDURE sp_listar_mermas(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
    IN p_causa VARCHAR(30),
    IN p_offset INT,
    IN p_limit INT
)
BEGIN
    SELECT 
        m.id_merma,
        mp.nombre AS materia_nombre,
        m.cantidad,
        m.unidad,
        m.causa,
        m.descripcion,
        m.fecha_merma,
        u.nombre_completo AS registrado_por_nombre,
        COUNT(*) OVER () AS total_filas
    FROM mermas m
    JOIN materias_primas mp ON mp.id_materia = m.id_referencia
    JOIN usuarios u ON u.id_usuario = m.registrado_por
    WHERE m.tipo_objeto = 'materia_prima'
      AND (p_fecha_inicio IS NULL OR DATE(m.fecha_merma) >= p_fecha_inicio)
      AND (p_fecha_fin IS NULL OR DATE(m.fecha_merma) <= p_fecha_fin)
      AND (p_causa IS NULL OR p_causa = '' OR m.causa = p_causa)
    ORDER BY m.fecha_merma DESC
    LIMIT p_limit OFFSET p_offset;
END;;
DELIMITER ;


-- 4. Obtener estadísticas de mermas
DROP PROCEDURE IF EXISTS sp_estadisticas_mermas;
DELIMITER ;;
CREATE PROCEDURE sp_estadisticas_mermas()
BEGIN
    -- Total de mermas hoy
    SELECT COALESCE(SUM(cantidad), 0) AS total_hoy
    FROM mermas
    WHERE tipo_objeto = 'materia_prima'
      AND DATE(fecha_merma) = CURDATE();
    
    -- Total de mermas esta semana
    SELECT COALESCE(SUM(cantidad), 0) AS total_semana
    FROM mermas
    WHERE tipo_objeto = 'materia_prima'
      AND YEARWEEK(fecha_merma, 1) = YEARWEEK(CURDATE(), 1);
    
    -- Top causas de merma
    SELECT causa, COUNT(*) AS cantidad, SUM(cantidad) AS total_perdido
    FROM mermas
    WHERE tipo_objeto = 'materia_prima'
    GROUP BY causa
    ORDER BY total_perdido DESC
    LIMIT 5;
END;;
DELIMITER ;


SHOW PROCEDURE STATUS WHERE Name = 'sp_mermas_materias_primas';

CALL sp_mermas_materias_primas('');