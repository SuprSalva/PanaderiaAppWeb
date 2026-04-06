from . import ventas
from flask import render_template, request, jsonify
from flask_login import login_required, current_user
from auth import roles_required
from sqlalchemy import text
from models import db
from decimal import Decimal
import json 

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
@roles_required('admin', 'empleado')
def index_ventas():
    return render_template("ventas/ventas.html")


# ============================================================
# API ENDPOINTS
# ============================================================

@ventas.route("/api/estadisticas")
@login_required
@roles_required('admin', 'empleado')
def api_estadisticas():
    """Estadísticas de ventas (solo pedidos entregados)"""
    try:
        result = db.session.execute(
            text("""
                SELECT 
                    COALESCE(SUM(p.total_estimado), 0) AS total_hoy,
                    COUNT(*) AS ventas_hoy,
                    COALESCE(SUM(CASE WHEN dp.cantidad IS NOT NULL THEN dp.cantidad ELSE 0 END), 0) AS total_piezas
                FROM pedidos p
                LEFT JOIN detalle_pedidos dp ON dp.id_pedido = p.id_pedido
                WHERE p.estado = 'entregado'
                  AND DATE(p.actualizado_en) = CURDATE()
            """)
        )
        
        row = result.fetchone()
        
        # Ventas de la semana
        result_semana = db.session.execute(
            text("""
                SELECT COALESCE(SUM(total_estimado), 0) AS total_semana
                FROM pedidos
                WHERE estado = 'entregado'
                  AND YEARWEEK(actualizado_en, 1) = YEARWEEK(CURDATE(), 1)
            """)
        )
        row_semana = result_semana.fetchone()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'estadisticas': {
                'total_hoy': float(row.total_hoy) if row.total_hoy else 0,
                'ventas_hoy': int(row.ventas_hoy) if row.ventas_hoy else 0,
                'total_piezas': float(row.total_piezas) if row.total_piezas else 0,
                'total_semana': float(row_semana.total_semana) if row_semana.total_semana else 0,
                'efectivo_hoy': 0,  # No aplica para pedidos web
                'tarjeta_hoy': 0,
                'transferencia_hoy': float(row.total_hoy) if row.total_hoy else 0
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
@roles_required('admin', 'empleado')
def api_lista_ventas():
    """Lista de pedidos entregados (son las ventas)"""
    fecha_inicio = request.args.get('fecha_inicio')
    fecha_fin = request.args.get('fecha_fin')
    offset = int(request.args.get('offset', 0))
    limit = int(request.args.get('limit', 20))
    
    try:
        # Consulta base: pedidos entregados
        query = """
            SELECT 
                p.id_pedido,
                CONCAT('PED-', p.folio) AS folio_venta,
                p.actualizado_en AS fecha_venta,
                p.total_estimado AS total,
                'transferencia' AS metodo_pago,
                0 AS cambio,
                'completada' AS estado,
                1 AS requiere_ticket,
                u.nombre_completo AS vendedor_nombre,
                COUNT(dp.id_detalle) AS num_productos,
                COUNT(*) OVER () AS total_filas,
                GROUP_CONCAT(
                    CONCAT(pr.nombre, ' x', dp.cantidad) 
                    SEPARATOR ', '
                ) AS productos_resumen
            FROM pedidos p
            JOIN usuarios u ON u.id_usuario = COALESCE(p.atendido_por, 1)
            LEFT JOIN detalle_pedidos dp ON dp.id_pedido = p.id_pedido
            LEFT JOIN productos pr ON pr.id_producto = dp.id_producto
            WHERE p.estado = 'entregado'
        """
        
        params = {}
        
        if fecha_inicio:
            query += " AND DATE(p.actualizado_en) >= :fecha_inicio"
            params['fecha_inicio'] = fecha_inicio
        
        if fecha_fin:
            query += " AND DATE(p.actualizado_en) <= :fecha_fin"
            params['fecha_fin'] = fecha_fin
        
        query += """
            GROUP BY p.id_pedido, p.folio, p.actualizado_en, p.total_estimado, u.nombre_completo
            ORDER BY p.actualizado_en DESC
            LIMIT :limit OFFSET :offset
        """
        
        params['limit'] = limit
        params['offset'] = offset
        
        result = db.session.execute(text(query), params)
        
        ventas_list = []
        total_filas = 0
        
        for row in result:
            ventas_list.append({
                'id_venta': row.id_pedido,
                'folio_venta': row.folio_venta,
                'fecha_venta': row.fecha_venta.strftime('%Y-%m-%d %H:%M:%S') if row.fecha_venta else None,
                'total': float(row.total) if row.total else 0,
                'metodo_pago': row.metodo_pago,
                'cambio': float(row.cambio) if row.cambio else 0,
                'estado': row.estado,
                'requiere_ticket': bool(row.requiere_ticket),
                'vendedor_nombre': row.vendedor_nombre,
                'num_productos': row.num_productos or 0,
                'productos_resumen': row.productos_resumen or ''
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


@ventas.route("/api/ventas/<int:id_pedido>")
@login_required
@roles_required('admin', 'empleado')
def api_detalle_venta(id_pedido):
    """Detalle completo de un pedido entregado"""
    try:
        # Cabecera del pedido
        pedido_result = db.session.execute(
            text("""
                SELECT 
                    p.id_pedido,
                    CONCAT('PED-', p.folio) AS folio_venta,
                    p.actualizado_en AS fecha_venta,
                    p.total_estimado AS total,
                    'transferencia' AS metodo_pago,
                    0 AS cambio,
                    'completada' AS estado,
                    u.nombre_completo AS vendedor_nombre,
                    p.fecha_recogida,
                    p.notas_cliente
                FROM pedidos p
                JOIN usuarios u ON u.id_usuario = COALESCE(p.atendido_por, 1)
                WHERE p.id_pedido = :id_pedido AND p.estado = 'entregado'
            """),
            {'id_pedido': id_pedido}
        ).fetchone()
        
        if not pedido_result:
            return jsonify({'success': False, 'error': 'Pedido no encontrado o no entregado'}), 404
        
        venta = {
            'id_venta': pedido_result.id_pedido,
            'folio_venta': pedido_result.folio_venta,
            'fecha_venta': pedido_result.fecha_venta.strftime('%Y-%m-%d %H:%M:%S') if pedido_result.fecha_venta else None,
            'total': float(pedido_result.total) if pedido_result.total else 0,
            'metodo_pago': pedido_result.metodo_pago,
            'cambio': float(pedido_result.cambio) if pedido_result.cambio else 0,
            'estado': pedido_result.estado,
            'vendedor_nombre': pedido_result.vendedor_nombre,
            'fecha_recogida': pedido_result.fecha_recogida.strftime('%Y-%m-%d %H:%M:%S') if pedido_result.fecha_recogida else None,
            'notas_cliente': pedido_result.notas_cliente
        }
        
        # Detalles del pedido
        detalles_result = db.session.execute(
            text("""
                SELECT 
                    dp.id_detalle,
                    pr.nombre AS producto_nombre,
                    pr.descripcion AS producto_descripcion,
                    dp.cantidad,
                    dp.precio_unitario,
                    0 AS descuento_pct,
                    dp.subtotal
                FROM detalle_pedidos dp
                JOIN productos pr ON pr.id_producto = dp.id_producto
                WHERE dp.id_pedido = :id_pedido
                ORDER BY dp.id_detalle
            """),
            {'id_pedido': id_pedido}
        ).fetchall()
        
        detalles = []
        for row in detalles_result:
            detalles.append({
                'id_detalle_venta': row.id_detalle,
                'producto_nombre': row.producto_nombre,
                'producto_descripcion': row.producto_descripcion,
                'cantidad': float(row.cantidad) if row.cantidad else 0,
                'precio_unitario': float(row.precio_unitario) if row.precio_unitario else 0,
                'descuento_pct': float(row.descuento_pct) if row.descuento_pct else 0,
                'subtotal': float(row.subtotal) if row.subtotal else 0
            })
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'venta': venta,
            'detalles': detalles,
            'ticket': None  # Los pedidos web no tienen ticket impreso
        })
        
    except Exception as e:
        db.session.rollback()
        print(f"Error en api_detalle_venta: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
    
@ventas.route("/corte-ventas")
@login_required
@roles_required('admin', 'empleado')
def corte_ventas():
    """Vista de corte de ventas (pendiente de implementar)"""
    return render_template("ventas/corteVentas.html")