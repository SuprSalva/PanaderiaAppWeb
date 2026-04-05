# costoUtilidad/routes.py
from . import costoUtilidad
from flask import render_template, request, redirect, url_for, flash, session, jsonify
from flask_login import login_required
from models import db
from functools import wraps
from auth import roles_required
import forms

# ─── Helper: ejecutar SP ────────────────────────────────────────────────────
 
def _call_sp(sp_name, params=()):
    """Llama a un SP y devuelve lista de dicts."""
    conn = db.engine.raw_connection()
    try:
        cursor = conn.cursor()
        cursor.callproc(sp_name, params)
        cols = [d[0] for d in cursor.description]
        rows = [dict(zip(cols, row)) for row in cursor.fetchall()]
        cursor.close()
        return rows
    finally:
        conn.close()
 
 
def _call_sp_one(sp_name, params=()):
    """Llama a un SP y devuelve el primer resultado (dict) o None."""
    rows = _call_sp(sp_name, params)
    return rows[0] if rows else None
 
 
def _parse_decimal(valor):
    """Convierte un string a float o None si está vacío/inválido."""
    try:
        v = str(valor).strip()
        return float(v) if v else None
    except (ValueError, TypeError):
        return None
 
 
# ─── Ruta principal: Costo y Utilidad por Producto ──────────────────────────
 
@costoUtilidad.route('/costo-utilidad', methods=['GET'])
@login_required
@roles_required('admin')
def index_costo_utilidad():
    form   = forms.CostoUtilidadFiltroForm(request.args)
    buscar = request.args.get('buscar', '').strip()
    orden  = request.args.get('orden', 'nombre_asc')
 
    # Rango de utilidad
    util_min = _parse_decimal(request.args.get('utilidad_min', ''))
    util_max = _parse_decimal(request.args.get('utilidad_max', ''))
 
    orden_sp_map = {
        'nombre_asc':  '',
        'margen_asc':  'margen_asc',
        'margen_desc': 'margen_desc',
        'costo_asc':   'costo_asc',
        'costo_desc':  'costo_desc',
    }
    orden_sp = orden_sp_map.get(orden, '')
 
    _kpis_default = {
        'total_productos':       0,
        'margen_prom':           None,
        'costo_prom':            None,
        'precio_prom':           None,
        'productos_margen_bajo': 0,
    }
 
    try:
        productos = _call_sp(
            'sp_reporte_costo_utilidad',
            (buscar or None, orden_sp or None, util_min, util_max)
        )
        kpis_raw = _call_sp_one('sp_kpi_costo_utilidad', ())
        kpis = {**_kpis_default, **(kpis_raw or {})}
    except Exception as e:
        flash(f'Error al obtener datos: {e}', 'error')
        productos = []
        kpis = _kpis_default
 
    return render_template(
        'costoUtilidad/costoUtilidad.html',
        form=form,
        productos=productos,
        kpis=kpis,
        buscar=buscar,
        orden=orden,
        util_min=util_min,
        util_max=util_max,
    )
 
 
# ─── API: detalle de insumos para un producto/receta ────────────────────────
 
@costoUtilidad.route('/costo-utilidad/api/detalle/<int:id_receta>', methods=['GET'])
@login_required
@roles_required('admin')
def api_detalle_costo(id_receta):
    try:
        detalle = _call_sp('sp_detalle_costo_producto', (id_receta,))
        return jsonify({'ok': True, 'detalle': detalle})
    except Exception as e:
        return jsonify({'ok': False, 'error': str(e)}), 500
 
 
# ─── Ruta: Utilidad Diaria ──────────────────────────────────────────────────
 
@costoUtilidad.route('/utilidad-diaria', methods=['GET'])
@login_required
@roles_required('admin')
def index_utilidad():
    return render_template('costoUtilidad/utilidad.html')
 