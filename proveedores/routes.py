import uuid as _uuid
import datetime
from flask import render_template, request, redirect, url_for, flash
from models import db, Proveedor
from . import proveedores

POR_PAGINA = 10

@proveedores.route('/proveedores', methods=['GET'])
def index_proveedores():
    buscar  = request.args.get('buscar', '').strip()
    estatus = request.args.get('estatus', 'todos')
    pagina  = request.args.get('pagina', 1, type=int)
    if pagina < 1:
        pagina = 1

    query = Proveedor.query
    if buscar:
        like = f'%{buscar}%'
        query = query.filter(
            db.or_(
                Proveedor.nombre.ilike(like),
                Proveedor.rfc.ilike(like),
                Proveedor.contacto.ilike(like),
            )
        )
    if estatus in ('activo', 'inactivo'):
        query = query.filter_by(estatus=estatus)

    paginacion      = query.order_by(Proveedor.nombre).paginate(
                          page=pagina, per_page=POR_PAGINA, error_out=False)
    lista           = paginacion.items

    total_proveedores  = Proveedor.query.count()
    total_activos      = Proveedor.query.filter_by(estatus='activo').count()
    total_inactivos    = Proveedor.query.filter_by(estatus='inactivo').count()

    return render_template(
        'proveedores/proveedores.html',
        proveedores=lista,
        paginacion=paginacion,
        pagina=pagina,
        total_proveedores=total_proveedores,
        total_activos=total_activos,
        total_inactivos=total_inactivos,
        buscar=buscar,
        estatus_sel=estatus,
    )

@proveedores.route('/proveedores/nuevo', methods=['POST'])
def proveedores_nuevo():
    nombre   = request.form.get('nombre',   '').strip()
    rfc      = request.form.get('rfc',      '').strip().upper() or None
    contacto = request.form.get('contacto', '').strip() or None
    telefono = request.form.get('telefono', '').strip() or None
    email    = request.form.get('email',    '').strip() or None
    direccion= request.form.get('direccion','').strip() or None

    if not nombre:
        flash('El nombre del proveedor es obligatorio.', 'danger')
        return redirect(url_for('proveedores.index_proveedores', modal='nuevo'))

    if rfc and Proveedor.query.filter_by(rfc=rfc).first():
        flash(f'Ya existe un proveedor con el RFC {rfc}.', 'danger')
        return redirect(url_for('proveedores.index_proveedores', modal='nuevo'))

    nuevo = Proveedor(
        uuid_proveedor = str(_uuid.uuid4()),
        nombre         = nombre,
        rfc            = rfc,
        contacto       = contacto,
        telefono       = telefono,
        email          = email,
        direccion      = direccion,
        estatus        = 'activo',
        creado_en      = datetime.datetime.now(),
        actualizado_en = datetime.datetime.now(),
    )
    db.session.add(nuevo)
    db.session.commit()
    flash(f'Proveedor "{nuevo.nombre}" registrado correctamente.', 'success')
    return redirect(url_for('proveedores.index_proveedores'))

@proveedores.route('/proveedores/editar/<int:id_proveedor>', methods=['POST'])
def proveedores_editar(id_proveedor):
    prov = Proveedor.query.get_or_404(id_proveedor)

    nombre   = request.form.get('nombre',   '').strip()
    rfc      = request.form.get('rfc',      '').strip().upper() or None
    contacto = request.form.get('contacto', '').strip() or None
    telefono = request.form.get('telefono', '').strip() or None
    email    = request.form.get('email',    '').strip() or None
    direccion= request.form.get('direccion','').strip() or None

    if not nombre:
        flash('El nombre del proveedor es obligatorio.', 'danger')
        return redirect(url_for('proveedores.index_proveedores',
                                modal='editar', id=id_proveedor))

    if rfc:
        duplicado = Proveedor.query.filter(
            Proveedor.rfc == rfc,
            Proveedor.id_proveedor != id_proveedor
        ).first()
        if duplicado:
            flash(f'Ya existe otro proveedor con el RFC {rfc}.', 'danger')
            return redirect(url_for('proveedores.index_proveedores',
                                    modal='editar', id=id_proveedor))

    prov.nombre        = nombre
    prov.rfc           = rfc
    prov.contacto      = contacto
    prov.telefono      = telefono
    prov.email         = email
    prov.direccion     = direccion
    prov.actualizado_en= datetime.datetime.now()
    db.session.commit()
    flash(f'Proveedor "{prov.nombre}" actualizado correctamente.', 'success')
    return redirect(url_for('proveedores.index_proveedores'))

@proveedores.route('/proveedores/confirmar-toggle/<int:id_proveedor>', methods=['GET'])
def proveedores_confirmar_toggle(id_proveedor):
    prov = Proveedor.query.get_or_404(id_proveedor)
    return render_template('proveedores/proveedores_confirmar_toggle.html', prov=prov)

@proveedores.route('/proveedores/toggle/<int:id_proveedor>', methods=['POST'])
def proveedores_toggle(id_proveedor):
    prov = Proveedor.query.get_or_404(id_proveedor)
    prov.estatus        = 'inactivo' if prov.estatus == 'activo' else 'activo'
    prov.actualizado_en = datetime.datetime.now()
    db.session.commit()
    accion = 'activado' if prov.estatus == 'activo' else 'desactivado'
    flash(f'Proveedor "{prov.nombre}" {accion}.', 'success')
    return redirect(url_for('proveedores.index_proveedores'))

