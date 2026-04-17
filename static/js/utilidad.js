'use strict';

/* ════════════════════════════════════════════════════════════
   MÓDULO: Utilidad por Ventas
   static/js/utilidad.js
   ════════════════════════════════════════════════════════════ */

const UV = {
  detalle:   [],   // datos completos del detalle (para paginación)
  pagina:    1,
  POR_PAG:   20,
};

/* ── Formato ─────────────────────────────────────────────── */
const P  = n => '$' + Number(n || 0).toLocaleString('es-MX', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const N  = n => Number(n || 0).toLocaleString('es-MX', { maximumFractionDigits: 2 });
const Pct = n => Number(n || 0).toFixed(1) + '%';

/* ── DOM helpers ─────────────────────────────────────────── */
function txt(id, v) { const e = document.getElementById(id); if (e) e.textContent = v; }
function el(id)     { return document.getElementById(id); }
function show(id)   { const e = el(id); if (e) e.style.display = ''; }
function hide(id)   { const e = el(id); if (e) e.style.display = 'none'; }
function esc(s)     {
  return String(s || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/* ── Margen → chip CSS class ─────────────────────────────── */
function chipClass(pct) {
  const p = parseFloat(pct || 0);
  return p >= 30 ? 'chip-high' : (p >= 20 ? 'chip-mid' : 'chip-low');
}

/* ── Fetch helper ────────────────────────────────────────── */
async function apiFetch(url) {
  const r = await fetch(url, { headers: { 'X-Requested-With': 'XMLHttpRequest' } });
  if (!r.ok) throw new Error('HTTP ' + r.status);
  const d = await r.json();
  if (!d.ok) throw new Error(d.error || 'Error del servidor');
  return d;
}

/* ── Leer fechas del formulario ──────────────────────────── */
function getFechas() {
  return {
    inicio: el('fecha-inicio')?.value || '',
    fin:    el('fecha-fin')?.value    || '',
  };
}

/* ── Construir URL para la API ───────────────────────────── */
function buildApiUrl() {
  const { inicio, fin } = getFechas();
  return `/utilidad-diaria/api/reporte?fecha_inicio=${inicio}&fecha_fin=${fin}`;
}

/* ── Construir URL para exportar ─────────────────────────── */
function buildExportUrl() {
  const { inicio, fin } = getFechas();
  return `/utilidad-diaria/exportar-excel?fecha_inicio=${inicio}&fecha_fin=${fin}`;
}

/* ══════════════════════════════════════════════════════════
   RENDERIZADO
   ══════════════════════════════════════════════════════════ */

function renderKpis(kpis) {
  txt('kpi-ingresos', P(kpis.total_ingresos));
  txt('kpi-ventas-count', N(kpis.total_ventas) + ' transacción(es)');
  txt('kpi-costo', P(kpis.total_costo));
  txt('kpi-productos-count', N(kpis.total_productos) + ' producto(s)');
  txt('kpi-utilidad', P(kpis.total_utilidad));
  txt('kpi-margen', Pct(kpis.margen_prom));
}

function renderProductos(productos) {
  const tbody = el('tbody-prod');
  const tbl   = el('tbl-prod');

  hide('spinner-prod');

  if (!productos || !productos.length) {
    hide('tbl-prod');
    show('empty-prod');
    return;
  }

  tbody.innerHTML = productos.map(p => {
    const utUnit  = parseFloat(p.utilidad_unitaria || 0);
    const utTot   = parseFloat(p.utilidad_total    || 0);
    const clsU    = utUnit >= 0 ? 'pos' : 'neg';
    const clsT    = utTot  >= 0 ? 'pos' : 'neg';
    const cChip   = chipClass(p.margen_pct);
    return `<tr>
      <td style="font-weight:600;">${esc(p.nombre_producto)}</td>
      <td style="text-align:right;">${N(p.total_piezas)} pzas</td>
      <td style="text-align:right;">${P(p.precio_prom_venta)}</td>
      <td style="text-align:right;color:var(--rust);">${P(p.costo_unitario)}</td>
      <td style="text-align:right;font-weight:700;" class="${clsU}">${P(utUnit)}</td>
      <td style="text-align:right;">
        <span class="uv-margen-chip ${cChip}">${Pct(p.margen_pct)}</span>
      </td>
      <td style="text-align:right;font-weight:700;" class="${clsT}">${P(utTot)}</td>
      <td style="text-align:right;">${P(p.ingresos_total)}</td>
    </tr>`;
  }).join('');

  tbl.style.display = '';
  hide('empty-prod');
}

function renderDetalle() {
  const tbody = el('tbody-det');
  const tbl   = el('tbl-det');
  const pagEl = el('pag-det');

  hide('spinner-det');

  if (!UV.detalle || !UV.detalle.length) {
    hide('tbl-det');
    hide('pag-det');
    show('empty-det');
    return;
  }

  const total  = UV.detalle.length;
  const paginas = Math.ceil(total / UV.POR_PAG);
  const inicio  = (UV.pagina - 1) * UV.POR_PAG;
  const fin     = Math.min(inicio + UV.POR_PAG, total);
  const pagina  = UV.detalle.slice(inicio, fin);

  tbody.innerHTML = pagina.map(d => {
    const utUnit = parseFloat(d.utilidad_unitaria || 0);
    const utTot  = parseFloat(d.utilidad_total    || 0);
    const clsU   = utUnit >= 0 ? 'pos' : 'neg';
    const clsT   = utTot  >= 0 ? 'pos' : 'neg';
    const fecha  = String(d.fecha_venta || '').substring(0, 10);
    const hora   = String(d.hora_venta  || '').substring(0, 5);
    return `<tr>
      <td style="font-size:11px;color:var(--brown-lt);">${esc(d.folio_venta)}</td>
      <td style="white-space:nowrap;font-size:12px;">${fecha}<br><span style="color:var(--brown-lt);font-size:10px;">${hora}</span></td>
      <td style="font-weight:600;">${esc(d.nombre_producto)}</td>
      <td style="text-align:right;">${N(d.cantidad)}</td>
      <td style="text-align:right;">${P(d.precio_venta)}</td>
      <td style="text-align:right;color:var(--rust);">${P(d.costo_unitario)}</td>
      <td style="text-align:right;font-weight:700;" class="${clsU}">${P(utUnit)}</td>
      <td style="text-align:right;font-weight:700;" class="${clsT}">${P(utTot)}</td>
      <td style="text-align:right;">${P(d.ingreso_total)}</td>
    </tr>`;
  }).join('');

  tbl.style.display = '';
  hide('empty-det');

  // Paginador
  if (paginas > 1) {
    txt('pag-det-info', `Página ${UV.pagina} de ${paginas} · ${total} líneas`);
    const ant = el('pag-det-ant'); if (ant) ant.disabled = UV.pagina === 1;
    const sig = el('pag-det-sig'); if (sig) sig.disabled = UV.pagina === paginas;
    pagEl.style.display = 'flex';
  } else {
    if (pagEl) pagEl.style.display = 'none';
  }
}

/* ══════════════════════════════════════════════════════════
   CARGA PRINCIPAL
   ══════════════════════════════════════════════════════════ */

async function cargarReporte() {
  const { inicio, fin } = getFechas();

  // Actualizar estado y exportar URL
  txt('uv-estado', `Consultando ${inicio} → ${fin}…`);
  const exportBtn = el('btn-exportar');
  if (exportBtn) exportBtn.href = buildExportUrl();

  // Mostrar spinners
  show('spinner-prod'); hide('tbl-prod'); hide('empty-prod');
  show('spinner-det');  hide('tbl-det');  hide('empty-det');

  // Reset paginación
  UV.pagina  = 1;
  UV.detalle = [];

  try {
    const data = await apiFetch(buildApiUrl());

    // KPIs
    renderKpis(data.kpis || {});

    // Productos
    renderProductos(data.productos || []);

    // Detalle
    UV.detalle = data.detalle || [];
    hide('spinner-det');
    renderDetalle();

    // Estado final
    const kpis = data.kpis || {};
    txt('uv-estado',
      `Período: ${inicio} a ${fin} · ${kpis.total_ventas || 0} transacción(es) · ${(data.detalle || []).length} líneas`
    );
  } catch (err) {
    console.error('[Utilidad]', err);
    hide('spinner-prod'); hide('tbl-prod');
    el('empty-prod').textContent = 'Error al cargar: ' + err.message;
    show('empty-prod');
    hide('spinner-det'); hide('tbl-det');
    el('empty-det').textContent = 'Error al cargar datos.';
    show('empty-det');
    txt('uv-estado', 'Error al consultar el servidor.');
  }
}


/* ══════════════════════════════════════════════════════════
   INIT
   ══════════════════════════════════════════════════════════ */
document.addEventListener('DOMContentLoaded', function () {

  // Botón Consultar
  el('btn-consultar')?.addEventListener('click', cargarReporte);

  // Atajos de rango rápido
  document.querySelectorAll('.uv-sc-btn').forEach(function (btn) {
    btn.addEventListener('click', function () {
      const dias = parseInt(btn.dataset.dias, 10);
      const hoy  = new Date();
      const ini  = new Date(hoy);
      ini.setDate(hoy.getDate() - dias + 1);

      const fmt = d => d.toISOString().substring(0, 10);
      const fInicio = el('fecha-inicio');
      const fFin    = el('fecha-fin');
      if (fInicio) fInicio.value = fmt(ini);
      if (fFin)    fFin.value    = fmt(hoy);
      cargarReporte();
    });
  });

  // Paginación detalle
  el('pag-det-ant')?.addEventListener('click', function () {
    if (UV.pagina > 1) { UV.pagina--; renderDetalle(); }
  });
  el('pag-det-sig')?.addEventListener('click', function () {
    const max = Math.ceil(UV.detalle.length / UV.POR_PAG);
    if (UV.pagina < max) { UV.pagina++; renderDetalle(); }
  });

  // Exportar Excel — el href se actualiza en cargarReporte()
  // (el enlace abre directamente el archivo)

  // Carga inicial automática
  cargarReporte();
});
