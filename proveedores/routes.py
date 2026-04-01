import uuid as _uuid
from flask import render_template, request, redirect, url_for, flash, session
from sqlalchemy import text
from sqlalchemy.exc import OperationalError, IntegrityError

from models import db, Proveedor
from forms import ProveedorForm
from . import proveedores

POR_PAGINA = 10


# ─── utilidad interna ──────────────────────────────────────────────────────────
def _usuario_actual():
    """Retorna el id_usuario de la sesión activa, o None si no hay sesión."""
    return session.get('id_usuario')


def _msg_error_sp(exc):
    """Extrae el mensaje del SIGNAL SQLSTATE lanzado por un SP de MySQL."""
    if exc.orig and len(exc.orig.args) > 1:
        return exc.orig.args[1]
    return 'Ocurrió un error al procesar la operación.'


# ─── Listado ───────────────────────────────────────────────────────────────────
@proveedores.route('/proveedores', methods=['GET'])
def index_proveedores():
    buscar  = request.args.get('buscar', '').strip()
    estatus = request.args.get('estatus', 'todos')
    pagina  = request.args.get('pagina', 1, type=int)
    if pagina < 1:
        pagina = 1

    query = Proveedor.query
    if buscar:
        like  = f'%{buscar}%'
        query = query.filter(
            db.or_(
                Proveedor.nombre.ilike(like),
                Proveedor.rfc.ilike(like),
                Proveedor.contacto.ilike(like),
            )
        )
    if estatus in ('activo', 'inactivo'):
        query = query.filter_by(estatus=estatus)

    paginacion = query.order_by(Proveedor.nombre).paginate(
        page=pagina, per_page=POR_PAGINA, error_out=False
    )
    lista = paginacion.items

    total_proveedores = Proveedor.query.count()
    total_activos     = Proveedor.query.filter_by(estatus='activo').count()
    total_inactivos   = Proveedor.query.filter_by(estatus='inactivo').count()

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


# ─── Crear ─────────────────────────────────────────────────────────────────────
@proveedores.route('/proveedores/nuevo', methods=['POST'])
def proveedores_nuevo():
    form = ProveedorForm(request.form)

    if not form.validate():
        for campo, errores in form.errors.items():
            for err in errores:
                flash(err, 'danger')
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
        flash(f'Proveedor "{form.nombre.data.strip()}" registrado correctamente.', 'success')

    except (OperationalError, IntegrityError) as e:
        db.session.rollback()
        flash(_msg_error_sp(e), 'danger')
        return redirect(url_for('proveedores.index_proveedores', modal='nuevo'))

    return redirect(url_for('proveedores.index_proveedores'))


# ─── Editar ────────────────────────────────────────────────────────────────────
@proveedores.route('/proveedores/editar/<int:id_proveedor>', methods=['POST'])
def proveedores_editar(id_proveedor):
    form = ProveedorForm(request.form)

    if not form.validate():
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
        flash(f'Proveedor "{form.nombre.data.strip()}" actualizado correctamente.', 'success')

    except (OperationalError, IntegrityError) as e:
        db.session.rollback()
        flash(_msg_error_sp(e), 'danger')
        return redirect(url_for('proveedores.index_proveedores',
                                modal='editar', id=id_proveedor))

    return redirect(url_for('proveedores.index_proveedores'))


# ─── Confirmar toggle ──────────────────────────────────────────────────────────
@proveedores.route('/proveedores/confirmar-toggle/<int:id_proveedor>', methods=['GET'])
def proveedores_confirmar_toggle(id_proveedor):
    prov = Proveedor.query.get_or_404(id_proveedor)
    return render_template('proveedores/proveedores_confirmar_toggle.html', prov=prov)


# ─── Toggle estatus (activo ↔ inactivo) ───────────────────────────────────────
@proveedores.route('/proveedores/toggle/<int:id_proveedor>', methods=['POST'])
def proveedores_toggle(id_proveedor):
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
        flash(f'Proveedor "{nombre_prov}" {accion} correctamente.', 'success')

    except (OperationalError, IntegrityError) as e:
        db.session.rollback()
        flash(_msg_error_sp(e), 'danger')

    return redirect(url_for('proveedores.index_proveedores'))