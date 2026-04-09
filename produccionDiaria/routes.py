"""
produccion_diaria/routes.py  – v2 (panes individuales)
"""
import json, datetime
from flask import render_template, request, redirect, url_for, flash, jsonify, current_app
from flask_login import login_required, current_user
from flask_wtf.csrf import validate_csrf
from wtforms import ValidationError
from sqlalchemy import text
from auth import roles_required
from models import db
from . import produccion_diaria
from forms import (NuevaProduccionDiariaForm, FinalizarProduccionDiariaForm,
                    CancelarProduccionDiariaForm, GuardarPlantillaForm)

POR_PAGINA = 15
ROL_ADMIN   = 'Administrador'
ROL_VEND    = 'Vendedor'
ROL_PAN     = 'Panadero'

def _call_sp(call_sql, select_sql, params):
    conn = db.session.connection()
    conn.execute(text(call_sql), params)
    row = conn.execute(text(select_sql)).mappings().one()
    db.session.commit()
    return dict(row)

def _log(msg):
    ts = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    return f'{msg} | usuario: {current_user.username} | fecha: {ts}'

# ─── Lista ───────────────────────────────────────────────────────────────────

@produccion_diaria.route('/produccion-diaria')
@login_required
@roles_required('admin', 'empleado', 'panadero')
def index_pd():
    estado    = request.args.get('estado', '')
    fecha_ini = request.args.get('fecha_ini', '')
    fecha_fin = request.args.get('fecha_fin', '')
    pagina    = max(request.args.get('pagina', 1, type=int), 1)
    offset    = (pagina - 1) * POR_PAGINA

    rows = db.session.execute(
        text("CALL sp_pd_lista(:est,:fi,:ff,:lim,:off)"),
        {'est': estado or None, 'fi': fecha_ini or None,
         'ff': fecha_fin or None, 'lim': POR_PAGINA, 'off': offset}
    ).mappings().all()
    db.session.execute(text("SELECT 1"))
    producciones = [dict(r) for r in rows]

    conteos = {}
    for e in ('pendiente','en_proceso','finalizado','cancelado'):
        conteos[e] = db.session.execute(
            text("SELECT COUNT(*) FROM produccion_diaria WHERE estado=:e"),
            {'e': e}).scalar() or 0

    # Productos agrupados con sus recetas (sin cálculo de stock en tarjetas)
    prods_rows = db.session.execute(text("""
        SELECT DISTINCT p.id_producto, p.nombre AS nombre_producto,
               r.id_receta, r.nombre AS nombre_receta,
               CAST(r.rendimiento AS UNSIGNED) AS rendimiento
        FROM  productos p
        JOIN  recetas r ON r.id_producto = p.id_producto
        WHERE p.estatus='activo' AND r.estatus='activo'
        ORDER BY p.nombre, r.rendimiento
    """)).mappings().all()

    from collections import OrderedDict
    _prods = OrderedDict()
    for row in prods_rows:
        pid = row['id_producto']
        if pid not in _prods:
            _prods[pid] = {
                'id_producto': pid,
                'nombre':      row['nombre_producto'],
                'recetas':     [],
            }
        _prods[pid]['recetas'].append({
            'id_receta':   row['id_receta'],
            'nombre':      row['nombre_receta'],
            'rendimiento': int(row['rendimiento'] or 0),
        })
    productos_agrupados = list(_prods.values())

    operarios = db.session.execute(text("""
        SELECT u.id_usuario, u.nombre_completo
        FROM   usuarios u JOIN roles r ON r.id_rol=u.id_rol
        WHERE  r.clave_rol='panadero' AND u.estatus='activo'
        ORDER BY u.nombre_completo
    """)).mappings().all()

    plantillas = db.session.execute(text("""
        SELECT pp.id_plantilla, pp.nombre, pp.descripcion,
               COUNT(ppd.id_ppd) AS total_lineas
        FROM   plantillas_produccion pp
        LEFT JOIN plantillas_produccion_detalle ppd
               ON ppd.id_plantilla=pp.id_plantilla
        GROUP BY pp.id_plantilla,pp.nombre,pp.descripcion
        ORDER BY pp.creado_en DESC LIMIT 20
    """)).mappings().all()

    form = NuevaProduccionDiariaForm()
    form.operario_id.choices = [(0,'— Sin asignar —')] + [
        (o['id_usuario'],o['nombre_completo']) for o in operarios]

    return render_template('produccion_diaria/index.html',
        producciones=producciones, conteos=conteos, productos=productos_agrupados,
        operarios=operarios, plantillas=plantillas, pagina=pagina,
        tiene_mas=len(producciones)==POR_PAGINA, estado_sel=estado,
        fecha_ini=fecha_ini, fecha_fin=fecha_fin, form=form)

# ─── Nueva ───────────────────────────────────────────────────────────────────

@produccion_diaria.route('/produccion-diaria/nueva', methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def nueva_pd():
    form = NuevaProduccionDiariaForm()
    operarios = db.session.execute(text(
        "SELECT u.id_usuario FROM usuarios u JOIN roles r ON r.id_rol=u.id_rol "
        "WHERE r.clave_rol='panadero' AND u.estatus='activo'"
    )).fetchall()
    form.operario_id.choices = [(0,'—')] + [(o[0],'') for o in operarios]

    if not form.validate_on_submit():
        for field, errs in form.errors.items():
            for e in errs:
                flash(f'{field}: {e}', 'error')
        return redirect(url_for('produccion_diaria.index_pd'))

    try:
        lineas = json.loads(form.cajas_json.data or '[]')
    except (json.JSONDecodeError, TypeError):
        flash('Error al leer la lista de productos.', 'error')
        return redirect(url_for('produccion_diaria.index_pd'))

    if not lineas:
        flash('Agrega al menos un producto.', 'error')
        return redirect(url_for('produccion_diaria.index_pd'))

    try:
        out = _call_sp(
            "CALL sp_pd_crear_cabecera(:nm,:obs,:op,:usr,@id,@folio,@ok,@msg)",
            "SELECT @id AS id_pd,@folio AS folio,@ok AS ok,@msg AS mensaje",
            {'nm': form.nombre.data.strip(),
             'obs': (form.observaciones.data or '').strip() or None,
             'op': form.operario_id.data or 0,
             'usr': current_user.id_usuario})

        if not out['ok']:
            flash(out['mensaje'], 'error')
            return redirect(url_for('produccion_diaria.index_pd'))

        id_pd = out['id_pd']
        folio = out['folio']
        conn  = db.session.connection()

        for linea in lineas:
            pzs = int(linea.get('cantidad_piezas', 0))
            if pzs <= 0:
                continue
            conn.execute(text("""
                INSERT INTO produccion_diaria_detalle
                  (id_pd,id_producto,id_receta,cantidad_piezas)
                VALUES (:pd,:prod,:rec,:pzs)
            """), {'pd': id_pd, 'prod': int(linea['id_producto']),
                   'rec': int(linea['id_receta']), 'pzs': pzs})

        db.session.commit()

        out2 = _call_sp("CALL sp_pd_calcular_insumos(:pd,@ok2,@msg2)",
                        "SELECT @ok2 AS ok,@msg2 AS mensaje", {'pd': id_pd})

        guardar  = (form.guardar_plantilla.data or '0') == '1'
        nombre_pl = (form.nombre_plantilla.data or '').strip()
        if guardar and nombre_pl:
            _call_sp("CALL sp_pd_guardar_plantilla(:pd,:nm,:desc,:usr,@pid,@ok3,@msg3)",
                     "SELECT @pid AS id_plant,@ok3 AS ok,@msg3 AS mensaje",
                     {'pd': id_pd, 'nm': nombre_pl, 'desc': None,
                      'usr': current_user.id_usuario})

        flash(out2.get('mensaje', f'Producción {folio} creada.'),
              'success' if out2.get('ok') else 'warning')
        return redirect(url_for('produccion_diaria.detalle_pd', id_pd=id_pd))

    except Exception as exc:
        db.session.rollback()
        current_app.logger.error(_log(f'Error nueva pd: {exc}'))
        flash(f'Error al crear la producción: {exc}', 'error')
        return redirect(url_for('produccion_diaria.index_pd'))

# ─── Detalle ─────────────────────────────────────────────────────────────────

@produccion_diaria.route('/produccion-diaria/<int:id_pd>')
@login_required
@roles_required('admin', 'empleado', 'panadero')
def detalle_pd(id_pd):
    pd_row = db.session.execute(
        text("SELECT * FROM vw_produccion_diaria WHERE id_pd=:id"), {'id': id_pd}
    ).mappings().one_or_none()
    if not pd_row:
        flash('Producción no encontrada.', 'error')
        return redirect(url_for('produccion_diaria.index_pd'))
    pd = dict(pd_row)

    lineas = [dict(r) for r in db.session.execute(text("""
        SELECT pdd.id_pdd, p.nombre AS nombre_producto, r.nombre AS nombre_receta,
               pdd.cantidad_piezas
        FROM  produccion_diaria_detalle pdd
        JOIN  productos p ON p.id_producto=pdd.id_producto
        JOIN  recetas   r ON r.id_receta=pdd.id_receta
        WHERE pdd.id_pd=:id ORDER BY pdd.id_pdd
    """), {'id': id_pd}).mappings().all()]

    insumos = [dict(r) for r in db.session.execute(text("""
        SELECT pdi.id_materia, mp.nombre AS nombre_materia, mp.unidad_base,
               pdi.cantidad_requerida, pdi.cantidad_descontada, mp.stock_actual,
               IF(mp.stock_actual>=pdi.cantidad_requerida,1,0) AS stock_suficiente
        FROM  produccion_diaria_insumos pdi
        JOIN  materias_primas mp ON mp.id_materia=pdi.id_materia
        WHERE pdi.id_pd=:id ORDER BY mp.nombre
    """), {'id': id_pd}).mappings().all()]

    return render_template('produccion_diaria/detalle.html',
        pd=pd, lineas=lineas, insumos=insumos,
        form_fin=FinalizarProduccionDiariaForm(),
        form_can=CancelarProduccionDiariaForm(),
        form_plant=GuardarPlantillaForm())

# ─── Iniciar ─────────────────────────────────────────────────────────────────

@produccion_diaria.route('/produccion-diaria/<int:id_pd>/iniciar', methods=['POST'])
@login_required
@roles_required('admin', 'panadero')
def iniciar_pd(id_pd):
    try:
        out = _call_sp("CALL sp_pd_iniciar(:pd,:usr,@ok,@msg)",
                       "SELECT @ok AS ok,@msg AS mensaje",
                       {'pd': id_pd, 'usr': current_user.id_usuario})
        flash(out['mensaje'], 'success' if out['ok'] else 'error')
    except Exception as exc:
        db.session.rollback()
        flash(f'Error al iniciar: {exc}', 'error')
    return redirect(url_for('produccion_diaria.detalle_pd', id_pd=id_pd))

# ─── Finalizar ───────────────────────────────────────────────────────────────

@produccion_diaria.route('/produccion-diaria/<int:id_pd>/finalizar', methods=['POST'])
@login_required
@roles_required('admin', 'panadero')
def finalizar_pd(id_pd):
    form = FinalizarProduccionDiariaForm()
    if not form.validate_on_submit():
        flash('Solicitud inválida.', 'error')
        return redirect(url_for('produccion_diaria.detalle_pd', id_pd=id_pd))
    try:
        out = _call_sp("CALL sp_pd_finalizar(:pd,:usr,@ok,@msg)",
                       "SELECT @ok AS ok,@msg AS mensaje",
                       {'pd': id_pd, 'usr': current_user.id_usuario})
        flash(out['mensaje'], 'success' if out['ok'] else 'error')
    except Exception as exc:
        db.session.rollback()
        flash(f'Error al finalizar: {exc}', 'error')
    return redirect(url_for('produccion_diaria.detalle_pd', id_pd=id_pd))

# ─── Cancelar ────────────────────────────────────────────────────────────────

@produccion_diaria.route('/produccion-diaria/<int:id_pd>/cancelar', methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def cancelar_pd(id_pd):
    form = CancelarProduccionDiariaForm()
    motivo = (form.motivo.data or '').strip() or 'Sin motivo'
    try:
        out = _call_sp("CALL sp_pd_cancelar(:pd,:usr,:mot,@ok,@msg)",
                       "SELECT @ok AS ok,@msg AS mensaje",
                       {'pd': id_pd, 'usr': current_user.id_usuario, 'mot': motivo})
        flash(out['mensaje'], 'success' if out['ok'] else 'error')
    except Exception as exc:
        db.session.rollback()
        flash(f'Error al cancelar: {exc}', 'error')
    return redirect(url_for('produccion_diaria.detalle_pd', id_pd=id_pd))

# ─── Guardar plantilla ───────────────────────────────────────────────────────

@produccion_diaria.route('/produccion-diaria/<int:id_pd>/plantilla', methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def guardar_plantilla_pd(id_pd):
    form = GuardarPlantillaForm()
    if not form.validate_on_submit():
        flash('El nombre de la plantilla es obligatorio.', 'error')
        return redirect(url_for('produccion_diaria.detalle_pd', id_pd=id_pd))
    try:
        out = _call_sp("CALL sp_pd_guardar_plantilla(:pd,:nm,:desc,:usr,@pid,@ok,@msg)",
                       "SELECT @pid AS id_plant,@ok AS ok,@msg AS mensaje",
                       {'pd': id_pd, 'nm': form.nombre.data.strip(),
                        'desc': (form.descripcion.data or '').strip() or None,
                        'usr': current_user.id_usuario})
        flash(out['mensaje'], 'success' if out['ok'] else 'error')
    except Exception as exc:
        db.session.rollback()
        flash(f'Error al guardar plantilla: {exc}', 'error')
    return redirect(url_for('produccion_diaria.detalle_pd', id_pd=id_pd))

# ─── API: Verificar insumos ───────────────────────────────────────────────────

@produccion_diaria.route('/produccion-diaria/api/verificar-insumos', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def api_verificar_insumos():
    try:
        validate_csrf(request.headers.get('X-CSRFToken', ''))
    except ValidationError:
        return jsonify({'ok': False, 'mensaje': 'Token CSRF inválido.'}), 400

    try:
        payload   = request.get_json(force=True, silent=True) or {}
        items     = payload.get('items', [])
        if not items:
            return jsonify({'ok': False, 'mensaje': 'Sin items.'}), 400

        id_recetas     = [int(i['id_receta']) for i in items if i.get('id_receta')]
        receta_piezas  = {int(i['id_receta']): float(i['piezas']) for i in items}

        rows = db.session.execute(text("""
            SELECT dr.id_receta, dr.id_materia, mp.nombre AS nombre_materia,
                   mp.unidad_base, dr.cantidad_requerida, r.rendimiento, mp.stock_actual
            FROM detalle_recetas dr
            JOIN recetas r          ON r.id_receta=dr.id_receta
            JOIN materias_primas mp ON mp.id_materia=dr.id_materia
            WHERE dr.id_receta IN :ids AND mp.estatus='activo'
        """), {'ids': tuple(id_recetas)}).mappings().all()
        db.session.commit()

        insumos: dict = {}
        for row in rows:
            id_mat = row['id_materia']
            piezas = receta_piezas.get(row['id_receta'], 0)
            req    = float(row['cantidad_requerida'] or 0) / float(row['rendimiento'] or 1) * piezas
            if id_mat not in insumos:
                insumos[id_mat] = {'id_materia': id_mat, 'nombre_materia': row['nombre_materia'],
                                   'unidad_base': row['unidad_base'], 'cantidad_requerida': 0.0,
                                   'stock_actual': float(row['stock_actual'] or 0)}
            insumos[id_mat]['cantidad_requerida'] += req

        lista = []
        hay_faltantes = False
        for ins in insumos.values():
            ok  = ins['stock_actual'] >= ins['cantidad_requerida']
            pct = round(min(ins['stock_actual'] / ins['cantidad_requerida'] * 100
                            if ins['cantidad_requerida'] > 0 else 100, 100))
            ins['stock_suficiente'] = ok
            ins['pct_disponible']   = pct
            if not ok: hay_faltantes = True
            lista.append(ins)

        lista.sort(key=lambda x: (x['stock_suficiente'], x['nombre_materia']))
        insumos_ok = sum(1 for i in lista if i['stock_suficiente'])
        return jsonify({'ok': True, 'hay_faltantes': hay_faltantes,
                        'total_insumos': len(lista), 'insumos_ok': insumos_ok,
                        'insumos': lista})
    except Exception as exc:
        return jsonify({'ok': False, 'mensaje': str(exc)}), 500

# ─── API: Cargar plantilla ────────────────────────────────────────────────────

@produccion_diaria.route('/produccion-diaria/api/plantilla/<int:id_plantilla>')
@login_required
@roles_required('admin', 'empleado', 'panadero')
def api_cargar_plantilla(id_plantilla):
    try:
        rows = db.session.execute(text("""
            SELECT ppd.id_ppd, ppd.id_producto, ppd.id_receta, ppd.cantidad_piezas,
                   p.nombre AS nombre_producto, r.nombre AS nombre_receta
            FROM  plantillas_produccion_detalle ppd
            JOIN  productos p ON p.id_producto=ppd.id_producto
            JOIN  recetas   r ON r.id_receta=ppd.id_receta
            WHERE ppd.id_plantilla=:id ORDER BY ppd.id_ppd
        """), {'id': id_plantilla}).mappings().all()
        return jsonify({'ok': True, 'lineas': [dict(r) for r in rows]})
    except Exception as exc:
        return jsonify({'ok': False, 'mensaje': str(exc)}), 500