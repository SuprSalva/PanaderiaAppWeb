import datetime
from collections import defaultdict

from flask import render_template, request, redirect, url_for, flash, current_app
from flask_login import login_required, current_user
from sqlalchemy import text

from models import db, Proveedor
from auth import roles_required
from forms import SalidaEfectivoForm
from utils.db_roles import role_connection
from . import efectivo


def _salida_form():
    form = SalidaEfectivoForm(request.form)
    form.id_proveedor.choices = (
        [(0, '— Sin proveedor —')] +
        [(p.id_proveedor, p.nombre)
         for p in Proveedor.query.filter_by(estatus='activo').order_by(Proveedor.nombre).all()]
    )
    return form


def _gen_folio():
    with role_connection() as conn:
        total = conn.execute(
            text("SELECT COUNT(*) FROM salidas_efectivo")
        ).scalar() + 1
    return f"SE-{total:04d}"


@efectivo.route("/salida-efectivo")
@login_required
@roles_required('admin', 'empleado')
def index_salida_efectivo():
    current_app.logger.info('Vista de panel de salidas de efectivo accesada | usuario: %s | fecha: %s', current_user.username, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    with role_connection() as conn:
        lista = conn.execute(
            text("SELECT * FROM vw_salidas_efectivo ORDER BY creado_en DESC")
        ).mappings().all()

    proveedores = Proveedor.query.filter_by(estatus='activo').order_by(Proveedor.nombre).all()
    form = _salida_form()

    hoy         = datetime.date.today()
    mes_inicio  = hoy.replace(day=1)
    mes_ant_fin = mes_inicio - datetime.timedelta(days=1)
    mes_ant_ini = mes_ant_fin.replace(day=1)

    egresos_hoy     = sum(float(s.monto) for s in lista
                          if s.fecha_salida == hoy and s.estado == 'aprobada')
    egresos_mes     = sum(float(s.monto) for s in lista
                          if s.fecha_salida >= mes_inicio and s.estado == 'aprobada')
    egresos_mes_ant = sum(float(s.monto) for s in lista
                          if mes_ant_ini <= s.fecha_salida <= mes_ant_fin
                          and s.estado == 'aprobada')
    movimientos_hoy = sum(1 for s in lista if s.fecha_salida == hoy)
    pendientes      = sum(1 for s in lista if s.estado == 'pendiente')

    cats_map = defaultdict(lambda: {'count': 0, 'total': 0.0})
    for s in lista:
        if s.fecha_salida == hoy and s.estado == 'aprobada':
            cats_map[s.categoria]['count'] += 1
            cats_map[s.categoria]['total'] += float(s.monto)
    cats_hoy = sorted(
        [{'key': k, **v} for k, v in cats_map.items() if v['total'] > 0],
        key=lambda x: x['total'], reverse=True,
    )
    max_cat = max((c['total'] for c in cats_hoy), default=1)

    return render_template("efectivo/salidaEfectivo.html",
        salidas=lista,
        proveedores=proveedores,
        form=form,
        egresos_hoy=egresos_hoy,
        egresos_mes=egresos_mes,
        egresos_mes_ant=egresos_mes_ant,
        movimientos_hoy=movimientos_hoy,
        pendientes=pendientes,
        total_salidas=len(lista),
        cats_hoy=cats_hoy,
        max_cat=max_cat,
    )


@efectivo.route("/salida-efectivo/registrar", methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def crear_salida():
    form = _salida_form()
    if not form.validate():
        primer_error = next(iter(form.errors.values()))[0]
        current_app.logger.warning('Intento de registrar salida de efectivo fallido (validacion) | usuario: %s | error: %s | fecha: %s', current_user.username, primer_error, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f' {primer_error}', 'error')
        return redirect(url_for('efectivo.index_salida_efectivo'))

    id_proveedor = form.id_proveedor.data or None
    folio = _gen_folio()
    try:
        with role_connection() as conn:
            conn.execute(
                text("CALL sp_registrar_salida_manual(:folio,:prov,:cat,:desc,:monto,:fecha,:usr)"),
                {
                    'folio': folio,
                    'prov':  int(id_proveedor) if id_proveedor else None,
                    'cat':   form.categoria.data,
                    'desc':  form.descripcion.data.strip(),
                    'monto': float(form.monto.data),
                    'fecha': form.fecha_salida.data,
                    'usr':   current_user.id_usuario,
                }
            )
            conn.commit()
        current_app.logger.info('Salida de efectivo registrada exitosamente | usuario: %s | folio: %s | fecha: %s', current_user.username, folio, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Salida {folio} registrada correctamente.', 'success')
    except Exception as e:
        orig = getattr(e, 'orig', None)
        msg = orig.args[1] if orig and hasattr(orig, 'args') and len(orig.args) >= 2 else str(e)
        current_app.logger.error('Error al registrar salida de efectivo | usuario: %s | error: %s | fecha: %s', current_user.username, msg, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Error al registrar: {msg}', 'error')

    return redirect(url_for('efectivo.index_salida_efectivo'))


@efectivo.route("/salida-efectivo/aprobar/<int:id_salida>", methods=['POST'])
@login_required
@roles_required('admin')
def aprobar_salida(id_salida):
    decision = request.form.get('decision', '')
    if decision not in ('aprobada', 'rechazada'):
        current_app.logger.warning('Resolucion de salida de efectivo fallida (decision invalida) | admin: %s | decision_enviada: %s | fecha: %s', current_user.username, decision, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash('Decisión no válida.', 'error')
        return redirect(url_for('efectivo.index_salida_efectivo'))

    try:
        with role_connection() as conn:
            conn.execute(
                text("CALL sp_aprobar_salida(:id, :dec, :usr)"),
                {'id': id_salida, 'dec': decision, 'usr': current_user.id_usuario}
            )
            conn.commit()
        accion = 'aprobada' if decision == 'aprobada' else 'rechazada'
        current_app.logger.info('Resolucion de salida de efectivo aplicada | admin: %s | decision: %s | id_salida: %s | fecha: %s', current_user.username, decision, id_salida, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Salida {accion} correctamente.', 'success')
    except Exception as e:
        orig = getattr(e, 'orig', None)
        msg = orig.args[1] if orig and hasattr(orig, 'args') and len(orig.args) >= 2 else str(e)
        current_app.logger.error('Error al resolver salida de efectivo | admin: %s | id_salida: %s | error: %s | fecha: %s', current_user.username, id_salida, msg, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        flash(f'Error: {msg}', 'error')

    return redirect(url_for('efectivo.index_salida_efectivo'))
