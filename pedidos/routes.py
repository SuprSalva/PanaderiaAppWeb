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
@roles_required('admin', 'empleado', 'panadero')
def catalogo():
    current_app.logger.info('Vista de catalogo de pedidos accesada | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    conn = db.session.connection()
    cur  = conn.connection.cursor()
    cur.execute("CALL sp_catalogo_pedido()")

    rows_tam  = cur.fetchall()
    cur.nextset()
    rows_prod = cur.fetchall()
    cur.close()

    Tamanio  = namedtuple('Tamanio',  ['id_tamanio', 'nombre', 'capacidad', 'descripcion'])
    Producto = namedtuple('Producto', ['id_producto', 'nombre', 'descripcion', 'precio_venta'])
    tamanios  = [Tamanio(*r)  for r in rows_tam]
    productos = [Producto(*r) for r in rows_prod]

    tamanios_json = Markup(json.dumps({
        str(t.id_tamanio): {'nombre': t.nombre, 'capacidad': t.capacidad}
        for t in tamanios
    }))
    productos_json = Markup(json.dumps({
        str(p.id_producto): {'nombre': p.nombre, 'precio': float(p.precio_venta)}
        for p in productos
    }))

    return render_template('pedidos/catalogo.html',
                           tamanios=tamanios,
                           productos=productos,
                           tamanios_json=tamanios_json,
                           productos_json=productos_json)


@pedidos_bp.route('/nuevo', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def crear_pedido():
    form = PedidoCajaForm(request.form)
    cajas_raw = request.form.get('cajas_json', '').strip()

    if not cajas_raw:
        current_app.logger.warning('Intento de crear pedido fallido (sin cajas) | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('No se recibieron cajas en el pedido.', 'error')
        return redirect(url_for('pedidos.catalogo'))
    try:
        cajas_data = json.loads(cajas_raw)
    except (ValueError, TypeError):
        current_app.logger.warning('Intento de crear pedido fallido (json invalido) | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('Error al leer los datos del pedido.', 'error')
        return redirect(url_for('pedidos.catalogo'))

    if not isinstance(cajas_data, list) or len(cajas_data) == 0:
        current_app.logger.warning('Intento de crear pedido fallido (sin cajas decodificadas) | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('Agrega al menos una caja al pedido.', 'error')
        return redirect(url_for('pedidos.catalogo'))

    fecha_str = request.form.get('fecha_recogida', '').strip()
    if not fecha_str:
        current_app.logger.warning('Intento de crear pedido fallido (sin fecha) | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('Indica la fecha y hora de recolección.', 'error')
        return redirect(url_for('pedidos.catalogo'))

    errores = _validar_cajas(cajas_data)
    if errores:
        for e in errores:
            flash(e, 'error')
        return redirect(url_for('pedidos.catalogo'))

    try:
        db.session.execute(
            text("SET @p_id_pedido = NULL, @p_folio = NULL, @p_error = NULL")
        )
        db.session.execute(
            text("""
                CALL sp_crear_pedido_caja(
                    :cliente, :fecha, :cajas,
                    @p_id_pedido, @p_folio, @p_error
                )
            """),
            {
                'cliente': current_user.id_usuario,
                'fecha':   fecha_str.replace('T', ' '),
                'cajas':   cajas_raw,
            }
        )
        row = db.session.execute(
            text("SELECT @p_id_pedido, @p_folio, @p_error")
        ).fetchone()

        if row[2]:
            db.session.rollback()
            current_app.logger.error('Error db al crear pedido | usuario: %s | error: %s | fecha: %s', current_user.username, row[2], datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash(f'Error: {row[2]}', 'error')
            return redirect(url_for('pedidos.catalogo'))

        db.session.commit()
        n = len(cajas_data)
        current_app.logger.info('Pedido creado exitosamente | usuario: %s | folio: %s | piezas: %s | fecha: %s', current_user.username, row[1], n, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(
            f'¡Pedido {row[1]} enviado con {n} caja{"s" if n > 1 else ""}! '
            'Te avisaremos cuando esté listo.',
            'success'
        )
        return redirect(url_for('pedidos.mis_pedidos'))

    except Exception as e:
        db.session.rollback()
        current_app.logger.error('Error general al crear pedido | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('Ocurrió un error al guardar tu pedido. Intenta de nuevo.', 'error')
        return redirect(url_for('pedidos.catalogo'))


def _validar_cajas(cajas_data: list) -> list[str]:
    errores = []
    TIPOS_VALIDOS   = {'simple', 'mixta', 'triple'}
    PANES_POR_TIPO  = {'simple': 1, 'mixta': 2, 'triple': 3}
    NOMBRES_TIPO    = {'simple': 'un tipo', 'mixta': 'dos tipos', 'triple': 'tres tipos'}

    for i, caja in enumerate(cajas_data, start=1):
        label = f'Caja {i}'

        try:
            id_tamanio = int(caja.get('id_tamanio', 0))
            if id_tamanio <= 0:
                raise ValueError
        except (TypeError, ValueError):
            errores.append(f'{label}: selecciona un tamaño de charola válido.')
            continue

        tipo = caja.get('tipo', '')
        if tipo not in TIPOS_VALIDOS:
            errores.append(f'{label}: tipo de caja inválido ("{tipo}").')
            continue

        panes = caja.get('panes', [])
        if not isinstance(panes, list) or len(panes) == 0:
            errores.append(f'{label}: agrega al menos un tipo de pan.')
            continue

        esperado = PANES_POR_TIPO[tipo]
        if len(panes) != esperado:
            errores.append(
                f'{label}: una caja {tipo} requiere exactamente '
                f'{NOMBRES_TIPO[tipo]} de pan.'
            )
            continue

        for j, pan in enumerate(panes, start=1):
            try:
                id_prod = int(pan.get('id_producto', 0))
                if id_prod <= 0:
                    raise ValueError
            except (TypeError, ValueError):
                errores.append(f'{label}, pan {j}: producto inválido.')

            try:
                cant = int(pan.get('cantidad', 0))
                if cant <= 0:
                    raise ValueError
            except (TypeError, ValueError):
                errores.append(f'{label}, pan {j}: cantidad inválida.')

            try:
                precio = float(pan.get('precio', -1))
                if precio < 0:
                    raise ValueError
            except (TypeError, ValueError):
                errores.append(f'{label}, pan {j}: precio inválido.')

    return errores


@pedidos_bp.route('/mis-pedidos')
@login_required
@roles_required('admin', 'empleado', 'panadero')
def mis_pedidos():
    current_app.logger.info('Vista de mis pedidos accesada | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    conn = db.session.connection()
    cur  = conn.connection.cursor()
    cur.execute("CALL sp_mis_pedidos_cliente(%s)", (current_user.id_usuario,))

    rows_ped   = cur.fetchall()
    cur.nextset()
    rows_notif = cur.fetchall()
    cur.close()

    cols_p = ['id_pedido', 'folio', 'estado', 'fecha_recogida', 'total_estimado',
              'motivo_rechazo', 'creado_en', 'tipo_caja', 'tamanio_nombre',
              'capacidad', 'panes_resumen', 'nombre_caja']
    cols_n = ['id_notif', 'id_pedido', 'folio', 'mensaje', 'leida', 'creado_en']
    Pedido = namedtuple('Pedido', cols_p)
    Notif  = namedtuple('Notif',  cols_n)
    pedidos = [Pedido(*r) for r in rows_ped]
    notifs  = [Notif(*r)  for r in rows_notif]

    return render_template('pedidos/mis_pedidos.html',
                           pedidos=pedidos,
                           notifs=notifs)


@pedidos_bp.route('/pedidos')
@login_required
@roles_required('admin', 'empleado', 'panadero')
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
@roles_required('admin', 'empleado', 'panadero')
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
@roles_required('admin', 'empleado', 'panadero')
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
@roles_required('admin', 'empleado', 'panadero')
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
@roles_required('admin', 'empleado', 'panadero')
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
@roles_required('admin', 'empleado', 'panadero')
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
@roles_required('admin', 'empleado', 'panadero')
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
@roles_required('admin', 'empleado', 'panadero')
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

# ── Aprobar pedido ──────────────────────────────────────────
@pedidos_bp.route('/<folio>/aprobar', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
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
            current_app.logger.info('Pedido aprobado exitosamente | usuario: %s | folio: %s | fecha: %s', current_user.username, folio, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash(f'Pedido {folio} aprobado', 'success')
        else:
            current_app.logger.warning('Aprobacion de pedido rechazada | usuario: %s | folio: %s | error: %s | fecha: %s', current_user.username, folio, row["err"], datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash(f'No se pudo aprobar: {row["err"] or "Error desconocido"}', 'error')
    except Exception as exc:
        db.session.rollback()
        current_app.logger.error('Error al aprobar pedido | usuario: %s | folio: %s | error: %s | fecha: %s', current_user.username, folio, str(exc), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Error: {exc}', 'error')
    return redirect(request.referrer or url_for('pedidos.cola_produccion'))


# ── Rechazar pedido ─────────────────────────────────────────
@pedidos_bp.route('/<folio>/rechazar', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def rechazar_pedido(folio):
    motivo = request.form.get('motivo', '').strip()
    if not motivo:
        current_app.logger.warning('Intento de rechazar pedido fallido (sin motivo) | usuario: %s | folio: %s | fecha: %s', current_user.username, folio, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('Debes indicar el motivo del rechazo.', 'warning')
        return redirect(request.referrer or url_for('pedidos.cola_produccion'))
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
            current_app.logger.info('Pedido rechazado exitosamente | usuario: %s | folio: %s | fecha: %s', current_user.username, folio, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash(f'Pedido {folio} rechazado.', 'success')
        else:
            current_app.logger.warning('Rechazo de pedido invalido por db | usuario: %s | folio: %s | error: %s | fecha: %s', current_user.username, folio, row["err"], datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            flash(f'No se pudo rechazar: {row["err"] or "Error desconocido"}', 'error')
    except Exception as exc:
        db.session.rollback()
        current_app.logger.error('Error al rechazar pedido | usuario: %s | folio: %s | error: %s | fecha: %s', current_user.username, folio, str(exc), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Error: {exc}', 'error')
    return redirect(request.referrer or url_for('pedidos.cola_produccion'))

@pedidos_bp.route('/<folio>/iniciar-produccion', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
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
@roles_required('admin', 'empleado', 'panadero')
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
@roles_required('admin', 'empleado', 'panadero')
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