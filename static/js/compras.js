/* ═══════════════════════════════════════════════════
   JavaScript — Módulo Compras
   Requiere las variables globales inyectadas por el
   template (data island):
     MATERIAS, URL_CREAR_COMPRA, CSRF_TOKEN
   ═══════════════════════════════════════════════════ */

/* ── Modales ── */
function openModal(id)  { document.getElementById(id).classList.add('open'); }
function closeModal(id) { document.getElementById(id).classList.remove('open'); }
document.querySelectorAll('.modal-overlay').forEach(el => {
  el.addEventListener('click', e => { if (e.target === el) el.classList.remove('open'); });
});

/* ── MODAL NUEVA / EDITAR COMPRA ── */
let renglonCount = 0;
let _tplOpciones = '';

function _initTpl() {
  if (!_tplOpciones) {
    const tpl = document.getElementById('tpl-opciones-materia');
    _tplOpciones = tpl ? tpl.innerHTML : '';
  }
}

function _resetModal() {
  document.getElementById('renglones-container').innerHTML = '';
  renglonCount = 0;
  document.getElementById('total-compra').textContent = '$0.00';
  document.getElementById('conversion-info').textContent = 'Selecciona una materia prima y unidad para ver la conversión.';
  document.getElementById('form-error').style.display = 'none';
  document.getElementById('form-nueva-compra').reset();
}

function abrirModalNueva() {
  _initTpl();
  _resetModal();
  document.getElementById('form-nueva-compra').action = URL_CREAR_COMPRA;
  document.getElementById('modal-add-titulo').textContent = '🛒 Nuevo Pedido de Compra';
  document.getElementById('fecha-compra').value = new Date().toISOString().split('T')[0];
  addRenglon();
  addRenglon();
  openModal('modal-add');
}

function abrirEditar(id, folio) {
  _initTpl();
  _resetModal();
  document.getElementById('form-nueva-compra').action = `/compras/editar/${id}`;
  document.getElementById('modal-add-titulo').textContent = `✏️ Editar Pedido — ${folio}`;
  document.getElementById('form-error').textContent = '';

  fetch(`/compras/detalle/${id}`)
    .then(r => r.json())
    .then(d => {
      const form = document.getElementById('form-nueva-compra');
      form.querySelector('select[name="id_proveedor"]').value = d.id_proveedor;
      form.querySelector('input[name="fecha_compra"]').value  = d.fecha_compra_iso;
      form.querySelector('input[name="folio_factura"]').value = d.folio_factura  || '';
      form.querySelector('input[name="observaciones"]').value = d.observaciones  || '';

      d.detalles.forEach(det => {
        addRenglon();
        const n = renglonCount;
        const buscarInput = document.querySelector(`#renglon-${n} .insumo-buscar`);
        const matHidden   = document.getElementById('imat-' + n);
        buscarInput.value = `${det.materia} (${det.unidad_base})`;
        matHidden.value   = det.id_materia;
        const lista = document.querySelector(`#renglon-${n} .insumo-lista`);
        lista.querySelectorAll('.insumo-opcion').forEach(op => {
          if (op.dataset.val == det.id_materia) op.classList.add('activo');
        });
        onMateriaCambio(n, det.id_unidad);
        document.getElementById('qty-' + n)._preval   = det.cantidad_comprada;
        document.getElementById('costo-' + n)._preval = det.costo_unitario;
      });
      openModal('modal-add');
    })
    .catch(() => { mostrarErrorForm('⚠️ Error al cargar el pedido.'); });
}

function addRenglon() {
  renglonCount++;
  const n = renglonCount;
  const container = document.getElementById('renglones-container');
  const div = document.createElement('div');
  div.className = 'detalle-row';
  div.id = 'renglon-' + n;
  div.innerHTML = `
    <div class="insumo-wrap">
      <span class="insumo-buscar-icon">🔍</span>
      <span class="insumo-arrow">▾</span>
      <input type="text" class="insumo-buscar" placeholder="— Buscar materia prima —"
             autocomplete="off"
             oninput="buscarInsumoC(this)"
             onfocus="abrirListaC(this)"
             onblur="cerrarListaDelayC(this, ${n})">
      <input type="hidden" name="id_materia[]" class="insumo-val" id="imat-${n}" value="">
      <div class="insumo-lista">${_tplOpciones}</div>
    </div>
    <input type="number" class="det-input" name="cantidad_comprada[]"
           placeholder="0" min="1" step="1" id="qty-${n}" onkeydown="if(['.','e','E','+','-'].includes(event.key))event.preventDefault()" oninput="calcSubtotal(${n})" required>
    <div style="display:flex;gap:4px;align-items:center">
      <select class="det-select" name="id_unidad_presentacion[]" id="usel-${n}"
              onchange="onUnidadCambio(${n})" style="flex:1;min-width:0">
        <option value="">— Elige materia primero —</option>
      </select>
      <button type="button" title="Nueva unidad de compra"
        style="flex-shrink:0;width:28px;height:28px;border-radius:6px;background:#f3e8d8;border:1.5px solid var(--tan);color:var(--brown);font-size:16px;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:background .2s"
        onmouseover="this.style.background='var(--tan)'" onmouseout="this.style.background='#f3e8d8'"
        onclick="abrirModalNuevaUnidad(${n})">＋</button>
    </div>
    <input type="number" class="det-input" name="costo_unitario[]"
           placeholder="$0.00" min="0" step="0.01" id="costo-${n}" oninput="calcSubtotal(${n})" required>
    <input type="text" class="det-input" readonly id="sub-${n}" value="$0.00"
           style="background:var(--warm-bg);font-weight:700;color:var(--brown-dk);">
    <input type="hidden" name="unidad_compra[]"     id="unidad-str-${n}" value="">
    <input type="hidden" name="factor_conversion[]" id="factor-${n}"     value="1">
    <input type="hidden" name="cantidad_base[]"     id="cant-base-${n}"  value="0">
    <button type="button" class="btn-remove" onclick="removeRenglon(${n})">✕</button>
  `;
  container.appendChild(div);
}

/* ── Buscador de materia prima ── */
function seleccionarInsumoC(op) {
  const wrap  = op.closest('.insumo-wrap');
  const input = wrap.querySelector('.insumo-buscar');
  const val   = wrap.querySelector('.insumo-val');
  const lista = wrap.querySelector('.insumo-lista');
  input.value = op.dataset.txt;
  val.value   = op.dataset.val;
  input.classList.remove('abierto');
  lista.classList.remove('abierta');
  lista.querySelectorAll('.insumo-opcion').forEach(o => o.classList.remove('activo'));
  op.classList.add('activo');
  const n = parseInt(val.id.replace('imat-', ''));
  onMateriaCambio(n);
}

function abrirListaC(input) {
  const lista = input.closest('.insumo-wrap').querySelector('.insumo-lista');
  document.querySelectorAll('.insumo-lista.abierta').forEach(l => { if (l !== lista) l.classList.remove('abierta'); });
  lista.classList.add('abierta');
  input.classList.add('abierto');
  lista.querySelectorAll('.insumo-opcion').forEach(op => op.classList.remove('oculto'));
  lista.querySelector('.insumo-sin-res').style.display = 'none';
}

function buscarInsumoC(input) {
  const q    = input.value.toLowerCase().trim();
  const wrap = input.closest('.insumo-wrap');
  const lista = wrap.querySelector('.insumo-lista');
  let hay = false;
  if (!q) wrap.querySelector('.insumo-val').value = '';
  lista.querySelectorAll('.insumo-opcion').forEach(op => {
    const ok = op.dataset.txt.toLowerCase().includes(q);
    op.classList.toggle('oculto', !ok);
    if (ok) hay = true;
  });
  lista.querySelector('.insumo-sin-res').style.display = hay ? 'none' : 'block';
  lista.classList.add('abierta');
}

function cerrarListaDelayC(input, n) {
  setTimeout(() => {
    const wrap  = input.closest('.insumo-wrap');
    const lista = wrap.querySelector('.insumo-lista');
    const val   = wrap.querySelector('.insumo-val');
    lista.classList.remove('abierta');
    input.classList.remove('abierto');
    if (!val.value) input.value = '';
  }, 150);
}

function removeRenglon(n) {
  const el = document.getElementById('renglon-' + n);
  if (el) { el.remove(); updateTotal(); }
}

/* ── Unidades y cálculos ── */
function onMateriaCambio(n, preselectUnitId = null) {
  const idMat = document.getElementById('imat-' + n)?.value || '';
  const uSel  = document.getElementById('usel-' + n);
  uSel.innerHTML = '<option value="">Cargando…</option>';
  document.getElementById('factor-' + n).value     = '1';
  document.getElementById('unidad-str-' + n).value = '';
  document.getElementById('cant-base-' + n).value  = '0';
  if (!idMat) { uSel.innerHTML = '<option value="">— Elige materia primero —</option>'; return; }

  fetch(`/compras/api/unidades/${idMat}`)
    .then(r => r.json())
    .then(data => {
      if (!data.length) {
        const base = MATERIAS[idMat]?.unidad_base || 'u';
        uSel.innerHTML = `<option value="0" data-factor="1" data-simbolo="${base}">${base} (base)</option>`;
      } else {
        uSel.innerHTML = data.map(u =>
          `<option value="${u.id}" data-factor="${u.factor_a_base}" data-simbolo="${u.simbolo}">${u.nombre} (×${u.factor_a_base})</option>`
        ).join('');
      }
      if (preselectUnitId) uSel.value = preselectUnitId;
      onUnidadCambio(n);
      const qtyEl   = document.getElementById('qty-' + n);
      const costoEl = document.getElementById('costo-' + n);
      if (qtyEl._preval   != null) { qtyEl.value   = qtyEl._preval;   delete qtyEl._preval; }
      if (costoEl._preval != null) { costoEl.value = costoEl._preval; delete costoEl._preval; calcSubtotal(n); }
    })
    .catch(() => { uSel.innerHTML = '<option value="0" data-factor="1">Unidad base</option>'; });
}

function onUnidadCambio(n) {
  const uSel   = document.getElementById('usel-' + n);
  const opt    = uSel.options[uSel.selectedIndex];
  const factor = parseFloat(opt?.dataset?.factor || 1);
  const simb   = opt?.dataset?.simbolo || '';
  const idMat  = document.getElementById('imat-' + n)?.value || '';
  const base   = idMat ? (MATERIAS[idMat]?.unidad_base || '?') : '?';
  document.getElementById('factor-' + n).value    = factor;
  document.getElementById('unidad-str-' + n).value = simb;
  calcSubtotal(n);
  if (idMat && simb) {
    document.getElementById('conversion-info').textContent =
      `1 ${simb} × ${factor} = ${factor} ${base} sumados al inventario.`;
  }
}

function calcSubtotal(n) {
  const qty    = parseFloat(document.getElementById('qty-' + n)?.value)   || 0;
  const costo  = parseFloat(document.getElementById('costo-' + n)?.value) || 0;
  const factor = parseFloat(document.getElementById('factor-' + n)?.value || 1);
  const sub    = qty * costo;
  const base   = qty * factor;
  const subEl  = document.getElementById('sub-' + n);
  if (subEl) subEl.value = '$' + sub.toFixed(2);
  const cbEl = document.getElementById('cant-base-' + n);
  if (cbEl) cbEl.value = base.toFixed(4);
  updateTotal();
}

function updateTotal() {
  let total = 0;
  document.querySelectorAll('[id^="sub-"]').forEach(el => {
    total += parseFloat(el.value.replace('$', '')) || 0;
  });
  document.getElementById('total-compra').textContent = '$' + total.toFixed(2);
}

/* ── Mensajes de error ── */
function mostrarErrorForm(msg) {
  const err = document.getElementById('form-error');
  err.style.background  = '#fce8df';
  err.style.color       = '#9c3a1a';
  err.style.borderColor = '#f5c6b0';
  err.textContent       = msg;
  err.style.display     = 'block';
  clearTimeout(err._t);
  err._t = setTimeout(() => { err.style.display = 'none'; }, 4000);
}

/* ── Validación del form de pedido ── */
document.getElementById('form-nueva-compra').addEventListener('submit', function(e) {
  document.getElementById('form-error').style.display = 'none';
  const prov  = this.querySelector('select[name="id_proveedor"]').value;
  const fecha = this.querySelector('input[name="fecha_compra"]').value;
  if (!prov || !fecha) {
    e.preventDefault(); mostrarErrorForm('⚠️ Proveedor y fecha son obligatorios.'); return;
  }
  const filas = document.querySelectorAll('#renglones-container .detalle-row');
  let tieneInsumos = false;
  for (const fila of filas) {
    const matInput = fila.querySelector('.insumo-val');
    const mat = matInput ? matInput.value : '';
    if (!mat) continue;
    tieneInsumos = true;
    const qty   = parseFloat(fila.querySelector('input[name="cantidad_comprada[]"]').value);
    const costo = fila.querySelector('input[name="costo_unitario[]"]').value.trim();
    if (!qty || qty <= 0) {
      e.preventDefault(); mostrarErrorForm('⚠️ Todos los insumos deben tener una cantidad mayor a 0.'); return;
    }
    if (costo === '' || parseFloat(costo) < 0) {
      e.preventDefault(); mostrarErrorForm('⚠️ Todos los insumos deben tener un costo unitario válido.'); return;
    }
  }
  if (!tieneInsumos) {
    e.preventDefault(); mostrarErrorForm('⚠️ Debes agregar al menos un insumo.'); return;
  }
  const btn = this.querySelector('button[type="submit"]');
  btn.disabled = true;
  btn.textContent = '⏳ Guardando…';
});

/* ── Modal: Ver detalle ── */
function verDetalle(id) {
  document.getElementById('det-folio').textContent = '';
  document.getElementById('det-body').innerHTML = '<p style="text-align:center;color:var(--brown-lt);padding:20px">Cargando…</p>';
  openModal('modal-detalle');
  fetch(`/compras/detalle/${id}`)
    .then(r => r.json())
    .then(d => {
      document.getElementById('det-folio').textContent = d.folio;
      const estatusBadge = {
        ordenado:   '<span class="badge badge-ordenado">📋 Ordenado</span>',
        finalizado: '<span class="badge badge-finalizado">✅ Finalizado</span>',
        cancelado:  '<span class="badge badge-cancelado">🚫 Cancelado</span>',
      }[d.estatus] || d.estatus;

      const cancelBox = d.estatus === 'cancelado'
        ? `<div class="cancelado-box"><strong>Motivo de cancelación:</strong> ${d.motivo_cancelacion}</div>` : '';

      const filas = d.detalles.map(det => `
        <tr>
          <td><strong>${det.materia}</strong></td>
          <td>${det.cantidad_comprada} ${det.unidad_compra}</td>
          <td style="color:var(--brown-lt);font-size:11px">${det.cantidad_comprada} × ${det.factor} = <strong>${det.cantidad_base} ${det.unidad_base}</strong></td>
          ${d.estatus === 'finalizado' ? `<td>+${det.cantidad_base} ${det.unidad_base}</td>` : '<td style="color:var(--brown-lt)">—</td>'}
          <td>$${det.costo_unitario.toFixed(2)}</td>
          <td><strong>$${det.subtotal.toFixed(2)}</strong></td>
        </tr>`).join('');

      document.getElementById('det-body').innerHTML = `
        <div class="detail-section">
          <h4>📦 Cabecera</h4>
          <div class="detail-grid-2">
            <div class="detail-item"><label>Folio</label><span>${d.folio}</span></div>
            <div class="detail-item"><label>Estatus</label><span>${estatusBadge}</span></div>
            <div class="detail-item"><label>Fecha</label><span>${d.fecha_compra}</span></div>
            <div class="detail-item"><label>No. Factura/Referencia</label><span>${d.folio_factura || '—'}</span></div>
            <div class="detail-item"><label>Total</label><span style="font-family:'Playfair Display',serif;font-size:18px">$${d.total.toFixed(2)}</span></div>
            ${d.observaciones ? `<div class="detail-item"><label>Observaciones</label><span>${d.observaciones}</span></div>` : ''}
          </div>
          ${cancelBox}
        </div>
        <div class="detail-section">
          <h4>🌾 Insumos</h4>
          <table class="det-view-table">
            <thead>
              <tr>
                <th>Materia Prima</th><th>Cant. Comprada</th><th>Conversión</th>
                <th>${d.estatus === 'finalizado' ? 'Stock Sumado' : 'Pendiente'}</th>
                <th>Costo Unit.</th><th>Subtotal</th>
              </tr>
            </thead>
            <tbody>${filas}</tbody>
          </table>
        </div>
        <div style="background:var(--brown-dk);color:var(--cream);padding:12px 18px;border-radius:10px;display:flex;justify-content:space-between;align-items:center;">
          <span style="font-size:13px;opacity:.8">Total del Pedido</span>
          <strong style="font-family:'Playfair Display',serif;font-size:22px">$${d.total.toFixed(2)}</strong>
        </div>`;
    })
    .catch(() => {
      document.getElementById('det-body').innerHTML = '<p style="color:var(--rust);text-align:center;padding:20px">Error al cargar el detalle.</p>';
    });
}

/* ── Modal: Finalizar ── */
function abrirFinalizar(id, folio) {
  document.getElementById('fin-folio').textContent = folio;
  document.getElementById('form-finalizar').action = `/compras/finalizar/${id}`;
  openModal('modal-finalizar');
}

/* ── Modal: Cancelar ── */
function abrirCancelar(id, folio) {
  document.getElementById('can-folio').textContent = folio;
  document.getElementById('can-motivo').value = '';
  document.getElementById('can-error').style.display = 'none';
  document.getElementById('form-cancelar').action = `/compras/cancelar/${id}`;
  openModal('modal-cancelar');
}

document.getElementById('form-cancelar').addEventListener('submit', function(e) {
  const motivo = document.getElementById('can-motivo').value.trim();
  if (!motivo) {
    e.preventDefault();
    const err = document.getElementById('can-error');
    err.textContent = '⚠️ El motivo de cancelación es obligatorio.';
    err.style.display = 'block';
    clearTimeout(err._t);
    err._t = setTimeout(() => { err.style.display = 'none'; }, 4000);
  }
});

/* ── Modal: Nueva unidad de compra ── */
let _nuRenglon = null;

function abrirModalNuevaUnidad(n) {
  const matInput = document.getElementById('imat-' + n);
  if (!matInput || !matInput.value) {
    mostrarErrorForm('⚠️ Primero selecciona una materia prima en esa fila antes de agregar una unidad.');
    return;
  }
  _nuRenglon = n;
  const mat = MATERIAS[matInput.value];
  document.getElementById('nu-materia-nombre').textContent = mat ? `${mat.nombre} (${mat.unidad_base})` : '';
  document.getElementById('nu-hint').textContent = `Cuántas ${mat?.unidad_base || 'unidades base'} equivale 1 de esta unidad.`;
  document.getElementById('nu-nombre').value  = '';
  document.getElementById('nu-simbolo').value = '';
  document.getElementById('nu-factor').value  = '';
  document.getElementById('nu-uso').value     = 'compra';
  document.getElementById('nu-error').style.display = 'none';
  openModal('modal-nueva-unidad');
}

function guardarNuevaUnidad() {
  const err     = document.getElementById('nu-error');
  err.style.display = 'none';
  const nombre  = document.getElementById('nu-nombre').value.trim();
  const simbolo = document.getElementById('nu-simbolo').value.trim();
  const factor  = document.getElementById('nu-factor').value.trim();
  const uso     = document.getElementById('nu-uso').value;

  function _nuErr(msg) {
    err.textContent = msg; err.style.display = 'block';
    clearTimeout(err._t); err._t = setTimeout(() => { err.style.display = 'none'; }, 4000);
  }
  if (!nombre || !simbolo || !factor) { _nuErr('⚠️ Nombre, símbolo y factor son obligatorios.'); return; }
  if (parseFloat(factor) <= 0)        { _nuErr('⚠️ El factor debe ser mayor a 0.');              return; }

  const n        = _nuRenglon;
  const matInput = document.getElementById('imat-' + n);
  const btn      = document.getElementById('nu-guardar-btn');
  btn.disabled = true;
  btn.textContent = '⏳ Guardando…';

  fetch('/compras/api/unidades/nueva', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRFToken': CSRF_TOKEN },
    body: JSON.stringify({ id_materia: matInput.value, nombre, simbolo, factor_a_base: parseFloat(factor), uso }),
  })
  .then(r => r.json().then(d => ({ ok: r.ok, data: d })))
  .then(({ ok, data }) => {
    btn.disabled = false; btn.textContent = '💾 Guardar Unidad';
    if (!ok) { _nuErr('⚠️ ' + (data.error || 'Error al guardar.')); return; }
    const uSel = document.getElementById('usel-' + n);
    const opt  = document.createElement('option');
    opt.value           = data.id;
    opt.dataset.factor  = data.factor_a_base;
    opt.dataset.simbolo = data.simbolo;
    opt.textContent     = `${data.nombre} (×${data.factor_a_base})`;
    uSel.appendChild(opt);
    uSel.value = data.id;
    onUnidadCambio(n);
    closeModal('modal-nueva-unidad');
    const msgEl = document.getElementById('form-error');
    msgEl.style.background  = '#e2eede';
    msgEl.style.color       = '#3a6034';
    msgEl.style.borderColor = '#b2d4aa';
    msgEl.textContent       = `✅ Unidad "${data.nombre}" agregada correctamente.`;
    msgEl.style.display     = 'block';
    setTimeout(() => { msgEl.style.display='none'; msgEl.style.background=''; msgEl.style.color=''; msgEl.style.borderColor=''; }, 4000);
  })
  .catch(() => {
    btn.disabled = false; btn.textContent = '💾 Guardar Unidad';
    _nuErr('⚠️ Error de red al guardar.');
  });
}

/* ── Filtro de tabla ── */
function filterTable() {
  const q       = document.getElementById('searchInput').value.toLowerCase();
  const prov    = document.getElementById('filterProv').value.toLowerCase();
  const estatus = document.getElementById('filterEstatus').value;
  const desde   = document.getElementById('filterDesde').value;
  const hasta   = document.getElementById('filterHasta').value;
  const rows    = document.querySelectorAll('#comprasTable tbody tr');
  let visible   = 0;
  rows.forEach(row => {
    const text   = row.textContent.toLowerCase();
    const rProv  = row.dataset.prov   || '';
    const rEst   = row.dataset.estatus || '';
    const rFecha = row.dataset.fecha   || '';
    const show = (!q       || text.includes(q))
              && (!prov    || rProv.includes(prov))
              && (!estatus || rEst === estatus)
              && (!desde   || rFecha >= desde)
              && (!hasta   || rFecha <= hasta);
    row.style.display = show ? '' : 'none';
    if (show) visible++;
  });
  document.getElementById('visibleCount').textContent = visible;
}
