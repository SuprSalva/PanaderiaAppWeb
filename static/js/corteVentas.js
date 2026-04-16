'use strict';
  // ── Refs ─────────────────────────────────────────────────
  const inputFecha    = document.getElementById('inputFecha');
  const btnBuscar     = document.getElementById('btnBuscar');
  const btnGenerar    = document.getElementById('btnGenerar');
  const btnImprimir   = document.getElementById('btnImprimir');
  const bannerFecha   = document.getElementById('bannerFecha');
  const bannerMonto   = document.getElementById('bannerMonto');
  const bannerDot     = document.getElementById('bannerDot');
  const bannerEstText = document.getElementById('bannerEstadoText');
  const estBadge      = document.getElementById('corteEstadoBadge');

  const tablaEstado   = document.getElementById('tablaEstado');
  const tablaWrap     = document.getElementById('tablaWrap');
  const bodyTrans     = document.getElementById('bodyTransacciones');
  const footPiezas    = document.getElementById('footPiezas');
  const footTotal     = document.getElementById('footTotal');
  const labelFechaTabla = document.getElementById('labelFechaTabla');

  const kpiVentas     = document.getElementById('kpiVentas');
  const kpiPiezas     = document.getElementById('kpiPiezas');
  const kpiEfectivo   = document.getElementById('kpiEfectivo');
  const kpiTarjeta    = document.getElementById('kpiTarjeta');
  const kpiCancelaciones = document.getElementById('kpiCancelaciones');
  const topProductos  = document.getElementById('topProductos');

  // Refs del Modal
  const modalConfirmacion = document.getElementById('modalConfirmacion');
  const modalConfirmacionText = document.getElementById('modalConfirmacionText');
  const btnModalCancelar = document.getElementById('btnModalCancelar');
  const btnModalConfirmar = document.getElementById('btnModalConfirmar');

  // Print area
  const prFecha  = document.getElementById('prFecha');
  const prKpis   = document.getElementById('prKpis');
  const prBody   = document.getElementById('prBody');
  const prFooter = document.getElementById('prFooter');

  const CSRF = document.querySelector('meta[name="csrf-token"]')
    ? document.querySelector('meta[name="csrf-token"]').getAttribute('content') : '';

  let _datos = null;   // último payload cargado
  let fechaPendiente = null; // Guardará la fecha mientras el usuario decide en el modal

  // ── Helpers ──────────────────────────────────────────────
  function fmt$(n) {
    return '$' + Number(n || 0).toLocaleString('es-MX', {
      minimumFractionDigits: 2, maximumFractionDigits: 2
    });
  }

  function labelFecha(iso) {
    if (!iso) return '';
    const [y, m, d] = iso.split('-');
    const M = ['enero','febrero','marzo','abril','mayo','junio',
               'julio','agosto','septiembre','octubre','noviembre','diciembre'];
    return `${parseInt(d)} de ${M[+m-1]} de ${y}`;
  }

  function toast(msg, tipo) {
    if (window.DM && window.DM.toast) { window.DM.toast(msg, tipo); }
    else { alert(msg); }
  }

  // ── Render KPIs ───────────────────────────────────────────
  function renderKpis(k) {
    bannerMonto.textContent      = fmt$(k.total_vendido);
    kpiVentas.textContent        = k.num_ventas;
    kpiPiezas.textContent        = k.total_piezas;
    kpiEfectivo.textContent      = fmt$(k.efectivo);
    kpiTarjeta.textContent       = fmt$(k.tarjeta);
    kpiCancelaciones.textContent = k.cancelaciones;
  }

  // ── Render banner estado ──────────────────────────────────
  function renderBannerEstado(fecha, corte) {
    bannerFecha.textContent = labelFecha(fecha);
    if (!corte) {
      bannerDot.className       = 'dot';
      bannerEstText.textContent = 'Abierto — sin corte generado';
      estBadge.innerHTML        = '';
      btnGenerar.disabled       = false;
    } else if (corte.estado === 'cerrado') {
      bannerDot.className       = 'dot closed';
      bannerEstText.textContent = `Cerrado · ${corte.cerrado_en}`;
      estBadge.innerHTML = `<span class="corte-cerrado-badge">🔒 Corte cerrado por ${corte.cerrado_por_nombre}</span>`;
      btnGenerar.disabled       = true;
    } else {
      bannerDot.className       = 'dot';
      bannerEstText.textContent = 'Abierto';
      estBadge.innerHTML        = '';
      btnGenerar.disabled       = false;
    }
  }

  // ── Render tabla de transacciones ────────────────────────
  function renderTabla(ventas) {
    if (!ventas || ventas.length === 0) {
      tablaWrap.style.display  = 'none';
      tablaEstado.style.display = 'flex';
      tablaEstado.innerHTML = `<span class="ico">🗒️</span><p>No hay transacciones para este día.</p>`;
      footPiezas.textContent = '—';
      footTotal.textContent  = '—';
      return;
    }
    tablaEstado.style.display = 'none';
    tablaWrap.style.display   = 'block';

    let sumPiezas = 0, sumTotal = 0;
    bodyTrans.innerHTML = ventas.map(v => {
      const ok = v.estado === 'completada';
      if (ok) { sumPiezas += v.total_piezas; sumTotal += v.total; }
      return `<tr>
        <td><span class="folio-tag">${v.folio}</span></td>
        <td><span class="badge badge-${v.origen}">${v.origen === 'caja' ? '🛒 Caja' : '🌐 Web'}</span></td>
        <td>${v.hora}</td>
        <td><span class="badge badge-${v.metodo_pago}">${v.metodo_pago}</span></td>
        <td>${ok ? v.total_piezas : '—'}</td>
        <td class="text-right">${ok ? fmt$(v.total) : `<s style="color:#aaa">${fmt$(v.total)}</s>`}</td>
        <td><span class="badge badge-${v.estado}">${v.estado}</span></td>
        <td style="font-size:12px;color:var(--brown-lt);">${v.vendedor}</td>
      </tr>`;
    }).join('');

    footPiezas.textContent = sumPiezas;
    footTotal.textContent  = fmt$(sumTotal);
  }

  // ── Render top productos ──────────────────────────────────
  function renderTop(productos) {
    if (!productos || productos.length === 0) {
      topProductos.innerHTML = `<div class="empty-state" style="padding:.75rem;"><span class="ico" style="font-size:1.2rem;">🥐</span><p>Sin ventas.</p></div>`;
      return;
    }
    topProductos.innerHTML = productos.map((p, i) => `
      <div class="top-item">
        <span class="top-rank${i === 0 ? ' gold' : ''}">${i + 1}</span>
        <span class="top-name">${p.producto}</span>
        <span class="top-qty">${p.piezas_vendidas} pzs</span>
        <span class="top-total">${fmt$(p.total_generado)}</span>
      </div>`).join('');
  }

  // ── Preparar datos de impresión ───────────────────────────
  function prepararPrint(fecha, data) {
    prFecha.textContent = `Fecha: ${labelFecha(fecha)} · Generado: ${new Date().toLocaleString('es-MX')}`;
    const k = data.kpis;
    prKpis.innerHTML = `
      <div class="pr-kpi"><strong>Ventas</strong>${k.num_ventas}</div>
      <div class="pr-kpi"><strong>Total</strong>${fmt$(k.total_vendido)}</div>
      <div class="pr-kpi"><strong>Efectivo</strong>${fmt$(k.efectivo)}</div>
      <div class="pr-kpi"><strong>Tarjeta</strong>${fmt$(k.tarjeta)}</div>
      <div class="pr-kpi"><strong>Transferencia</strong>${fmt$(k.transferencia)}</div>
      <div class="pr-kpi"><strong>Piezas</strong>${k.total_piezas}</div>
      <div class="pr-kpi"><strong>Cancelaciones</strong>${k.cancelaciones}</div>`;
    prBody.innerHTML = (data.ventas || []).map(v => `
      <tr>
        <td>${v.folio}</td><td>${v.origen}</td><td>${v.hora}</td>
        <td>${v.metodo_pago}</td><td>${v.total_piezas}</td>
        <td>${fmt$(v.total)}</td><td>${v.estado}</td>
      </tr>`).join('');
    prFooter.textContent = 'Dulce Migaja · Sistema de Gestión';
  }

  // ── Cargar datos del día ──────────────────────────────────
  function cargarResumen(fecha) {
    tablaEstado.style.display = 'flex';
    tablaEstado.innerHTML     = '<div class="spinner-row">Cargando...</div>';
    tablaWrap.style.display   = 'none';
    topProductos.innerHTML    = '<div class="spinner-row">Cargando...</div>';
    estBadge.innerHTML        = '';
    btnGenerar.disabled       = false;

    fetch(`/ventas/api/corte-ventas/resumen?fecha=${encodeURIComponent(fecha)}`, {
      headers: { 'X-CSRFToken': CSRF }
    })
      .then(r => r.json())
      .then(data => {
        if (!data.ok) { toast(data.error || 'Error al consultar.', 'error'); return; }
        _datos = data;
        labelFechaTabla.textContent = labelFecha(fecha);
        renderKpis(data.kpis);
        renderBannerEstado(fecha, data.corte);
        renderTabla(data.ventas);
        renderTop(data.productos);
        prepararPrint(fecha, data);
      })
      .catch(() => toast('Error de conexión.', 'error'));
  }

  // ── 1. Función para ABRIR el modal ──
  function preguntarGenerarCorte() {
    const fecha = inputFecha.value;
    if (!fecha) { toast('Selecciona una fecha.', 'warning'); return; }

    fechaPendiente = fecha;
    modalConfirmacionText.innerHTML = `¿Generar corte del día <strong>${labelFecha(fecha)}</strong>?`;
    modalConfirmacion.style.display = 'flex';
  }

  // ── 2. Función para EJECUTAR la acción (Generar Corte) ──
  function ejecutarGenerarCorte() {
    modalConfirmacion.style.display = 'none'; // Ocultar el modal
    const fecha = fechaPendiente;
    if (!fecha) return;

    btnGenerar.disabled      = true;
    btnGenerar.textContent   = 'Generando...';

    const fd = new FormData();
    fd.append('fecha', fecha);

    fetch('/ventas/api/corte-ventas/generar', {
      method: 'POST',
      headers: { 'X-CSRFToken': CSRF },
      body: fd
    })
      .then(r => r.json())
      .then(data => {
        toast(data.mensaje, data.ok ? 'success' : 'error');
        if (data.ok) cargarResumen(fecha);
        else { btnGenerar.disabled = false; }
      })
      .catch(() => {
        toast('Error de conexión.', 'error');
        btnGenerar.disabled = false;
      })
      .finally(() => { 
        btnGenerar.textContent = '✔ Generar Corte'; 
        fechaPendiente = null; // Limpiar variable
      });
  }

  // ── Eventos ───────────────────────────────────────────────
  
  // Controles principales
  btnBuscar.addEventListener('click',  () => { if (inputFecha.value) cargarResumen(inputFecha.value); });
  inputFecha.addEventListener('keydown', e => { if (e.key === 'Enter') btnBuscar.click(); });
  
  // Asignar el evento para abrir el modal al botón "Generar Corte"
  btnGenerar.addEventListener('click', preguntarGenerarCorte);
  
  btnImprimir.addEventListener('click', () => {
    if (!_datos) { toast('Consulta un día primero.', 'warning'); return; }
    window.print();
  });

  // Eventos del Modal
  btnModalCancelar.addEventListener('click', () => {
    modalConfirmacion.style.display = 'none';
    fechaPendiente = null;
  });
  
  btnModalConfirmar.addEventListener('click', ejecutarGenerarCorte);

  // Carga automática con la fecha de hoy al abrir la página
  if (inputFecha && inputFecha.value) cargarResumen(inputFecha.value);
