  function openModal(id)  { document.getElementById(id).classList.add('open'); }
  function closeModal(id) { document.getElementById(id).classList.remove('open'); }
  document.querySelectorAll('.modal-overlay').forEach(el => {
    el.addEventListener('click', e => { if (e.target === el) el.classList.remove('open'); });
  });

  // Fecha por defecto = hoy
  document.addEventListener('DOMContentLoaded', () => {
    const today = new Date().toISOString().split('T')[0];
    const af = document.getElementById('add-fecha');
    if (af) af.value = today;
  });

  function abrirNuevaSalida() {
    const form = document.getElementById('form-nueva-salida');
    if (form) form.reset();

    const today = new Date().toISOString().split('T')[0];
    const af = document.getElementById('add-fecha');
    if (af) af.value = today;

    const btn = document.getElementById('btn-registrar');
    if (btn) {
      btn.disabled = false;
      btn.innerHTML = '<animated-icons src="/static/icons/save-0c38d9a8.json" trigger="loop" attributes=\'{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#FFFFFF","background":"#FFFFFF"}}\' height="22" width="22"></animated-icons> Registrar Salida';
    }

    const err = document.getElementById('salida-form-error');
    if (err) err.style.display = 'none';

    openModal('modal-add');
  }

  function openAprobacionBtn(btn) {
    document.getElementById('aprov-folio').textContent = 'Folio ' + btn.dataset.folio;
    document.getElementById('aprov-desc').textContent  = btn.dataset.desc;
    document.getElementById('aprov-monto').textContent = '−$' + parseFloat(btn.dataset.monto).toFixed(2);
    document.getElementById('form-aprobacion').action  = '/salida-efectivo/aprobar/' + btn.dataset.id;
    openModal('modal-aprobacion');
  }

  const CAT_LABELS = {
    compra_insumos:      '🛒 Compra de Insumos',
    servicios_utilities: '⚡ Servicios / Utilities',
    mantenimiento:       '🔧 Mantenimiento',
    otros:               '📦 Otros',
  };
  const ESTADO_LABELS = { aprobada: '✅ Aprobada', pendiente: '⏳ Pendiente', rechazada: '🚫 Rechazada' };

  function openDetalleRow(row) {
    const d = row.dataset;
    document.getElementById('det-folio').textContent     = d.folio;
    document.getElementById('det-desc').textContent      = d.desc;
    document.getElementById('det-cat').textContent       = CAT_LABELS[d.cat]  || d.cat;
    document.getElementById('det-monto').textContent     = '−$' + parseFloat(d.monto).toFixed(2);
    document.getElementById('det-fecha').textContent     = d.fecha;
    document.getElementById('det-user').textContent      = d.registrador;
    document.getElementById('det-proveedor').textContent = d.proveedor || '—';
    document.getElementById('det-aprobador').textContent = d.aprobador || '—';
    const resolucionWrap = document.getElementById('det-fecha-resolucion-wrap');
    if ((d.estado === 'aprobada' || d.estado === 'rechazada') && d.actualizado) {
      document.getElementById('det-fecha-resolucion').textContent = d.actualizado;
      resolucionWrap.style.display = '';
    } else {
      resolucionWrap.style.display = 'none';
    }
    const estadoEl = document.getElementById('det-estado');
    estadoEl.textContent = ESTADO_LABELS[d.estado] || d.estado;
    estadoEl.style.color = d.estado === 'aprobada' ? '#3a6034' : d.estado === 'pendiente' ? '#8a6200' : '#888';
    const compraWrap = document.getElementById('det-compra-wrap');
    if (d.folioCompra) {
      document.getElementById('det-folio-compra').textContent = d.folioCompra;
      compraWrap.style.display = '';
    } else {
      compraWrap.style.display = 'none';
    }
    openModal('modal-detalle');
  }

  function mostrarErrorSalida(msg) {
    const el = document.getElementById('salida-form-error');
    el.textContent = msg;
    el.style.display = 'block';
    clearTimeout(el._t);
    el._t = setTimeout(() => { el.style.display = 'none'; }, 4000);
  }

  document.getElementById('form-nueva-salida').addEventListener('submit', function(e) {
    document.getElementById('salida-form-error').style.display = 'none';
    const desc  = this.querySelector('input[name="descripcion"]').value.trim();
    const cat   = this.querySelector('select[name="categoria"]').value;
    const fecha = this.querySelector('input[name="fecha_salida"]').value;
    const monto = parseFloat(this.querySelector('input[name="monto"]').value);

    if (!desc) {
      e.preventDefault(); mostrarErrorSalida('⚠️ La descripción es obligatoria.'); return;
    }
    if (!cat) {
      e.preventDefault(); mostrarErrorSalida('⚠️ Selecciona una categoría.'); return;
    }
    if (!fecha) {
      e.preventDefault(); mostrarErrorSalida('⚠️ La fecha es obligatoria.'); return;
    }
    if (!monto || monto <= 0) {
      e.preventDefault(); mostrarErrorSalida('⚠️ El monto es obligatorio y debe ser mayor a cero.'); return;
    }
    const btn = this.querySelector('#btn-registrar');
    btn.disabled = true;
    btn.textContent = '⏳ Guardando…';
  });

  function filterTable() {
    const q     = document.getElementById('searchInput').value.toLowerCase();
    const cat   = document.getElementById('filterCat').value;
    const est   = document.getElementById('filterEstado').value;
    const desde = document.getElementById('filterDesde').value;
    const hasta = document.getElementById('filterHasta').value;
    const rows  = document.querySelectorAll('#egresosTable tbody tr');
    let visible = 0;
    rows.forEach(row => {
      const text     = row.textContent.toLowerCase();
      const rowCat   = row.dataset.cat    || '';
      const rowEst   = row.dataset.estado || '';
      const rowFecha = String(row.dataset.fecha || '');
      const show = (!q     || text.includes(q))
                && (!cat   || rowCat   === cat)
                && (!est   || rowEst   === est)
                && (!desde || rowFecha >= desde)
                && (!hasta || rowFecha <= hasta);
      row.style.display = show ? '' : 'none';
      if (show) visible++;
    });
    document.getElementById('visibleCount').textContent = visible;
  }
