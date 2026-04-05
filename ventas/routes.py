from . import ventas
from flask import render_template, request, jsonify, session
from flask_login import login_required, current_user
from sqlalchemy import text
from models import db
import json
from decimal import Decimal

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

# ============================================================
# RUTAS DE VISTAS (HTML)
# ============================================================

@ventas.route("/")
@ventas.route("/ventas")
@login_required
def index_ventas():
    return render_template("ventas/ventas.html")

@ventas.route("/corte-ventas")
@login_required
def corte_ventas():
    return render_template("ventas/corteVentas.html")

@ventas.route("/ventas-online")
@login_required
def ventas_online():
    return render_template("ventas/ventas-online.html")

@ventas.route("/checkout")
@login_required
def checkout():
    return render_template("ventas/checkout.html")

# ============================================================
# API ENDPOINTS (con prefijo /api/)
# ============================================================

@ventas.route("/api/catalogo")
@login_required
def api_catalogo():
    """Obtener catálogo de productos con stock actual"""
    busqueda = request.args.get('busqueda', '')
    
    try:
        result = db.session.execute(
            text("CALL sp_catalogo_ventas(:busqueda)"),
            {'busqueda': busqueda}
        )
        
        productos = []
        for row in result:
            productos.append({
                'id_producto': row.id_producto,
                'nombre': row.nombre,
                'descripcion': row.descripcion,
                'precio_venta': float(row.precio_venta) if row.precio_venta else 0,
                'stock_actual': float(row.stock_actual) if row.stock_actual else 0,
                'stock_minimo': float(row.stock_minimo) if row.stock_minimo else 0,
                'estado_stock': row.estado_stock
            })
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'productos': productos
        })
    except Exception as e:
        db.session.rollback()
        print(f"Error en api_catalogo: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@ventas.route("/api/estadisticas")
@login_required
def api_estadisticas():
    """Obtener estadísticas rápidas de ventas"""
    try:
        # Consulta directa de estadísticas
        result = db.session.execute(
            text("""
                SELECT 
                    COALESCE(SUM(CASE WHEN DATE(fecha_venta) = CURDATE() AND estado = 'completada' THEN total ELSE 0 END), 0) AS total_hoy,
                    COUNT(CASE WHEN DATE(fecha_venta) = CURDATE() AND estado = 'completada' THEN 1 END) AS ventas_hoy,
                    COALESCE(SUM(CASE WHEN YEARWEEK(fecha_venta, 1) = YEARWEEK(CURDATE(), 1) AND estado = 'completada' THEN total ELSE 0 END), 0) AS total_semana,
                    COALESCE(SUM(CASE WHEN DATE(fecha_venta) = CURDATE() AND estado = 'completada' AND metodo_pago = 'efectivo' THEN total ELSE 0 END), 0) AS efectivo_hoy,
                    COALESCE(SUM(CASE WHEN DATE(fecha_venta) = CURDATE() AND estado = 'completada' AND metodo_pago = 'tarjeta' THEN total ELSE 0 END), 0) AS tarjeta_hoy,
                    COALESCE(SUM(CASE WHEN DATE(fecha_venta) = CURDATE() AND estado = 'completada' AND metodo_pago = 'transferencia' THEN total ELSE 0 END), 0) AS transferencia_hoy,
                    COALESCE(SUM(CASE WHEN DATE(fecha_venta) = CURDATE() AND estado = 'completada' THEN (SELECT COALESCE(SUM(cantidad), 0) FROM detalle_ventas WHERE id_venta = ventas.id_venta) ELSE 0 END), 0) AS total_piezas
                FROM ventas
            """)
        )
        
        row = result.fetchone()
        db.session.commit()
        
        return jsonify({
            'success': True,
            'estadisticas': {
                'total_hoy': float(row.total_hoy) if row.total_hoy else 0,
                'ventas_hoy': int(row.ventas_hoy) if row.ventas_hoy else 0,
                'total_semana': float(row.total_semana) if row.total_semana else 0,
                'efectivo_hoy': float(row.efectivo_hoy) if row.efectivo_hoy else 0,
                'tarjeta_hoy': float(row.tarjeta_hoy) if row.tarjeta_hoy else 0,
                'transferencia_hoy': float(row.transferencia_hoy) if row.transferencia_hoy else 0,
                'total_piezas': float(row.total_piezas) if row.total_piezas else 0
            }
        })
    except Exception as e:
        db.session.rollback()
        print(f"Error en api_estadisticas: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@ventas.route("/api/ventas", methods=['GET'])
@login_required
def api_lista_ventas():
    """Lista paginada de ventas con filtros"""
    fecha_inicio = request.args.get('fecha_inicio')
    fecha_fin = request.args.get('fecha_fin')
    metodo_pago = request.args.get('metodo_pago')
    estado = request.args.get('estado', 'completada')
    vendedor_id = request.args.get('vendedor_id')
    offset = int(request.args.get('offset', 0))
    limit = int(request.args.get('limit', 20))
    
    try:
        # Obtener lista de ventas
        result = db.session.execute(
            text("""
                SELECT 
                    v.id_venta,
                    v.folio_venta,
                    v.fecha_venta,
                    v.total,
                    v.metodo_pago,
                    v.cambio,
                    v.estado,
                    v.requiere_ticket,
                    u.nombre_completo AS vendedor_nombre,
                    COUNT(dv.id_detalle_venta) AS num_productos,
                    COUNT(*) OVER () AS total_filas
                FROM ventas v
                JOIN usuarios u ON u.id_usuario = v.vendedor_id
                LEFT JOIN detalle_ventas dv ON dv.id_venta = v.id_venta
                WHERE (:fecha_inicio IS NULL OR DATE(v.fecha_venta) >= :fecha_inicio)
                  AND (:fecha_fin IS NULL OR DATE(v.fecha_venta) <= :fecha_fin)
                  AND (:metodo_pago IS NULL OR :metodo_pago = '' OR v.metodo_pago = :metodo_pago)
                  AND (:estado IS NULL OR :estado = '' OR v.estado = :estado)
                  AND (:vendedor_id IS NULL OR :vendedor_id = 0 OR v.vendedor_id = :vendedor_id)
                GROUP BY v.id_venta, v.folio_venta, v.fecha_venta, v.total,
                         v.metodo_pago, v.cambio, v.estado, v.requiere_ticket, u.nombre_completo
                ORDER BY v.fecha_venta DESC
                LIMIT :limit OFFSET :offset
            """),
            {
                'fecha_inicio': fecha_inicio,
                'fecha_fin': fecha_fin,
                'metodo_pago': metodo_pago,
                'estado': estado,
                'vendedor_id': int(vendedor_id) if vendedor_id and vendedor_id != '0' else None,
                'offset': offset,
                'limit': limit
            }
        )
        
        ventas_list = []
        total_filas = 0
        
        for row in result:
            ventas_list.append({
                'id_venta': row.id_venta,
                'folio_venta': row.folio_venta,
                'fecha_venta': row.fecha_venta.strftime('%Y-%m-%d %H:%M:%S') if row.fecha_venta else None,
                'total': float(row.total) if row.total else 0,
                'metodo_pago': row.metodo_pago,
                'cambio': float(row.cambio) if row.cambio else 0,
                'estado': row.estado,
                'requiere_ticket': bool(row.requiere_ticket),
                'vendedor_nombre': row.vendedor_nombre,
                'num_productos': row.num_productos or 0
            })
            total_filas = row.total_filas if hasattr(row, 'total_filas') else total_filas
        
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
        print(f"Error en api_lista_ventas: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@ventas.route("/api/ventas/crear", methods=['POST'])
@login_required
def api_crear_venta():
    """Crear una nueva venta usando el stored procedure"""
    data = request.get_json()
    
    if not data:
        return jsonify({'success': False, 'error': 'Datos inválidos'}), 400
    
    items = data.get('items', [])
    metodo_pago = data.get('metodo_pago', 'efectivo')
    monto_recibido = data.get('monto_recibido')
    requiere_ticket = data.get('requiere_ticket', True)
    
    # Validar que haya items
    if not items:
        return jsonify({'success': False, 'error': 'Agrega al menos un producto'}), 400
    
    # Validar método de pago
    if metodo_pago not in ['efectivo', 'tarjeta', 'transferencia', 'otro']:
        return jsonify({'success': False, 'error': 'Método de pago inválido'}), 400
    
    # Si es efectivo, validar monto recibido
    if metodo_pago == 'efectivo' and (monto_recibido is None or float(monto_recibido) <= 0):
        return jsonify({'success': False, 'error': 'Ingresa el monto recibido'}), 400
    
    # Formatear items para el SP
    items_json = []
    total_venta = 0
    for item in items:
        subtotal = float(item['cantidad']) * float(item['precio_unitario']) * (1 - float(item.get('descuento_pct', 0)) / 100)
        total_venta += subtotal
        items_json.append({
            'id_producto': item['id_producto'],
            'cantidad': float(item['cantidad']),
            'precio_unitario': float(item['precio_unitario']),
            'descuento_pct': float(item.get('descuento_pct', 0))
        })
    
    # Validar monto recibido vs total
    if metodo_pago == 'efectivo' and float(monto_recibido) < total_venta:
        return jsonify({'success': False, 'error': f'Monto recibido insuficiente. Total: ${total_venta:.2f}'}), 400
    
    try:
        # Llamar al stored procedure
        db.session.execute(
            text("""
                CALL sp_crear_venta(
                    :vendedor_id, 
                    :metodo_pago, 
                    :monto_recibido, 
                    :requiere_ticket, 
                    :items, 
                    @id_venta, 
                    @folio, 
                    @cambio, 
                    @error
                )
            """),
            {
                'vendedor_id': current_user.id_usuario,
                'metodo_pago': metodo_pago,
                'monto_recibido': float(monto_recibido) if monto_recibido else None,
                'requiere_ticket': 1 if requiere_ticket else 0,
                'items': json.dumps(items_json)
            }
        )
        
        # Obtener los valores de salida
        output = db.session.execute(
            text("SELECT @id_venta AS id_venta, @folio AS folio, @cambio AS cambio, @error AS error")
        ).fetchone()
        
        db.session.commit()
        
        if output.error:
            return jsonify({
                'success': False,
                'error': output.error
            }), 400
        
        # Obtener el ticket generado
        ticket_info = None
        if requiere_ticket and output.id_venta:
            ticket_result = db.session.execute(
                text("""
                    SELECT contenido_json 
                    FROM tickets 
                    WHERE id_venta = :id_venta
                """),
                {'id_venta': output.id_venta}
            ).fetchone()
            
            if ticket_result:
                ticket_info = ticket_result.contenido_json
        
        return jsonify({
            'success': True,
            'id_venta': output.id_venta,
            'folio': output.folio,
            'cambio': float(output.cambio) if output.cambio else 0,
            'ticket': ticket_info
        })
        
    except Exception as e:
        db.session.rollback()
        print(f"Error en api_crear_venta: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@ventas.route("/api/ventas/<folio>")
@login_required
def api_detalle_venta(folio):
    """Obtener detalle completo de una venta por folio"""
    try:
        # Obtener cabecera
        venta_result = db.session.execute(
            text("""
                SELECT v.id_venta, v.folio_venta, v.fecha_venta, v.total, 
                       v.metodo_pago, v.cambio, v.requiere_ticket, v.estado,
                       u.nombre_completo AS vendedor_nombre
                FROM ventas v
                JOIN usuarios u ON u.id_usuario = v.vendedor_id
                WHERE v.folio_venta = :folio
            """),
            {'folio': folio}
        ).fetchone()
        
        if not venta_result:
            return jsonify({'success': False, 'error': 'Venta no encontrada'}), 404
        
        venta = {
            'id_venta': venta_result.id_venta,
            'folio_venta': venta_result.folio_venta,
            'fecha_venta': venta_result.fecha_venta.strftime('%Y-%m-%d %H:%M:%S') if venta_result.fecha_venta else None,
            'total': float(venta_result.total) if venta_result.total else 0,
            'metodo_pago': venta_result.metodo_pago,
            'cambio': float(venta_result.cambio) if venta_result.cambio else 0,
            'requiere_ticket': bool(venta_result.requiere_ticket),
            'estado': venta_result.estado,
            'vendedor_nombre': venta_result.vendedor_nombre
        }
        
        # Obtener detalles
        detalles_result = db.session.execute(
            text("""
                SELECT dv.id_detalle_venta, p.nombre AS producto_nombre,
                       p.descripcion AS producto_descripcion,
                       dv.cantidad, dv.precio_unitario, dv.descuento_pct, dv.subtotal
                FROM detalle_ventas dv
                JOIN productos p ON p.id_producto = dv.id_producto
                WHERE dv.id_venta = :id_venta
                ORDER BY dv.id_detalle_venta
            """),
            {'id_venta': venta['id_venta']}
        ).fetchall()
        
        detalles = []
        for row in detalles_result:
            detalles.append({
                'id_detalle_venta': row.id_detalle_venta,
                'producto_nombre': row.producto_nombre,
                'producto_descripcion': row.producto_descripcion,
                'cantidad': float(row.cantidad) if row.cantidad else 0,
                'precio_unitario': float(row.precio_unitario) if row.precio_unitario else 0,
                'descuento_pct': float(row.descuento_pct) if row.descuento_pct else 0,
                'subtotal': float(row.subtotal) if row.subtotal else 0
            })
        
        # Obtener ticket
        ticket_result = db.session.execute(
            text("""
                SELECT id_ticket, contenido_json, impreso, generado_en
                FROM tickets
                WHERE id_venta = :id_venta
            """),
            {'id_venta': venta['id_venta']}
        ).fetchone()
        
        ticket = None
        if ticket_result:
            ticket = {
                'id_ticket': ticket_result.id_ticket,
                'contenido_json': ticket_result.contenido_json,
                'impreso': bool(ticket_result.impreso),
                'generado_en': ticket_result.generado_en.strftime('%Y-%m-%d %H:%M:%S') if ticket_result.generado_en else None
            }
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'venta': venta,
            'detalles': detalles,
            'ticket': ticket
        })
        
    except Exception as e:
        db.session.rollback()
        print(f"Error en api_detalle_venta: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@ventas.route("/api/ventas/<int:id_venta>/cancelar", methods=['POST'])
@login_required
def api_cancelar_venta(id_venta):
    """Cancelar una venta y restaurar inventario"""
    try:
        # Verificar que la venta existe y está completada
        venta = db.session.execute(
            text("SELECT estado, folio_venta FROM ventas WHERE id_venta = :id_venta"),
            {'id_venta': id_venta}
        ).fetchone()
        
        if not venta:
            return jsonify({'success': False, 'error': 'Venta no encontrada'}), 404
        
        if venta.estado != 'completada':
            return jsonify({'success': False, 'error': f'Solo se pueden cancelar ventas completadas. Estado actual: {venta.estado}'}), 400
        
        # Restaurar inventario
        detalles = db.session.execute(
            text("SELECT id_producto, cantidad FROM detalle_ventas WHERE id_venta = :id_venta"),
            {'id_venta': id_venta}
        ).fetchall()
        
        for detalle in detalles:
            db.session.execute(
                text("""
                    UPDATE inventario_pt 
                    SET stock_actual = stock_actual + :cantidad,
                        ultima_actualizacion = NOW()
                    WHERE id_producto = :id_producto
                """),
                {'id_producto': detalle.id_producto, 'cantidad': detalle.cantidad}
            )
        
        # Marcar venta como cancelada
        db.session.execute(
            text("UPDATE ventas SET estado = 'cancelada' WHERE id_venta = :id_venta"),
            {'id_venta': id_venta}
        )
        
        # Registrar en logs
        db.session.execute(
            text("""
                INSERT INTO logs_sistema (tipo, nivel, id_usuario, modulo, accion, descripcion, creado_en)
                VALUES ('venta', 'WARNING', :usuario_id, 'ventas', 'cancelar_venta',
                        CONCAT('Venta cancelada: ', :folio), NOW())
            """),
            {'usuario_id': current_user.id_usuario, 'folio': venta.folio_venta}
        )
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Venta cancelada exitosamente'
        })
        
    except Exception as e:
        db.session.rollback()
        print(f"Error en api_cancelar_venta: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@ventas.route("/api/ticket/<folio>/imprimir", methods=['POST'])
@login_required
def api_marcar_ticket_impreso(folio):
    """Marcar un ticket como impreso"""
    try:
        db.session.execute(
            text("""
                UPDATE tickets t
                JOIN ventas v ON v.id_venta = t.id_venta
                SET t.impreso = 1
                WHERE v.folio_venta = :folio
            """),
            {'folio': folio}
        )
        db.session.commit()
        
        return jsonify({'success': True})
        
    except Exception as e:
        db.session.rollback()
        print(f"Error en api_marcar_ticket_impreso: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500