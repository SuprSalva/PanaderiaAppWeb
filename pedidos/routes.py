import json
from collections import namedtuple
from markupsafe import Markup

from flask import (
    render_template, request, redirect, url_for,
    flash, jsonify, abort
)
from flask_login import current_user
from sqlalchemy import text
from models import db
from pedidos import pedidos_bp
from forms import PedidoCajaForm  # usado en crear_pedido para validación


# ─────────────────────────────────────────────
#  CATÁLOGO
# ─────────────────────────────────────────────

@pedidos_bp.route('/nuevo', methods=['GET'])
def catalogo():
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


# ─────────────────────────────────────────────
#  CREAR PEDIDO DE CAJA  (múltiples cajas)
# ─────────────────────────────────────────────

@pedidos_bp.route('/nuevo', methods=['POST'])
def crear_pedido():
    form = PedidoCajaForm(request.form)

    # ── Reconstruir la lista de cajas desde el JSON del form ──
    # El JS envía un campo oculto "cajas_json" con el array serializado
    # para no tener que mapear FieldList dinámico con prefijos WTForms.
    cajas_raw = request.form.get('cajas_json', '').strip()

    if not cajas_raw:
        flash('No se recibieron cajas en el pedido.', 'danger')
        return redirect(url_for('pedidos.catalogo'))

    # Cargar y validar estructura básica
    try:
        cajas_data = json.loads(cajas_raw)
    except (ValueError, TypeError):
        flash('Error al leer los datos del pedido.', 'danger')
        return redirect(url_for('pedidos.catalogo'))

    if not isinstance(cajas_data, list) or len(cajas_data) == 0:
        flash('Agrega al menos una caja al pedido.', 'danger')
        return redirect(url_for('pedidos.catalogo'))

    # Validar fecha con el form
    fecha_str = request.form.get('fecha_recogida', '').strip()
    if not fecha_str:
        flash('Indica la fecha y hora de recolección.', 'danger')
        return redirect(url_for('pedidos.catalogo'))

    # ── Validaciones en Python usando las reglas de forms.py ──
    errores = _validar_cajas(cajas_data)
    if errores:
        for e in errores:
            flash(e, 'danger')
        return redirect(url_for('pedidos.catalogo'))

    # ── Llamar al SP con el JSON completo de cajas ────────────
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
            flash(f'Error: {row[2]}', 'danger')
            return redirect(url_for('pedidos.catalogo'))

        db.session.commit()
        n = len(cajas_data)
        flash(
            f'¡Pedido {row[1]} enviado con {n} caja{"s" if n > 1 else ""}! '
            'Te avisaremos cuando esté listo.',
            'success'
        )
        return redirect(url_for('pedidos.mis_pedidos'))

    except Exception:
        db.session.rollback()
        flash('Ocurrió un error al guardar tu pedido. Intenta de nuevo.', 'danger')
        return redirect(url_for('pedidos.catalogo'))


def _validar_cajas(cajas_data: list) -> list[str]:
    """
    Valida la lista de cajas usando las mismas reglas que CajaForm / PanCajaForm.
    Retorna lista de mensajes de error (vacía si todo está bien).
    """
    errores = []
    TIPOS_VALIDOS   = {'simple', 'mixta', 'triple'}
    PANES_POR_TIPO  = {'simple': 1, 'mixta': 2, 'triple': 3}
    NOMBRES_TIPO    = {'simple': 'un tipo', 'mixta': 'dos tipos', 'triple': 'tres tipos'}

    for i, caja in enumerate(cajas_data, start=1):
        label = f'Caja {i}'

        # Tamaño
        try:
            id_tamanio = int(caja.get('id_tamanio', 0))
            if id_tamanio <= 0:
                raise ValueError
        except (TypeError, ValueError):
            errores.append(f'{label}: selecciona un tamaño de charola válido.')
            continue

        # Tipo
        tipo = caja.get('tipo', '')
        if tipo not in TIPOS_VALIDOS:
            errores.append(f'{label}: tipo de caja inválido ("{tipo}").')
            continue

        # Panes
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


# ─────────────────────────────────────────────
#  MIS PEDIDOS (cliente)
# ─────────────────────────────────────────────

@pedidos_bp.route('/mis-pedidos')
def mis_pedidos():
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


# ─────────────────────────────────────────────
#  LISTA INTERNA (staff)
# ─────────────────────────────────────────────

@pedidos_bp.route('/pedidos')
def lista():
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


# ─────────────────────────────────────────────
#  DETALLE DE PEDIDO
# ─────────────────────────────────────────────

@pedidos_bp.route('/<folio>')
def detalle(folio):
    conn = db.session.connection()
    cur  = conn.connection.cursor()
    cur.execute("CALL sp_detalle_pedido(%s)", (folio,))

    row_pedido = cur.fetchone()
    if not row_pedido:
        cur.close()
        abort(404)

    cols_ped = ['id_pedido', 'folio', 'estado', 'fecha_recogida', 'total_estimado',
                'motivo_rechazo', 'creado_en', 'id_cliente', 'cliente_nombre',
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


# ─────────────────────────────────────────────
#  CAMBIAR ESTADO (staff)
# ─────────────────────────────────────────────

@pedidos_bp.route('/<folio>/estado', methods=['POST'])
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
            flash(f'No se pudo cambiar el estado: {row[0]}', 'danger')
            return redirect(url_for('pedidos.detalle', folio=folio))

        db.session.commit()
        LABELS = {
            'aprobado':      'aprobado ✅',
            'rechazado':     'rechazado ❌',
            'en_produccion': 'en producción ⚙️',
            'listo':         'listo para recoger 🎉',
            'entregado':     'entregado 📦',
        }
        flash(f'Pedido {folio} marcado como {LABELS.get(nuevo_estado, nuevo_estado)}.', 'success')

    except Exception:
        db.session.rollback()
        flash('Error al cambiar el estado. Intenta de nuevo.', 'danger')

    return redirect(url_for('pedidos.detalle', folio=folio))


# ─────────────────────────────────────────────
#  NOTIFICACIONES
# ─────────────────────────────────────────────

@pedidos_bp.route('/notificaciones/leer', methods=['POST'])
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
def badge_notifs():
    row = db.session.execute(
        text("CALL sp_badge_notifs(:u)"),
        {'u': current_user.id_usuario}
    ).fetchone()
    return jsonify({'count': row[0] if row else 0})