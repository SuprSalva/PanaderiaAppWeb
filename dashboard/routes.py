import datetime
import json
from decimal import Decimal

from flask import render_template, request, current_app
from flask_login import login_required, current_user

from auth import roles_required
from models import db
from . import dashboard_bp
from forms import PeriodoForm


# ── Helpers BD ─────────────────────────────────────────────────

def _call_sp(sp_name, params=()):
    conn = db.engine.raw_connection()
    try:
        cursor = conn.cursor()
        cursor.callproc(sp_name, params)
        if cursor.description:
            cols = [d[0] for d in cursor.description]
            rows = [dict(zip(cols, r)) for r in cursor.fetchall()]
        else:
            rows = []
        cursor.close()
        return rows
    finally:
        conn.close()


def _call_sp_multi(sp_name, params=()):
    conn = db.engine.raw_connection()
    try:
        cursor = conn.cursor()
        cursor.callproc(sp_name, params)
        sets = []
        while True:
            if cursor.description:
                cols = [d[0] for d in cursor.description]
                sets.append([dict(zip(cols, r)) for r in cursor.fetchall()])
            else:
                sets.append([])
            if not cursor.nextset():
                break
        cursor.close()
        return sets
    finally:
        conn.close()


def _json(data, status=200):
    def _serial(obj):
        if isinstance(obj, Decimal):
            return float(obj)
        if isinstance(obj, (datetime.date, datetime.datetime)):
            return str(obj)
        return str(obj)
    return current_app.response_class(
        response=json.dumps(data, default=_serial, ensure_ascii=False),
        status=status,
        mimetype='application/json',
    )


def _pct(actual, anterior):
    a, b = float(actual or 0), float(anterior or 0)
    if b == 0:
        return None
    return round((a - b) / b * 100, 1)


PERIODOS_VALIDOS = ('hoy', 'semanal', 'mensual', 'anual')


# ── Ruta principal ──────────────────────────────────────────────

@dashboard_bp.route('/dashboard')
@login_required
@roles_required('admin', 'empleado', 'panadero')
def index():
    form = PeriodoForm(request.args)
    now  = datetime.datetime.now()
    return render_template('dashboard.html', form=form, now=now)


# ── API · Ventas Totales (admin + empleado) ─────────────────────
# SP: sp_dash_ventas_totales(p_periodo)
# Usa vista: vw_dash_ventas_consolidadas

@dashboard_bp.route('/dashboard/api/ventas')
@login_required
@roles_required('admin', 'empleado')
def api_ventas():
    periodo = request.args.get('periodo', 'semanal')
    if periodo not in PERIODOS_VALIDOS:
        periodo = 'semanal'
    try:
        sets    = _call_sp_multi('sp_dash_ventas_totales', (periodo,))
        resumen = sets[0][0] if sets and sets[0] else {}
        serie   = sets[1]    if len(sets) > 1     else []

        actual   = float(resumen.get('total_actual',   0) or 0)
        anterior = float(resumen.get('total_anterior', 0) or 0)

        return _json({
            'ok':               True,
            'total_actual':     actual,
            'total_anterior':   anterior,
            'pct_cambio':       _pct(actual, anterior),
            'tickets_actual':   int(resumen.get('tickets_actual',   0) or 0),
            'tickets_anterior': int(resumen.get('tickets_anterior', 0) or 0),
            'serie':            serie,
        })
    except Exception as exc:
        current_app.logger.error('dashboard.api_ventas | %s', exc)
        return _json({'ok': False, 'error': str(exc)}, 500)


# ── API · Salidas de Efectivo (solo admin) ──────────────────────
# SP: sp_dash_salidas_efectivo(p_periodo)

@dashboard_bp.route('/dashboard/api/salidas')
@login_required
@roles_required('admin')
def api_salidas():
    periodo = request.args.get('periodo', 'semanal')
    if periodo not in PERIODOS_VALIDOS:
        periodo = 'semanal'
    try:
        sets    = _call_sp_multi('sp_dash_salidas_efectivo', (periodo,))
        resumen = sets[0][0] if sets and sets[0] else {}
        cats    = sets[1]    if len(sets) > 1    else []

        actual   = float(resumen.get('total_actual',   0) or 0)
        anterior = float(resumen.get('total_anterior', 0) or 0)

        return _json({
            'ok':                   True,
            'total_actual':         actual,
            'total_anterior':       anterior,
            'pct_cambio':           _pct(actual, anterior),
            'movimientos_actual':   int(resumen.get('movimientos_actual',   0) or 0),
            'movimientos_anterior': int(resumen.get('movimientos_anterior', 0) or 0),
            'por_categoria':        cats,
        })
    except Exception as exc:
        current_app.logger.error('dashboard.api_salidas | %s', exc)
        return _json({'ok': False, 'error': str(exc)}, 500)


# ── API · Utilidad Bruta por Producto (solo admin) ──────────────
# SP: sp_dash_utilidad_por_producto()
# Usa costo promedio del último mes (detalle_compras del mes).
# Fallback a v_ultimo_costo_materia cuando no hay compras recientes.

@dashboard_bp.route('/dashboard/api/utilidad')
@login_required
@roles_required('admin')
def api_utilidad():
    try:
        rows = _call_sp('sp_dash_utilidad_por_producto')
        return _json({'ok': True, 'productos': rows})
    except Exception as exc:
        current_app.logger.error('dashboard.api_utilidad | %s', exc)
        return _json({'ok': False, 'error': str(exc)}, 500)


# ── API · Top 5 Productos (admin + empleado + panadero) ─────────
# SP: sp_dash_top_productos()
# Fijo: últimos 7 días, top 5, ventas por pieza (nuevo flujo).
# Usa vista: vw_dash_piezas_vendidas

@dashboard_bp.route('/dashboard/api/top-productos')
@login_required
@roles_required('admin', 'empleado', 'panadero')
def api_top_productos():
    try:
        rows = _call_sp('sp_dash_top_productos')
        return _json({'ok': True, 'productos': rows})
    except Exception as exc:
        current_app.logger.error('dashboard.api_top_productos | %s', exc)
        return _json({'ok': False, 'error': str(exc)}, 500)


# ── API · Stock Crítico MP (admin + empleado + panadero) ────────
# SP: sp_dash_mp_criticas()
# Usa vista: vw_dash_mp_criticas

@dashboard_bp.route('/dashboard/api/mp-criticas')
@login_required
@roles_required('admin', 'empleado', 'panadero')
def api_mp_criticas():
    try:
        rows = _call_sp('sp_dash_mp_criticas')
        return _json({
            'ok':      True,
            'items':   rows,
            'total':   len(rows),
            'criticas': sum(1 for r in rows if r.get('nivel') == 'critico'),
        })
    except Exception as exc:
        current_app.logger.error('dashboard.api_mp_criticas | %s', exc)
        return _json({'ok': False, 'error': str(exc)}, 500)