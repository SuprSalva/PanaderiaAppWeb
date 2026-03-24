import uuid as _uuid
import datetime
from flask import render_template, request, redirect, url_for, flash, jsonify
from models import db, Receta, DetalleReceta, MateriaPrima, Producto, UnidadPresentacion
from forms import RecetaForm
from . import recetas_bp

POR_PAGINA = 9 

@recetas_bp.route('/recetas/unidades/<int:id_materia>', methods=['GET'])
def recetas_unidades(id_materia):
    materia = MateriaPrima.query.get_or_404(id_materia)
    unidades = (UnidadPresentacion.query
                .filter_by(id_materia=id_materia, activo=True)
                .filter(UnidadPresentacion.uso.in_(['receta', 'ambos']))
                .order_by(UnidadPresentacion.nombre)
                .all())
    return jsonify({
        'unidad_base': materia.unidad_base,
        'unidades': [
            {
                'id':     u.id_unidad,
                'nombre': u.nombre,
                'simbolo': u.simbolo,
                'factor': float(u.factor_a_base),
            }
            for u in unidades
        ]
    })

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

@recetas_bp.route('/recetas', methods=['GET'])
def index_recetas():
    buscar  = request.args.get('buscar', '').strip()
    estatus = request.args.get('estatus', 'todos')
    pagina  = request.args.get('pagina', 1, type=int)
    if pagina < 1:
        pagina = 1

    query = Receta.query
    if buscar:
        query = query.filter(Receta.nombre.ilike(f'%{buscar}%'))
    if estatus in ('activo', 'inactivo'):
        query = query.filter_by(estatus=estatus)

    paginacion      = query.order_by(Receta.nombre).paginate(
                          page=pagina, per_page=POR_PAGINA, error_out=False)
    lista           = paginacion.items

    total_recetas   = Receta.query.count()
    total_activas   = Receta.query.filter_by(estatus='activo').count()
    total_inactivas = Receta.query.filter_by(estatus='inactivo').count()
    insumos_unicos  = db.session.query(
        db.func.count(db.func.distinct(DetalleReceta.id_materia))
    ).scalar() or 0

    materias = (MateriaPrima.query
                .filter_by(estatus='activo')
                .order_by(MateriaPrima.nombre)
                .all())

    form_nueva, productos = _form_con_productos()

    return render_template(
        'recetas/recetas.html',
        recetas=lista,
        paginacion=paginacion,
        pagina=pagina,
        total_recetas=total_recetas,
        total_activas=total_activas,
        total_inactivas=total_inactivas,
        insumos_unicos=insumos_unicos,
        buscar=buscar,
        estatus_sel=estatus,
        materias=materias,
        productos=productos,
        form_nueva=form_nueva,
    )

@recetas_bp.route('/recetas/nueva', methods=['POST'])
def recetas_nueva():
    form, _ = _form_con_productos(request.form)
    insumos = _recopilar_insumos()

    if not form.validate():
        for errors in form.errors.values():
            for err in errors:
                flash(err, 'danger')
        return redirect(url_for('recetas_bp.index_recetas', modal='nueva'))

    if not insumos:
        flash('Agrega al menos un insumo a la receta.', 'danger')
        return redirect(url_for('recetas_bp.index_recetas', modal='nueva'))

    nueva = Receta(
        uuid_receta        = str(_uuid.uuid4()),
        id_producto        = form.id_producto.data or None,
        nombre             = form.nombre.data.strip(),
        descripcion        = (form.descripcion.data or '').strip() or None,
        rendimiento        = float(form.rendimiento.data),
        unidad_rendimiento = form.unidad_rendimiento.data,
        precio_venta       = float(form.precio_venta.data) if form.precio_venta.data else None,
        estatus            = 'activo',
        creado_en          = datetime.datetime.now(),
        actualizado_en     = datetime.datetime.now(),
    )
    db.session.add(nueva)
    db.session.flush()

    for orden, ins in enumerate(insumos, start=1):
        db.session.add(DetalleReceta(
            id_receta              = nueva.id_receta,
            id_materia             = ins['id_materia'],
            id_unidad_presentacion = ins['id_unidad_presentacion'],
            cantidad_presentacion  = ins['cantidad_presentacion'],
            cantidad_requerida     = ins['cantidad_requerida'],
            orden                  = orden,
        ))

    db.session.commit()
    flash(f'Receta "{nueva.nombre}" creada correctamente.', 'success')
    return redirect(url_for('recetas_bp.index_recetas'))

@recetas_bp.route('/recetas/editar/<int:id_receta>', methods=['POST'])
def recetas_editar(id_receta):
    receta = Receta.query.get_or_404(id_receta)
    form, _ = _form_con_productos(request.form)
    insumos = _recopilar_insumos()

    if not form.validate():
        for errors in form.errors.values():
            for err in errors:
                flash(err, 'danger')
        return redirect(url_for('recetas_bp.index_recetas', modal='editar', id=id_receta))

    if not insumos:
        flash('La receta debe tener al menos un insumo.', 'danger')
        return redirect(url_for('recetas_bp.index_recetas', modal='editar', id=id_receta))

    receta.id_producto        = form.id_producto.data or None
    receta.nombre             = form.nombre.data.strip()
    receta.descripcion        = (form.descripcion.data or '').strip() or None
    receta.rendimiento        = float(form.rendimiento.data)
    receta.unidad_rendimiento = form.unidad_rendimiento.data
    receta.precio_venta       = float(form.precio_venta.data) if form.precio_venta.data else None
    receta.actualizado_en     = datetime.datetime.now()

    DetalleReceta.query.filter_by(id_receta=receta.id_receta).delete()
    for orden, ins in enumerate(insumos, start=1):
        db.session.add(DetalleReceta(
            id_receta              = receta.id_receta,
            id_materia             = ins['id_materia'],
            id_unidad_presentacion = ins['id_unidad_presentacion'],
            cantidad_presentacion  = ins['cantidad_presentacion'],
            cantidad_requerida     = ins['cantidad_requerida'],
            orden                  = orden,
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