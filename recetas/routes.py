import uuid as _uuid
import datetime
from flask import render_template, request, redirect, url_for, flash
from models import db, Receta, DetalleReceta, MateriaPrima
from . import recetas_bp


def _recopilar_insumos():
    ids        = request.form.getlist('id_materia[]')
    cantidades = request.form.getlist('cantidad_requerida[]')
    resultado  = []
    for mid, cant in zip(ids, cantidades):
        mid  = mid.strip()
        cant = cant.strip()
        if mid and cant:
            try:
                resultado.append((int(mid), float(cant)))
            except ValueError:
                pass
    return resultado


@recetas_bp.route('/recetas', methods=['GET'])
def index_recetas():
    buscar  = request.args.get('buscar', '').strip()
    estatus = request.args.get('estatus', 'todos')

    query = Receta.query
    if buscar:
        query = query.filter(Receta.nombre.ilike(f'%{buscar}%'))
    if estatus in ('activo', 'inactivo'):
        query = query.filter_by(estatus=estatus)

    lista          = query.order_by(Receta.nombre).all()
    total_recetas  = Receta.query.count()
    total_activas  = Receta.query.filter_by(estatus='activo').count()
    total_inactivas = Receta.query.filter_by(estatus='inactivo').count()
    insumos_unicos = db.session.query(
        db.func.count(db.func.distinct(DetalleReceta.id_materia))
    ).scalar() or 0

    materias = (MateriaPrima.query
                .filter_by(estatus='activo')
                .order_by(MateriaPrima.nombre)
                .all())

    return render_template(
        'recetas/recetas.html',
        recetas=lista,
        total_recetas=total_recetas,
        total_activas=total_activas,
        total_inactivas=total_inactivas,
        insumos_unicos=insumos_unicos,
        buscar=buscar,
        estatus_sel=estatus,
        materias=materias
    )


@recetas_bp.route('/recetas/nueva', methods=['POST'])
def recetas_nueva():
    nombre       = request.form.get('nombre', '').strip()
    descripcion  = request.form.get('descripcion', '').strip()
    rendimiento  = request.form.get('rendimiento', '').strip()
    unidad_rend  = request.form.get('unidad_rendimiento', 'pza').strip()
    precio_venta = request.form.get('precio_venta', '').strip()
    insumos      = _recopilar_insumos()

    if not nombre:
        flash('El nombre de la receta es obligatorio.', 'danger')
        return redirect(url_for('recetas_bp.index_recetas'))
    if not rendimiento:
        flash('El rendimiento es obligatorio.', 'danger')
        return redirect(url_for('recetas_bp.index_recetas'))
    if not insumos:
        flash('Agrega al menos un insumo a la receta.', 'danger')
        return redirect(url_for('recetas_bp.index_recetas'))

    nueva = Receta(
        uuid_receta        = str(_uuid.uuid4()),
        nombre             = nombre,
        descripcion        = descripcion,
        rendimiento        = float(rendimiento),
        unidad_rendimiento = unidad_rend,
        precio_venta       = float(precio_venta) if precio_venta else None,
        estatus            = 'activo',
        creado_en          = datetime.datetime.now(),
        actualizado_en     = datetime.datetime.now(),
    )
    db.session.add(nueva)
    db.session.flush()

    for orden, (mid, cant) in enumerate(insumos, start=1):
        db.session.add(DetalleReceta(
            id_receta          = nueva.id_receta,
            id_materia         = mid,
            cantidad_requerida = cant,
            orden              = orden
        ))

    db.session.commit()
    flash(f'Receta "{nueva.nombre}" creada correctamente.', 'success')
    return redirect(url_for('recetas_bp.index_recetas'))


@recetas_bp.route('/recetas/editar/<int:id_receta>', methods=['POST'])
def recetas_editar(id_receta):
    receta       = Receta.query.get_or_404(id_receta)
    nombre       = request.form.get('nombre', '').strip()
    descripcion  = request.form.get('descripcion', '').strip()
    rendimiento  = request.form.get('rendimiento', '').strip()
    unidad_rend  = request.form.get('unidad_rendimiento', 'pza').strip()
    precio_venta = request.form.get('precio_venta', '').strip()
    insumos      = _recopilar_insumos()

    if not nombre or not rendimiento:
        flash('Nombre y rendimiento son obligatorios.', 'danger')
        return redirect(url_for('recetas_bp.index_recetas'))
    if not insumos:
        flash('La receta debe tener al menos un insumo.', 'danger')
        return redirect(url_for('recetas_bp.index_recetas'))

    receta.nombre             = nombre
    receta.descripcion        = descripcion
    receta.rendimiento        = float(rendimiento)
    receta.unidad_rendimiento = unidad_rend
    receta.precio_venta       = float(precio_venta) if precio_venta else None
    receta.actualizado_en     = datetime.datetime.now()

    # Borrar insumos anteriores y reemplazar
    DetalleReceta.query.filter_by(id_receta=receta.id_receta).delete()
    for orden, (mid, cant) in enumerate(insumos, start=1):
        db.session.add(DetalleReceta(
            id_receta          = receta.id_receta,
            id_materia         = mid,
            cantidad_requerida = cant,
            orden              = orden
        ))

    db.session.commit()
    flash(f'Receta "{receta.nombre}" actualizada correctamente.', 'success')
    return redirect(url_for('recetas_bp.index_recetas'))


@recetas_bp.route('/recetas/confirmar-toggle/<int:id_receta>', methods=['GET'])
def recetas_confirmar_toggle(id_receta):
    receta = Receta.query.get_or_404(id_receta)
    return render_template('recetas/recetas_confirmar_toggle.html', receta=receta)


@recetas_bp.route('/recetas/toggle/<int:id_receta>', methods=['POST'])
def recetas_toggle(id_receta):
    receta = Receta.query.get_or_404(id_receta)
    receta.estatus        = 'inactivo' if receta.estatus == 'activo' else 'activo'
    receta.actualizado_en = datetime.datetime.now()
    db.session.commit()
    accion = 'activada' if receta.estatus == 'activo' else 'desactivada'
    flash(f'Receta "{receta.nombre}" {accion}.', 'success')
    return redirect(url_for('recetas_bp.index_recetas'))