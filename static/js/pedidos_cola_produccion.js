/* ── Helpers ── */
function getCsrf() {
  const m = document.querySelector('meta[name="csrf-token"]');
  return m ? m.getAttribute('content') : '';
}
function cerrarModal(id) {
  document.getElementById(id).classList.remove('open');
  document.body.style.overflow = '';
}
function abrirModal(id) {
  document.getElementById(id).classList.add('open');
  document.body.style.overflow = 'hidden';
}
document.querySelectorAll('.modal-bd').forEach(m =>
  m.addEventListener('click', e => { if (e.target === m) cerrarModal(m.id); })
);

/* ── Filtros ── */
window.filtrarEstado = function(est) {
  const sel = document.querySelector('select[name="estado"]');
  if (sel) sel.value = est;
  document.getElementById('form-filtro').submit();
};

/* ── Aprobar / Rechazar ── */
window.abrirAprobar = function(folio) {
  document.getElementById('ap-folio').textContent = folio;
  document.getElementById('form-aprobar').action  = '/' + folio + '/aprobar';
  abrirModal('modalAprobar');
};
window.abrirRechazar = function(folio) {
  document.getElementById('rch-folio').textContent = folio;
  document.getElementById('form-rechazar').action  = '/' + folio + '/rechazar';
  abrirModal('modalRechazar');
};

/* ── Modal Detalle ── */
const _detCache = {};
window.abrirDetalle = async function(folio) {
  document.getElementById('det-folio').textContent = folio;
  document.getElementById('det-body').innerHTML =
    '<div class="spinner-wrap"><div class="spinner"></div><span>Cargando detalle…</span></div>';
  abrirModal('modalDetalle');

  if (_detCache[folio]) { renderDetalle(folio, _detCache[folio]); return; }
  try {
    const r = await fetch('/api/' + folio + '/detalle');
    const d = await r.json();
    if (!d.ok) {
      document.getElementById('det-body').innerHTML =
        `<div class="m-body"><p style="color:#dc2626;">⚠️ ${d.mensaje}</p></div>`;
      return;
    }
    _detCache[folio] = d;
    renderDetalle(folio, d);
  } catch(e) {
    document.getElementById('det-body').innerHTML =
      `<div class="m-body"><p style="color:#dc2626;">Error: ${e.message}</p></div>`;
  }
};

function badgeEstado(est) {
  const map = {
    pendiente:         'background:#fef3c7;color:#92400e',
    aprobado:          'background:#dbeafe;color:#1d4ed8',
    pendiente_insumos: 'background:#ede9fe;color:#5b21b6',
    en_produccion:     'background:#d1fae5;color:#065f46',
    listo:             'background:#ffedd5;color:#9a3412',
    rechazado:         'background:#f3f4f6;color:#374151',
  };
  const ic = {pendiente:'📋',aprobado:'✅',pendiente_insumos:'🛒',
              en_produccion:'⚙️',listo:'🎉',rechazado:'❌'}[est] || '•';
  const lb = est.replace(/_/g,' ').replace(/\b\w/g,c=>c.toUpperCase());
  return `<span style="display:inline-flex;align-items:center;gap:4px;padding:3px 10px;
    border-radius:20px;font-size:12px;font-weight:700;${map[est]||'background:#f3f4f6;color:#374151'}">
    ${ic} ${lb}</span>`;
}

function renderDetalle(folio, d) {
  const p = d.pedido, est = p.estado;

  const itemsHtml = d.items.map(i => `
    <tr>
      <td style="padding:8px 12px;font-weight:700;">${i.producto_nombre}</td>
      <td style="padding:8px 12px;text-align:center;">${i.cantidad}</td>
      <td style="padding:8px 12px;text-align:right;">$${i.precio_unitario.toFixed(2)}</td>
      <td style="padding:8px 12px;text-align:right;font-weight:700;">$${i.subtotal.toFixed(2)}</td>
    </tr>`).join('');

  const histHtml = d.historial.map(h => `
    <div class="hist-item">
      <div class="hist-dot"></div>
      <div style="flex:1;">
        <div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap;">
          <span style="font-size:10px;color:var(--brown-lt);white-space:nowrap;">${h.creado_en}</span>
          <span style="font-size:11px;font-weight:700;color:var(--brown);">${h.usuario_nombre}</span>
          <span style="font-size:11px;color:var(--brown-lt);">${h.estado_antes} → ${h.estado_despues}</span>
        </div>
        ${h.nota ? `<div style="font-size:11px;color:var(--text);margin-top:3px;">${h.nota}</div>` : ''}
      </div>
    </div>`).join('');

  let accionesHtml = '';
  if (est === 'pendiente') {
    accionesHtml = `
      <button class="btn btn-success btn-sm"
              onclick="cerrarModal('modalDetalle');abrirAprobar('${folio}')">✅ Aprobar</button>
      <button class="btn btn-danger btn-sm"
              onclick="cerrarModal('modalDetalle');abrirRechazar('${folio}')">❌ Rechazar</button>`;
  } else if (est === 'aprobado') {
    accionesHtml = `
      <form method="POST" action="/${folio}/iniciar-produccion" style="display:inline;"
            onsubmit="return confirm('¿Iniciar producción? Se verificará y descontará el stock.')">
        <input type="hidden" name="csrf_token" value="${getCsrf()}">
        <button class="btn btn-blue btn-sm">▶ Iniciar Producción</button>
      </form>
      <button class="btn btn-danger btn-sm"
              onclick="cerrarModal('modalDetalle');abrirRechazar('${folio}')">❌ Rechazar</button>`;
  } else if (est === 'pendiente_insumos') {
    accionesHtml = `
      <a href="/compras" class="btn btn-purple btn-sm">🛒 Ir a Compras</a>
      <form method="POST" action="/${folio}/iniciar-produccion" style="display:inline;"
            onsubmit="return confirm('¿Reintentar inicio de producción?')">
        <input type="hidden" name="csrf_token" value="${getCsrf()}">
        <button class="btn btn-outline btn-sm">🔄 Reintentar</button>
      </form>`;
  } else if (est === 'en_produccion') {
    accionesHtml = `
      <form method="POST" action="/${folio}/terminar-produccion" style="display:inline;"
            onsubmit="return confirm('¿Marcar como LISTO? El cliente recibirá una notificación.')">
        <input type="hidden" name="csrf_token" value="${getCsrf()}">
        <button class="btn btn-success btn-sm">🎉 Marcar como Listo</button>
      </form>`;
  } else if (est === 'listo') {
    accionesHtml = `
      <form method="POST" action="/${folio}/estado" style="display:inline;"
            onsubmit="return confirm('¿Confirmar entrega?')">
        <input type="hidden" name="csrf_token" value="${getCsrf()}">
        <input type="hidden" name="estado" value="entregado">
        <button class="btn btn-outline btn-sm">📦 Confirmar Entrega</button>
      </form>`;
  }

  document.getElementById('det-body').innerHTML = `
    <div class="m-body">
      <div class="info-grid-2">
        <div class="info-item">
          <div class="i-lbl">Cliente</div>
          <div class="i-val">👤 ${p.cliente_nombre}</div>
        </div>
        <div class="info-item">
          <div class="i-lbl">Estado</div>
          <div style="margin-top:4px;">${badgeEstado(est)}</div>
        </div>
        <div class="info-item">
          <div class="i-lbl">Fecha de recogida</div>
          <div class="i-val">📅 ${p.fecha_recogida}</div>
        </div>
        <div class="info-item">
          <div class="i-lbl">Total estimado</div>
          <div class="i-val" style="font-size:18px;color:var(--rust);">
            $${p.total_estimado.toFixed(2)}
          </div>
        </div>
        ${p.tipo_caja !== '—' ? `
        <div class="info-item">
          <div class="i-lbl">Tipo de caja</div>
          <div class="i-val">${p.tipo_caja} — ${p.tamanio_nombre}</div>
        </div>` : ''}
        <div class="info-item">
          <div class="i-lbl">Registrado</div>
          <div class="i-val" style="font-size:12px;color:var(--brown-lt);">${p.creado_en}</div>
        </div>
      </div>

      ${p.motivo_rechazo ? `
      <div style="background:#fee2e2;border:1px solid #fca5a5;border-radius:9px;padding:12px 14px;">
        <div style="font-size:10px;font-weight:800;color:#991b1b;text-transform:uppercase;
                    margin-bottom:4px;">Motivo de rechazo</div>
        <div style="font-size:13px;color:#991b1b;">${p.motivo_rechazo}</div>
      </div>` : ''}

      <div style="border:1px solid var(--tan);border-radius:10px;overflow:hidden;">
        <div style="background:var(--warm-bg);padding:9px 14px;font-size:11px;font-weight:800;
                    color:var(--brown);text-transform:uppercase;letter-spacing:.4px;">
          🍞 Productos del pedido
        </div>
        <table style="width:100%;border-collapse:collapse;font-size:12px;">
          <thead>
            <tr style="background:var(--warm-bg);">
              <th style="padding:7px 12px;text-align:left;font-size:10px;color:var(--brown);text-transform:uppercase;">Producto</th>
              <th style="padding:7px 12px;text-align:center;font-size:10px;color:var(--brown);text-transform:uppercase;">Cant.</th>
              <th style="padding:7px 12px;text-align:right;font-size:10px;color:var(--brown);text-transform:uppercase;">Precio</th>
              <th style="padding:7px 12px;text-align:right;font-size:10px;color:var(--brown);text-transform:uppercase;">Subtotal</th>
            </tr>
          </thead>
          <tbody>${itemsHtml}</tbody>
          <tfoot>
            <tr style="border-top:2px solid var(--tan);background:var(--warm-bg);">
              <td colspan="3" style="padding:9px 12px;text-align:right;font-weight:800;color:var(--brown);">Total:</td>
              <td style="padding:9px 12px;text-align:right;font-weight:900;font-size:15px;color:var(--brown-dk);">
                $${p.total_estimado.toFixed(2)}
              </td>
            </tr>
          </tfoot>
        </table>
      </div>

      ${d.historial.length > 0 ? `
      <div style="border:1px solid var(--tan);border-radius:10px;overflow:hidden;">
        <div style="background:var(--warm-bg);padding:9px 14px;font-size:11px;font-weight:800;
                    color:var(--brown);text-transform:uppercase;letter-spacing:.4px;">
          📜 Historial de cambios
        </div>
        <div style="padding:8px 14px;">${histHtml}</div>
      </div>` : ''}

      ${accionesHtml ? `
      <div style="display:flex;gap:8px;flex-wrap:wrap;padding-top:4px;
                  border-top:1px solid var(--tan);">
        ${accionesHtml}
        <button class="btn btn-outline btn-sm"
                onclick="cerrarModal('modalDetalle');abrirInsumos('${folio}')">
          🌾 Ver Insumos
        </button>
      </div>` : ''}
    </div>`;
}

/* ── Modal Insumos ── */
window.abrirInsumos = async function(folio) {
  document.getElementById('ins-folio-title').textContent = folio;
  document.getElementById('ins-modal-body').innerHTML =
    '<div class="spinner-wrap"><div class="spinner"></div><span>Calculando insumos…</span></div>';
  abrirModal('modalInsumos');

  try {
    const r = await fetch('/api/' + folio + '/insumos');
    const d = await r.json();
    if (!d.ok) {
      document.getElementById('ins-modal-body').innerHTML =
        `<div class="m-body"><p style="color:#dc2626;">⚠️ ${d.mensaje}</p></div>`;
      return;
    }
    renderInsumos(folio, d);
  } catch(e) {
    document.getElementById('ins-modal-body').innerHTML =
      `<div class="m-body"><p style="color:#dc2626;">Error: ${e.message}</p></div>`;
  }
};

function renderInsumos(folio, d) {
  const body = document.getElementById('ins-modal-body');

  if (!d.insumos || d.insumos.length === 0) {
    body.innerHTML = `<div class="m-body">
      <div style="background:#fef3c7;border:1px solid #fcd34d;border-radius:9px;
                  padding:12px 16px;font-size:13px;color:#92400e;">
        ⚠️ No se encontraron insumos. Verifica que los productos tengan recetas activas
        con el tamaño de charola correcto.
      </div></div>`;
    return;
  }

  const alertHtml = d.hay_faltantes
    ? `<div style="background:#fee2e2;border:1px solid #fca5a5;border-radius:9px;
                   padding:10px 14px;font-size:12px;color:#991b1b;font-weight:700;
                   display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:8px;">
         <span>⛔ ${d.total - d.ok_count} de ${d.total} insumo(s) con stock insuficiente.</span>
         <a href="/compras" style="color:#991b1b;font-weight:800;text-decoration:underline;">
           Ir a Compras →
         </a>
       </div>`
    : `<div style="background:#d1fae5;border:1px solid #6ee7b7;border-radius:9px;
                   padding:10px 14px;font-size:12px;color:#065f46;font-weight:700;">
         ✅ Stock suficiente para todos los insumos (${d.total}).
       </div>`;

  const rows = d.insumos.map(ins => {
    const ok  = ins.stock_suficiente;
    const pct = Math.min(ins.pct_disponible || 0, 100);
    const col = ok ? '#10b981' : (pct >= 50 ? '#f59e0b' : '#ef4444');
    const falta = ok ? '' : (ins.cantidad_requerida - ins.stock_actual).toFixed(2);
    return `<tr style="${ok ? '' : 'background:#fff5f5;'}">
      <td style="padding:8px 12px;font-weight:700;">${ins.nombre_materia}</td>
      <td style="padding:8px 12px;font-size:11px;color:var(--brown-lt);">${ins.categoria||'—'}</td>
      <td style="padding:8px 12px;font-weight:700;">${ins.cantidad_requerida.toFixed(2)} ${ins.unidad_base}</td>
      <td style="padding:8px 12px;">
        <div class="bar-wrap">
          <span style="font-weight:${ok?'600':'800'};color:${ok?'var(--text)':'#dc2626'};">
            ${ins.stock_actual.toFixed(2)} ${ins.unidad_base}
          </span>
          <div class="bar-mini">
            <div class="bar-fill" style="width:${pct}%;background:${col};"></div>
          </div>
          <span style="font-size:10px;color:var(--brown-lt);">${pct.toFixed(0)}%</span>
        </div>
      </td>
      <td style="padding:8px 12px;font-weight:700;color:${ok?'#065f46':'#dc2626'};">
        ${ok ? '✅ OK' : `⛔ Falta ${falta} ${ins.unidad_base}`}
      </td>
    </tr>`;
  }).join('');

  body.innerHTML = `
    <div class="m-body">
      ${alertHtml}
      <div style="overflow-x:auto;border:1px solid var(--tan);border-radius:10px;overflow:hidden;">
        <table class="ins-table">
          <thead>
            <tr><th>Insumo</th><th>Categoría</th><th>Requerido</th>
                <th>Disponible</th><th>Estado</th></tr>
          </thead>
          <tbody>${rows}</tbody>
        </table>
      </div>
      ${d.hay_faltantes ? `
      <div style="display:flex;gap:8px;">
        <a href="/compras" class="btn btn-purple btn-sm">🛒 Ir al módulo de Compras</a>
      </div>` : ''}
    </div>`;
}
