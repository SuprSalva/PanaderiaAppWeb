'use strict';
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
  const kpiTransferencia = document.getElementById('kpiTransferencia');
  const kpiCancelaciones = document.getElementById('kpiCancelaciones');
  const topProductos  = document.getElementById('topProductos');

  const modalConfirmacion = document.getElementById('modalConfirmacion');
  const modalConfirmacionText = document.getElementById('modalConfirmacionText');
  const btnModalCancelar = document.getElementById('btnModalCancelar');
  const btnModalConfirmar = document.getElementById('btnModalConfirmar');

  const prFecha  = document.getElementById('prFecha');
  const prKpis   = document.getElementById('prKpis');
  const prBody   = document.getElementById('prBody');
  const prFooter = document.getElementById('prFooter');

  const CSRF = document.querySelector('meta[name="csrf-token"]')
    ? document.querySelector('meta[name="csrf-token"]').getAttribute('content') : '';

  let _datos = null; 
  let fechaPendiente = null; 

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

  function renderKpis(k) {
    bannerMonto.textContent      = fmt$(k.total_vendido);
    kpiVentas.textContent        = k.num_ventas;
    kpiPiezas.textContent        = k.total_piezas;
    kpiEfectivo.textContent      = fmt$(k.efectivo);
    kpiTarjeta.textContent       = fmt$(k.tarjeta);
    kpiTransferencia.textContent = fmt$(k.transferencia);
    kpiCancelaciones.textContent = k.cancelaciones;
  }

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

  function renderTabla(ventas) {
    if (!ventas || ventas.length === 0) {
      tablaWrap.style.display  = 'none';
      tablaEstado.style.display = 'flex';
      tablaEstado.innerHTML = `<span class="ico"><animated-icons src="/static/icons/newspaper-b3a68157.json" trigger="loop" attributes='{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#E07A52FF","background":"#FFFFFF"}}' height="36" width="36"></animated-icons></span><p>No hay transacciones para este día.</p>`;
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
      const origenBadge = v.origen === 'caja'
        ? `<span class="badge badge-caja" style="display:inline-flex;align-items:center;gap:4px; font-size:var(--text-base);">Caja</span>`
        : `<span class="badge badge-pedido_web" style="display:inline-flex;align-items:center;gap:4px; font-size:var(--text-base);"> Online</span>`;
      const metodoBadge = {
        efectivo: `<span class="badge badge-efectivo" style="display:inline-flex;align-items:center;gap:4px;">Efectivo</span>`,
        tarjeta: `<span class="badge badge-tarjeta" style="display:inline-flex;align-items:center;gap:4px;">Tarjeta</span>`,
        transferencia: `<span class="badge badge-transferencia" style="display:inline-flex;align-items:center;gap:4px;">Transferencia</span>`
      }[v.metodo_pago] || `<span class="badge badge-otro">${v.metodo_pago}</span>`;
      const estadoBadge = v.estado === 'completada'
        ? `<span class="badge badge-completada" style="display:inline-flex;align-items:center;gap:4px;"><animated-icons src="/static/icons/success-2cb0da6b.json" trigger="loop" attributes='{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#559C27FF","background":"#FFFFFF"}}' height="30" width="30"></animated-icons> Completada</span>`
        : `<span class="badge badge-cancelada" style="display:inline-flex;align-items:center;gap:4px;"><animated-icons src="/static/icons/error-0c38d9a8.json" trigger="loop" attributes='{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#E07A52FF","background":"#FFFFFF"}}' height="30" width="30"></animated-icons> ${v.estado}</span>`;
      return `<tr>
        <td><span class="folio-tag">${v.folio}</span></td>
        <td>${origenBadge}</td>
        <td>${v.hora}</td>
        <td>${metodoBadge}</td>
        <td>${ok ? v.total_piezas : '—'}</td>
        <td class="text-right">${ok ? fmt$(v.total) : `<s style="color:#aaa">${fmt$(v.total)}</s>`}</td>
        <td>${estadoBadge}</td>
        <td style="font-size:var(--text-base);color:var(--brown-lt);">${v.vendedor}</td>
      </tr>`;
    }).join('');

    footPiezas.textContent = sumPiezas;
    footTotal.textContent  = fmt$(sumTotal);
  }

  function renderTop(productos) {
    if (!productos || productos.length === 0) {
      topProductos.innerHTML = `<div class="empty-state" style="padding:.75rem;"><span class="ico" style="font-size:1.2rem;"><animated-icons src="/static/icons/report-v2-1869947d.json" trigger="loop" attributes='{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#E07A52FF","background":"#FFFFFF"}}' height="30" width="30"></animated-icons></span><p>Sin ventas.</p></div>`;
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

  function preguntarGenerarCorte() {
    const fecha = inputFecha.value;
    if (!fecha) { toast('Selecciona una fecha.', 'warning'); return; }

    fechaPendiente = fecha;
    modalConfirmacionText.innerHTML = `¿Generar corte del día <strong>${labelFecha(fecha)}</strong>?`;
    modalConfirmacion.style.display = 'flex';
  }

  function ejecutarGenerarCorte() {
    const montoFisico = document.getElementById('inputEfectivoFisico').value;
    
    if (!montoFisico || parseFloat(montoFisico) < 0) {
      toast('Por favor, ingresa el monto de efectivo físico en caja.', 'warning');
      return;
    }

    const fecha = fechaPendiente;
    btnModalConfirmar.disabled = true;
    modalConfirmacion.style.display = 'none'; 

    const fd = new FormData();
    fd.append('fecha', fecha);
    fd.append('efectivo_declarado', montoFisico); // Enviamos el valor declarado

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
        btnGenerar.textContent = 'Generar Corte'; 
        fechaPendiente = null;
      });
  }

  btnBuscar.addEventListener('click',  () => { if (inputFecha.value) cargarResumen(inputFecha.value); });
  inputFecha.addEventListener('keydown', e => { if (e.key === 'Enter') btnBuscar.click(); });
  
  btnGenerar.addEventListener('click', preguntarGenerarCorte);
  
  btnImprimir.addEventListener('click', () => {
    if (!_datos) { toast('Consulta un día primero.', 'warning'); return; }

    const fecha = inputFecha.value;
    const originalText = btnImprimir.innerHTML;
    
    btnImprimir.innerHTML = 'Generando PDF...';
    btnImprimir.disabled = true;

    const element = document.getElementById('printArea');
    element.style.display = 'block';

    const opt = {
      margin:       10,
      filename:     `Corte_Ventas_DulceMigaja_${fecha}.pdf`,
      image:        { type: 'jpeg', quality: 0.98 },
      html2canvas:  { scale: 2, useCORS: true }, // scale: 2 mejora la calidad del texto
      jsPDF:        { unit: 'mm', format: 'letter', orientation: 'portrait' }
    };

    html2pdf().set(opt).from(element).save().then(() => {
      element.style.display = 'none';
      btnImprimir.innerHTML = originalText;
      btnImprimir.disabled = false;
      toast('PDF exportado correctamente.', 'success');
    }).catch(err => {
      element.style.display = 'none';
      btnImprimir.innerHTML = originalText;
      btnImprimir.disabled = false;
      toast('Hubo un error al generar el PDF.', 'error');
    });
  });

  btnModalCancelar.addEventListener('click', () => {
    modalConfirmacion.style.display = 'none';
    fechaPendiente = null;
  });
  
  btnModalConfirmar.addEventListener('click', ejecutarGenerarCorte);

  document.getElementById('btnExportXls')?.addEventListener('click', () => {
    const fecha = inputFecha.value;
    if (!fecha) { toast('Consulta un día primero.', 'warning'); return; }
    if (!_datos) { toast('Consulta un día primero.', 'warning'); return; }
    window.location.href = `/ventas/api/corte-ventas/exportar-excel?fecha=${encodeURIComponent(fecha)}`;
  });

  if (inputFecha && inputFecha.value) cargarResumen(inputFecha.value);
