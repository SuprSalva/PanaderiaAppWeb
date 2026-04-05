import uuid as _uuid
import datetime
<<<<<<< Updated upstream
from flask import render_template, request, redirect, url_for, flash, session, current_app
from flask_login import login_required, current_user
from auth import roles_required
from sqlalchemy import text
from sqlalchemy.exc import OperationalError, IntegrityError

=======
from flask import render_template, request, redirect, url_for, flash
>>>>>>> Stashed changes
from models import db, Proveedor
from . import proveedores

POR_PAGINA = 10

@proveedores.route('/proveedores', methods=['GET'])
def index_proveedores():
    current_app.logger.info('Vista de catalogo de proveedores accesada | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
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

<<<<<<< Updated upstream
    if not form.validate():
        current_app.logger.warning('Creacion de proveedor fallida (validacion) | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        for campo, errores in form.errors.items():
            for err in errores:
                flash(err, 'error')
        return redirect(url_for('proveedores.index_proveedores', modal='nuevo'))

    rfc_val = (form.rfc.data or '').strip().upper() or None

    try:
        db.session.execute(
            text("CALL sp_crear_proveedor(:uuid, :nombre, :rfc, :contacto, "
                 ":telefono, :email, :direccion, :creado_por)"),
            {
                'uuid':       str(_uuid.uuid4()),
                'nombre':     form.nombre.data.strip(),
                'rfc':        rfc_val,
                'contacto':   (form.contacto.data or '').strip() or None,
                'telefono':   (form.telefono.data or '').strip() or None,
                'email':      (form.email.data or '').strip() or None,
                'direccion':  (form.direccion.data or '').strip() or None,
                'creado_por': _usuario_actual(),
            }
        )
        db.session.commit()
        current_app.logger.info('Proveedor creado exitosamente | usuario: %s | proveedor: %s | fecha: %s', current_user.username, form.nombre.data.strip(), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Proveedor "{form.nombre.data.strip()}" registrado correctamente.', 'success')

    except (OperationalError, IntegrityError) as e:
        db.session.rollback()
        current_app.logger.error('Error db al crear proveedor | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(_msg_error_sp(e), 'danger')
=======
    if not nombre:
        flash('El nombre del proveedor es obligatorio.', 'danger')
        return redirect(url_for('proveedores.index_proveedores', modal='nuevo'))

    if rfc and Proveedor.query.filter_by(rfc=rfc).first():
        flash(f'Ya existe un proveedor con el RFC {rfc}.', 'danger')
>>>>>>> Stashed changes
        return redirect(url_for('proveedores.index_proveedores', modal='nuevo'))
    except Exception as e:
        db.session.rollback()
        current_app.logger.error('Error general al crear proveedor | usuario: %s | error: %s | fecha: %s', current_user.username, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('Error al crear proveedor.', 'danger')
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

<<<<<<< Updated upstream
    if not form.validate():
        current_app.logger.warning('Edicion de proveedor fallida (validacion) | usuario: %s | id_proveedor: %s | fecha: %s', current_user.username, id_proveedor, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        for campo, errores in form.errors.items():
            for err in errores:
                flash(err, 'danger')
        return redirect(url_for('proveedores.index_proveedores',
                                modal='editar', id=id_proveedor))

    rfc_val = (form.rfc.data or '').strip().upper() or None

    try:
        db.session.execute(
            text("CALL sp_editar_proveedor(:id, :nombre, :rfc, :contacto, "
                 ":telefono, :email, :direccion, :ejecutado_por)"),
            {
                'id':            id_proveedor,
                'nombre':        form.nombre.data.strip(),
                'rfc':           rfc_val,
                'contacto':      (form.contacto.data or '').strip() or None,
                'telefono':      (form.telefono.data or '').strip() or None,
                'email':         (form.email.data or '').strip() or None,
                'direccion':     (form.direccion.data or '').strip() or None,
                'ejecutado_por': _usuario_actual(),
            }
        )
        db.session.commit()
        current_app.logger.info('Proveedor editado exitosamente | usuario: %s | proveedor: %s | fecha: %s', current_user.username, form.nombre.data.strip(), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Proveedor "{form.nombre.data.strip()}" actualizado correctamente.', 'success')

    except (OperationalError, IntegrityError) as e:
        db.session.rollback()
        current_app.logger.error('Error db al editar proveedor | usuario: %s | id_proveedor: %s | error: %s | fecha: %s', current_user.username, id_proveedor, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(_msg_error_sp(e), 'error')
        return redirect(url_for('proveedores.index_proveedores',
                                modal='editar', id=id_proveedor))
    except Exception as e:
        db.session.rollback()
        current_app.logger.error('Error general al editar proveedor | usuario: %s | id_proveedor: %s | error: %s | fecha: %s', current_user.username, id_proveedor, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('Error al actualizar proveedor.', 'error')
        return redirect(url_for('proveedores.index_proveedores',
                                modal='editar', id=id_proveedor))
=======
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
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
    try:
        result = db.session.execute(
            text("CALL sp_toggle_proveedor(:id, :ejecutado_por)"),
            {
                'id':            id_proveedor,
                'ejecutado_por': _usuario_actual(),
            }
        )
        row = result.fetchone()
        db.session.commit()

        nuevo_estatus = row.nuevo_estatus if row else 'actualizado'
        nombre_prov   = row.nombre        if row else ''
        accion        = 'activado' if nuevo_estatus == 'activo' else 'desactivado'
        current_app.logger.info('Estatus de proveedor cambiado | usuario: %s | proveedor: %s | estatus: %s | fecha: %s', current_user.username, nombre_prov, nuevo_estatus, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Proveedor "{nombre_prov}" {accion} correctamente.', 'success')

    except (OperationalError, IntegrityError) as e:
        db.session.rollback()
        current_app.logger.error('Error db al cambiar estatus de proveedor | usuario: %s | id_proveedor: %s | error: %s | fecha: %s', current_user.username, id_proveedor, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(_msg_error_sp(e), 'error')
    except Exception as e:
        db.session.rollback()
        current_app.logger.error('Error general al cambiar estatus de proveedor | usuario: %s | id_proveedor: %s | error: %s | fecha: %s', current_user.username, id_proveedor, str(e), datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('Error al cambiar estatus.', 'error')

    return redirect(url_for('proveedores.index_proveedores'))
=======
    prov = Proveedor.query.get_or_404(id_proveedor)
    prov.estatus        = 'inactivo' if prov.estatus == 'activo' else 'activo'
    prov.actualizado_en = datetime.datetime.now()
    db.session.commit()
    accion = 'activado' if prov.estatus == 'activo' else 'desactivado'
    flash(f'Proveedor "{prov.nombre}" {accion}.', 'success')
>>>>>>> Stashed changes
