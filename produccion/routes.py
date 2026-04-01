# produccion/routes.py  — v2 (recipe-based, flujo 3 pasos)
from functools import wraps
from flask import render_template, request, redirect, url_for, flash, session, jsonify
from flask_login import login_required, current_user
from sqlalchemy import text
from models import db
from . import produccion

POR_PAGINA = 15

# ──────────────────────────────────────────────────────────────
# Helper OUT-params
# ──────────────────────────────────────────────────────────────
def _call_sp(call_sql, select_sql, params):
    conn = db.session.connection()
    conn.execute(text(call_sql), params)
    row = conn.execute(text(select_sql)).mappings().one()
    db.session.commit()
    return dict(row)


# ══════════════════════════════════════════════════════════════
# LISTA PRINCIPAL
# GET /produccion
# ══════════════════════════════════════════════════════════════
@produccion.route('/produccion')
@login_required
def index_produccion():
    estado    = request.args.get('estado', '')
    fecha_ini = request.args.get('fecha_ini', '')
    fecha_fin = request.args.get('fecha_fin', '')
    pagina    = request.args.get('pagina', 1, type=int)
    if pagina < 1: pagina = 1
    offset = (pagina - 1) * POR_PAGINA

    rows = db.session.execute(
        text("CALL sp_lista_ordenes_produccion(:est, :fi, :ff, :lim, :off)"),
        {
            'est': estado or None,
            'fi':  fecha_ini or None,
            'ff':  fecha_fin or None,
            'lim': POR_PAGINA,
            'off': offset,
        }
    ).mappings().all()
    db.session.execute(text("SELECT 1"))
    lotes = [dict(r) for r in rows]

    # Conteos por estado
    conteos = {}
    for e in ('pendiente', 'en_proceso', 'finalizado', 'cancelado'):
        conteos[e] = db.session.execute(
            text("SELECT COUNT(*) FROM produccion WHERE estado = :e"), {'e': e}
        ).scalar() or 0

    # Recetas activas con producto asociado + demanda de pedidos
    recetas = db.session.execute(text("""
        SELECT r.id_receta, r.nombre AS nombre_receta, r.rendimiento,
               r.unidad_rendimiento,
               p.id_producto, p.nombre AS nombre_producto,
               t.nombre AS tamano, t.capacidad,
               (SELECT COUNT(*)
                  FROM detalle_pedidos dp
                  JOIN pedidos ped ON ped.id_pedido = dp.id_pedido
                 WHERE dp.id_producto = p.id_producto
                   AND ped.estado IN ('pendiente','aprobado','en_produccion')
               ) AS pedidos_pendientes
        FROM recetas r
        JOIN productos p ON p.id_producto = r.id_producto
        LEFT JOIN tamanios_charola t ON t.id_tamanio = r.id_tamanio
        WHERE r.estatus = 'activo'
          AND r.id_producto IS NOT NULL
        ORDER BY pedidos_pendientes DESC, p.nombre, r.nombre
    """)).mappings().all()
    recetas = [dict(r) for r in recetas]

    # Operarios (panadero + admin)
    operarios = db.session.execute(text("""
        SELECT u.id_usuario, u.nombre_completo, r.nombre_rol
        FROM usuarios u JOIN roles r ON r.id_rol = u.id_rol
        WHERE u.estatus = 'activo'
          AND r.clave_rol IN ('panadero','admin')
        ORDER BY r.clave_rol DESC, u.nombre_completo
    """)).mappings().all()
    operarios = [dict(o) for o in operarios]

    db.session.commit()

    return render_template(
        'produccion/produccion.html',
        lotes=lotes,
        conteos=conteos,
        recetas=recetas,
        operarios=operarios,
        estado_sel=estado,
        fecha_ini=fecha_ini,
        fecha_fin=fecha_fin,
        pagina=pagina,
        por_pagina=POR_PAGINA,
        tiene_mas=(len(lotes) == POR_PAGINA),
    )


# ══════════════════════════════════════════════════════════════
# CREAR ORDEN  POST /produccion/nueva
# ══════════════════════════════════════════════════════════════
@produccion.route('/produccion/nueva', methods=['POST'])
@login_required
def produccion_nueva():
    id_receta      = request.form.get('id_receta', type=int)
    cantidad_lotes = request.form.get('cantidad_lotes', type=float)
    operario_id    = request.form.get('operario_id', type=int) or None
    observaciones  = (request.form.get('observaciones', '') or '').strip() or None
    creado_por     = current_user.id_usuario

    if not id_receta or not cantidad_lotes:
        flash('Selecciona una receta y una cantidad válida.', 'danger')
        return redirect(url_for('produccion.index_produccion'))

    try:
        out = _call_sp(
            """CALL sp_crear_orden_produccion(
                :receta, :cant, :operario, :obs, :creado,
                @id_prod, @folio, @ok, @msg)""",
            "SELECT @id_prod AS id_produccion, @folio AS folio, @ok AS ok, @msg AS mensaje",
            {'receta': id_receta, 'cant': cantidad_lotes,
             'operario': operario_id, 'obs': observaciones, 'creado': creado_por}
        )
        if out['ok']:
            flash(f"✅ {out['mensaje']}", 'success')
            return redirect(url_for('produccion.detalle_orden', id_produccion=out['id_produccion']))
        flash(f"⚠️ {out['mensaje']}", 'danger')
    except Exception as exc:
        db.session.rollback()
        flash(f'Error inesperado: {exc}', 'danger')
    return redirect(url_for('produccion.index_produccion'))


# ══════════════════════════════════════════════════════════════
# DETALLE  GET /produccion/<id>
# ══════════════════════════════════════════════════════════════
@produccion.route('/produccion/<int:id_produccion>')
@login_required
def detalle_orden(id_produccion):
    try:
        conn = db.session.connection()
        conn.execute(
            text("CALL sp_detalle_orden_produccion(:id, @ok, @msg)"),
            {'id': id_produccion}
        )
        out = conn.execute(
            text("SELECT @ok AS ok, @msg AS mensaje")
        ).mappings().one()

        if not out['ok']:
            flash(f"⚠️ {out['mensaje']}", 'danger')
            return redirect(url_for('produccion.index_produccion'))

        cabecera = conn.execute(text("""
            SELECT p.id_produccion, p.folio_lote,
                   r.id_receta, r.nombre AS nombre_receta,
                   r.rendimiento, r.unidad_rendimiento,
                   pr.id_producto, pr.nombre AS nombre_producto,
                   p.cantidad_lotes, p.piezas_esperadas, p.piezas_producidas,
                   p.estado, p.fecha_inicio, p.fecha_fin_estimado,
                   p.fecha_fin_real, p.creado_en, p.observaciones,
                   u_op.nombre_completo AS operario,
                   u_cr.nombre_completo AS creado_por_nombre,
                   (SELECT COUNT(*)
                      FROM detalle_pedidos dp
                      JOIN pedidos ped ON ped.id_pedido = dp.id_pedido
                     WHERE dp.id_producto = p.id_producto
                       AND ped.estado IN ('pendiente','aprobado','en_produccion')
                   ) AS pedidos_pendientes
            FROM produccion p
            JOIN recetas   r  ON r.id_receta    = p.id_receta
            JOIN productos pr ON pr.id_producto = p.id_producto
            LEFT JOIN usuarios u_op ON u_op.id_usuario = p.operario_id
            LEFT JOIN usuarios u_cr ON u_cr.id_usuario = p.creado_por
            WHERE p.id_produccion = :id
        """), {'id': id_produccion}).mappings().one_or_none()

        # Insumos reales (post-finalización)
        insumos_reales = conn.execute(text("""
            SELECT dp.id_materia, mp.nombre AS nombre_materia,
                   mp.unidad_base, mp.categoria,
                   dp.cantidad_requerida, dp.cantidad_descontada,
                   mp.stock_actual AS stock_post
            FROM detalle_produccion dp
            JOIN materias_primas mp ON mp.id_materia = dp.id_materia
            WHERE dp.id_produccion = :id ORDER BY mp.nombre
        """), {'id': id_produccion}).mappings().all()

        # Insumos teóricos (pre-finalización)
        insumos_teoricos = conn.execute(text("""
            SELECT dr.id_materia, mp.nombre AS nombre_materia,
                   mp.unidad_base, mp.categoria,
                   ROUND(p.cantidad_lotes * dr.cantidad_requerida, 4) AS cantidad_requerida,
                   mp.stock_actual,
                   CASE WHEN mp.stock_actual >= ROUND(p.cantidad_lotes * dr.cantidad_requerida, 4)
                        THEN 1 ELSE 0 END AS stock_suficiente
            FROM produccion p
            JOIN detalle_recetas dr ON dr.id_receta = p.id_receta
            JOIN materias_primas mp ON mp.id_materia = dr.id_materia
            WHERE p.id_produccion = :id ORDER BY mp.nombre
        """), {'id': id_produccion}).mappings().all()

        db.session.commit()

        if not cabecera:
            flash('Orden no encontrada.', 'danger')
            return redirect(url_for('produccion.index_produccion'))

        return render_template(
            'produccion/detalle_orden.html',
            orden=dict(cabecera),
            insumos_reales=[dict(r) for r in insumos_reales],
            insumos_teoricos=[dict(r) for r in insumos_teoricos],
        )
    except Exception as exc:
        db.session.rollback()
        flash(f'Error: {exc}', 'danger')
        return redirect(url_for('produccion.index_produccion'))


# ══════════════════════════════════════════════════════════════
# INICIAR  POST /produccion/<id>/iniciar  (pendiente→en_proceso)
# ══════════════════════════════════════════════════════════════
@produccion.route('/produccion/<int:id_produccion>/iniciar', methods=['POST'])
@login_required
def iniciar_orden(id_produccion):
    try:
        out = _call_sp(
            "CALL sp_iniciar_orden_produccion(:id, :usr, @ok, @msg)",
            "SELECT @ok AS ok, @msg AS mensaje",
            {'id': id_produccion, 'usr': current_user.id_usuario}
        )
        flash(f"{'✅' if out['ok'] else '⚠️'} {out['mensaje']}",
              'success' if out['ok'] else 'danger')
    except Exception as exc:
        db.session.rollback()
        flash(f'Error al iniciar: {exc}', 'danger')
    return redirect(url_for('produccion.detalle_orden', id_produccion=id_produccion))


# ══════════════════════════════════════════════════════════════
# FINALIZAR  POST /produccion/<id>/finalizar (en_proceso→finalizado)
# ══════════════════════════════════════════════════════════════
@produccion.route('/produccion/<int:id_produccion>/finalizar', methods=['POST'])
@login_required
def finalizar_orden(id_produccion):
    piezas_reales = request.form.get('piezas_reales', type=float) or None
    try:
        out = _call_sp(
            "CALL sp_finalizar_orden_produccion(:id, :usr, :pzs, @ok, @msg)",
            "SELECT @ok AS ok, @msg AS mensaje",
            {'id': id_produccion, 'usr': current_user.id_usuario, 'pzs': piezas_reales}
        )
        flash(f"{'✅' if out['ok'] else '⚠️'} {out['mensaje']}",
              'success' if out['ok'] else 'danger')
    except Exception as exc:
        db.session.rollback()
        flash(f'Error al finalizar: {exc}', 'danger')
    return redirect(url_for('produccion.detalle_orden', id_produccion=id_produccion))


# ══════════════════════════════════════════════════════════════
# CANCELAR  POST /produccion/<id>/cancelar
# ══════════════════════════════════════════════════════════════
@produccion.route('/produccion/<int:id_produccion>/cancelar', methods=['POST'])
@login_required
def cancelar_orden(id_produccion):
    motivo = (request.form.get('motivo', '') or '').strip() or 'Sin motivo'
    try:
        out = _call_sp(
            "CALL sp_cancelar_orden_produccion(:id, :usr, :mot, @ok, @msg)",
            "SELECT @ok AS ok, @msg AS mensaje",
            {'id': id_produccion, 'usr': current_user.id_usuario, 'mot': motivo}
        )
        flash(f"{'✅' if out['ok'] else '⚠️'} {out['mensaje']}",
              'success' if out['ok'] else 'danger')
    except Exception as exc:
        db.session.rollback()
        flash(f'Error al cancelar: {exc}', 'danger')
    return redirect(url_for('produccion.detalle_orden', id_produccion=id_produccion))


# ══════════════════════════════════════════════════════════════
# API — Verificar insumos antes de crear o finalizar
# GET /produccion/api/verificar?id_receta=X&cantidad=Y
# ══════════════════════════════════════════════════════════════
@produccion.route('/produccion/api/verificar')
@login_required
def api_verificar():
    id_receta = request.args.get('id_receta', type=int)
    cantidad  = request.args.get('cantidad',  type=float)

    if not id_receta or not cantidad or cantidad <= 0:
        return jsonify({'ok': False, 'mensaje': 'Parámetros inválidos.'}), 400

    try:
        rows = db.session.execute(text("""
            SELECT
                mp.id_materia,
                mp.nombre                                     AS nombre_materia,
                mp.unidad_base, mp.categoria,
                ROUND(:cant * dr.cantidad_requerida, 4)       AS cantidad_requerida,
                mp.stock_actual, mp.stock_minimo,
                CASE WHEN mp.stock_actual >= ROUND(:cant * dr.cantidad_requerida, 4)
                     THEN 1 ELSE 0 END                        AS stock_suficiente,
                LEAST(100, ROUND(
                    mp.stock_actual /
                    NULLIF(ROUND(:cant * dr.cantidad_requerida, 4), 0) * 100
                , 1))                                         AS pct_disponible
            FROM detalle_recetas dr
            JOIN materias_primas mp ON mp.id_materia = dr.id_materia
            WHERE dr.id_receta = :receta
            ORDER BY mp.nombre
        """), {'receta': id_receta, 'cant': cantidad}).mappings().all()

        db.session.commit()

        if not rows:
            return jsonify({'ok': False, 'mensaje': 'La receta no tiene insumos configurados.'}), 400

        insumos = []
        for r in rows:
            item = dict(r)
            for k in ('cantidad_requerida', 'stock_actual', 'stock_minimo', 'pct_disponible'):
                if item.get(k) is not None:
                    item[k] = float(item[k])
            item['stock_suficiente'] = bool(item['stock_suficiente'])
            item['pct_disponible']   = min(item['pct_disponible'] or 0, 100)
            insumos.append(item)

        hay_faltantes = any(not i['stock_suficiente'] for i in insumos)
        return jsonify({
            'ok': True,
            'puede_producir': not hay_faltantes,
            'hay_faltantes': hay_faltantes,
            'total_insumos': len(insumos),
            'insumos_ok': sum(1 for i in insumos if i['stock_suficiente']),
            'insumos': insumos,
        })
    except Exception as exc:
        db.session.rollback()
        return jsonify({'ok': False, 'mensaje': str(exc)}), 500


# ══════════════════════════════════════════════════════════════
# Ruta legacy — solicitudes (mantener compatibilidad sidebar)
# ══════════════════════════════════════════════════════════════
@produccion.route('/produccion-solicitud')
@login_required
def index_produccion_solicitud():
    return render_template('produccion/solicitudes.html')