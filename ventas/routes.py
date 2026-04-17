from . import ventas
from flask import render_template, request, jsonify, current_app
from flask_login import login_required, current_user
from auth import roles_required
from sqlalchemy import text
from models import db
from decimal import Decimal
from datetime import date, datetime
import json
from utils.db_roles import role_connection, get_role_engine


class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        if isinstance(obj, datetime):
            return obj.strftime('%Y-%m-%d %H:%M:%S')
        return super(DecimalEncoder, self).default(obj)

def fetch_as_dict(cursor):
    if not cursor.description:
        return []
    column_names = [col[0] for col in cursor.description]
    return [dict(zip(column_names, row)) for row in cursor.fetchall()]


# ============================================================
# RUTAS DE VISTAS (HTML)
# ============================================================

@ventas.route("/")
@ventas.route("/ventas")
@login_required
@roles_required('admin', 'empleado')
def index_ventas():
    """Vista de ventas online (pedidos entregados)"""
    current_app.logger.info('Vista de registro general de ventas accesada | usuario: %s | fecha: %s', current_user.username, datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    return render_template("ventas/ventas.html")


@ventas.route("/caja")
@login_required
@roles_required('admin', 'empleado')
def ventas_caja():
    """NUEVO: Vista de punto de venta en caja"""
    current_app.logger.info('Vista de punto de venta en caja accesada | usuario: %s | fecha: %s', current_user.username, datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    return render_template("ventas/ventas_caja.html")


# ============================================================
# API ENDPOINTS - ESTADÍSTICAS (UNIFICADAS)
# ============================================================

@ventas.route("/api/estadisticas")
@login_required
@roles_required('admin', 'empleado')
def api_estadisticas():
    """Estadísticas de ventas unificadas (caja + online)"""
    try:
        # Ventas de hoy (caja + online)
        result = db.session.execute(
            text("""
                SELECT 
                    COALESCE(SUM(total), 0) AS total_hoy,
                    COUNT(*) AS ventas_hoy,
                    COALESCE(SUM(piezas), 0) AS total_piezas
                FROM (
                    -- Ventas de caja hoy
                    SELECT v.total, COALESCE(SUM(dv.cantidad), 0) AS piezas
                    FROM ventas v
                    LEFT JOIN detalle_ventas dv ON dv.id_venta = v.id_venta
                    WHERE v.estado = 'completada'
                      AND DATE(v.fecha_venta) = CURDATE()
                    GROUP BY v.id_venta, v.total
                    
                    UNION ALL
                    
                    -- Pedidos online entregados hoy
                    SELECT p.total_estimado AS total, COALESCE(SUM(dp.cantidad), 0) AS piezas
                    FROM pedidos p
                    LEFT JOIN detalle_pedidos dp ON dp.id_pedido = p.id_pedido
                    WHERE p.estado = 'entregado'
                      AND DATE(p.actualizado_en) = CURDATE()
                    GROUP BY p.id_pedido, p.total_estimado
                ) AS ventas_diarias
            """)
        )
        
        row = result.fetchone()
        
        # Ventas de la semana
        result_semana = db.session.execute(
            text("""
                SELECT COALESCE(SUM(total), 0) AS total_semana
                FROM (
                    SELECT v.total AS total
                    FROM ventas v
                    WHERE v.estado = 'completada'
                      AND YEARWEEK(v.fecha_venta, 1) = YEARWEEK(CURDATE(), 1)
                    
                    UNION ALL
                    
                    SELECT p.total_estimado AS total
                    FROM pedidos p
                    WHERE p.estado = 'entregado'
                      AND YEARWEEK(p.actualizado_en, 1) = YEARWEEK(CURDATE(), 1)
                ) AS ventas_semanales
            """)
        )
        row_semana = result_semana.fetchone()
        
        # Calcular total de piezas (necesario para el dashboard)
        result_piezas = db.session.execute(
            text("""
                SELECT COALESCE(SUM(piezas), 0) AS total_piezas_semana
                FROM (
                    SELECT COALESCE(SUM(dv.cantidad), 0) AS piezas
                    FROM ventas v
                    LEFT JOIN detalle_ventas dv ON dv.id_venta = v.id_venta
                    WHERE v.estado = 'completada'
                      AND YEARWEEK(v.fecha_venta, 1) = YEARWEEK(CURDATE(), 1)
                    GROUP BY v.id_venta
                    
                    UNION ALL
                    
                    SELECT COALESCE(SUM(dp.cantidad), 0) AS piezas
                    FROM pedidos p
                    LEFT JOIN detalle_pedidos dp ON dp.id_pedido = p.id_pedido
                    WHERE p.estado = 'entregado'
                      AND YEARWEEK(p.actualizado_en, 1) = YEARWEEK(CURDATE(), 1)
                    GROUP BY p.id_pedido
                ) AS piezas_semanales
            """)
        )
        row_piezas = result_piezas.fetchone()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'estadisticas': {
                'total_hoy': float(row.total_hoy) if row.total_hoy else 0,
                'ventas_hoy': int(row.ventas_hoy) if row.ventas_hoy else 0,
                'total_piezas': float(row.total_piezas) if row.total_piezas else 0,
                'total_semana': float(row_semana.total_semana) if row_semana.total_semana else 0,
                'total_piezas_semana': float(row_piezas.total_piezas_semana) if row_piezas.total_piezas_semana else 0
            }
        })
    except Exception as e:
        db.session.rollback()
        current_app.logger.error('Error al consultar estadisticas de ventas | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({'success': False, 'error': str(e)}), 500
    
# ============================================================
# API ENDPOINTS - LISTA DE VENTAS (UNIFICADA)
# ============================================================

@ventas.route("/api/ventas", methods=['GET'])
@login_required
@roles_required('admin', 'empleado')
def api_lista_ventas():
    """Lista de ventas unificadas (caja + pedidos online)"""
    fecha_inicio = request.args.get('fecha_inicio')
    fecha_fin = request.args.get('fecha_fin')
    offset = int(request.args.get('offset', 0))
    limit = int(request.args.get('limit', 20))
    
    try:
        # Ventas de caja - con collations estandarizadas
        query_caja = """
            SELECT 
                v.id_venta AS id,
                v.folio_venta AS folio,
                v.fecha_venta AS fecha,
                v.total AS total,
                CONVERT(v.metodo_pago USING utf8mb4) COLLATE utf8mb4_unicode_ci AS metodo_pago,
                'completada' AS estado,
                CONVERT(u.nombre_completo USING utf8mb4) COLLATE utf8mb4_unicode_ci AS vendedor_nombre,
                'caja' AS origen
            FROM ventas v
            JOIN usuarios u ON u.id_usuario = v.vendedor_id
            WHERE v.estado = 'completada'
        """
        
        # Pedidos online - con collations estandarizadas
        query_pedidos = """
            SELECT 
                p.id_pedido AS id,
                CONCAT('PED-', LPAD(p.id_pedido, 4, '0')) AS folio,
                p.actualizado_en AS fecha,
                p.total_estimado AS total,
                CONVERT(p.metodo_pago USING utf8mb4) COLLATE utf8mb4_unicode_ci AS metodo_pago,
                'entregado' AS estado,
                CONVERT(u.nombre_completo USING utf8mb4) COLLATE utf8mb4_unicode_ci AS vendedor_nombre,
                'online' AS origen
            FROM pedidos p
            JOIN usuarios u ON u.id_usuario = COALESCE(p.atendido_por, 1)
            WHERE p.estado = 'entregado'
        """
        
        params = {}
        
        # Agregar filtros de fecha si existen
        if fecha_inicio:
            query_caja += " AND DATE(v.fecha_venta) >= :fecha_inicio"
            query_pedidos += " AND DATE(p.actualizado_en) >= :fecha_inicio"
            params['fecha_inicio'] = fecha_inicio
        
        if fecha_fin:
            query_caja += " AND DATE(v.fecha_venta) <= :fecha_fin"
            query_pedidos += " AND DATE(p.actualizado_en) <= :fecha_fin"
            params['fecha_fin'] = fecha_fin
        
        # Unir ambas consultas
        full_query = f"""
            SELECT * FROM (
                {query_caja}
                UNION ALL
                {query_pedidos}
            ) AS todas_ventas
            ORDER BY fecha DESC
            LIMIT :limit OFFSET :offset
        """
        
        params['limit'] = limit
        params['offset'] = offset
        
        result = db.session.execute(text(full_query), params)
        
        ventas_list = []
        
        for row in result:
            # Obtener productos resumen
            productos_resumen = ""
            if row.origen == 'caja':
                prod_result = db.session.execute(
                    text("""
                        SELECT p.nombre, dv.cantidad
                        FROM detalle_ventas dv
                        JOIN productos p ON p.id_producto = dv.id_producto
                        WHERE dv.id_venta = :id_venta
                        LIMIT 3
                    """),
                    {'id_venta': row.id}
                ).fetchall()
                if prod_result:
                    productos_resumen = ', '.join([f"{p.nombre} x{int(p.cantidad)}" for p in prod_result])
                else:
                    productos_resumen = "Sin productos"
            else:
                prod_result = db.session.execute(
                    text("""
                        SELECT p.nombre, dp.cantidad
                        FROM detalle_pedidos dp
                        JOIN productos p ON p.id_producto = dp.id_producto
                        WHERE dp.id_pedido = :id_pedido
                        LIMIT 3
                    """),
                    {'id_pedido': row.id}
                ).fetchall()
                if prod_result:
                    productos_resumen = ', '.join([f"{p.nombre} x{int(p.cantidad)}" for p in prod_result])
                else:
                    productos_resumen = "Sin productos"
            
            ventas_list.append({
                'id_venta': row.id,
                'folio_venta': row.folio,
                'fecha_venta': row.fecha.strftime('%Y-%m-%d %H:%M:%S') if row.fecha else None,
                'total': float(row.total) if row.total else 0,
                'metodo_pago': row.metodo_pago,
                'estado': row.estado,
                'vendedor_nombre': row.vendedor_nombre,
                'origen': row.origen,
                'productos_resumen': productos_resumen
            })
        
        # Consulta separada para el total (sin paginación)
        count_query = f"""
            SELECT COUNT(*) as total FROM (
                {query_caja}
                UNION ALL
                {query_pedidos}
            ) AS total_ventas
        """
        count_params = {}
        if fecha_inicio:
            count_params['fecha_inicio'] = fecha_inicio
        if fecha_fin:
            count_params['fecha_fin'] = fecha_fin
        
        total_result = db.session.execute(text(count_query), count_params)
        total_filas = total_result.fetchone().total
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'ventas': ventas_list,
            'total': total_filas,
            'offset': offset,
            'limit': limit
        })
    except Exception as e:
        db.session.rollback()
        current_app.logger.error('Error al consutar lista de ventas | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
    
# ============================================================
# API ENDPOINTS - DETALLE DE VENTA (UNIFICADO)
# ============================================================

@ventas.route("/api/ventas/<int:id_venta>")
@login_required
@roles_required('admin', 'empleado')
def api_detalle_venta(id_venta):
    """Detalle completo de una venta (caja o pedido online)"""
    try:
        with role_connection() as conn:
            venta_caja = conn.execute(
                text("""
                    SELECT
                        v.id_venta,
                        v.folio_venta,
                        v.fecha_venta,
                        v.total,
                        v.metodo_pago,
                        v.cambio,
                        v.estado,
                        u.nombre_completo AS vendedor_nombre,
                        'caja' AS origen,
                        NULL AS fecha_recogida,
                        NULL AS notas_cliente
                    FROM ventas v
                    JOIN usuarios u ON u.id_usuario = v.vendedor_id
                    WHERE v.id_venta = :id_venta AND v.estado = 'completada'
                """),
                {'id_venta': id_venta}
            ).fetchone()

            if venta_caja:
                venta = {
                    'id_venta': venta_caja.id_venta,
                    'folio_venta': venta_caja.folio_venta,
                    'fecha_venta': venta_caja.fecha_venta.strftime('%Y-%m-%d %H:%M:%S') if venta_caja.fecha_venta else None,
                    'total': float(venta_caja.total) if venta_caja.total else 0,
                    'metodo_pago': venta_caja.metodo_pago,
                    'cambio': float(venta_caja.cambio) if venta_caja.cambio else 0,
                    'estado': venta_caja.estado,
                    'vendedor_nombre': venta_caja.vendedor_nombre,
                    'origen': 'caja',
                    'fecha_recogida': None,
                    'notas_cliente': None
                }

                detalles_result = conn.execute(
                    text("""
                        SELECT
                            dv.id_detalle_venta AS id_detalle,
                            p.nombre AS producto_nombre,
                            p.descripcion AS producto_descripcion,
                            dv.cantidad,
                            dv.precio_unitario,
                            dv.descuento_pct,
                            dv.subtotal
                        FROM detalle_ventas dv
                        JOIN productos p ON p.id_producto = dv.id_producto
                        WHERE dv.id_venta = :id_venta
                        ORDER BY dv.id_detalle_venta
                    """),
                    {'id_venta': id_venta}
                ).fetchall()

            else:
                pedido = conn.execute(
                    text("""
                        SELECT
                            p.id_pedido,
                            p.folio,
                            p.actualizado_en AS fecha_venta,
                            p.total_estimado AS total,
                            p.metodo_pago,
                            'completada' AS estado,
                            u.nombre_completo AS vendedor_nombre,
                            p.fecha_recogida,
                            p.notas_cliente,
                            'online' AS origen
                        FROM pedidos p
                        JOIN usuarios u ON u.id_usuario = COALESCE(p.atendido_por, 1)
                        WHERE p.id_pedido = :id_pedido AND p.estado = 'entregado'
                    """),
                    {'id_pedido': id_venta}
                ).fetchone()

                if not pedido:
                    return jsonify({'success': False, 'error': 'Venta no encontrada'}), 404

                venta = {
                    'id_venta': pedido.id_pedido,
                    'folio_venta': pedido.folio,
                    'fecha_venta': pedido.fecha_venta.strftime('%Y-%m-%d %H:%M:%S') if pedido.fecha_venta else None,
                    'total': float(pedido.total) if pedido.total else 0,
                    'metodo_pago': pedido.metodo_pago,
                    'cambio': 0,
                    'estado': pedido.estado,
                    'vendedor_nombre': pedido.vendedor_nombre,
                    'origen': 'online',
                    'fecha_recogida': pedido.fecha_recogida.strftime('%Y-%m-%d %H:%M:%S') if pedido.fecha_recogida else None,
                    'notas_cliente': pedido.notas_cliente
                }

                detalles_result = conn.execute(
                    text("""
                        SELECT
                            dp.id_detalle,
                            p.nombre AS producto_nombre,
                            p.descripcion AS producto_descripcion,
                            dp.cantidad,
                            dp.precio_unitario,
                            0 AS descuento_pct,
                            dp.subtotal
                        FROM detalle_pedidos dp
                        JOIN productos p ON p.id_producto = dp.id_producto
                        WHERE dp.id_pedido = :id_pedido
                        ORDER BY dp.id_detalle
                    """),
                    {'id_pedido': id_venta}
                ).fetchall()

        detalles = []
        for row in detalles_result:
            detalles.append({
                'id_detalle_venta': row.id_detalle,
                'producto_nombre': row.producto_nombre,
                'producto_descripcion': row.producto_descripcion if hasattr(row, 'producto_descripcion') else '',
                'cantidad': float(row.cantidad) if row.cantidad else 0,
                'precio_unitario': float(row.precio_unitario) if row.precio_unitario else 0,
                'descuento_pct': float(row.descuento_pct) if row.descuento_pct else 0,
                'subtotal': float(row.subtotal) if row.subtotal else 0
            })

        return jsonify({
            'success': True,
            'venta': venta,
            'detalles': detalles
        })

    except Exception as e:
        current_app.logger.error('Error al consultar detalle de venta | usuario: %s | id_venta: %s | error: %s | fecha: %s', current_user.username, id_venta, str(e), datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({'success': False, 'error': str(e)}), 500


# ============================================================
# API ENDPOINTS - VENTAS EN CAJA (NUEVOS)
# ============================================================

@ventas.route("/api/productos-stock")
@login_required
@roles_required('admin', 'empleado')
def api_productos_stock():
    """Obtener productos con stock disponible para venta en caja"""
    try:
        with role_connection() as conn:
            result = conn.execute(
                text("""
                    SELECT
                        id_producto,
                        nombre,
                        descripcion,
                        imagen_url,
                        precio_venta,
                        stock_actual,
                        estado_stock
                    FROM vw_productos_stock
                    WHERE estatus = 'activo'
                    ORDER BY nombre
                """)
            )

            productos = []
            for row in result:
                productos.append({
                    'id_producto': row.id_producto,
                    'nombre': row.nombre,
                    'descripcion': row.descripcion,
                    'imagen_url': row.imagen_url,
                    'precio_venta': float(row.precio_venta) if row.precio_venta else 0,
                    'stock_actual': float(row.stock_actual) if row.stock_actual else 0,
                    'estado_stock': row.estado_stock
                })

        return jsonify({'success': True, 'productos': productos})

    except Exception as e:
        current_app.logger.error('Error al consultar productos en stock (api ventas) | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({'success': False, 'error': str(e)}), 500

@ventas.route("/api/estadisticas-caja")
@login_required
@roles_required('admin', 'empleado')
def api_estadisticas_caja():
    """Estadísticas de ventas en caja"""
    try:
        with role_connection() as conn:
            row_hoy = conn.execute(
                text("""
                    SELECT
                        COALESCE(SUM(total), 0) AS total_hoy,
                        COUNT(*) AS ventas_hoy,
                        COALESCE(SUM(total_piezas), 0) AS total_piezas
                    FROM vw_ventas_caja
                    WHERE DATE(fecha_venta) = CURDATE()
                """)
            ).fetchone()

            row_semana = conn.execute(
                text("""
                    SELECT COALESCE(SUM(total), 0) AS total_semana
                    FROM vw_ventas_caja
                    WHERE YEARWEEK(fecha_venta, 1) = YEARWEEK(CURDATE(), 1)
                """)
            ).fetchone()

        return jsonify({
            'success': True,
            'estadisticas': {
                'total_hoy': float(row_hoy.total_hoy) if row_hoy.total_hoy else 0,
                'ventas_hoy': int(row_hoy.ventas_hoy) if row_hoy.ventas_hoy else 0,
                'total_piezas': float(row_hoy.total_piezas) if row_hoy.total_piezas else 0,
                'total_semana': float(row_semana.total_semana) if row_semana.total_semana else 0
            }
        })
    except Exception as e:
        current_app.logger.error('Error al consultar estadisticas de caja | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({'success': False, 'error': str(e)}), 500


@ventas.route("/api/registrar-venta-caja", methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def api_registrar_venta_caja():
    """Registrar una nueva venta en caja y descontar inventario"""
    try:
        data = request.get_json()

        if not data:
            return jsonify({'success': False, 'error': 'No se recibieron datos'}), 400

        productos = data.get('productos', [])
        metodo_pago = data.get('metodo_pago', 'efectivo')
        efectivo_recibido = data.get('efectivo_recibido', 0)

        if not productos:
            return jsonify({'success': False, 'error': 'Debe seleccionar al menos un producto'}), 400

        if metodo_pago not in ['efectivo', 'tarjeta', 'transferencia']:
            return jsonify({'success': False, 'error': 'Método de pago no válido'}), 400

        productos_json = json.dumps([
            {
                'id_producto': p['id_producto'],
                'cantidad': float(p['cantidad']),
                'precio': float(p['precio'])
            }
            for p in productos
        ])

        with role_connection() as conn:
            # Validar stock
            for producto in productos:
                stock_result = conn.execute(
                    text("SELECT stock_actual FROM inventario_pt WHERE id_producto = :id_producto"),
                    {'id_producto': producto['id_producto']}
                ).fetchone()

                if not stock_result or stock_result.stock_actual < producto['cantidad']:
                    return jsonify({'success': False, 'error': 'Stock insuficiente'}), 400

            conn.execute(
                text("""
                    CALL sp_registrar_venta_caja(
                        :productos_json,
                        :metodo_pago,
                        :efectivo_recibido,
                        :vendedor_id,
                        @id_venta,
                        @folio_venta,
                        @cambio,
                        @total
                    )
                """),
                {
                    'productos_json': productos_json,
                    'metodo_pago': metodo_pago,
                    'efectivo_recibido': float(efectivo_recibido) if efectivo_recibido else 0,
                    'vendedor_id': current_user.id_usuario
                }
            )

            output = conn.execute(
                text("SELECT @id_venta AS id_venta, @folio_venta AS folio_venta, @cambio AS cambio, @total AS total")
            ).fetchone()

            conn.commit()

        current_app.logger.info('Venta en caja registrada | usuario: %s | folio: %s | total: %s | fecha: %s', current_user.username, output.folio_venta, output.total, datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({
            'success': True,
            'venta': {
                'id_venta': output.id_venta,
                'folio_venta': output.folio_venta,
                'cambio': float(output.cambio) if output.cambio else 0,
                'total': float(output.total) if output.total else 0
            }
        })

    except Exception as e:
        current_app.logger.error('Error general al registrar venta en caja | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({'success': False, 'error': str(e)}), 500


@ventas.route("/api/generar-ticket/<int:id_venta>", methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def api_generar_ticket(id_venta):
    """Generar ticket de impresión para una venta en caja"""
    try:
        with role_connection() as conn:
            venta_result = conn.execute(
                text("""
                    SELECT
                        v.id_venta,
                        v.folio_venta,
                        v.fecha_venta,
                        v.total,
                        v.metodo_pago,
                        v.cambio,
                        u.nombre_completo AS vendedor_nombre
                    FROM ventas v
                    JOIN usuarios u ON u.id_usuario = v.vendedor_id
                    WHERE v.id_venta = :id_venta AND v.estado = 'completada'
                """),
                {'id_venta': id_venta}
            ).fetchone()

            if not venta_result:
                return jsonify({'success': False, 'error': 'Venta no encontrada'}), 404

            detalles_result = conn.execute(
                text("""
                    SELECT
                        p.nombre AS producto_nombre,
                        dv.cantidad,
                        dv.precio_unitario,
                        dv.subtotal
                    FROM detalle_ventas dv
                    JOIN productos p ON p.id_producto = dv.id_producto
                    WHERE dv.id_venta = :id_venta
                    ORDER BY dv.id_detalle_venta
                """),
                {'id_venta': id_venta}
            ).fetchall()

            detalles = []
            for row in detalles_result:
                detalles.append({
                    'producto_nombre': row.producto_nombre,
                    'cantidad': float(row.cantidad),
                    'precio_unitario': float(row.precio_unitario),
                    'subtotal': float(row.subtotal)
                })

            ticket_content = {
                'folio': venta_result.folio_venta,
                'fecha': venta_result.fecha_venta.strftime('%d/%m/%Y %H:%M:%S'),
                'vendedor': venta_result.vendedor_nombre,
                'metodo_pago': venta_result.metodo_pago,
                'cambio': float(venta_result.cambio) if venta_result.cambio else 0,
                'total': float(venta_result.total),
                'detalles': detalles
            }

            existing = conn.execute(
                text("SELECT id_ticket FROM tickets WHERE id_venta = :id_venta"),
                {'id_venta': id_venta}
            ).fetchone()

            if existing:
                conn.execute(
                    text("""
                        UPDATE tickets
                        SET contenido_json = :contenido,
                            generado_en = NOW(),
                            impreso = 0
                        WHERE id_venta = :id_venta
                    """),
                    {'contenido': json.dumps(ticket_content, cls=DecimalEncoder), 'id_venta': id_venta}
                )
            else:
                conn.execute(
                    text("""
                        INSERT INTO tickets (id_venta, contenido_json, impreso, generado_en)
                        VALUES (:id_venta, :contenido, 0, NOW())
                    """),
                    {'id_venta': id_venta, 'contenido': json.dumps(ticket_content, cls=DecimalEncoder)}
                )

            conn.commit()

        current_app.logger.info('Ticket generado | usuario: %s | folio_venta: %s | fecha: %s', current_user.username, ticket_content['folio'], datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({'success': True, 'ticket': ticket_content})

    except Exception as e:
        current_app.logger.error('Error general al generar ticket | usuario: %s | id_venta: %s | error: %s | fecha: %s', current_user.username, id_venta, str(e), datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({'success': False, 'error': str(e)}), 500

# ─── FUNCIONES DEL CORTE ───────

@ventas.route("/corte-ventas")
@login_required
@roles_required('admin', 'empleado')
def corte_ventas():
    """Página del corte de ventas diario."""
    current_app.logger.info('Vista de panel de corte de caja accesada | usuario: %s | fecha: %s', current_user.username, datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    hoy = date.today().isoformat()
    return render_template("ventas/corteVentas.html", hoy=hoy)


@ventas.route("/api/corte-ventas/resumen")
@login_required
@roles_required('admin', 'empleado')
def api_corte_resumen():
    """
    Devuelve el resumen del corte para la fecha indicada.
    Param: ?fecha=YYYY-MM-DD  (default: hoy)
    """
    fecha_str = request.args.get('fecha', date.today().isoformat())

    try:
        datetime.strptime(fecha_str, '%Y-%m-%d')
    except ValueError:
        return jsonify({'ok': False, 'error': 'Fecha inválida.'}), 400

    try:
        raw_conn = get_role_engine().raw_connection()
        try:
            cur = raw_conn.cursor()
            cur.callproc('sp_corte_resumen', (fecha_str,))

            kpis_raw      = fetch_as_dict(cur); cur.nextset()
            ventas_raw    = fetch_as_dict(cur); cur.nextset()
            productos_raw = fetch_as_dict(cur); cur.nextset()
            corte_raw     = fetch_as_dict(cur)
            cur.close()
        finally:
            raw_conn.close()

        kpi = kpis_raw[0] if kpis_raw else {}

        ventas_list = [
            {
                'origen'      : r.get('origen', ''),
                'folio'       : r.get('folio', ''),
                'hora'        : str(r.get('hora')) if r.get('hora') else '',
                'total'       : float(r.get('total', 0) or 0),
                'metodo_pago' : r.get('metodo_pago', ''),
                'estado'      : r.get('estado', ''),
                'vendedor'    : r.get('vendedor', ''),
                'total_piezas': int(r.get('total_piezas', 0) or 0),
            }
            for r in ventas_raw
        ]

        productos_list = [
            {
                'producto'       : r.get('producto', ''),
                'piezas_vendidas': int(r.get('piezas_vendidas', 0) or 0),
                'total_generado' : float(r.get('total_generado', 0) or 0),
            }
            for r in productos_raw
        ]

        corte = None
        if corte_raw:
            c  = corte_raw[0]
            ce = c.get('cerrado_en')
            corte = {
                'id_corte'          : c.get('id_corte'),
                'estado'            : c.get('estado', ''),
                'total_ventas'      : float(c.get('total_ventas', 0) or 0),
                'total_tickets'     : int(c.get('total_tickets', 0) or 0),
                'efectivo'          : float(c.get('efectivo', 0) or 0),
                'tarjeta'           : float(c.get('tarjeta', 0) or 0),
                'transferencia'     : float(c.get('transferencia', 0) or 0),
                'cancelaciones'     : int(c.get('cancelaciones', 0) or 0),
                'cerrado_en'        : ce.strftime('%d/%m/%Y %H:%M') if ce else None,
                'cerrado_por_nombre': c.get('cerrado_por_nombre', ''),
            }

        return jsonify({
            'ok'       : True,
            'kpis'     : {
                'num_ventas'   : int(kpi.get('num_ventas', 0) or 0),
                'total_vendido': float(kpi.get('total_vendido', 0) or 0),
                'total_piezas' : float(kpi.get('total_piezas', 0) or 0),
                'efectivo'     : float(kpi.get('efectivo', 0) or 0),
                'tarjeta'      : float(kpi.get('tarjeta', 0) or 0),
                'transferencia': float(kpi.get('transferencia', 0) or 0),
                'cancelaciones': int(kpi.get('cancelaciones', 0) or 0),
            },
            'ventas'   : ventas_list,
            'productos': productos_list,
            'corte'    : corte,
        })

    except Exception as exc:
        current_app.logger.error('Error general al obtener resumen de corte | usuario: %s | fecha_objetivo: %s | error: %s | fecha: %s', current_user.username, fecha_str, str(exc), datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({'ok': False, 'error': str(exc)}), 500


@ventas.route("/api/corte-ventas/generar", methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def api_corte_generar():
    """
    Genera (cierra) el corte diario para la fecha indicada.
    Body: fecha=YYYY-MM-DD  +  X-CSRFToken header
    """
    fecha_str = request.form.get('fecha', '').strip()
    efectivo_declarado = request.form.get('efectivo_declarado', 0)
    usuario_id = current_user.id_usuario

    try:
        datetime.strptime(fecha_str, '%Y-%m-%d')
    except ValueError:
        return jsonify({'ok': False, 'mensaje': 'Fecha inválida.'}), 400

    try:
        raw_conn = get_role_engine().raw_connection()
        try:
            cur = raw_conn.cursor()
            cur.callproc('sp_corte_generar', (fecha_str, usuario_id, efectivo_declarado, 0, ''))
            cur.close()

            out = raw_conn.cursor()
            out.execute('SELECT @_sp_corte_generar_3, @_sp_corte_generar_4')
            row = out.fetchone()
            out.close()

            if row:
                ok      = int(row[0]) if row[0] is not None else 0
                mensaje = str(row[1]) if row[1] is not None else ''
            else:
                ok      = 0
                mensaje = "Error al leer la respuesta del procedimiento."

            if ok:
                raw_conn.commit()
            else:
                raw_conn.rollback()
        finally:
            raw_conn.close()

        if ok:
            current_app.logger.info('Corte de caja generado exitosamente | usuario: %s | fecha_objetivo: %s | efectivo_declarado: %s | fecha: %s', current_user.username, fecha_str, efectivo_declarado, datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        else:
            current_app.logger.warning('Generacion de corte fallida | usuario: %s | fecha_objetivo: %s | error: %s | fecha: %s', current_user.username, fecha_str, mensaje, datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({'ok': bool(ok), 'mensaje': mensaje})

    except Exception as exc:
        current_app.logger.error('Error general al generar corte de caja | usuario: %s | error: %s | fecha: %s', current_user.username, str(exc), datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        return jsonify({'ok': False, 'mensaje': str(exc)}), 500
