'use strict';

const DM = {
  periodo: 'semanal',   // filtro activo compartido
  charts:  {},
  // paginación utilidad
  utilDatos: [],
  utilPagina: 1,
  UTIL_POR_PAG: 5,
};

/* ── Formato ──────────────────────────────────────────────────── */
const P  = n => '$' + Number(n || 0).toLocaleString('es-MX', {minimumFractionDigits:2, maximumFractionDigits:2});
const N  = n => Number(n || 0).toLocaleString('es-MX');

/* ── Colores ─────────────────────────────────────────────────── */
const C = { brown:'#7c4a1e', rust:'#c0522a', gold:'#c9950a', muted:'#9c7c5c' };

/* ── DOM helper ──────────────────────────────────────────────── */
function txt(id, v) { const e = document.getElementById(id); if (e) e.textContent = v; }
function el(id)     { return document.getElementById(id); }

/* ── Fetch ────────────────────────────────────────────────────── */
async function apiFetch(url) {
  const r = await fetch(url, { headers: { 'X-Requested-With': 'XMLHttpRequest' } });
  if (!r.ok) throw new Error('HTTP ' + r.status);
  const d = await r.json();
  if (!d.ok) throw new Error(d.error || 'Error');
  return d;
}

/* ── Badge cambio % ──────────────────────────────────────────── */
function renderBadge(elId, pct) {
  const e = el(elId); if (!e) return;
  if (pct === null || pct === undefined) {
    e.textContent = 'Sin dato anterior'; e.className = 'dm-badge neutral'; return;
  }
  e.textContent = (pct >= 0 ? '↑ ' : '↓ ') + Math.abs(pct) + '% vs período anterior';
  e.className   = 'dm-badge ' + (pct >= 0 ? 'up' : 'down');
}

/* ── Etiqueta legible del periodo ────────────────────────────── */
function labelPeriodo(p) {
  return {hoy:'Hoy', semanal:'Esta semana', mensual:'Este mes', anual:'Este año'}[p] || p;
}

/* ── Cambio de periodo ───────────────────────────────────────── */
function setPeriodo(p) {
  DM.periodo = p;
  document.querySelectorAll('.dm-p-btn').forEach(b => {
    b.classList.toggle('active', b.dataset.periodo === p);
  });
  txt('label-periodo-grafica', labelPeriodo(p));
  cargarVentas();
  cargarSalidas();
}

/* ══════════════════════════════════════════════════════════════
   1. VENTAS TOTALES
   SP: sp_dash_ventas_totales(periodo)  · vw_dash_ventas_consolidadas
══════════════════════════════════════════════════════════════ */
async function cargarVentas() {
  txt('kpi-ventas-total',    '…');
  txt('kpi-ventas-anterior', '…');
  try {
    const d = await apiFetch('/dashboard/api/ventas?periodo=' + DM.periodo);

    txt('kpi-ventas-total',    P(d.total_actual));
    txt('kpi-ventas-tickets',  N(d.tickets_actual) + ' transacción(es)');
    txt('kpi-ventas-anterior', P(d.total_anterior));
    renderBadge('badge-ventas', d.pct_cambio);

    // Guardar para flujo neto
    DM._ventasActual = d.total_actual;
    _actualizarFlujoNeto();

    // Gráfica de barras
    const labels  = d.serie.map(s => { const p = String(s.fecha).split('-'); return p[2]+'/'+p[1]; });
    const totales = d.serie.map(s => parseFloat(s.total_dia || 0));

    if (DM.charts.ventas) {
      DM.charts.ventas.data.labels = labels;
      DM.charts.ventas.data.datasets[0].data = totales;
      DM.charts.ventas.update('active');
      return;
    }
    const ctx = el('chart-ventas'); if (!ctx) return;
    DM.charts.ventas = new Chart(ctx, {
      type: 'bar',
      data: {
        labels,
        datasets: [{
          label: 'Ingresos', data: totales,
          backgroundColor: C.brown + 'CC', borderColor: C.brown,
          borderWidth: 1, borderRadius: 5, hoverBackgroundColor: C.rust,
        }],
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        interaction: { mode: 'index', intersect: false },
        plugins: {
          legend: { display: false },
          tooltip: { callbacks: { label: c => ' ' + P(c.parsed.y) } },
        },
        scales: {
          x: { grid: { display: false }, ticks: { font: { size: 10 }, maxRotation: 45, color: C.muted } },
          y: {
            beginAtZero: true, grid: { color: '#f3ede7' },
            ticks: {
              font: { size: 10 }, color: C.muted,
              callback: v => '$' + (v >= 1000 ? (v/1000).toFixed(1)+'k' : v),
            },
          },
        },
      },
    });
  } catch (e) {
    console.error('[Ventas]', e);
    txt('kpi-ventas-total', 'Error al cargar');
  }
}

/* ══════════════════════════════════════════════════════════════
   2. SALIDAS DE EFECTIVO  (solo admin)
   SP: sp_dash_salidas_efectivo(periodo)
══════════════════════════════════════════════════════════════ */
async function cargarSalidas() {
  const eTotal = el('kpi-salidas-total'); if (!eTotal) return;
  eTotal.textContent = '…';
  try {
    const d = await apiFetch('/dashboard/api/salidas?periodo=' + DM.periodo);

    txt('kpi-salidas-total', P(d.total_actual));
    txt('kpi-salidas-movs',  N(d.movimientos_actual) + ' salida(s) aprobada(s)');
    renderBadge('badge-salidas', d.pct_cambio);

    DM._salidasActual = d.total_actual;
    _actualizarFlujoNeto();
  } catch (e) {
    console.error('[Salidas]', e);
    txt('kpi-salidas-total', 'Error al cargar');
  }
}

function _actualizarFlujoNeto() { /* reservado si se requiere en futuro */ }

/* ══════════════════════════════════════════════════════════════
   3. UTILIDAD BRUTA POR PRODUCTO  (solo admin)
   SP: sp_dash_utilidad_por_producto()
   Tabla paginada: 5 filas por página
   Columnas: Producto | Precio venta | Costo unitario | Utilidad | Margen %
══════════════════════════════════════════════════════════════ */
async function cargarUtilidad() {
  const tbody = el('tbody-utilidad'); if (!tbody) return;
  tbody.innerHTML = '<tr><td colspan="5" class="dm-empty">Cargando…</td></tr>';
  try {
    const d = await apiFetch('/dashboard/api/utilidad');
    if (!d.productos || !d.productos.length) {
      tbody.innerHTML = '<tr><td colspan="5" class="dm-empty">Sin datos — verifique recetas activas y compras del último mes.</td></tr>';
      return;
    }
    DM.utilDatos  = d.productos;
    DM.utilPagina = 1;
    renderUtilidad();
  } catch (e) {
    tbody.innerHTML = '<tr><td colspan="5" style="color:#ef4444;padding:12px;">Error al cargar utilidad.</td></tr>';
    console.error('[Utilidad]', e);
  }
}

function renderUtilidad() {
  const tbody = el('tbody-utilidad'); if (!tbody) return;
  const total   = DM.utilDatos.length;
  const paginas = Math.ceil(total / DM.UTIL_POR_PAG);
  const inicio  = (DM.utilPagina - 1) * DM.UTIL_POR_PAG;
  const fin     = Math.min(inicio + DM.UTIL_POR_PAG, total);
  const pagina  = DM.utilDatos.slice(inicio, fin);

  tbody.innerHTML = pagina.map(p => {
    const margen  = parseFloat(p.margen_pct || 0);
    const util    = parseFloat(p.utilidad_unitaria || 0);
    const color   = util >= 0 ? 'var(--brown-dk)' : '#ef4444';
    return `<tr>
      <td style="font-weight:600;">${p.nombre_producto}</td>
      <td style="text-align:right;">${P(p.precio_venta)}</td>
      <td style="text-align:right;color:var(--rust);">${P(p.costo_unitario)}</td>
      <td style="text-align:right;font-weight:700;color:${color};">${P(util)}</td>
      <td style="text-align:right;">${margen.toFixed(1)}%</td>
    </tr>`;
  }).join('');

  // Paginador
  const pag = el('pag-utilidad');
  if (pag) {
    pag.style.display = paginas > 1 ? 'flex' : 'none';
    txt('pag-util-info', `Página ${DM.utilPagina} de ${paginas}`);
    const ant = el('pag-util-ant'); if (ant) ant.disabled = DM.utilPagina === 1;
    const sig = el('pag-util-sig'); if (sig) sig.disabled = DM.utilPagina === paginas;
  }
}

/* ══════════════════════════════════════════════════════════════
   4. TOP 5 PRODUCTOS MÁS VENDIDOS  (todos los roles)
   SP: sp_dash_top_productos()  — fijo 7 días, top 5
   Tabla: Producto | Piezas vendidas | Ingresos generados
══════════════════════════════════════════════════════════════ */
async function cargarTopProductos() {
  const tbody = el('tbody-top'); if (!tbody) return;
  tbody.innerHTML = '<tr><td colspan="3" class="dm-empty">Cargando…</td></tr>';
  try {
    const d = await apiFetch('/dashboard/api/top-productos');
    if (!d.productos || !d.productos.length) {
      tbody.innerHTML = '<tr><td colspan="3" class="dm-empty">Sin ventas en los últimos 7 días.</td></tr>';
      return;
    }
    const medal = ['1.', '2.', '3.', '4.', '5.'];
    tbody.innerHTML = d.productos.map((p, i) => `
      <tr>
        <td>
          <span style="font-size:15px;margin-right:6px;">${medal[i] || (i+1)+'.'}</span>
          <span style="font-weight:600;">${p.nombre_producto}</span>
        </td>
        <td style="text-align:right;font-weight:700;">${N(p.total_piezas)} pzas</td>
        <td style="text-align:right;font-weight:700;color:var(--brown-dk);">${P(p.total_ingresos)}</td>
      </tr>`).join('');
  } catch (e) {
    tbody.innerHTML = '<tr><td colspan="3" style="color:#ef4444;padding:12px;">Error al cargar.</td></tr>';
    console.error('[Top]', e);
  }
}

/* ══════════════════════════════════════════════════════════════
   5. INSUMOS BAJO STOCK MÍNIMO  (todos los roles)
   SP: sp_dash_mp_criticas()  · vw_dash_mp_criticas
   Tabla: Materia Prima | Categoría | Stock actual | Stock mín | Estado
   (sin columna "Nivel")
══════════════════════════════════════════════════════════════ */
async function cargarMPCriticas() {
  const tbody = el('tbody-stock'); if (!tbody) return;
  tbody.innerHTML = '<tr><td colspan="5" class="dm-empty">Cargando…</td></tr>';
  try {
    const d = await apiFetch('/dashboard/api/mp-criticas');
    if (!d.items || !d.items.length) {
      tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:28px;color:var(--brown-lt);">✅ Todos los insumos están sobre el stock mínimo.</td></tr>';
      return;
    }
    const labels = {
      critico: `<animated-icons
        src="https://animatedicons.co/get-icon?name=Risk&style=minimalistic&token=240003ce-c76a-49ff-b69a-4123c54f8934"
        trigger="loop"
        attributes='{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#FF0707FF","background":"#FFFFFF"}}'
        height="15"
        width="15"
      ></animated-icons> Crítico`,
      bajo: `<animated-icons
        src="https://animatedicons.co/get-icon?name=Alert&style=minimalistic&token=240003ce-c76a-49ff-b69a-4123c54f8934"
        trigger="loop"
        attributes='{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#FF0707FF","background":"#FFFFFF"}}'
        height="15"
        width="15"
      ></animated-icons> Bajo`,
      advertencia:`<animated-icons
        src="https://animatedicons.co/get-icon?name=Alert&style=minimalistic&token=240003ce-c76a-49ff-b69a-4123c54f8934"
        trigger="loop"
        attributes='{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#E07A52FF","background":"#FFFFFF"}}'
        height="15"
        width="15"
      ></animated-icons> Advertencia`,
    };
    tbody.innerHTML = d.items.map(mp => {
      const pct = parseFloat(mp.pct_stock || 0);
      const w   = Math.min(100, Math.max(0, pct));
      return `<tr>
        <td style="font-weight:600;">${mp.nombre}</td>
        <td style="color:var(--brown-lt);">${mp.categoria}</td>
        <td style="text-align:right;">
          ${Number(mp.stock_actual).toFixed(2)} ${mp.unidad_base}
          <span class="dm-stock-bar"><span class="dm-stock-bar-fill ${mp.nivel}" style="width:${w}%;display:block;height:100%;"></span></span>
          <small style="color:var(--brown-lt);margin-left:4px;">${pct}%</small>
        </td>
        <td style="text-align:right;">${Number(mp.stock_minimo).toFixed(2)} ${mp.unidad_base}</td>
        <td style="text-align:center;"><span class="chip-estado chip-${mp.nivel}">${labels[mp.nivel]||mp.nivel}</span></td>
      </tr>`;
    }).join('');
  } catch (e) {
    tbody.innerHTML = '<tr><td colspan="5" style="color:#ef4444;padding:12px;">Error al cargar.</td></tr>';
    console.error('[Stock]', e);
  }
}

/* ── Init ─────────────────────────────────────────────────────── */
function cargarTodo() {
  txt('ult-actualizacion', 'Actualizado: ' + new Date().toLocaleTimeString('es-MX'));
  cargarVentas();
  cargarSalidas();
  cargarUtilidad();
  cargarTopProductos();
  cargarMPCriticas();
}


document.addEventListener('DOMContentLoaded', () => {
  // Filtros de periodo (ventas + salidas comparten estado)
  document.querySelectorAll('.dm-p-btn').forEach(b => {
    b.addEventListener('click', () => setPeriodo(b.dataset.periodo));
  });

  // Paginación de utilidad
  el('pag-util-ant')?.addEventListener('click', () => {
    if (DM.utilPagina > 1) { DM.utilPagina--; renderUtilidad(); }
  });
  el('pag-util-sig')?.addEventListener('click', () => {
    const max = Math.ceil(DM.utilDatos.length / DM.UTIL_POR_PAG);
    if (DM.utilPagina < max) { DM.utilPagina++; renderUtilidad(); }
  });

  // Refresh
  el('btn-refresh')?.addEventListener('click', () => {
    const ico = el('ico-refresh');
    if (ico) ico.classList.add('spinning');
    cargarTodo();
    setTimeout(() => ico?.classList.remove('spinning'), 2000);
  });

  cargarTodo();
  setInterval(cargarTodo, 5 * 60 * 1000); // auto-refresh 5 min
});