function cerrarModalLista(id) {
  document.getElementById(id).classList.remove('open');
  document.getElementById(id).style.display = 'none';
}
function abrirModalLista(id) {
  var el = document.getElementById(id);
  el.style.display = 'flex';
  el.classList.add('open');
}

function abrirDetalle(folio) {
  document.getElementById('det-lista-folio').textContent = folio;
  var body = document.getElementById('det-lista-body');
  body.innerHTML = '<div style="display:flex;flex-direction:column;align-items:center;justify-content:center;padding:40px;gap:12px;color:var(--brown-lt);"><div style="width:32px;height:32px;border:3px solid var(--tan);border-top-color:var(--brown);border-radius:50%;animation:spinLista .7s linear infinite;"></div><span>Cargando…</span></div>';
  abrirModalLista('mDetalle');

  fetch('/api/' + folio + '/detalle')
    .then(function(r){ return r.json(); })
    .then(function(data){
      if (!data.ok) {
        body.innerHTML = '<p style="padding:20px;color:var(--rust);">Error al cargar el pedido.</p>';
        return;
      }
      var p = data.pedido;
      var rol = window.SESSION_ROL || '';
      var acciones = '';
      if (p.estado === 'pendiente' && (rol === 'admin' || rol === 'empleado')) {
        acciones = '<button class="btn" style="background:#10b981;color:#fff;padding:8px 14px;border-radius:8px;font-size:12px;font-weight:700;border:none;cursor:pointer;" onclick="cerrarModalLista(\'mDetalle\');abrirAprobar(\'' + folio + '\')">✅ Aprobar</button> '
                 + '<button class="btn" style="background:#ef4444;color:#fff;padding:8px 14px;border-radius:8px;font-size:12px;font-weight:700;border:none;cursor:pointer;" onclick="cerrarModalLista(\'mDetalle\');abrirRechazar(\'' + folio + '\')">❌ Rechazar</button> ';
      }

      var itemsRows = (data.items || []).map(function(i){
        return '<tr><td style="font-weight:600;">' + i.producto_nombre + '</td>'
             + '<td style="text-align:right">' + Math.round(i.cantidad) + ' pzas</td>'
             + '<td style="text-align:right">$' + i.precio_unitario.toFixed(2) + '</td>'
             + '<td style="text-align:right;font-weight:700;">$' + i.subtotal.toFixed(2) + '</td></tr>';
      }).join('');

      var estadoLabels = {
        'pendiente':'⏳ Pendiente','aprobado':'✅ Aprobado','en_produccion':'⚙️ En Producción',
        'listo':'🎉 Listo','entregado':'📦 Entregado','rechazado':'❌ Rechazado'
      };

      body.innerHTML = '<div style="padding:20px 22px;display:flex;flex-direction:column;gap:14px;">'
        + '<div class="det-info-grid">'
        + '<div class="det-info-item"><div class="i-lbl">Cliente</div><div class="i-val">' + p.cliente_nombre + '</div></div>'
        + '<div class="det-info-item"><div class="i-lbl">Recolección</div><div class="i-val" style="color:var(--rust);">' + p.fecha_recogida + '</div></div>'
        + '<div class="det-info-item"><div class="i-lbl">Estado</div><div class="i-val"><span class="badge-estado badge-' + p.estado + '">' + (estadoLabels[p.estado] || p.estado) + '</span></div></div>'
        + '<div class="det-info-item"><div class="i-lbl">Total Estimado</div><div class="i-val" style="color:var(--rust);">$' + p.total_estimado.toFixed(2) + '</div></div>'
        + '<div class="det-info-item"><div class="i-lbl">Tipo de Caja</div><div class="i-val">' + p.tipo_caja + '</div></div>'
        + '</div>'
        + (itemsRows ? '<table class="det-items-tbl"><thead><tr><th>Pan</th><th style="text-align:right">Piezas</th><th style="text-align:right">Precio</th><th style="text-align:right">Subtotal</th></tr></thead><tbody>' + itemsRows + '</tbody></table>' : '')
        + (p.motivo_rechazo ? '<div style="padding:10px 14px;background:#fff5f2;border:1px solid var(--rust);border-radius:8px;font-size:12px;color:var(--rust);"><strong>Motivo de rechazo:</strong> ' + p.motivo_rechazo + '</div>' : '')
        + '</div>'
        + '<div style="padding:14px 22px 20px;border-top:1px solid var(--tan);display:flex;justify-content:flex-end;gap:9px;flex-wrap:wrap;">'
        + acciones
        + '<a href="/' + folio + '" class="btn btn-outline" style="font-size:12px;font-weight:700;padding:8px 14px;border-radius:8px;text-decoration:none;color:var(--brown-dk);border:1.5px solid var(--tan);">Ver Completo →</a>'
        + '<button type="button" onclick="cerrarModalLista(\'mDetalle\')" class="btn btn-outline" style="font-size:12px;font-weight:700;padding:8px 14px;border-radius:8px;">Cerrar</button>'
        + '</div>';
    })
    .catch(function(){
      body.innerHTML = '<p style="padding:20px;color:var(--rust);">Error de conexión.</p>';
    });
}

function abrirAprobar(folio) {
  document.getElementById('ap-lista-folio').textContent = folio;
  document.getElementById('form-lista-aprobar').action = '/' + folio + '/aprobar';
  abrirModalLista('mAprobar');
}

function abrirRechazar(folio) {
  document.getElementById('rch-lista-folio').textContent = folio;
  document.getElementById('form-lista-rechazar').action = '/' + folio + '/rechazar';
  abrirModalLista('mRechazar');
}

document.addEventListener('DOMContentLoaded', function(){
  ['mDetalle','mAprobar','mRechazar'].forEach(function(id){
    var el = document.getElementById(id);
    if (el) el.addEventListener('click', function(e){
      if (e.target === this) cerrarModalLista(id);
    });
  });
});
