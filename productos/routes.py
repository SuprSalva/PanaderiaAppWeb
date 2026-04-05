import uuid as _uuid
import datetime
from flask import render_template, request, redirect, url_for, flash, current_app
from flask_login import login_required, current_user
from auth import roles_required
from models import db, Producto, InventarioPT
from forms import ProductoForm
from . import productos_bp

POR_PAGINA = 10

@productos_bp.route('/productos', methods=['GET'])
@login_required
@roles_required('admin','empleado')
def index_productos():
    current_app.logger.info('Vista de inventario de productos accesada | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    buscar  = request.args.get('buscar', '').strip()
    estatus = request.args.get('estatus', 'todos')
    pagina  = request.args.get('pagina', 1, type=int)
    if pagina < 1:
        pagina = 1

    query = Producto.query
    if buscar:
        query = query.filter(Producto.nombre.ilike(f'%{buscar}%'))
    if estatus in ('activo', 'inactivo'):
        query = query.filter_by(estatus=estatus)

    paginacion      = query.order_by(Producto.nombre).paginate(
                          page=pagina, per_page=POR_PAGINA, error_out=False)
    lista           = paginacion.items
    total           = Producto.query.count()
    total_activos   = Producto.query.filter_by(estatus='activo').count()
    total_inactivos = Producto.query.filter_by(estatus='inactivo').count()

    form_nueva = ProductoForm()

    return render_template(
        'productos/productos.html',
        productos=lista,
        paginacion=paginacion,
        pagina=pagina,
        total=total,
        total_activos=total_activos,
        total_inactivos=total_inactivos,
        buscar=buscar,
        estatus_sel=estatus,
        form_nueva=form_nueva,
    )

@productos_bp.route('/productos/nuevo', methods=['POST'])
@login_required
@roles_required('admin','empleado')
def productos_nuevo():
    form = ProductoForm(request.form)

    if not form.validate():
        current_app.logger.warning('Creacion de producto fallida (validacion) | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        for errors in form.errors.values():
            for err in errors:
                flash(err, 'error')
        return redirect(url_for('productos_bp.index_productos', modal='nuevo'))

    nuevo = Producto(
        uuid_producto  = str(_uuid.uuid4()),
        nombre         = form.nombre.data.strip(),
        descripcion    = (form.descripcion.data or '').strip() or None,
        precio_venta   = float(form.precio_venta.data),
        estatus        = 'activo',
        creado_en      = datetime.datetime.now(),
        actualizado_en = datetime.datetime.now(),
        creado_por     = None,
    )
    db.session.add(nuevo)
    db.session.flush()

    inv = InventarioPT(
        id_producto  = nuevo.id_producto,
        stock_actual = 0,
        stock_minimo = 0,
    )
    try:
        db.session.add(inv)
        db.session.commit()
        current_app.logger.info('Producto creado exitosamente | usuario: %s | producto: %s | fecha: %s', current_user.username, nuevo.nombre, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Producto "{nuevo.nombre}" creado correctamente.', 'success')
    except Exception as e:
        db.session.rollback()
        current_app.logger.error('Error al crear producto | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Error al guardar el producto: {str(e)}', 'error')

    return redirect(url_for('productos_bp.index_productos'))

@productos_bp.route('/productos/editar/<int:id_producto>', methods=['POST'])
@login_required
@roles_required('admin','empleado')
def productos_editar(id_producto):
    producto = Producto.query.get_or_404(id_producto)
    form     = ProductoForm(request.form)

    if not form.validate():
        current_app.logger.warning('Edicion de producto fallida (validacion) | usuario: %s | id_producto: %s | fecha: %s', current_user.username, id_producto, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        for errors in form.errors.values():
            for err in errors:
                flash(err, 'error')
        return redirect(url_for('productos_bp.index_productos', modal='editar', id=id_producto))

    producto.nombre         = form.nombre.data.strip()
    producto.descripcion    = (form.descripcion.data or '').strip() or None
    producto.precio_venta   = float(form.precio_venta.data)
    producto.actualizado_en = datetime.datetime.now()

    if producto.inventario:
        producto.inventario.stock_minimo = float(form.stock_minimo.data or 0)

    try:
        db.session.commit()
        current_app.logger.info('Producto actualizado exitosamente | usuario: %s | producto: %s | fecha: %s', current_user.username, producto.nombre, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Producto "{producto.nombre}" actualizado correctamente.', 'success')
    except Exception as e:
        db.session.rollback()
        current_app.logger.error('Error al actualizar producto | usuario: %s | id_producto: %s | error: %s | fecha: %s', current_user.username, id_producto, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Error al actualizar el producto: {str(e)}', 'error')

    return redirect(url_for('productos_bp.index_productos'))

@productos_bp.route('/productos/confirmar-toggle/<int:id_producto>', methods=['GET'])
@login_required
@roles_required('admin','empleado')
def productos_confirmar_toggle(id_producto):
    producto = Producto.query.get_or_404(id_producto)
    return render_template('productos/productos_confirmar_toggle.html', producto=producto)

@productos_bp.route('/productos/toggle/<int:id_producto>', methods=['POST'])
@login_required 
@roles_required('admin','empleado')
def productos_toggle(id_producto):
    producto = Producto.query.get_or_404(id_producto)
    producto.estatus        = 'inactivo' if producto.estatus == 'activo' else 'activo'
    producto.actualizado_en = datetime.datetime.now()
    try:
        db.session.commit()
        accion = 'activado' if producto.estatus == 'activo' else 'desactivado'
        current_app.logger.info('Estatus de producto cambiado | usuario: %s | producto: %s | estatus: %s | fecha: %s', current_user.username, producto.nombre, producto.estatus, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Producto "{producto.nombre}" {accion}.', 'success')
    except Exception as e:
        db.session.rollback()
        current_app.logger.error('Error al cambiar estatus de producto | usuario: %s | id_producto: %s | error: %s | fecha: %s', current_user.username, id_producto, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Error al cambiar estatus: {str(e)}', 'error')

    return redirect(url_for('productos_bp.index_productos'))