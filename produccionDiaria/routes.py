import json
import datetime
from flask import (
    render_template, request, redirect, url_for,
    flash, jsonify, current_app
)
from flask_login import login_required, current_user
from sqlalchemy import text

from auth import roles_required
from flask_wtf.csrf import validate_csrf
from wtforms import ValidationError
from models import db
from . import produccion_diaria
from forms import (
    NuevaProduccionDiariaForm,
    FinalizarProduccionDiariaForm,
    CancelarProduccionDiariaForm,
    GuardarPlantillaForm,
)

POR_PAGINA = 10

def _call_sp(call_sql, select_sql, params):
    conn = db.session.connection()
    conn.execute(text(call_sql), params)
    row = conn.execute(text(select_sql)).mappings().one()
    db.session.commit()
    return dict(row)


def _log(msg):
    ts = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    return f'{msg} | usuario: {current_user.username} | fecha: {ts}'


@produccion_diaria.route('/produccion-diaria')
@login_required
@roles_required('admin', 'empleado', 'panadero')
def index_pd():
    current_app.logger.info(_log('Vista lista produccion_diaria'))

    estado    = request.args.get('estado', '')
    fecha_ini = request.args.get('fecha_ini', '')
    fecha_fin = request.args.get('fecha_fin', '')
    pagina    = max(request.args.get('pagina', 1, type=int), 1)
    offset    = (pagina - 1) * POR_PAGINA

    rows = db.session.execute(
        text("CALL sp_pd_lista(:est, :fi, :ff, :lim, :off)"),
        {
            'est': estado or None,
            'fi':  fecha_ini or None,
            'ff':  fecha_fin or None,
            'lim': POR_PAGINA,
            'off': offset,
        }
    ).mappings().all()
    db.session.execute(text("SELECT 1"))  
    producciones = [dict(r) for r in rows]

    conteos = {}
    for e in ('pendiente', 'en_proceso', 'finalizado', 'cancelado'):
        conteos[e] = db.session.execute(
            text("SELECT COUNT(*) FROM produccion_diaria WHERE estado = :e"),
            {'e': e}
        ).scalar() or 0

    tamanios = db.session.execute(
        text("SELECT id_tamanio, nombre, capacidad FROM tamanios_charola "
             "WHERE estatus='activo' ORDER BY capacidad")
    ).mappings().all()

    productos = db.session.execute(
        text("""
            SELECT p.id_producto, p.nombre AS nombre_producto,
                   r.id_receta, r.id_tamanio, r.rendimiento,
                   t.nombre AS tamanio_nombre, t.capacidad
            FROM productos p
            JOIN recetas r ON r.id_producto = p.id_producto
            JOIN tamanios_charola t ON t.id_tamanio = r.id_tamanio
            WHERE r.estatus = 'activo'
              AND r.id_tamanio IS NOT NULL
            ORDER BY p.nombre, t.capacidad
        """)
    ).mappings().all()

    operarios = db.session.execute(
        text("""
            SELECT u.id_usuario, u.nombre_completo, r.nombre_rol
            FROM usuarios u
            JOIN roles r ON r.id_rol = u.id_rol
            WHERE u.estatus = 'activo'
              AND r.clave_rol IN ('panadero', 'admin')
            ORDER BY r.clave_rol DESC, u.nombre_completo
        """)
    ).mappings().all()

    plantillas = db.session.execute(
        text("""
            SELECT pp.id_plantilla, pp.nombre, pp.descripcion,
                   COUNT(ppd.id_ppd) AS total_lineas
            FROM plantillas_produccion pp
            LEFT JOIN plantillas_produccion_detalle ppd
                   ON ppd.id_plantilla = pp.id_plantilla
            WHERE pp.creado_por = :uid OR :uid IN (
                SELECT id_usuario FROM usuarios u
                JOIN roles r ON r.id_rol=u.id_rol WHERE r.clave_rol='admin'
                  AND u.id_usuario=:uid
            )
            GROUP BY pp.id_plantilla
            ORDER BY pp.creado_en DESC
            LIMIT 20
        """),
        {'uid': current_user.id_usuario}
    ).mappings().all()

    db.session.commit()

    form_nueva    = NuevaProduccionDiariaForm()
    form_nueva.operario_id.choices = [(0, '— Sin asignar —')] + [
        (o['id_usuario'], o['nombre_completo']) for o in operarios
    ]

    total_count = db.session.execute(
        text("""
            SELECT COUNT(*) FROM produccion_diaria
            WHERE (:est IS NULL OR estado = :est)
            AND (:fi  IS NULL OR DATE(creado_en) >= :fi)
            AND (:ff  IS NULL OR DATE(creado_en) <= :ff)
        """),
        {
            'est': estado or None,
            'fi':  fecha_ini or None,
            'ff':  fecha_fin or None,
        }
    ).scalar() or 0

    return render_template(
        'produccion_diaria/index.html',
        producciones=[dict(p) for p in producciones],
        conteos=conteos,
        tamanios=[dict(t) for t in tamanios],
        productos=[dict(p) for p in productos],
        operarios=[dict(o) for o in operarios],
        plantillas=[dict(p) for p in plantillas],
        estado_sel=estado,
        fecha_ini=fecha_ini,
        fecha_fin=fecha_fin,
        pagina=pagina,
        tiene_mas=(len(producciones) == POR_PAGINA),
        form_nueva=form_nueva,
        total_count=total_count,
    )


@produccion_diaria.route('/produccion-diaria/nueva', methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def nueva_pd():
    form = NuevaProduccionDiariaForm()
    operarios = db.session.execute(
        text("SELECT u.id_usuario FROM usuarios u JOIN roles r ON r.id_rol=u.id_rol "
             "WHERE u.estatus='activo' AND r.clave_rol IN ('panadero','admin')")
    ).scalars().all()
    form.operario_id.choices = [(0, '')] + [(o, '') for o in operarios]
    db.session.commit()

    if not form.validate_on_submit():
        for field, errs in form.errors.items():
            for e in errs:
                flash(f'{e}', 'error')
        return redirect(url_for('produccion_diaria.index_pd'))

    nombre      = form.nombre.data.strip()
    operario_id = form.operario_id.data or None
    observaciones = (form.observaciones.data or '').strip() or None
    cajas_raw   = form.cajas_json.data
    guardar_plantilla = form.guardar_plantilla.data == '1'
    nombre_plantilla  = (form.nombre_plantilla.data or '').strip() or None

    try:
        cajas = json.loads(cajas_raw)
        if not cajas:
            raise ValueError('Lista vacía')
    except Exception:
        flash('Lista de cajas inválida. Agrega al menos una línea.', 'error')
        return redirect(url_for('produccion_diaria.index_pd'))

    try:
        out = _call_sp(
            """CALL sp_pd_crear_cabecera(
                :nombre, :obs, :operario, :creado,
                @id_pd, @folio, @ok, @msg)""",
            "SELECT @id_pd AS id_pd, @folio AS folio, @ok AS ok, @msg AS mensaje",
            {'nombre': nombre, 'obs': observaciones,
             'operario': operario_id, 'creado': current_user.id_usuario}
        )
        if not out['ok']:
            flash(out['mensaje'], 'error')
            return redirect(url_for('produccion_diaria.index_pd'))

        id_pd = out['id_pd']

        conn = db.session.connection()
        for linea in cajas:
            id_tamanio    = int(linea['id_tamanio'])
            tipo          = linea['tipo']
            cant_cajas    = int(linea['cantidad_cajas'])
            piezas_esp    = int(linea['piezas_esperadas'])

            conn.execute(text("""
                INSERT INTO produccion_diaria_detalle
                  (id_pd, id_tamanio, tipo, cantidad_cajas, piezas_esperadas)
                VALUES (:pd, :tam, :tipo, :cant, :piezas)
            """), {'pd': id_pd, 'tam': id_tamanio, 'tipo': tipo,
                   'cant': cant_cajas, 'piezas': piezas_esp})

            id_pdd = conn.execute(text("SELECT LAST_INSERT_ID()")).scalar()

            for prod in linea.get('productos', []):
                conn.execute(text("""
                    INSERT INTO produccion_diaria_linea_prod
                      (id_pdd, id_producto, id_receta, piezas_por_caja)
                    VALUES (:pdd, :prod, :rec, :piezas)
                """), {
                    'pdd': id_pdd,
                    'prod': int(prod['id_producto']),
                    'rec':  int(prod['id_receta']),
                    'piezas': int(prod['piezas']),
                })

        out2 = _call_sp(
            "CALL sp_pd_calcular_insumos(:pd, @ok, @msg)",
            "SELECT @ok AS ok, @msg AS mensaje",
            {'pd': id_pd}
        )

        msg = out2.get('mensaje', 'Producción creada.')
        flash(msg, 'success' if out2['ok'] else 'warning')

        if guardar_plantilla and nombre_plantilla:
            try:
                _call_sp(
                    """CALL sp_pd_guardar_plantilla(
                        :pd, :nom, :desc, :usr,
                        @id_plant, @ok, @msg)""",
                    "SELECT @id_plant AS id_plant, @ok AS ok, @msg AS mensaje",
                    {'pd': id_pd, 'nom': nombre_plantilla,
                     'desc': None, 'usr': current_user.id_usuario}
                )
            except Exception as exc:
                flash(f'Producción creada, pero error al guardar plantilla: {exc}', 'warning')

        current_app.logger.info(_log(
            f'Produccion diaria creada | id_pd: {id_pd} | folio: {out["folio"]}'
        ))
        return redirect(url_for('produccion_diaria.detalle_pd', id_pd=id_pd))

    except Exception as exc:
        db.session.rollback()
        current_app.logger.error(_log(f'Error al crear produccion_diaria | error: {exc}'))
        flash(f'Error inesperado: {exc}', 'error')
        return redirect(url_for('produccion_diaria.index_pd'))


@produccion_diaria.route('/produccion-diaria/<int:id_pd>')
@login_required
@roles_required('admin', 'empleado', 'panadero')
def detalle_pd(id_pd):
    current_app.logger.info(_log(f'Vista detalle pd | id_pd: {id_pd}'))
    try:
        conn = db.session.connection()

        cabecera = conn.execute(text("""
            SELECT pd.id_pd, pd.folio, pd.nombre, pd.estado,
                   pd.total_cajas, pd.total_piezas_esperadas,
                   pd.alerta_insumos, pd.insumos_descontados,
                   pd.inventario_acreditado, pd.observaciones,
                   pd.motivo_cancelacion, pd.fecha_inicio,
                   pd.fecha_fin_real, pd.creado_en,
                   u_op.nombre_completo AS operario,
                   u_cr.nombre_completo AS creado_por_nombre
            FROM produccion_diaria pd
            LEFT JOIN usuarios u_op ON u_op.id_usuario = pd.operario_id
            LEFT JOIN usuarios u_cr ON u_cr.id_usuario = pd.creado_por
            WHERE pd.id_pd = :id
        """), {'id': id_pd}).mappings().one_or_none()

        if not cabecera:
            flash('Producción no encontrada.', 'warning')
            return redirect(url_for('produccion_diaria.index_pd'))

        lineas = conn.execute(text("""
            SELECT pdd.id_pdd, pdd.id_tamanio, pdd.tipo,
                   pdd.cantidad_cajas, pdd.piezas_esperadas,
                   pdd.piezas_producidas,
                   t.nombre AS tamanio_nombre, t.capacidad
            FROM produccion_diaria_detalle pdd
            JOIN tamanios_charola t ON t.id_tamanio = pdd.id_tamanio
            WHERE pdd.id_pd = :id
            ORDER BY pdd.id_pdd
        """), {'id': id_pd}).mappings().all()

        prods_por_linea = conn.execute(text("""
            SELECT pdlp.id_pdd, pdlp.id_producto, pdlp.piezas_por_caja,
                   p.nombre AS nombre_producto,
                   r.nombre AS nombre_receta
            FROM produccion_diaria_linea_prod pdlp
            JOIN productos p ON p.id_producto = pdlp.id_producto
            JOIN recetas r   ON r.id_receta   = pdlp.id_receta
            JOIN produccion_diaria_detalle pdd ON pdd.id_pdd = pdlp.id_pdd
            WHERE pdd.id_pd = :id
            ORDER BY pdlp.id_pdd, p.nombre
        """), {'id': id_pd}).mappings().all()

        insumos = conn.execute(text("""
            SELECT mp.nombre AS nombre_materia, mp.unidad_base,
                   pdi.cantidad_requerida, pdi.cantidad_descontada,
                   mp.stock_actual,
                   CASE WHEN mp.stock_actual >= pdi.cantidad_requerida
                        THEN 1 ELSE 0 END AS stock_suficiente
            FROM produccion_diaria_insumos pdi
            JOIN materias_primas mp ON mp.id_materia = pdi.id_materia
            WHERE pdi.id_pd = :id
            ORDER BY mp.nombre
        """), {'id': id_pd}).mappings().all()

        db.session.commit()

        prods_map = {}
        for p in prods_por_linea:
            prods_map.setdefault(p['id_pdd'], []).append(dict(p))

        lineas_data = []
        for l in lineas:
            d = dict(l)
            d['productos'] = prods_map.get(l['id_pdd'], [])
            lineas_data.append(d)

        form_fin = FinalizarProduccionDiariaForm()
        form_can = CancelarProduccionDiariaForm()
        form_plant = GuardarPlantillaForm()

        return render_template(
            'produccion_diaria/detalle.html',
            pd=dict(cabecera),
            lineas=lineas_data,
            insumos=[dict(i) for i in insumos],
            form_fin=form_fin,
            form_can=form_can,
            form_plant=form_plant,
        )

    except Exception as exc:
        db.session.rollback()
        flash(f'Error al cargar detalle: {exc}', 'error')
        return redirect(url_for('produccion_diaria.index_pd'))


@produccion_diaria.route('/produccion-diaria/<int:id_pd>/iniciar', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def iniciar_pd(id_pd):
    try:
        out = _call_sp(
            "CALL sp_pd_iniciar(:pd, :usr, @ok, @msg)",
            "SELECT @ok AS ok, @msg AS mensaje",
            {'pd': id_pd, 'usr': current_user.id_usuario}
        )
        tipo = 'success' if out['ok'] else 'error'
        flash(out['mensaje'], tipo)
        current_app.logger.info(_log(
            f'Iniciar pd | id_pd: {id_pd} | ok: {out["ok"]}'
        ))
    except Exception as exc:
        db.session.rollback()
        current_app.logger.error(_log(f'Error iniciar pd {id_pd}: {exc}'))
        flash(f'Error al iniciar: {exc}', 'error')
    return redirect(url_for('produccion_diaria.detalle_pd', id_pd=id_pd))


@produccion_diaria.route('/produccion-diaria/<int:id_pd>/finalizar', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def finalizar_pd(id_pd):
    form = FinalizarProduccionDiariaForm()
    piezas = form.piezas_totales.data or None

    try:
        out = _call_sp(
            "CALL sp_pd_finalizar(:pd, :usr, :pzs, @ok, @msg)",
            "SELECT @ok AS ok, @msg AS mensaje",
            {'pd': id_pd, 'usr': current_user.id_usuario, 'pzs': piezas}
        )
        tipo = 'success' if out['ok'] else 'error'
        flash(out['mensaje'], tipo)
        current_app.logger.info(_log(
            f'Finalizar pd | id_pd: {id_pd} | ok: {out["ok"]}'
        ))
    except Exception as exc:
        db.session.rollback()
        current_app.logger.error(_log(f'Error finalizar pd {id_pd}: {exc}'))
        flash(f'Error al finalizar: {exc}', 'error')
    return redirect(url_for('produccion_diaria.detalle_pd', id_pd=id_pd))


@produccion_diaria.route('/produccion-diaria/<int:id_pd>/cancelar', methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def cancelar_pd(id_pd):
    form = CancelarProduccionDiariaForm()
    motivo = (form.motivo.data or '').strip() or 'Sin motivo'

    try:
        out = _call_sp(
            "CALL sp_pd_cancelar(:pd, :usr, :mot, @ok, @msg)",
            "SELECT @ok AS ok, @msg AS mensaje",
            {'pd': id_pd, 'usr': current_user.id_usuario, 'mot': motivo}
        )
        tipo = 'success' if out['ok'] else 'error'
        flash(out['mensaje'], tipo)
        current_app.logger.info(_log(
            f'Cancelar pd | id_pd: {id_pd} | motivo: {motivo}'
        ))
    except Exception as exc:
        db.session.rollback()
        current_app.logger.error(_log(f'Error cancelar pd {id_pd}: {exc}'))
        flash(f'Error al cancelar: {exc}', 'error')
    return redirect(url_for('produccion_diaria.detalle_pd', id_pd=id_pd))


@produccion_diaria.route('/produccion-diaria/<int:id_pd>/plantilla', methods=['POST'])
@login_required
@roles_required('admin', 'empleado')
def guardar_plantilla_pd(id_pd):
    form = GuardarPlantillaForm()
    if not form.validate_on_submit():
        flash('El nombre de la plantilla es obligatorio.', 'error')
        return redirect(url_for('produccion_diaria.detalle_pd', id_pd=id_pd))

    try:
        out = _call_sp(
            """CALL sp_pd_guardar_plantilla(
                :pd, :nom, :desc, :usr,
                @id_plant, @ok, @msg)""",
            "SELECT @id_plant AS id_plant, @ok AS ok, @msg AS mensaje",
            {'pd': id_pd,
             'nom': form.nombre.data.strip(),
             'desc': (form.descripcion.data or '').strip() or None,
             'usr': current_user.id_usuario}
        )
        tipo = 'success' if out['ok'] else 'error'
        flash(out['mensaje'], tipo)
    except Exception as exc:
        db.session.rollback()
        flash(f'Error al guardar plantilla: {exc}', 'error')
    return redirect(url_for('produccion_diaria.detalle_pd', id_pd=id_pd))


@produccion_diaria.route('/produccion-diaria/api/verificar-insumos', methods=['POST'])
@login_required
@roles_required('admin', 'empleado', 'panadero')
def api_verificar_insumos():
    try:
        validate_csrf(request.headers.get('X-CSRFToken', ''))
    except ValidationError:
        return jsonify({'ok': False, 'mensaje': 'Token CSRF inválido.'}), 400

    try:
        payload = request.get_json(force=True, silent=True) or {}
        items   = payload.get('items', [])
        if not items:
            return jsonify({'ok': False, 'mensaje': 'Sin items.'}), 400

        id_recetas = [int(i['id_receta']) for i in items if i.get('id_receta')]
        if not id_recetas:
            return jsonify({'ok': False, 'mensaje': 'Recetas inválidas.'}), 400

        receta_piezas = {int(i['id_receta']): float(i['piezas']) for i in items}

        rows = db.session.execute(text("""
            SELECT dr.id_receta, dr.id_materia,
                   mp.nombre AS nombre_materia, mp.unidad_base,
                   dr.cantidad_requerida, r.rendimiento,
                   mp.stock_actual
            FROM detalle_recetas dr
            JOIN recetas r         ON r.id_receta  = dr.id_receta
            JOIN materias_primas mp ON mp.id_materia = dr.id_materia
            WHERE dr.id_receta IN :ids
              AND mp.estatus = 'activo'
        """), {'ids': tuple(id_recetas)}).mappings().all()

        db.session.commit()

        insumos: dict = {}
        for row in rows:
            id_mat  = row['id_materia']
            piezas  = receta_piezas.get(row['id_receta'], 0)
            req     = float(row['cantidad_requerida'] or 0) \
                      / float(row['rendimiento'] or 1) * piezas

            if id_mat not in insumos:
                insumos[id_mat] = {
                    'id_materia':         id_mat,
                    'nombre_materia':     row['nombre_materia'],
                    'unidad_base':        row['unidad_base'],
                    'cantidad_requerida': 0.0,
                    'stock_actual':       float(row['stock_actual'] or 0),
                }
            insumos[id_mat]['cantidad_requerida'] += req

        result = []
        hay_faltantes = False
        for data in insumos.values():
            data['cantidad_requerida'] = round(data['cantidad_requerida'], 4)
            data['stock_suficiente']   = data['stock_actual'] >= data['cantidad_requerida']
            if not data['stock_suficiente']:
                hay_faltantes = True
            pct = (data['stock_actual'] / data['cantidad_requerida'] * 100) \
                  if data['cantidad_requerida'] > 0 else 100
            data['pct_disponible'] = min(round(pct, 1), 100)
            result.append(data)

        result.sort(key=lambda x: (x['stock_suficiente'], x['nombre_materia']))

        return jsonify({
            'ok':           True,
            'hay_faltantes': hay_faltantes,
            'total_insumos': len(result),
            'insumos_ok':    sum(1 for i in result if i['stock_suficiente']),
            'insumos':       result,
        })

    except Exception as exc:
        db.session.rollback()
        return jsonify({'ok': False, 'mensaje': str(exc)}), 500



@produccion_diaria.route('/produccion-diaria/api/plantilla/<int:id_plantilla>')
@login_required
@roles_required('admin', 'empleado')
def api_cargar_plantilla(id_plantilla):
    try:
        conn = db.session.connection()

        cab = conn.execute(text("""
            SELECT id_plantilla, nombre, descripcion
            FROM plantillas_produccion WHERE id_plantilla = :id
        """), {'id': id_plantilla}).mappings().one_or_none()

        if not cab:
            return jsonify({'ok': False, 'mensaje': 'Plantilla no encontrada.'}), 404

        lineas = conn.execute(text("""
            SELECT ppd.id_ppd, ppd.id_tamanio, ppd.tipo, ppd.cantidad_cajas,
                   t.nombre AS tamanio_nombre, t.capacidad
            FROM plantillas_produccion_detalle ppd
            JOIN tamanios_charola t ON t.id_tamanio = ppd.id_tamanio
            WHERE ppd.id_plantilla = :id
        """), {'id': id_plantilla}).mappings().all()

        prods = conn.execute(text("""
            SELECT pplp.id_ppd, pplp.id_producto, pplp.id_receta,
                   pplp.piezas_por_caja,
                   p.nombre AS nombre_producto
            FROM plantillas_produccion_linea_prod pplp
            JOIN productos p ON p.id_producto = pplp.id_producto
            JOIN plantillas_produccion_detalle ppd ON ppd.id_ppd = pplp.id_ppd
            WHERE ppd.id_plantilla = :id
        """), {'id': id_plantilla}).mappings().all()

        db.session.commit()

        prods_map = {}
        for p in prods:
            prods_map.setdefault(p['id_ppd'], []).append(dict(p))

        lineas_data = []
        for l in lineas:
            d = dict(l)
            d['piezas_esperadas'] = d['capacidad'] * d['cantidad_cajas']
            d['productos'] = prods_map.get(l['id_ppd'], [])
            lineas_data.append(d)

        return jsonify({
            'ok':     True,
            'nombre': cab['nombre'],
            'lineas': lineas_data,
        })

    except Exception as exc:
        db.session.rollback()
        return jsonify({'ok': False, 'mensaje': str(exc)}), 500