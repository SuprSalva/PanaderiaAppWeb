import uuid as _uuid
import datetime
from flask import render_template, request, redirect, url_for, flash, current_app
from models import db, MateriaPrima
from . import materias_primas_bp
from flask_login import login_required, current_user
from auth import roles_required

POR_PAGINA = 10


@materias_primas_bp.route('/materias-primas', methods=['GET'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def index_materias_primas():
    buscar = request.args.get('buscar', '').strip()
    estatus = request.args.get('estatus', 'todos')
    nivel_stock = request.args.get('nivel_stock', '')  # nuevo filtro
    pagina = request.args.get('pagina', 1, type=int)
    if pagina < 1:
        pagina = 1

    query = MateriaPrima.query
    if buscar:
        query = query.filter(
            db.or_(
                MateriaPrima.nombre.ilike(f'%{buscar}%'),
                MateriaPrima.categoria.ilike(f'%{buscar}%'),
            )
        )
    if estatus in ('activo', 'inactivo'):
        query = query.filter_by(estatus=estatus)

    # Aplicar filtro por nivel de stock (sobre la consulta, no sobre todos)
    if nivel_stock == 'normal':
        query = query.filter(MateriaPrima.stock_actual > MateriaPrima.stock_minimo)
    elif nivel_stock == 'bajo':
        query = query.filter(
            MateriaPrima.stock_actual > 0,
            MateriaPrima.stock_actual <= MateriaPrima.stock_minimo
        )
    elif nivel_stock == 'critico':
        query = query.filter(MateriaPrima.stock_actual <= 0)

    paginacion = query.order_by(MateriaPrima.nombre).paginate(page=pagina, per_page=POR_PAGINA, error_out=False)
    lista = paginacion.items

    # Contadores globales (sin el filtro de nivel_stock, para las tarjetas)
    todas = MateriaPrima.query.all()
    normal = sum(1 for m in todas if float(m.stock_actual) > float(m.stock_minimo))
    bajo = sum(1 for m in todas if 0 < float(m.stock_actual) <= float(m.stock_minimo))
    critico = sum(1 for m in todas if float(m.stock_actual) <= 0)
    total = len(todas)

    return render_template(
        'materiasPrimas/materiasPrimas.html',
        materias=lista,
        paginacion=paginacion,
        pagina=pagina,
        total=total,
        total_activos=MateriaPrima.query.filter_by(estatus='activo').count(),
        total_inactivos=MateriaPrima.query.filter_by(estatus='inactivo').count(),
        stat_normal=normal,
        stat_bajo=bajo,
        stat_critico=critico,
        buscar=buscar,
        estatus_sel=estatus,
        nivel_stock_sel=nivel_stock 
    )


@materias_primas_bp.route('/materias-primas/nueva', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def materias_primas_nueva():
    nombre      = request.form.get('nombre', '').strip()
    categoria   = request.form.get('categoria', '').strip()
    unidad_base = request.form.get('unidad_base', '').strip()
    stock_min   = request.form.get('stock_minimo', '0').strip()
    stock_ini   = request.form.get('stock_inicial', '0').strip()
    estatus     = request.form.get('estatus', 'activo')

    if not nombre:
        current_app.logger.warning('Creacion de materia prima fallida (sin nombre) | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('El nombre es obligatorio.', 'error')
        return redirect(url_for('materias_primas.index_materias_primas', modal='nueva'))
    if not unidad_base:
        current_app.logger.warning('Creacion de materia prima fallida (sin unidad) | usuario: %s | materia: %s | fecha: %s', current_user.username, nombre, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('La unidad base es obligatoria.', 'error')
        return redirect(url_for('materias_primas.index_materias_primas', modal='nueva'))

    if MateriaPrima.query.filter(
            db.func.lower(MateriaPrima.nombre) == nombre.lower()).first():
        current_app.logger.warning('Creacion de materia prima fallida (duplicada) | usuario: %s | materia: %s | fecha: %s', current_user.username, nombre, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Ya existe una materia prima llamada "{nombre}".', 'error')
        return redirect(url_for('materias_primas.index_materias_primas', modal='nueva'))

    try:
        stock_min_f = float(stock_min) if stock_min else 0.0
        stock_ini_f = float(stock_ini) if stock_ini else 0.0
    except ValueError:
        current_app.logger.warning('Creacion de materia prima fallida (stock no numerico) | usuario: %s | materia: %s | fecha: %s', current_user.username, nombre, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('Los valores de stock deben ser numéricos.', 'error')
        return redirect(url_for('materias_primas.index_materias_primas', modal='nueva'))

    ahora = datetime.datetime.now()
    nueva = MateriaPrima(
        uuid_materia   = str(_uuid.uuid4()),
        nombre         = nombre,
        categoria      = categoria or None,
        unidad_base    = unidad_base,
        stock_actual   = stock_ini_f,
        stock_minimo   = stock_min_f,
        estatus        = estatus if estatus in ('activo', 'inactivo') else 'activo',
        creado_en      = ahora,
        actualizado_en = ahora,
    )

    try:
        db.session.add(nueva)
        db.session.commit()
        current_app.logger.info('Materia prima creada exitosamente | usuario: %s | materia: %s | fecha: %s', current_user.username, nueva.nombre, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Materia prima "{nueva.nombre}" creada correctamente.', 'success')
    except Exception as e:
        db.session.rollback()
        current_app.logger.error('Error al guardar materia prima | usuario: %s | materia: %s | error: %s | fecha: %s', current_user.username, nueva.nombre, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Error al guardar: {str(e)}', 'error')
        return redirect(url_for('materias_primas.index_materias_primas', modal='nueva'))

    return redirect(url_for('materias_primas.index_materias_primas'))


@materias_primas_bp.route('/materias-primas/editar/<int:id_materia>', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def materias_primas_editar(id_materia):
    materia     = MateriaPrima.query.get_or_404(id_materia)
    nombre      = request.form.get('nombre', '').strip()
    categoria   = request.form.get('categoria', '').strip()
    unidad_base = request.form.get('unidad_base', '').strip()
    stock_min   = request.form.get('stock_minimo', '').strip()
    estatus     = request.form.get('estatus', '')

    if not nombre:
        current_app.logger.warning('Edicion de materia prima fallida (sin nombre) | usuario: %s | id: %s | fecha: %s', current_user.username, id_materia, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('El nombre es obligatorio.', 'error')
        return redirect(url_for('materias_primas.index_materias_primas',
                                modal='editar', id=id_materia))
    if not unidad_base:
        current_app.logger.warning('Edicion de materia prima fallida (sin unidad) | usuario: %s | id: %s | fecha: %s', current_user.username, id_materia, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('La unidad base es obligatoria.', 'error')
        return redirect(url_for('materias_primas.index_materias_primas',
                                modal='editar', id=id_materia))

    dup = MateriaPrima.query.filter(
        db.func.lower(MateriaPrima.nombre) == nombre.lower(),
        MateriaPrima.id_materia != id_materia
    ).first()
    if dup:
        current_app.logger.warning('Edicion de materia prima fallida (nombre duplicado) | usuario: %s | nombre_pedido: %s | id: %s | fecha: %s', current_user.username, nombre, id_materia, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Ya existe otra materia prima llamada "{nombre}".', 'error')
        return redirect(url_for('materias_primas.index_materias_primas',
                                modal='editar', id=id_materia))

    materia.nombre         = nombre
    materia.categoria      = categoria or None
    materia.unidad_base    = unidad_base
    materia.actualizado_en = datetime.datetime.now()

    if stock_min:
        try:
            materia.stock_minimo = float(stock_min)
        except ValueError:
            pass
    if estatus in ('activo', 'inactivo'):
        materia.estatus = estatus

    try:
        db.session.commit()
        current_app.logger.info('Materia prima actualizada exitosamente | usuario: %s | materia: %s | fecha: %s', current_user.username, materia.nombre, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Materia prima "{materia.nombre}" actualizada correctamente.', 'success')
    except Exception as e:
        db.session.rollback()
        current_app.logger.error('Error al actualizar materia prima | usuario: %s | id: %s | error: %s | fecha: %s', current_user.username, id_materia, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Error al actualizar: {str(e)}', 'error')
        return redirect(url_for('materias_primas.index_materias_primas',
                                modal='editar', id=id_materia))

    return redirect(url_for('materias_primas.index_materias_primas'))


@materias_primas_bp.route('/materias-primas/toggle/<int:id_materia>', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def materias_primas_toggle(id_materia):
    materia = MateriaPrima.query.get_or_404(id_materia)
    materia.estatus        = 'inactivo' if materia.estatus == 'activo' else 'activo'
    materia.actualizado_en = datetime.datetime.now()

    try:
        db.session.commit()
        accion = 'activada' if materia.estatus == 'activo' else 'desactivada'
        current_app.logger.info('Estatus de materia prima cambiado | usuario: %s | materia: %s | estatus: %s | fecha: %s', current_user.username, materia.nombre, materia.estatus, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Materia prima "{materia.nombre}" {accion}.', 'success')
    except Exception as e:
        db.session.rollback()
        current_app.logger.error('Error al cambiar estatus de materia prima | usuario: %s | materia: %s | error: %s | fecha: %s', current_user.username, materia.nombre, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Error: {str(e)}', 'error')

    return redirect(url_for('materias_primas.index_materias_primas'))