import json
import datetime
from collections import namedtuple
from markupsafe import Markup

from flask import (
    render_template, request, redirect, url_for,
    flash, jsonify, abort, current_app
)
from flask_login import login_required, current_user
from auth import roles_required
from sqlalchemy import text
from models import db
from pedidos import pedidos_bp
from forms import PedidoCajaForm 


@pedidos_bp.route('/nuevo', methods=['GET'])
@login_required
@roles_required('admin', 'empleado', 'panadero', 'cliente')
def catalogo():
    current_app.logger.info(
        'Vista tienda express | usuario: %s | fecha: %s',
        current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    )
    conn = db.session.connection()
    cur  = conn.connection.cursor()
    cur.execute("CALL sp_catalogo_tienda()")
    rows = cur.fetchall()
    cur.close()
 
    Producto = namedtuple('Producto', [
        'id_producto', 'uuid_producto', 'nombre', 'descripcion',
        'precio_venta', 'stock_actual', 'stock_minimo', 'nivel_stock'
    ])
    productos = [Producto(*r) for r in rows]
 
    productos_json = Markup(json.dumps([
        {
            'id':          p.id_producto,
            'uuid':        p.uuid_producto,
            'nombre':      p.nombre,
            'descripcion': p.descripcion or '',
            'precio':      float(p.precio_venta),
            'stock':       int(p.stock_actual),
            'nivel':       p.nivel_stock,
            'imagen_url':   p.imagen_url or '',
        }
        for p in productos
    ]))
 
    return render_template(
        'pedidos/catalogo.html',
        productos=productos,
        productos_json=productos_json,
    )


@pedidos_bp.route('/nuevo', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero', 'cliente')
def crear_pedido():
    carrito_raw  = request.form.get('carrito_json', '').strip()
    hora_str     = request.form.get('hora_recogida', '').strip()
    metodo_pago  = request.form.get('metodo_pago', 'efectivo').strip()
    notas        = request.form.get('notas', '').strip() or None
 
    if not carrito_raw:
        flash('No se recibieron productos en el pedido.', 'error')
        return redirect(url_for('pedidos.catalogo'))
 
    try:
        carrito_data = json.loads(carrito_raw)
    except (ValueError, TypeError):
        flash('Error al leer los datos del carrito.', 'error')
        return redirect(url_for('pedidos.catalogo'))
 
    if not isinstance(carrito_data, list) or len(carrito_data) == 0:
        flash('Agrega al menos un producto al pedido.', 'error')
        return redirect(url_for('pedidos.catalogo'))
 
    if not hora_str:
        flash('Selecciona la hora de recogida.', 'error')
        return redirect(url_for('pedidos.catalogo'))
 
    if metodo_pago not in ('efectivo', 'tarjeta', 'transferencia'):
        flash('Método de pago inválido.', 'error')
        return redirect(url_for('pedidos.catalogo'))
 
    productos_json_str = json.dumps([
        {'id': item['id'], 'qty': item['qty'], 'precio': item['precio']}
        for item in carrito_data
    ])
 
    try:
        conn = db.session.connection()
        cur  = conn.connection.cursor()
        cur.callproc('sp_pedido_express', (
            current_user.id_usuario,
            hora_str + ':00',
            metodo_pago,
            notas,
            productos_json_str,
            0, '', '',          # OUT p_id_pedido, p_folio, p_error
        ))
        cur.nextset()
        cur.execute(
            "SELECT @_sp_pedido_express_5, "
            "       @_sp_pedido_express_6, "
            "       @_sp_pedido_express_7"
        )
        row = cur.fetchone()
        cur.close()
 
        p_id_pedido, p_folio, p_error = row[0], row[1], row[2]
 
        if p_error:
            db.session.rollback()
            current_app.logger.warning(
                'Pedido express rechazado | usuario: %s | error: %s | fecha: %s',
                current_user.username, p_error,
                datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
            flash(f'No se pudo crear el pedido: {p_error}', 'error')
            return redirect(url_for('pedidos.catalogo'))
 
        db.session.commit()
        n = sum(item['qty'] for item in carrito_data)
        current_app.logger.info(
            'Pedido express creado | usuario: %s | folio: %s | piezas: %s | fecha: %s',
            current_user.username, p_folio, int(n),
            datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        )
        flash(
            f'¡Pedido {p_folio} enviado con {int(n)} '
            f'pieza{"s" if n != 1 else ""}! '
            f'Te avisaremos cuando esté listo para las {hora_str}.',
            'success'
        )
        return redirect(url_for('pedidos.mis_pedidos'))
 
    except Exception as exc:
        db.session.rollback()
        current_app.logger.error(
            'Error al crear pedido express | usuario: %s | error: %s | fecha: %s',
            current_user.username, str(exc),
            datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        )
        flash('Ocurrió un error al guardar tu pedido. Intenta de nuevo.', 'error')
        return redirect(url_for('pedidos.catalogo'))


@pedidos_bp.route('/gestion')
@login_required
@roles_required('admin', 'empleado', 'panadero')
def gestion_pedidos():
    current_app.logger.info(
        'Vista gestión pedidos | usuario: %s | fecha: %s',
        current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    )
    estado = request.args.get('estado', '') or None
    fecha  = request.args.get('fecha', '')  or None
 
    pedidos_rows = db.session.execute(text("""
        SELECT
            p.id_pedido,
            p.folio,
            p.estado,
            p.fecha_recogida,
            p.total_estimado,
            p.metodo_pago,
            p.creado_en,
            u.nombre_completo              AS cliente_nombre,
            u.telefono,
            COALESCE(a.nombre_completo,'—') AS atendido_por,
            GROUP_CONCAT(
              CONCAT(pr.nombre, ' ×', CAST(dp.cantidad AS SIGNED))
              ORDER BY pr.nombre SEPARATOR ' · '
            )                              AS productos_resumen,
            IFNULL(SUM(dp.cantidad), 0)    AS total_piezas
        FROM pedidos p
        JOIN usuarios u  ON u.id_usuario  = p.id_cliente
        LEFT JOIN usuarios a ON a.id_usuario  = p.atendido_por
        LEFT JOIN detalle_pedidos dp ON dp.id_pedido   = p.id_pedido
        LEFT JOIN productos pr       ON pr.id_producto = dp.id_producto
          AND (:estado IS NULL OR p.estado = :estado)
          AND (:fecha  IS NULL OR DATE(p.fecha_recogida) = :fecha)
        GROUP BY
            p.id_pedido, p.folio, p.estado, p.fecha_recogida,
            p.total_estimado, p.metodo_pago, p.creado_en,
            u.nombre_completo, u.telefono, a.nombre_completo
        ORDER BY
            FIELD(p.estado, 'pendiente', 'aprobado', 'listo', 'rechazado'),
            p.fecha_recogida ASC
    """), {'estado': estado, 'fecha': fecha}).mappings().all()
 
    db.session.commit()
 
    conteos_rows = db.session.execute(
        text("SELECT estado, total FROM v_conteo_pedidos_por_estado")
    ).fetchall()
    conteos = {r[0]: r[1] for r in conteos_rows}
 
    _dias  = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo']
    _meses = ['enero','febrero','marzo','abril','mayo','junio',
              'julio','agosto','septiembre','octubre','noviembre','diciembre']
    _now   = datetime.datetime.now()
    fecha_hoy = (
        f"{_dias[_now.weekday()]} {_now.day} "
        f"de {_meses[_now.month - 1]}, {_now.year}"
    )
 
    return render_template(
        'pedidos/gestion_pedidos.html',
        pedidos=pedidos_rows,
        conteos=conteos,
        filtro_estado=estado or '',
        filtro_fecha=fecha or '',
        fecha_hoy=fecha_hoy,
        now=_now,
    )
 

# REEMPLAZAR la función mis_pedidos() en pedidos/routes.py

@pedidos_bp.route('/mis-pedidos')
@login_required
@roles_required('admin', 'empleado', 'panadero', 'cliente')
def mis_pedidos():
    current_app.logger.info(
        'Vista de mis pedidos | usuario: %s | fecha: %s',
        current_user.username,
        datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    )
    conn = db.session.connection()
    cur  = conn.connection.cursor()
    cur.execute("CALL sp_mis_pedidos_cliente(%s)", (current_user.id_usuario,))

    rows_ped   = cur.fetchall()
    cur.nextset()
    rows_notif = cur.fetchall()
    cur.close()

    cols_p = [
        'id_pedido', 'folio', 'estado', 'fecha_recogida',
        'total_estimado', 'motivo_rechazo', 'creado_en',
        'metodo_pago', 'panes_resumen', 'total_piezas'
    ]
    cols_n = ['id_notif', 'id_pedido', 'folio', 'mensaje', 'leida', 'creado_en']

    Pedido = namedtuple('Pedido', cols_p)
    Notif  = namedtuple('Notif',  cols_n)
    pedidos = [Pedido(*r) for r in rows_ped]
    notifs  = [Notif(*r)  for r in rows_notif]

    return render_template(
        'pedidos/mis_pedidos.html',
        pedidos=pedidos,
        notifs=notifs,
    )

@pedidos_bp.route('/pedidos')
@login_required
@roles_required('admin', 'empleado', 'panadero', 'cliente')
def lista():
    current_app.logger.info('Vista de lista general de pedidos accesada | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    estado = request.args.get('estado') or None
    fecha  = request.args.get('fecha')  or None
    buscar = request.args.get('q')      or None

    pedidos = db.session.execute(
        text("CALL sp_lista_pedidos_interna(:estado, :fecha, :buscar)"),
        {'estado': estado, 'fecha': fecha, 'buscar': buscar}
    ).fetchall()

    try:
        db.session.execute(text("DO 0"))
    except Exception:
        pass

    conteos_rows = db.session.execute(
        text("SELECT estado, total FROM v_conteo_pedidos_por_estado")
    ).fetchall()
    conteos = {r[0]: r[1] for r in conteos_rows}

    return render_template('pedidos/lista.html',
                           pedidos=pedidos,
                           conteos=conteos,
                           filtro_estado=estado or '',
                           filtro_fecha=fecha   or '',
                           filtro_q=buscar      or '')



@pedidos_bp.route('/<folio>')
@login_required
@roles_required('admin', 'empleado', 'panadero', 'cliente')
def detalle(folio):
    conn = db.session.connection()
    cur  = conn.connection.cursor()
    cur.execute("CALL sp_detalle_pedido(%s)", (folio,))

    row_pedido = cur.fetchone()
    if not row_pedido:
        cur.close()
        abort(404)

    cols_ped = ['id_pedido', 'folio', 'estado', 'fecha_recogida', 'total_estimado',
                'motivo_rechazo', 'creado_en', 'id_cliente', 'cliente_nombre', 'telefono',
                'atendido_por_nombre', 'tipo_caja', 'tamanio_nombre', 'capacidad']
    Pedido   = namedtuple('Pedido', cols_ped)
    pedido   = Pedido(*row_pedido)

    cur.nextset()
    row_caja = cur.fetchone()
    Caja     = namedtuple('Caja', ['tipo', 'tamanio', 'nombre_caja', 'capacidad', 'precio_venta'])
    caja     = Caja(*row_caja) if row_caja else None

    cur.nextset()
    Item  = namedtuple('Item', ['producto_nombre', 'producto_descripcion',
                                'cantidad', 'precio_unitario', 'subtotal'])
    items = [Item(*r) for r in cur.fetchall()]

    cur.nextset()
    Hist      = namedtuple('Hist', ['estado_antes', 'estado_despues', 'nota',
                                    'creado_en', 'usuario_nombre'])
    historial = [Hist(*r) for r in cur.fetchall()]
    cur.close()

    return render_template('pedidos/detalle.html',
                           pedido=pedido,
                           caja=caja,
                           items=items,
                           historial=historial)



@pedidos_bp.route('/<folio>/estado', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero', 'cliente')
def cambiar_estado(folio):
    nuevo_estado = request.form.get('estado', '').strip()
    nota         = request.form.get('nota', '').strip() or None

    try:
        db.session.execute(text("SET @p_error = NULL"))
        db.session.execute(
            text("""
                CALL sp_cambiar_estado_pedido(
                    :folio, :estado, :user, :nota, @p_error
                )
            """),
            {
                'folio':  folio,
                'estado': nuevo_estado,
                'user':   current_user.id_usuario,
                'nota':   nota,
            }
        )
        row = db.session.execute(text("SELECT @p_error")).fetchone()

        if row[0]:
            db.session.rollback()
            current_app.logger.warning('Cambio de estado fallido (rechazado por db) | usuario: %s | folio: %s | error: %s | fecha: %s', current_user.username, folio, row[0], datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash(f'No se pudo cambiar el estado: {row[0]}', 'error')
            return redirect(url_for('pedidos.detalle', folio=folio))

        db.session.commit()
        LABELS = {
            'aprobado':      'aprobado ✅',
            'rechazado':     'rechazado ❌',
            'en_produccion': 'en producción ⚙️',
            'listo':         'listo para recoger 🎉',
            'entregado':     'entregado 📦',
        }
        current_app.logger.info('Estado de pedido cambiado | usuario: %s | folio: %s | nuevo_estado: %s | fecha: %s', current_user.username, folio, nuevo_estado, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Pedido {folio} marcado como {LABELS.get(nuevo_estado, nuevo_estado)}.', 'success')

    except Exception as e:
        db.session.rollback()
        current_app.logger.error('Error al cambiar estado de pedido | usuario: %s | folio: %s | error: %s | fecha: %s', current_user.username, folio, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('Error al cambiar el estado. Intenta de nuevo.', 'danger')

    return redirect(url_for('pedidos.detalle', folio=folio))


@pedidos_bp.route('/notificaciones/leer', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero', 'cliente')
def marcar_leidas():
    try:
        db.session.execute(
            text("CALL sp_marcar_notifs_leidas(:u)"),
            {'u': current_user.id_usuario}
        )
        db.session.commit()
        return jsonify({'ok': True})
    except Exception:
        db.session.rollback()
        return jsonify({'ok': False}), 500


@pedidos_bp.route('/api/badge')
@login_required
@roles_required('admin', 'empleado', 'panadero', 'cliente')
def badge_notifs():
    row = db.session.execute(
        text("CALL sp_badge_notifs(:u)"),
        {'u': current_user.id_usuario}
    ).fetchone()
    return jsonify({'count': row[0] if row else 0})

# ============================================================
#  AGREGAR al final de pedidos/routes.py
#  (después de la función marcar_leidas)
# ============================================================

@pedidos_bp.route('/produccion-pedidos')
@login_required
@roles_required('admin', 'empleado', 'panadero', 'cliente')
def cola_produccion():
    current_app.logger.info('Vista de cola de produccion accesada | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    estado  = request.args.get('estado', '') or None   # ← esta es la única línea de estado
    fecha   = request.args.get('fecha',  '') or None
    pagina  = request.args.get('pagina', 1, type=int)
    if pagina < 1:
        pagina = 1
    limit  = 20
    offset = (pagina - 1) * limit

    pedidos_rows = db.session.execute(text("""
        SELECT
            p.id_pedido, p.folio, p.estado, p.fecha_recogida,
            p.total_estimado, p.creado_en, p.tipo,
            COALESCE(t.nombre, '—')        AS tamanio_nombre,
            t.capacidad,
            u.nombre_completo              AS cliente_nombre,
            GROUP_CONCAT(
              CONCAT(pr.nombre, ' ×', CAST(dp.cantidad AS SIGNED))
              ORDER BY pr.nombre SEPARATOR ' / '
            )                              AS productos_resumen,
            COUNT(DISTINCT dp.id_producto) AS num_productos,
            IFNULL(SUM(dp.cantidad), 0)    AS total_piezas
        FROM pedidos p
        JOIN usuarios u ON u.id_usuario = p.id_cliente
        LEFT JOIN tamanios_charola t  ON t.id_tamanio   = p.id_tamanio
        LEFT JOIN detalle_pedidos  dp ON dp.id_pedido   = p.id_pedido
        LEFT JOIN productos        pr ON pr.id_producto = dp.id_producto
        WHERE p.estado NOT IN ('entregado')
          AND (:estado IS NULL OR p.estado = :estado)
          AND (:fecha  IS NULL OR DATE(p.fecha_recogida) = :fecha)
        GROUP BY p.id_pedido, p.folio, p.estado, p.fecha_recogida,
                 p.total_estimado, p.creado_en, p.tipo,
                 t.nombre, t.capacidad, u.nombre_completo
        ORDER BY
          FIELD(p.estado, 'en_produccion', 'pendiente_insumos',
                'pendiente', 'aprobado', 'listo', 'rechazado'),
          p.fecha_recogida ASC
        LIMIT :limit OFFSET :offset
    """), {'estado': estado, 'fecha': fecha, 'limit': limit, 'offset': offset}).mappings().all()

    db.session.commit()

    conteos_rows = db.session.execute(text("""
        SELECT estado, COUNT(*) AS total
          FROM pedidos
         WHERE estado NOT IN ('entregado')
         GROUP BY estado
    """)).fetchall()
    conteos = {r[0]: r[1] for r in conteos_rows}

    db.session.commit()
    _dias_es   = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo']
    _meses_es  = ['enero','febrero','marzo','abril','mayo','junio',
                    'julio','agosto','septiembre','octubre','noviembre','diciembre']
    _now       = datetime.datetime.now()
    fecha_hoy  = f"{_dias_es[_now.weekday()]} {_now.day} de {_meses_es[_now.month-1]}, {_now.year}"
    return render_template(
        'pedidos/cola_produccion.html',
        pedidos=pedidos_rows,
        conteos=conteos,
        filtro_estado=estado or '',
        filtro_fecha=fecha if fecha else '',
        pagina=pagina,
        tiene_mas=(len(pedidos_rows) == limit),
        fecha_hoy=fecha_hoy,
        now=_now,
    )

@pedidos_bp.route('/api/<folio>/insumos')
@login_required
@roles_required('admin', 'empleado', 'panadero', 'cliente')
def api_insumos_pedido(folio):
    try:
        conn = db.session.connection()
        cur  = conn.connection.cursor()

        # Buscar pedido
        cur.execute("SELECT id_pedido, id_tamanio FROM pedidos WHERE folio = %s LIMIT 1", (folio,))
        row_ped = cur.fetchone()
        if not row_ped:
            cur.close()
            return jsonify({'ok': False, 'mensaje': f'Pedido {folio} no encontrado.'}), 404

        v_id_pedido  = row_ped[0]
        v_id_tamanio = row_ped[1]  # puede ser None

        cur.execute("""
            SELECT
                mp.id_materia,
                mp.nombre            AS nombre_materia,
                mp.unidad_base,
                mp.categoria,
                ROUND(SUM((dp.cantidad / r.rendimiento) * dr.cantidad_requerida), 4)
                                     AS cantidad_requerida,
                mp.stock_actual,
                CASE WHEN mp.stock_actual >=
                    ROUND(SUM((dp.cantidad / r.rendimiento) * dr.cantidad_requerida), 4)
                    THEN 1 ELSE 0 END AS stock_suficiente,
                LEAST(100, ROUND(
                    mp.stock_actual /
                    NULLIF(ROUND(SUM((dp.cantidad / r.rendimiento) * dr.cantidad_requerida), 4), 0)
                    * 100, 1))        AS pct_disponible
            FROM detalle_pedidos  dp
            JOIN recetas          r   ON r.id_producto = dp.id_producto
                                     AND r.estatus     = 'activo'
                                     AND (
                                       (%s IS NOT NULL AND r.id_tamanio = %s)
                                       OR (%s IS NULL AND r.id_tamanio IS NULL)
                                     )
            JOIN detalle_recetas  dr  ON dr.id_receta  = r.id_receta
            JOIN materias_primas  mp  ON mp.id_materia = dr.id_materia
            WHERE dp.id_pedido = %s
            GROUP BY mp.id_materia, mp.nombre, mp.unidad_base,
                     mp.categoria, mp.stock_actual
            ORDER BY mp.nombre
        """, (v_id_tamanio, v_id_tamanio, v_id_tamanio, v_id_pedido))

        rows = cur.fetchall()
        cur.close()

        insumos = []
        for r in rows:
            insumos.append({
                'id_materia':       r[0],
                'nombre_materia':   r[1],
                'unidad_base':      r[2],
                'categoria':        r[3],
                'cantidad_requerida': float(r[4]) if r[4] is not None else 0,
                'stock_actual':     float(r[5]) if r[5] is not None else 0,
                'stock_suficiente': bool(r[6]),
                'pct_disponible':   min(float(r[7]) if r[7] is not None else 0, 100),
            })

        hay_faltantes = any(not i['stock_suficiente'] for i in insumos)
        return jsonify({
            'ok':           True,
            'hay_faltantes': hay_faltantes,
            'total':        len(insumos),
            'ok_count':     sum(1 for i in insumos if i['stock_suficiente']),
            'insumos':      insumos,
        })

    except Exception as exc:
        db.session.rollback()
        return jsonify({'ok': False, 'mensaje': str(exc)}), 500


@pedidos_bp.route('/api/<folio>/faltantes-compra')
@login_required
@roles_required('admin', 'empleado', 'panadero', 'cliente')
def api_faltantes_compra(folio):
    try:
        conn = db.session.connection()
        cur  = conn.connection.cursor()

        cur.execute("SELECT id_pedido, id_tamanio FROM pedidos WHERE folio = %s LIMIT 1", (folio,))
        row_ped = cur.fetchone()
        if not row_ped:
            cur.close()
            return jsonify({'ok': False, 'mensaje': f'Pedido {folio} no encontrado.'}), 404

        v_id_pedido  = row_ped[0]
        v_id_tamanio = row_ped[1]

        cur.execute("""
            SELECT
                mp.id_materia,
                mp.nombre       AS nombre_materia,
                mp.unidad_base,
                ROUND(SUM((dp.cantidad / r.rendimiento) * dr.cantidad_requerida), 4)
                                AS cantidad_requerida,
                mp.stock_actual,
                ROUND(GREATEST(0,
                    SUM((dp.cantidad / r.rendimiento) * dr.cantidad_requerida) - mp.stock_actual
                ), 4)           AS cantidad_faltante
            FROM detalle_pedidos dp
            JOIN recetas r ON r.id_producto = dp.id_producto
                          AND r.estatus = 'activo'
                          AND (
                            (%s IS NOT NULL AND r.id_tamanio = %s)
                            OR (%s IS NULL AND r.id_tamanio IS NULL)
                          )
            JOIN detalle_recetas dr ON dr.id_receta  = r.id_receta
            JOIN materias_primas mp ON mp.id_materia = dr.id_materia
            WHERE dp.id_pedido = %s
            GROUP BY mp.id_materia, mp.nombre, mp.unidad_base, mp.stock_actual
            HAVING cantidad_faltante > 0
            ORDER BY mp.nombre
        """, (v_id_tamanio, v_id_tamanio, v_id_tamanio, v_id_pedido))

        rows = cur.fetchall()
        cur.close()

        faltantes = [{
            'id_materia':         r[0],
            'nombre_materia':     r[1],
            'unidad_base':        r[2],
            'cantidad_requerida': float(r[3]) if r[3] else 0,
            'stock_actual':       float(r[4]) if r[4] else 0,
            'cantidad_faltante':  float(r[5]) if r[5] else 0,
        } for r in rows]

        return jsonify({'ok': True, 'folio_pedido': folio, 'faltantes': faltantes})

    except Exception as exc:
        db.session.rollback()
        return jsonify({'ok': False, 'mensaje': str(exc)}), 500

@pedidos_bp.route('/<folio>/aprobar', methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def aprobar_pedido(folio):
    nota = request.form.get('nota', '').strip() or 'Pedido aprobado.'
    try:
        conn = db.session.connection()
        conn.execute(text("SET @ok=0, @err=NULL"))
        conn.execute(
            text("CALL sp_aprobar_pedido(:f, :u, :n, @ok, @err)"),
            {'f': folio, 'u': current_user.id_usuario, 'n': nota}
        )
        row = conn.execute(text("SELECT @ok AS ok, @err AS err")).mappings().one()
        db.session.commit()
 
        if int(row['ok'] or 0) == 1:
            current_app.logger.info(
                'Pedido aprobado | usuario: %s | folio: %s | fecha: %s',
                current_user.username, folio,
                datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
            flash(f'Pedido {folio} aprobado. El stock se descontará al marcarlo listo.', 'success')
        else:
            db.session.rollback()
            flash(f'No se pudo aprobar: {row["err"] or "Error desconocido"}', 'error')
    except Exception as exc:
        db.session.rollback()
        current_app.logger.error(
            'Error al aprobar pedido | usuario: %s | folio: %s | error: %s | fecha: %s',
            current_user.username, folio, str(exc),
            datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        )
        flash(f'Error: {exc}', 'error')
    return redirect(request.referrer or url_for('pedidos.gestion_pedidos'))
 
 
@pedidos_bp.route('/<folio>/rechazar', methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def rechazar_pedido(folio):
    motivo = request.form.get('motivo', '').strip()
    if not motivo:
        flash('Debes indicar el motivo del rechazo.', 'warning')
        return redirect(request.referrer or url_for('pedidos.gestion_pedidos'))
    try:
        conn = db.session.connection()
        conn.execute(text("SET @ok=0, @err=NULL"))
        conn.execute(
            text("CALL sp_rechazar_pedido(:f, :u, :m, @ok, @err)"),
            {'f': folio, 'u': current_user.id_usuario, 'm': motivo}
        )
        row = conn.execute(text("SELECT @ok AS ok, @err AS err")).mappings().one()
        db.session.commit()
 
        if int(row['ok'] or 0) == 1:
            current_app.logger.info(
                'Pedido rechazado | usuario: %s | folio: %s | fecha: %s',
                current_user.username, folio,
                datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
            flash(f'Pedido {folio} rechazado ❌.', 'success')
        else:
            db.session.rollback()
            flash(f'No se pudo rechazar: {row["err"] or "Error desconocido"}', 'error')
    except Exception as exc:
        db.session.rollback()
        flash(f'Error: {exc}', 'error')
    return redirect(request.referrer or url_for('pedidos.gestion_pedidos'))
 

@pedidos_bp.route('/<folio>/iniciar-produccion', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero', 'cliente')
def iniciar_produccion(folio):
    try:
        conn = db.session.connection()
        conn.execute(text("SET @ok=0, @est=NULL, @err=NULL, @falt=NULL"))
        conn.execute(
            text("CALL sp_iniciar_produccion_pedido(:f, :u, @ok, @est, @err, @falt)"),
            {'f': folio, 'u': current_user.id_usuario}
        )
        row = conn.execute(
            text("SELECT @ok AS ok, @est AS estado, @err AS err, @falt AS faltantes")
        ).mappings().one()
        db.session.commit()

        if int(row['ok'] or 0) == 1:
            if row['estado'] == 'en_produccion':
                current_app.logger.info('Produccion de pedido iniciada | usuario: %s | folio: %s | fecha: %s', current_user.username, folio, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                flash(f'Pedido {folio} iniciado. Insumos descontados.', 'success')
            else:
                current_app.logger.warning('Intento de iniciar produccion parado (insumos insuficientes) | usuario: %s | folio: %s | faltantes: %s | fecha: %s', current_user.username, folio, row["faltantes"], datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                flash(
                    f'Insumos insuficientes. Pedido marcado como "Pendiente de Insumos". '
                    f'Faltantes: {row["faltantes"]}',
                    'warning'
                )
        else:
            current_app.logger.warning('Intento de iniciar produccion denegado por db | usuario: %s | folio: %s | error: %s | fecha: %s', current_user.username, folio, row["err"], datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash(f'No se pudo iniciar: {row["err"] or "Error desconocido"}', 'error')
    except Exception as exc:
        db.session.rollback()
        current_app.logger.error('Error al iniciar produccion | usuario: %s | folio: %s | error: %s | fecha: %s', current_user.username, folio, str(exc), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Error: {exc}', 'error')
    return redirect(url_for('pedidos.cola_produccion', folio=folio))


@pedidos_bp.route('/<folio>/terminar-produccion', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero', 'cliente')
def terminar_produccion(folio):
    try:
        conn = db.session.connection()
        conn.execute(text("SET @ok=0, @err=NULL"))
        conn.execute(
            text("CALL sp_terminar_produccion_pedido(:f, :u, @ok, @err)"),
            {'f': folio, 'u': current_user.id_usuario}
        )
        row = conn.execute(text("SELECT @ok AS ok, @err AS err")).mappings().one()
        db.session.commit()

        if int(row['ok'] or 0) == 1:
            current_app.logger.info('Produccion terminada | usuario: %s | folio: %s | fecha: %s', current_user.username, folio, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash(f'Pedido {folio} listo. El cliente fue notificado.', 'success')
        else:
            current_app.logger.warning('Terminar produccion invalido por db | usuario: %s | folio: %s | error: %s | fecha: %s', current_user.username, folio, row["err"], datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash(f'No se pudo terminar: {row["err"] or "Error desconocido"}', 'error')
    except Exception as exc:
        db.session.rollback()
        current_app.logger.error('Error al terminar produccion | usuario: %s | folio: %s | error: %s | fecha: %s', current_user.username, folio, str(exc), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Error: {exc}', 'error')
    return redirect(url_for('pedidos.cola_produccion', folio=folio))

@pedidos_bp.route('/api/<folio>/detalle')
@login_required
@roles_required('admin', 'empleado', 'panadero', 'cliente')
def api_detalle_pedido(folio):
    try:
        conn = db.session.connection()
        cur  = conn.connection.cursor()
        cur.execute("CALL sp_detalle_pedido(%s)", (folio,))

        row_pedido = cur.fetchone()
        if not row_pedido:
            cur.close()
            return jsonify({'ok': False, 'mensaje': 'Pedido no encontrado.'}), 404

        pedido = {
            'id_pedido':          row_pedido[0],
            'folio':              row_pedido[1],
            'estado':             row_pedido[2],
            'fecha_recogida':     row_pedido[3].strftime('%d/%m/%Y %H:%M') if row_pedido[3] else '—',
            'total_estimado':     float(row_pedido[4]) if row_pedido[4] else 0,
            'motivo_rechazo':     row_pedido[5] or '',
            'creado_en':          row_pedido[6].strftime('%d/%m/%Y %H:%M') if row_pedido[6] else '—',
            'id_cliente':         row_pedido[7],
            'cliente_nombre':     row_pedido[8] or '—',
            'atendido_por':       row_pedido[9] or '—',
            'tipo_caja':          row_pedido[10] or '—',
            'tamanio_nombre':     row_pedido[11] or '—',
            'capacidad':          row_pedido[12],
        }

        cur.nextset()  
        row_caja = cur.fetchone()
        caja = None
        if row_caja:
            caja = {
                'tipo':        row_caja[0],
                'tamanio':     row_caja[1],
                'nombre_caja': row_caja[2],
                'capacidad':   row_caja[3],
                'precio_venta': float(row_caja[4]) if row_caja[4] else 0,
            }

        cur.nextset()  
        items = []
        for r in cur.fetchall():
            items.append({
                'producto_nombre':       r[0],
                'producto_descripcion':  r[1] or '',
                'cantidad':              float(r[2]) if r[2] else 0,
                'precio_unitario':       float(r[3]) if r[3] else 0,
                'subtotal':              float(r[4]) if r[4] else 0,
            })

        cur.nextset()  
        historial = []
        for r in cur.fetchall():
            historial.append({
                'estado_antes':   r[0],
                'estado_despues': r[1],
                'nota':           r[2] or '',
                'creado_en':      r[3].strftime('%d/%m/%Y %H:%M') if r[3] else '—',
                'usuario_nombre': r[4] or '—',
            })

        cur.close()

        return jsonify({
            'ok':       True,
            'pedido':   pedido,
            'caja':     caja,
            'items':    items,
            'historial': historial,
        })

    except Exception as exc:
        return jsonify({'ok': False, 'mensaje': str(exc)}), 500
    

@pedidos_bp.route('/api/notificaciones', methods=['GET'])
@login_required
def api_notificaciones():
    """Obtener notificaciones del usuario actual"""
    try:
        result = db.session.execute(
            text("""
                SELECT id_notif, id_pedido, folio, tipo, mensaje, leida, creado_en
                FROM notificaciones_pedidos
                WHERE id_usuario = :usuario_id
                ORDER BY creado_en DESC
                LIMIT 10
            """),
            {'usuario_id': current_user.id_usuario}
        )
        
        notificaciones = []
        for row in result:
            notificaciones.append({
                'id_notif': row.id_notif,
                'id_pedido': row.id_pedido,
                'folio': row.folio,
                'tipo': row.tipo,
                'mensaje': row.mensaje,
                'leida': bool(row.leida),
                'creado_en': row.creado_en.strftime('%Y-%m-%d %H:%M:%S') if row.creado_en else None
            })
        
        db.session.commit()
        
        return jsonify({
            'ok': True,
            'notificaciones': notificaciones
        })
    except Exception as e:
        db.session.rollback()
        print(f"Error en api_notificaciones: {str(e)}")
        return jsonify({
            'ok': False,
            'error': str(e)
        }), 500

@pedidos_bp.route('/<folio>/marcar-listo', methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def marcar_listo(folio):
    try:
        conn = db.session.connection()
        conn.execute(text("SET @ok=0, @err=NULL"))
        conn.execute(
            text("CALL sp_marcar_listo_pedido(:f, :u, @ok, @err)"),
            {'f': folio, 'u': current_user.id_usuario}
        )
        row = conn.execute(text("SELECT @ok AS ok, @err AS err")).mappings().one()
        db.session.commit()
 
        if int(row['ok'] or 0) == 1:
            current_app.logger.info(
                'Pedido marcado listo | usuario: %s | folio: %s | fecha: %s',
                current_user.username, folio,
                datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
            flash(f'Pedido {folio} marcado como listo 🎉. Cliente notificado.', 'success')
        else:
            db.session.rollback()
            flash(f'No se pudo marcar como listo: {row["err"] or "Error desconocido"}', 'error')
    except Exception as exc:
        db.session.rollback()
        flash(f'Error: {exc}', 'error')
    return redirect(request.referrer or url_for('pedidos.gestion_pedidos'))

@pedidos_bp.route('/<folio>/marcar-entregado', methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def marcar_entregado(folio):
    try:
        conn = db.session.connection()
        conn.execute(text("SET @ok=0, @err=NULL"))
        conn.execute(
            text("CALL sp_marcar_entregado_pedido(:f, :u, @ok, @err)"),
            {'f': folio, 'u': current_user.id_usuario}
        )
        row = conn.execute(text("SELECT @ok AS ok, @err AS err")).mappings().one()
        db.session.commit()
 
        if int(row['ok'] or 0) == 1:
            current_app.logger.info(
                'Pedido entregado | usuario: %s | folio: %s | fecha: %s',
                current_user.username, folio,
                datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
            flash(f'Pedido {folio} marcado como entregado 📦.', 'success')
        else:
            db.session.rollback()
            flash(f'No se pudo marcar como entregado: {row["err"] or "Error desconocido"}', 'error')
    except Exception as exc:
        db.session.rollback()
        flash(f'Error: {exc}', 'error')
    return redirect(request.referrer or url_for('pedidos.gestion_pedidos'))
 
 
@pedidos_bp.route('/tienda')
@login_required
@roles_required('admin', 'empleado', 'cliente')
def tienda():
    """Catálogo: permite pedir aunque no haya stock (por encargo)."""
    current_app.logger.info(
        'Vista tienda accesada | usuario: %s | fecha: %s',
        current_user.username,
        datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    )
    conn = db.session.connection()
    cur  = conn.connection.cursor()
    cur.execute("CALL sp_catalogo_tienda()")
    rows = cur.fetchall()
    cur.close()
 
    Producto = namedtuple('Producto', [
        'id_producto', 'uuid_producto', 'nombre', 'descripcion',
        'precio_venta', 'stock_actual', 'stock_minimo', 'nivel_stock',
        'imagen_url'
    ])
    productos = [Producto(*r) for r in rows]
 
    productos_json = Markup(json.dumps([
        {
            'id':          p.id_producto,
            'uuid':        p.uuid_producto,
            'nombre':      p.nombre,
            'descripcion': p.descripcion or '',
            'precio':      float(p.precio_venta),
            'stock':       int(p.stock_actual),
            'nivel':       p.nivel_stock,
            'imagen_url':  p.imagen_url or '',
        }
        for p in productos
    ]))
 
    return render_template(
        'pedidos/tienda.html',
        productos=productos,
        productos_json=productos_json,
    )

@pedidos_bp.route('/tienda/crear', methods=['POST'])
@login_required
@roles_required('admin', 'cliente')
def crear_pedido_express():
    """Procesa el pedido express de la tienda del día."""
    carrito_raw = request.form.get('carrito_json', '').strip()
    hora_str    = request.form.get('hora_recogida', '').strip()
    notas       = request.form.get('notas', '').strip() or None

    if not carrito_raw:
        flash('No se recibieron productos en el pedido.', 'error')
        return redirect(url_for('pedidos.tienda'))

    try:
        carrito_data = json.loads(carrito_raw)
    except (ValueError, TypeError):
        flash('Error al leer los datos del carrito.', 'error')
        return redirect(url_for('pedidos.tienda'))

    if not isinstance(carrito_data, list) or len(carrito_data) == 0:
        flash('Agrega al menos un producto al pedido.', 'error')
        return redirect(url_for('pedidos.tienda'))

    if not hora_str:
        flash('Selecciona la hora de recogida.', 'error')
        return redirect(url_for('pedidos.tienda'))

    # Validar hora formato HH:MM
    import re as _re
    if not _re.match(r'^\d{2}:\d{2}$', hora_str):
        flash('Hora de recogida inválida.', 'error')
        return redirect(url_for('pedidos.tienda'))

    productos_json = json.dumps([
        {'id': item['id'], 'qty': item['qty'], 'precio': item['precio']}
        for item in carrito_data
    ])

    try:
        conn = db.session.connection()
        cur  = conn.connection.cursor()
        cur.callproc('sp_pedido_express', (
            current_user.id_usuario,
            hora_str + ':00',      # TIME: HH:MM:SS
            notas,
            productos_json,
            0,      # OUT p_id_pedido
            '',     # OUT p_folio
            '',     # OUT p_error
        ))
        cur.nextset()

        # Leer OUTs
        cur.execute("SELECT @_sp_pedido_express_4, @_sp_pedido_express_5, @_sp_pedido_express_6")
        row = cur.fetchone()
        cur.close()

        p_id_pedido, p_folio, p_error = row[0], row[1], row[2]

        if p_error:
            db.session.rollback()
            current_app.logger.warning(
                'Pedido express rechazado | usuario: %s | error: %s | fecha: %s',
                current_user.username, p_error,
                datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
            flash(f'No se pudo crear el pedido: {p_error}', 'error')
            return redirect(url_for('pedidos.tienda'))

        db.session.commit()
        n_items = sum(item['qty'] for item in carrito_data)
        current_app.logger.info(
            'Pedido express creado | usuario: %s | folio: %s | piezas: %s | fecha: %s',
            current_user.username, p_folio, n_items,
            datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        )
        flash(
            f'¡Pedido {p_folio} enviado con {int(n_items)} '
            f'pieza{"s" if n_items != 1 else ""}! '
            f'Te avisaremos cuando esté listo para recoger a las {hora_str}.',
            'success'
        )
        return redirect(url_for('pedidos.mis_pedidos'))

    except Exception as exc:
        db.session.rollback()
        current_app.logger.error(
            'Error general al crear pedido express | usuario: %s | error: %s | fecha: %s',
            current_user.username, str(exc),
            datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        )
        flash('Ocurrió un error al guardar tu pedido. Intenta de nuevo.', 'error')
        return redirect(url_for('pedidos.tienda'))


@pedidos_bp.route('/tienda/futuro', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'cliente')
def crear_pedido_futuro():
    import re as _re

    carrito_raw   = request.form.get('carrito_json',   '').strip()
    fecha_str     = request.form.get('fecha_entrega',  '').strip()
    hora_str      = request.form.get('hora_recogida',  '').strip()
    metodo_pago   = request.form.get('metodo_pago',    'efectivo').strip()
    notas         = request.form.get('notas',          '').strip() or None
    es_inmediato  = request.form.get('es_inmediato',   '0').strip()  # '1' = compra del día

    if not carrito_raw:
        flash('No se recibieron productos en el pedido.', 'error')
        return redirect(url_for('pedidos.tienda'))

    try:
        carrito_data = json.loads(carrito_raw)
    except (ValueError, TypeError):
        flash('Error al leer los datos del carrito.', 'error')
        return redirect(url_for('pedidos.tienda'))

    if not isinstance(carrito_data, list) or len(carrito_data) == 0:
        flash('Agrega al menos un producto al pedido.', 'error')
        return redirect(url_for('pedidos.tienda'))

    if not fecha_str or not hora_str:
        flash('Selecciona la fecha y hora de recogida.', 'error')
        return redirect(url_for('pedidos.tienda'))

    if not _re.match(r'^\d{4}-\d{2}-\d{2}$', fecha_str):
        flash('Formato de fecha inválido.', 'error')
        return redirect(url_for('pedidos.tienda'))

    if not _re.match(r'^\d{2}:\d{2}$', hora_str):
        flash('Formato de hora inválido.', 'error')
        return redirect(url_for('pedidos.tienda'))

    if metodo_pago not in ('efectivo', 'tarjeta', 'transferencia'):
        flash('Método de pago inválido.', 'error')
        return redirect(url_for('pedidos.tienda'))

    es_inmediato_int = 1 if es_inmediato == '1' else 0

    fecha_dt_str = f"{fecha_str} {hora_str}:00"
    try:
        fecha_dt = datetime.datetime.strptime(fecha_dt_str, '%Y-%m-%d %H:%M:%S')
    except ValueError:
        flash('Fecha u hora inválida.', 'error')
        return redirect(url_for('pedidos.tienda'))

    # Validación 24h solo para pedidos futuros
    if es_inmediato_int == 0:
        if fecha_dt < datetime.datetime.now() + datetime.timedelta(hours=24):
            flash('La fecha de recogida debe ser al menos 24 horas desde ahora.', 'error')
            return redirect(url_for('pedidos.tienda'))
    else:
        # Compra inmediata: solo verificar que no sea en el pasado
        if fecha_dt < datetime.datetime.now():
            flash('La hora de recogida no puede ser en el pasado.', 'error')
            return redirect(url_for('pedidos.tienda'))

    productos_json_str = json.dumps([
        {'id': item['id'], 'qty': item['qty'], 'precio': item['precio']}
        for item in carrito_data
    ])

    try:
        db.session.execute(text(
            "SET @p_id_pedido = NULL, @p_folio = NULL, @p_error = NULL"
        ))
        db.session.execute(
            text("""
                CALL sp_pedido_futuro(
                    :cliente, :fecha_dt, :metodo, :notas, :inmediato, :prods,
                    @p_id_pedido, @p_folio, @p_error
                )
            """),
            {
                'cliente':   current_user.id_usuario,
                'fecha_dt':  fecha_dt_str,
                'metodo':    metodo_pago,
                'notas':     notas,
                'inmediato': es_inmediato_int,
                'prods':     productos_json_str,
            }
        )
        row = db.session.execute(
            text("SELECT @p_id_pedido, @p_folio, @p_error")
        ).fetchone()

        if row[2]:
            db.session.rollback()
            current_app.logger.warning(
                'Pedido rechazado por SP | usuario: %s | error: %s | fecha: %s',
                current_user.username, row[2],
                datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
            flash(f'No se pudo crear el pedido: {row[2]}', 'error')
            return redirect(url_for('pedidos.tienda'))

        db.session.commit()
        p_folio = row[1]
        n_pzas  = sum(item['qty'] for item in carrito_data)

        tipo_msg = 'del día' if es_inmediato_int else 'programado'
        current_app.logger.info(
            'Pedido %s creado | usuario: %s | folio: %s | piezas: %d | entrega: %s | fecha: %s',
            tipo_msg, current_user.username, p_folio, int(n_pzas), fecha_dt_str,
            datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        )

        if es_inmediato_int:
            flash(
                f'¡Pedido {p_folio} enviado — {int(n_pzas)} '
                f'pieza{"s" if n_pzas != 1 else ""}! '
                f'Recogida hoy a las {hora_str}. Pago al recoger.',
                'success'
            )
        else:
            flash(
                f'¡Pedido {p_folio} enviado — {int(n_pzas)} '
                f'pieza{"s" if n_pzas != 1 else ""}! '
                f'Recogida el {fecha_str} a las {hora_str}. Pago al recoger.',
                'success'
            )
        return redirect(url_for('pedidos.mis_pedidos'))

    except Exception as exc:
        db.session.rollback()
        orig = getattr(exc, 'orig', None)
        msg  = (orig.args[1]
                if orig and hasattr(orig, 'args') and len(orig.args) >= 2
                else str(exc))
        current_app.logger.error(
            'Error al crear pedido | usuario: %s | error: %s | fecha: %s',
            current_user.username, msg,
            datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        )
        flash('Ocurrió un error al guardar tu pedido. Intenta de nuevo.', 'error')
        return redirect(url_for('pedidos.tienda'))