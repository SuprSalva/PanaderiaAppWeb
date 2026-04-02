import uuid
import datetime
from decimal import Decimal

from flask import render_template, request, redirect, url_for, flash, jsonify
from flask_login import login_required, current_user
from sqlalchemy import text

from models import db, Compra, DetalleCompra, Proveedor, MateriaPrima, UnidadPresentacion, SalidaEfectivo
from auth import roles_required
from utils.db_roles import call_sp
from forms import CompraForm
from . import compras


def _compra_form():
    """Instancia CompraForm con las opciones de proveedores activos."""
    form = CompraForm(request.form)
    form.id_proveedor.choices = (
        [(-1, '— Seleccionar —')] +
        [(p.id_proveedor, p.nombre)
         for p in Proveedor.query.filter_by(estatus='activo').order_by(Proveedor.nombre).all()]
    )
    return form


def _generar_folio(prefijo='C'):
    """Genera un folio único basado en el count actual."""
    total = db.session.execute(text("SELECT COUNT(*) FROM compras")).scalar() + 1
    return f"{prefijo}-{total:04d}"


def _generar_folio_salida():
    total = db.session.execute(text("SELECT COUNT(*) FROM salidas_efectivo")).scalar() + 1
    return f"SE-{total:04d}"


# ── LISTA DE COMPRAS ────────────────────────────────────────
@compras.route("/compras")
@login_required
@roles_required('admin', 'empleado')
def index_compras():
    lista = db.session.execute(
        text("SELECT * FROM vw_compras ORDER BY creado_en DESC")
    ).mappings().all()
    proveedores   = Proveedor.query.filter_by(estatus='activo').order_by(Proveedor.nombre).all()
    materias      = MateriaPrima.query.filter_by(estatus='activo').order_by(MateriaPrima.nombre).all()
    total_compras = len(lista)
    mes_actual    = datetime.date.today().replace(day=1)
    compras_mes   = sum(1 for c in lista if c.fecha_compra >= mes_actual)
    gasto_mes     = sum(float(c.total) for c in lista
                        if c.fecha_compra >= mes_actual and c.estatus == 'finalizado')
    provs_activos = len(set(c.id_proveedor for c in lista))

    form = _compra_form()

    return render_template("compras/compras.html",
        compras=lista,
        proveedores=proveedores,
        materias=materias,
        total_compras=total_compras,
        compras_mes=compras_mes,
        gasto_mes=gasto_mes,
        provs_activos=provs_activos,
        form=form,
    )


# ── API: unidades de una materia prima ───────────────────────
@compras.route("/compras/api/unidades/<int:id_materia>")
@login_required
@roles_required('admin', 'empleado')
def api_unidades_materia(id_materia):
    unidades = UnidadPresentacion.query.filter_by(
        id_materia=id_materia, activo=True
    ).filter(UnidadPresentacion.uso.in_(['compra', 'ambos'])).all()
    return jsonify([{
        'id':             u.id_unidad,
        'nombre':         u.nombre,
        'simbolo':        u.simbolo,
        'factor_a_base':  float(u.factor_a_base),
    } for u in unidades])


# ── CREAR PEDIDO (estatus: ordenado) ────────────────────────
@compras.route("/compras/crear", methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def crear_compra():
    form = _compra_form()
    if not form.validate():
        for errors in form.errors.values():
            flash(errors[0], 'error')
        return redirect(url_for('compras.index_compras'))

    id_proveedor   = form.id_proveedor.data
    fecha_compra   = form.fecha_compra.data
    folio_factura  = form.folio_factura.data.strip() if form.folio_factura.data else ''
    observaciones  = form.observaciones.data.strip() if form.observaciones.data else ''

    ids_materia    = request.form.getlist('id_materia[]')
    ids_unidad     = request.form.getlist('id_unidad_presentacion[]')
    cantidades     = request.form.getlist('cantidad_comprada[]')
    unidades_str   = request.form.getlist('unidad_compra[]')
    factores       = request.form.getlist('factor_conversion[]')
    cantidades_b   = request.form.getlist('cantidad_base[]')
    costos         = request.form.getlist('costo_unitario[]')

    ids_materia = [m for m in ids_materia if m]
    if not ids_materia:
        flash('Debes agregar al menos un insumo.', 'error')
        return redirect(url_for('compras.index_compras'))

    folio = _generar_folio()

    try:
        # 1. Crear cabecera via SP
        result = db.session.execute(
            text("CALL sp_crear_pedido_compra(:folio,:fact,:prov,:fecha,:obs,:creado, @id_out)"),
            {
                'folio':  folio,
                'fact':   folio_factura or None,
                'prov':   int(id_proveedor),
                'fecha':  fecha_compra,
                'obs':    observaciones or None,
                'creado': current_user.id_usuario,
            }
        )
        db.session.execute(text("COMMIT"))
        id_compra = db.session.execute(text("SELECT @id_out")).scalar()

        # 2. Insertar detalles via SP
        for i in range(len(ids_materia)):
            if not ids_materia[i]:
                continue
            db.session.execute(
                text("""CALL sp_agregar_detalle_compra(
                    :id_compra,:id_mat,:id_uni,
                    :cant,:uni,:factor,:cant_b,:costo)"""),
                {
                    'id_compra': id_compra,
                    'id_mat':    int(ids_materia[i]),
                    'id_uni':    int(ids_unidad[i]) if ids_unidad[i] else 0,
                    'cant':      float(cantidades[i]),
                    'uni':       unidades_str[i],
                    'factor':    float(factores[i]) if factores[i] else 1.0,
                    'cant_b':    float(cantidades_b[i]) if cantidades_b[i] else float(cantidades[i]),
                    'costo':     float(costos[i]),
                }
            )
            db.session.execute(text("COMMIT"))

        flash(f'Pedido {folio} creado en estatus Ordenado.', 'success')
    except Exception as e:
        db.session.rollback()
        orig = getattr(e, 'orig', None)
        msg = (orig.args[1] if orig and hasattr(orig, 'args') and len(orig.args) >= 2 else str(e))
        flash(f'Error al crear el pedido: {msg}', 'error')

    return redirect(url_for('compras.index_compras'))


# ── CANCELAR PEDIDO ─────────────────────────────────────────
@compras.route("/compras/cancelar/<int:id_compra>", methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def cancelar_compra(id_compra):
    motivo = request.form.get('motivo_cancelacion', '').strip()
    if not motivo:
        flash('Debes indicar el motivo de cancelación.', 'error')
        return redirect(url_for('compras.index_compras'))
    try:
        call_sp(
            "CALL sp_cancelar_compra(:id, :motivo, :usr)",
            {'id': id_compra, 'motivo': motivo, 'usr': current_user.id_usuario}
        )
        flash('Pedido cancelado correctamente.', 'success')
    except Exception as e:
        orig = getattr(e, 'orig', None)
        msg = (orig.args[1] if orig and hasattr(orig, 'args') and len(orig.args) >= 2 else str(e))
        flash(f'Error al cancelar: {msg}', 'error')
    return redirect(url_for('compras.index_compras'))


# ── FINALIZAR PEDIDO (acepta mercancía → actualiza stock + salida efectivo) ──
@compras.route("/compras/finalizar/<int:id_compra>", methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def finalizar_compra(id_compra):
    folio_salida = _generar_folio_salida()
    try:
        call_sp(
            "CALL sp_finalizar_compra(:id, :usr, :folio)",
            {'id': id_compra, 'usr': current_user.id_usuario, 'folio': folio_salida}
        )
        flash('Mercancía aceptada: inventario actualizado. Salida de efectivo registrada y en espera de autorización del administrador.', 'success')
    except Exception as e:
        orig = getattr(e, 'orig', None)
        msg = (orig.args[1] if orig and hasattr(orig, 'args') and len(orig.args) >= 2 else str(e))
        flash(f'Error al finalizar: {msg}', 'error')
    return redirect(url_for('compras.index_compras'))


# ── EDITAR PEDIDO (solo estatus ordenado) ───────────────────
@compras.route("/compras/editar/<int:id_compra>", methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def editar_compra(id_compra):
    form = _compra_form()
    # En edición solo validamos fecha (proveedor no se modifica)
    if not form.fecha_compra.data:
        flash('La fecha de compra es obligatoria.', 'error')
        return redirect(url_for('compras.index_compras'))

    folio_factura  = form.folio_factura.data.strip() if form.folio_factura.data else ''
    observaciones  = form.observaciones.data.strip() if form.observaciones.data else ''

    ids_materia    = request.form.getlist('id_materia[]')
    ids_unidad     = request.form.getlist('id_unidad_presentacion[]')
    cantidades     = request.form.getlist('cantidad_comprada[]')
    unidades_str   = request.form.getlist('unidad_compra[]')
    factores       = request.form.getlist('factor_conversion[]')
    cantidades_b   = request.form.getlist('cantidad_base[]')
    costos         = request.form.getlist('costo_unitario[]')

    ids_materia = [m for m in ids_materia if m]
    if not ids_materia:
        flash('Debes agregar al menos un insumo.', 'error')
        return redirect(url_for('compras.index_compras'))

    try:
        # 1. Limpiar detalles existentes
        db.session.execute(text("CALL sp_limpiar_detalles_compra(:id)"), {'id': id_compra})
        db.session.execute(text("COMMIT"))

        # 2. Actualizar campos del encabezado
        db.session.execute(
            text("UPDATE compras SET folio_factura=:ff, observaciones=:obs WHERE id_compra=:id"),
            {'ff': folio_factura or None, 'obs': observaciones or None, 'id': id_compra}
        )
        db.session.execute(text("COMMIT"))

        # 3. Re-insertar detalles
        for i in range(len(ids_materia)):
            if not ids_materia[i]:
                continue
            db.session.execute(
                text("""CALL sp_agregar_detalle_compra(
                    :id_compra,:id_mat,:id_uni,
                    :cant,:uni,:factor,:cant_b,:costo)"""),
                {
                    'id_compra': id_compra,
                    'id_mat':    int(ids_materia[i]),
                    'id_uni':    int(ids_unidad[i]) if ids_unidad[i] else 0,
                    'cant':      float(cantidades[i]),
                    'uni':       unidades_str[i],
                    'factor':    float(factores[i]) if factores[i] else 1.0,
                    'cant_b':    float(cantidades_b[i]) if cantidades_b[i] else float(cantidades[i]),
                    'costo':     float(costos[i]),
                }
            )
            db.session.execute(text("COMMIT"))

        flash('Pedido actualizado correctamente.', 'success')
    except Exception as e:
        db.session.rollback()
        orig = getattr(e, 'orig', None)
        msg = (orig.args[1] if orig and hasattr(orig, 'args') and len(orig.args) >= 2 else str(e))
        flash(f'Error al editar: {msg}', 'error')

    return redirect(url_for('compras.index_compras'))


# ── CORREGIR PRECIO (pago rechazado) ───────────────────────
@compras.route("/compras/corregir-precio/<int:id_compra>", methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def corregir_precio_compra(id_compra):
    costos = request.form.getlist('costo_unitario[]')
    ids_detalle = request.form.getlist('id_detalle[]')

    if not ids_detalle or not costos or len(ids_detalle) != len(costos):
        flash('Datos de corrección incompletos.', 'error')
        return redirect(url_for('compras.index_compras'))

    folio_salida = _generar_folio_salida()
    try:
        # 1. Actualizar cada costo unitario
        for id_det, costo in zip(ids_detalle, costos):
            db.session.execute(
                text("UPDATE detalle_compras SET costo_unitario = :c WHERE id_detalle_compra = :id"),
                {'c': float(costo), 'id': int(id_det)}
            )
        db.session.execute(text("COMMIT"))

        # 2. SP recalcula total y genera nueva salida pendiente
        db.session.execute(
            text("CALL sp_corregir_precio_compra(:id, :folio, :usr)"),
            {'id': id_compra, 'folio': folio_salida, 'usr': current_user.id_usuario}
        )
        db.session.execute(text("COMMIT"))
        flash('Precio corregido. Nueva salida de efectivo enviada para autorización.', 'success')
    except Exception as e:
        db.session.rollback()
        orig = getattr(e, 'orig', None)
        msg = orig.args[1] if orig and hasattr(orig, 'args') and len(orig.args) >= 2 else str(e)
        flash(f'Error al corregir: {msg}', 'error')

    return redirect(url_for('compras.index_compras'))


# ── CREAR UNIDAD DE COMPRA ───────────────────────────────────
@compras.route("/compras/api/unidades/nueva", methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def crear_unidad():
    data = request.get_json()
    id_materia    = data.get('id_materia')
    nombre        = (data.get('nombre') or '').strip()
    simbolo       = (data.get('simbolo') or '').strip()
    factor        = data.get('factor_a_base')
    uso           = data.get('uso', 'compra')

    if not id_materia or not nombre or not simbolo or not factor:
        return jsonify({'error': 'Todos los campos son obligatorios.'}), 400
    try:
        factor = float(factor)
        if factor <= 0:
            raise ValueError()
    except (ValueError, TypeError):
        return jsonify({'error': 'El factor debe ser un número mayor a 0.'}), 400
    if uso not in ('compra', 'ambos'):
        uso = 'compra'

    try:
        db.session.execute(
            text("CALL sp_crear_unidad_compra(:mat,:nom,:sim,:fac,:uso, @id_out)"),
            {'mat': int(id_materia), 'nom': nombre, 'sim': simbolo,
             'fac': factor, 'uso': uso}
        )
        db.session.execute(text("COMMIT"))
        id_unidad = db.session.execute(text("SELECT @id_out")).scalar()
    except Exception as e:
        db.session.rollback()
        orig = getattr(e, 'orig', None)
        if orig and hasattr(orig, 'args') and len(orig.args) >= 2:
            msg = orig.args[1]   # solo el texto, sin el código numérico
        else:
            msg = str(e)
        return jsonify({'error': msg}), 400

    return jsonify({
        'id':            id_unidad,
        'nombre':        nombre,
        'simbolo':       simbolo,
        'factor_a_base': factor,
    }), 201


# ── DETALLE (JSON para modal) ───────────────────────────────
@compras.route("/compras/detalle/<int:id_compra>")
@login_required
@roles_required('admin', 'empleado')
def detalle_compra(id_compra):
    compra = Compra.query.get_or_404(id_compra)
    detalles = (
        db.session.query(DetalleCompra, MateriaPrima, UnidadPresentacion)
        .join(MateriaPrima, DetalleCompra.id_materia == MateriaPrima.id_materia)
        .outerjoin(UnidadPresentacion,
                   DetalleCompra.id_unidad_presentacion == UnidadPresentacion.id_unidad)
        .filter(DetalleCompra.id_compra == id_compra)
        .all()
    )
    return jsonify({
        'id_compra':           compra.id_compra,
        'id_proveedor':        compra.id_proveedor,
        'folio':               compra.folio,
        'folio_factura':       compra.folio_factura or '',
        'estatus':             compra.estatus,
        'motivo_cancelacion':  compra.motivo_cancelacion or '',
        'fecha_compra':        compra.fecha_compra.strftime('%d/%m/%Y'),
        'fecha_compra_iso':    compra.fecha_compra.strftime('%Y-%m-%d'),
        'total':               float(compra.total),
        'observaciones':       compra.observaciones or '',
        'detalles': [{
            'id_detalle_compra': d.DetalleCompra.id_detalle_compra,
            'id_materia':       d.MateriaPrima.id_materia,
            'id_unidad':        d.DetalleCompra.id_unidad_presentacion,
            'materia':          d.MateriaPrima.nombre,
            'unidad_base':      d.MateriaPrima.unidad_base,
            'unidad_compra':    d.DetalleCompra.unidad_compra,
            'cantidad_comprada': float(d.DetalleCompra.cantidad_comprada),
            'factor':           float(d.DetalleCompra.factor_conversion),
            'cantidad_base':    float(d.DetalleCompra.cantidad_base),
            'costo_unitario':   float(d.DetalleCompra.costo_unitario),
            'subtotal':         float(d.DetalleCompra.cantidad_comprada * d.DetalleCompra.costo_unitario),
        } for d in detalles]
    })
