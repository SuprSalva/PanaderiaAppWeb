'use strict';

/* ════════════════════════════════════════════════════════════
   MÓDULO: Costo y Utilidad por Producto
   static/js/costoUtilidad.js
   ════════════════════════════════════════════════════════════ */

/* ── Formato ─────────────────────────────────────────────── */
const P  = n => '$' + Number(n || 0).toLocaleString('es-MX', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const Pct = n => Number(n || 0).toFixed(1) + '%';
function fmtCantidad(val, unidad) {
  function fmt(n) { const r = Math.round(n * 100) / 100; return r % 1 === 0 ? String(Math.round(r)) : String(r); }
  if (unidad === 'g'  && val >= 1000) return fmt(val / 1000) + ' kg';
  if (unidad === 'ml' && val >= 1000) return fmt(val / 1000) + ' L';
  if (unidad === 'l')  return val.toFixed(3) + ' l';
  return Math.round(val) + ' ' + unidad;
}
function esc(s) {
  return String(s || '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

/* ── Paginación ──────────────────────────────────────────── */
const CU = { pagina: 1, POR_PAG: 12 };

function initPaginacion() {
  const filas = Array.from(document.querySelectorAll('#cu-tbody tr'));
  const total = filas.length;
  if (!total) return;

  const paginas = Math.ceil(total / CU.POR_PAG);

  function renderPag() {
    const desde = (CU.pagina - 1) * CU.POR_PAG;
    const hasta = Math.min(desde + CU.POR_PAG, total);

    filas.forEach((tr, i) => {
      tr.style.display = (i >= desde && i < hasta) ? '' : 'none';
    });

    const infoEl = document.getElementById('cu-pag-info');
    if (infoEl) infoEl.textContent = `Mostrando ${desde + 1}–${hasta} de ${total} producto${total !== 1 ? 's' : ''}`;

    const controles = document.getElementById('cu-pag-controles');
    if (!controles) return;
    controles.innerHTML = '';

    const btnAnt = document.createElement('button');
    btnAnt.className = 'cu-pag-btn';
    btnAnt.textContent = '‹ Anterior';
    btnAnt.disabled = CU.pagina === 1;
    btnAnt.onclick = () => { CU.pagina--; renderPag(); };
    controles.appendChild(btnAnt);

    // Números de página (máx 5 visibles)
    const rango = 2;
    for (let p = 1; p <= paginas; p++) {
      if (p === 1 || p === paginas || (p >= CU.pagina - rango && p <= CU.pagina + rango)) {
        const b = document.createElement('button');
        b.className = 'cu-pag-btn' + (p === CU.pagina ? ' active' : '');
        b.textContent = p;
        b.onclick = () => { CU.pagina = p; renderPag(); };
        controles.appendChild(b);
      } else if (
        (p === CU.pagina - rango - 1 || p === CU.pagina + rango + 1) &&
        p !== 1 && p !== paginas
      ) {
        const sp = document.createElement('span');
        sp.textContent = '…';
        sp.style.cssText = 'font-size:12px;color:var(--brown-lt);padding:0 4px;';
        controles.appendChild(sp);
      }
    }

    const btnSig = document.createElement('button');
    btnSig.className = 'cu-pag-btn';
    btnSig.textContent = 'Siguiente ›';
    btnSig.disabled = CU.pagina === paginas;
    btnSig.onclick = () => { CU.pagina++; renderPag(); };
    controles.appendChild(btnSig);
  }

  renderPag();
}

/* ── Debounce para búsqueda ──────────────────────────────── */
let _debTimer = null;
function debounceSubmit() {
  clearTimeout(_debTimer);
  _debTimer = setTimeout(() => {
    document.getElementById('form-filtro')?.submit();
  }, 420);
}

/* ── Desglose de ingredientes ────────────────────────────── */
function selectProducto(row) {
  // Marcar fila activa
  document.querySelectorAll('#cu-tbody tr').forEach(r => r.classList.remove('fila-activa'));
  row.classList.add('fila-activa');

  const idReceta   = row.dataset.idReceta;
  const nombre     = row.dataset.nombre;
  const costo      = parseFloat(row.dataset.costo || 0);
  const utilidad   = parseFloat(row.dataset.utilidad || 0);
  const margen     = parseFloat(row.dataset.margen || 0);
  const rendimiento = parseFloat(row.dataset.rendimiento || 1);

  // Actualizar cabecera del panel
  const tituloEl = document.getElementById('cu-des-titulo');
  const subEl    = document.getElementById('cu-des-subtitle');
  if (tituloEl) tituloEl.textContent = nombre;
  if (subEl)    subEl.textContent    = `Rendimiento: ${row.dataset.rendimiento} ${row.dataset.unidad}`;

  // Mostrar spinner
  document.getElementById('cu-des-placeholder').style.display = 'none';
  document.getElementById('cu-des-spinner').style.display     = 'flex';
  document.getElementById('cu-des-content').style.display     = 'none';

  // KPIs inmediatos (del data-* de la fila)
  document.getElementById('cu-des-costo').textContent  = P(costo);
  document.getElementById('cu-des-lote').textContent   = P(costo * rendimiento);
  const utilEl = document.getElementById('cu-des-util');
  utilEl.textContent  = P(utilidad);
  utilEl.className    = 'cu-des-kpi-val ' + (utilidad >= 0 ? 'cu-pos' : 'cu-neg');
  document.getElementById('cu-des-margen').textContent = Pct(margen);

  // Fetch ingredientes
  fetch(`/costo-utilidad/api/detalle/${idReceta}`, {
    headers: { 'X-Requested-With': 'XMLHttpRequest' }
  })
  .then(r => { if (!r.ok) throw new Error('HTTP ' + r.status); return r.json(); })
  .then(data => {
    if (!data.ok) throw new Error(data.error || 'Error del servidor');
    renderIngredientes(data.detalle || []);
    document.getElementById('cu-des-spinner').style.display = 'none';
    document.getElementById('cu-des-content').style.display = '';
  })
  .catch(err => {
    document.getElementById('cu-des-spinner').style.display = 'none';
    document.getElementById('cu-des-content').style.display = '';
    document.getElementById('cu-ing-tbody').innerHTML =
      `<tr><td colspan="4" style="text-align:center;padding:20px;color:var(--rust);">Error: ${esc(err.message)}</td></tr>`;
  });
}

function renderIngredientes(detalle) {
  const tbody = document.getElementById('cu-ing-tbody');
  if (!detalle.length) {
    tbody.innerHTML = `<tr><td colspan="4" style="text-align:center;padding:20px;color:var(--brown-lt);">Sin ingredientes registrados en la receta.</td></tr>`;
    return;
  }
  tbody.innerHTML = detalle.map(ing => {
    const pct  = parseFloat(ing.pct_del_costo || 0);
    const ancho = Math.min(Math.max(pct, 0), 100).toFixed(1);
    return `<tr>
      <td>
        <div class="cu-ing-nm">${esc(ing.materia_nombre)}</div>
        <div class="cu-ing-cant">${fmtCantidad(Number(ing.cantidad_requerida || 0), ing.unidad_base)}</div>
      </td>
      <td style="text-align:right;font-family: Lato, sans-serif;font-weight:700;color:var(--brown-dk);">
        ${P(ing.subtotal_costo)}
      </td>
      <td style="min-width:100px;">
        <div class="cu-ing-bar-wrap">
          <div class="cu-ing-bar"><div class="cu-ing-bar-fill" style="width:${ancho}%"></div></div>
          <span class="cu-ing-pct">${pct.toFixed(1)}%</span>
        </div>
      </td>
    </tr>`;
  }).join('');
}

/* ── Init ────────────────────────────────────────────────── */
document.addEventListener('DOMContentLoaded', function () {
  initPaginacion();

  // Auto-seleccionar primer producto si existe
  const primera = document.querySelector('#cu-tbody tr');
  if (primera) selectProducto(primera);
});
