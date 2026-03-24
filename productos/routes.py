import uuid as _uuid
import datetime
from flask import render_template, request, redirect, url_for, flash
from models import db, Producto, InventarioPT
from forms import ProductoForm
from . import productos_bp

POR_PAGINA = 10

@productos_bp.route('/productos', methods=['GET'])
def index_productos():
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
def productos_nuevo():
    form = ProductoForm(request.form)

    if not form.validate():
        for errors in form.errors.values():
            for err in errors:
                flash(err, 'danger')
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
        stock_minimo = float(form.stock_minimo.data or 0),
    )
    db.session.add(inv)
    db.session.commit()

    flash(f'Producto "{nuevo.nombre}" creado correctamente.', 'success')
    return redirect(url_for('productos_bp.index_productos'))

@productos_bp.route('/productos/editar/<int:id_producto>', methods=['POST'])
def productos_editar(id_producto):
    producto = Producto.query.get_or_404(id_producto)
    form     = ProductoForm(request.form)

    if not form.validate():
        for errors in form.errors.values():
            for err in errors:
                flash(err, 'danger')
        return redirect(url_for('productos_bp.index_productos', modal='editar', id=id_producto))

    producto.nombre         = form.nombre.data.strip()
    producto.descripcion    = (form.descripcion.data or '').strip() or None
    producto.precio_venta   = float(form.precio_venta.data)
    producto.actualizado_en = datetime.datetime.now()

    if producto.inventario:
        producto.inventario.stock_minimo = float(form.stock_minimo.data or 0)

    db.session.commit()
    flash(f'Producto "{producto.nombre}" actualizado correctamente.', 'success')
    return redirect(url_for('productos_bp.index_productos'))

@productos_bp.route('/productos/confirmar-toggle/<int:id_producto>', methods=['GET'])
def productos_confirmar_toggle(id_producto):
    producto = Producto.query.get_or_404(id_producto)
    return render_template('productos/productos_confirmar_toggle.html', producto=producto)

@productos_bp.route('/productos/toggle/<int:id_producto>', methods=['POST'])
def productos_toggle(id_producto):
    producto = Producto.query.get_or_404(id_producto)
    producto.estatus        = 'inactivo' if producto.estatus == 'activo' else 'activo'
    producto.actualizado_en = datetime.datetime.now()
    db.session.commit()
    accion = 'activado' if producto.estatus == 'activo' else 'desactivado'
    flash(f'Producto "{producto.nombre}" {accion}.', 'success')
    return redirect(url_for('productos_bp.index_productos'))