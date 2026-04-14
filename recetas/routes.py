import uuid as _uuid
import datetime
from flask import render_template, request, redirect, url_for, flash, jsonify, session, current_app
from flask_login import login_required, current_user
from auth import roles_required
from sqlalchemy import text
from sqlalchemy.exc import OperationalError, IntegrityError

from models import db, Receta, DetalleReceta, MateriaPrima, Producto, UnidadPresentacion
from forms import RecetaForm
from . import recetas_bp


def _usuario_actual():
    return session.get('id_usuario')


def _msg_error_sp(exc):
    if exc.orig and len(exc.orig.args) > 1:
        return exc.orig.args[1]
    return 'Ocurrió un error al procesar la operación.'


def _recopilar_insumos():
    ids         = request.form.getlist('id_materia[]')
    cantidades  = request.form.getlist('cantidad_presentacion[]')
    id_unidades = request.form.getlist('id_unidad_presentacion[]')
    resultado   = []
    vistos      = set()

    for mid, cant_pres, id_up in zip(ids, cantidades, id_unidades):
        mid       = mid.strip()
        cant_pres = cant_pres.strip()
        id_up     = id_up.strip()
        if not mid or not cant_pres:
            continue
        try:
            mid       = int(mid)
            cant_pres = float(cant_pres)
        except ValueError:
            continue
        if mid in vistos:
            continue
        vistos.add(mid)

        if id_up:
            try:
                id_up  = int(id_up)
                up     = UnidadPresentacion.query.get(id_up)
                factor = float(up.factor_a_base) if up else 1.0
            except (ValueError, AttributeError):
                id_up  = None
                factor = 1.0
        else:
            id_up  = None
            factor = 1.0

        resultado.append({
            'id_materia':             mid,
            'cantidad_presentacion':  cant_pres,
            'id_unidad_presentacion': id_up,
            'cantidad_requerida':     round(cant_pres * factor, 4),
        })
    return resultado


def _form_con_productos(form_data=None):
    form = RecetaForm(form_data)
    productos = (Producto.query
                 .filter_by(estatus='activo')
                 .order_by(Producto.nombre)
                 .all())
    form.id_producto.choices = [(0, '— Seleccionar producto —')] + [
        (p.id_producto, p.nombre) for p in productos
    ]
    return form, productos


# ── Unidades disponibles para un insumo ──────────────────────────────
@recetas_bp.route('/recetas/unidades/<int:id_materia>', methods=['GET'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def recetas_unidades(id_materia):
    materia  = MateriaPrima.query.get_or_404(id_materia)
    unidades = (UnidadPresentacion.query
                .filter_by(id_materia=id_materia, activo=True)
                .filter(UnidadPresentacion.uso.in_(['receta', 'ambos']))
                .order_by(UnidadPresentacion.nombre)
                .all())
    return jsonify({
        'unidad_base': materia.unidad_base,
        'unidades': [
            {'id': u.id_unidad, 'nombre': u.nombre,
             'simbolo': u.simbolo, 'factor': float(u.factor_a_base)}
            for u in unidades
        ]
    })


# ── API: crear nueva unidad de presentación (uso receta) ─────────────
@recetas_bp.route('/recetas/api/unidades/nueva', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def recetas_nueva_unidad():
    data       = request.get_json()
    id_materia = data.get('id_materia')
    nombre     = (data.get('nombre')  or '').strip()
    simbolo    = (data.get('simbolo') or '').strip()
    factor     = data.get('factor_a_base')
    uso        = data.get('uso', 'receta')

    if not id_materia or not nombre or not simbolo or not factor:
        return jsonify({'error': 'Todos los campos son obligatorios.'}), 400
    try:
        factor = float(factor)
        if factor <= 0:
            raise ValueError()
    except (ValueError, TypeError):
        return jsonify({'error': 'El factor debe ser un número mayor a 0.'}), 400
    if uso not in ('receta', 'ambos'):
        uso = 'receta'

    try:
        db.session.execute(
            text("CALL sp_crear_unidad_compra(:mat, :nom, :sim, :fac, :uso, @id_out)"),
            {'mat': int(id_materia), 'nom': nombre, 'sim': simbolo,
             'fac': factor, 'uso': uso}
        )
        db.session.execute(text("COMMIT"))
        id_unidad = db.session.execute(text("SELECT @id_out")).scalar()
    except Exception as e:
        db.session.rollback()
        orig = getattr(e, 'orig', None)
        msg  = (orig.args[1] if orig and hasattr(orig, 'args') and len(orig.args) >= 2
                else str(e))
        return jsonify({'error': msg}), 400

    current_app.logger.info(
        'Unidad de receta creada | usuario: %s | materia: %s | unidad: %s | fecha: %s',
        current_user.username, id_materia, nombre,
        datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    )
    return jsonify({'id': id_unidad, 'nombre': nombre,
                    'simbolo': simbolo, 'factor_a_base': factor}), 201


# ── Index ─────────────────────────────────────────────────────────────
@recetas_bp.route('/recetas', methods=['GET'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def index_recetas():
    current_app.logger.info(
        'Vista de recetario accesada | usuario: %s | fecha: %s',
        current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    )
    modal  = request.args.get('modal', '')
    obj_id = request.args.get('id', 0, type=int)

    lista = Receta.query.order_by(Receta.nombre).all()

    stats = db.session.execute(
        text("""
            SELECT
                COUNT(*)                  AS total_recetas,
                SUM(estatus = 'activo')   AS total_activas,
                SUM(estatus = 'inactivo') AS total_inactivas
            FROM vw_recetas
        """)
    ).fetchone()

    materias       = (MateriaPrima.query
                      .filter_by(estatus='activo')
                      .order_by(MateriaPrima.nombre)
                      .all())
    form_nueva, productos = _form_con_productos()

    receta_editar  = Receta.query.get(obj_id) if obj_id and modal == 'editar'  else None
    receta_detalle = Receta.query.get(obj_id) if obj_id and modal == 'detalle' else None

    return render_template(
        'recetas/recetas.html',
        recetas=lista,
        total_recetas=stats.total_recetas or 0,
        total_activas=stats.total_activas or 0,
        total_inactivas=stats.total_inactivas or 0,
        materias=materias,
        productos=productos,
        form_nueva=form_nueva,
        receta_editar=receta_editar,
        receta_detalle=receta_detalle,
    )


# ── Nueva receta ──────────────────────────────────────────────────────
@recetas_bp.route('/recetas/nueva', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def recetas_nueva():
    form, _ = _form_con_productos(request.form)
    insumos = _recopilar_insumos()

    if not form.validate():
        for errors in form.errors.values():
            for err in errors:
                flash(err, 'error')
        return redirect(url_for('recetas_bp.index_recetas', modal='nueva'))
    if not insumos:
        flash('Agrega al menos un insumo a la receta.', 'warning')
        return redirect(url_for('recetas_bp.index_recetas', modal='nueva'))

    try:
        result = db.session.execute(
            text("CALL sp_crear_receta("
                 ":uuid, :id_producto, :nombre, :descripcion, "
                 ":rendimiento, :unidad_rendimiento, :precio_venta, :creado_por)"),
            {
                'uuid':               str(_uuid.uuid4()),
                'id_producto':        form.id_producto.data or None,
                'nombre':             form.nombre.data.strip(),
                'descripcion':        (form.descripcion.data or '').strip() or None,
                'rendimiento':        float(form.rendimiento.data),
                'unidad_rendimiento': form.unidad_rendimiento.data,
                'precio_venta':       float(form.precio_venta.data) if form.precio_venta.data else None,
                'creado_por':         _usuario_actual(),
            }
        )
        id_receta = result.fetchone().id_receta
        for orden, ins in enumerate(insumos, start=1):
            db.session.add(DetalleReceta(
                id_receta=id_receta, id_materia=ins['id_materia'],
                id_unidad_presentacion=ins['id_unidad_presentacion'],
                cantidad_presentacion=ins['cantidad_presentacion'],
                cantidad_requerida=ins['cantidad_requerida'], orden=orden,
            ))
        db.session.commit()
        nombre = form.nombre.data.strip()
        current_app.logger.info('Receta creada | usuario: %s | receta: %s | fecha: %s',
            current_user.username, nombre, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Receta "{nombre}" creada correctamente.', 'success')
    except (OperationalError, IntegrityError) as e:
        db.session.rollback()
        flash(_msg_error_sp(e), 'error')
        return redirect(url_for('recetas_bp.index_recetas', modal='nueva'))
    except Exception as e:
        db.session.rollback()
        flash(f'Error al crear receta: {str(e)}', 'error')
        return redirect(url_for('recetas_bp.index_recetas', modal='nueva'))

    return redirect(url_for('recetas_bp.index_recetas'))


# ── Editar receta ─────────────────────────────────────────────────────
@recetas_bp.route('/recetas/editar/<int:id_receta>', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def recetas_editar(id_receta):
    form, _ = _form_con_productos(request.form)
    insumos = _recopilar_insumos()

    if not form.validate():
        for errors in form.errors.values():
            for err in errors:
                flash(err, 'error')
        return redirect(url_for('recetas_bp.index_recetas', modal='editar', id=id_receta))
    if not insumos:
        flash('La receta debe tener al menos un insumo.', 'warning')
        return redirect(url_for('recetas_bp.index_recetas', modal='editar', id=id_receta))

    try:
        db.session.execute(
            text("CALL sp_editar_receta("
                 ":id_receta, :id_producto, :nombre, :descripcion, "
                 ":rendimiento, :unidad_rendimiento, :precio_venta, :ejecutado_por)"),
            {
                'id_receta':          id_receta,
                'id_producto':        form.id_producto.data or None,
                'nombre':             form.nombre.data.strip(),
                'descripcion':        (form.descripcion.data or '').strip() or None,
                'rendimiento':        float(form.rendimiento.data),
                'unidad_rendimiento': form.unidad_rendimiento.data,
                'precio_venta':       float(form.precio_venta.data) if form.precio_venta.data else None,
                'ejecutado_por':      _usuario_actual(),
            }
        )
        DetalleReceta.query.filter_by(id_receta=id_receta).delete()
        for orden, ins in enumerate(insumos, start=1):
            db.session.add(DetalleReceta(
                id_receta=id_receta, id_materia=ins['id_materia'],
                id_unidad_presentacion=ins['id_unidad_presentacion'],
                cantidad_presentacion=ins['cantidad_presentacion'],
                cantidad_requerida=ins['cantidad_requerida'], orden=orden,
            ))
        db.session.commit()
        nombre = form.nombre.data.strip()
        current_app.logger.info('Receta editada | usuario: %s | receta: %s | fecha: %s',
            current_user.username, nombre, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Receta "{nombre}" actualizada correctamente.', 'success')
    except (OperationalError, IntegrityError) as e:
        db.session.rollback()
        flash(_msg_error_sp(e), 'error')
        return redirect(url_for('recetas_bp.index_recetas', modal='editar', id=id_receta))
    except Exception as e:
        db.session.rollback()
        flash(f'Error al actualizar receta: {str(e)}', 'error')
        return redirect(url_for('recetas_bp.index_recetas', modal='editar', id=id_receta))

    return redirect(url_for('recetas_bp.index_recetas'))


@recetas_bp.route('/recetas/confirmar-toggle/<int:id_receta>', methods=['GET'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def recetas_confirmar_toggle(id_receta):
    receta = Receta.query.get_or_404(id_receta)
    return render_template('recetas/recetas_confirmar_toggle.html', receta=receta)


@recetas_bp.route('/recetas/toggle/<int:id_receta>', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def recetas_toggle(id_receta):
    try:
        result = db.session.execute(
            text("CALL sp_toggle_receta(:id_receta, :ejecutado_por)"),
            {'id_receta': id_receta, 'ejecutado_por': _usuario_actual()}
        )
        row = result.fetchone()
        db.session.commit()
        nuevo_estatus = row.nuevo_estatus if row else 'actualizado'
        nombre_r      = row.nombre        if row else ''
        accion        = 'activada' if nuevo_estatus == 'activo' else 'desactivada'
        flash(f'Receta "{nombre_r}" {accion}.', 'success')
    except (OperationalError, IntegrityError) as e:
        db.session.rollback()
        flash(_msg_error_sp(e), 'error')
    except Exception as e:
        db.session.rollback()
        flash(f'Error al cambiar estatus: {str(e)}', 'error')
    return redirect(url_for('recetas_bp.index_recetas'))