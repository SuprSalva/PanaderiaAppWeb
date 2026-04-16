function toast(msg, tipo) {
  const container = document.getElementById('toast-container') || (() => {
    const c = document.createElement('div');
    c.id = 'toast-container';
    c.style.cssText = 'position:fixed;top:18px;right:18px;z-index:9999;display:flex;flex-direction:column;gap:8px;';
    document.body.appendChild(c);
    return c;
  })();
  const colors = {
    'warn':    { bg:'#fef3c7', border:'#fbbf24', text:'#92400e', icon:'⚠️' },
    'error':   { bg:'#fee2e2', border:'#f87171', text:'#991b1b', icon:'⛔' },
    'success': { bg:'#d1fae5', border:'#6ee7b7', text:'#065f46', icon:'✅' },
    'info':    { bg:'#dbeafe', border:'#93c5fd', text:'#1e40af', icon:'ℹ️' },
  };
  const c = colors[tipo] || colors['info'];
  const el = document.createElement('div');
  el.style.cssText = `background:${c.bg};border:1.5px solid ${c.border};color:${c.text};
    border-radius:10px;padding:11px 16px;font-size:13px;font-weight:700;
    max-width:320px;box-shadow:0 4px 16px rgba(0,0,0,.12);
    display:flex;align-items:flex-start;gap:8px;font-family:'Lato',sans-serif;
    animation:slideIn .2s ease;`;
  el.innerHTML = `<span>${c.icon}</span><span style="flex:1">${msg}</span>
    <button onclick="this.parentElement.remove()" style="background:none;border:none;
      cursor:pointer;color:${c.text};font-size:15px;line-height:1;padding:0 0 0 4px;">✕</button>`;
  container.appendChild(el);
  setTimeout(() => el.remove(), 5000);
}

let LINEAS = [], REC_SEL = null, PROD_SEL = null;

window.cerrarModal = id => {
  document.getElementById(id).classList.remove('open');
  document.body.style.overflow = '';
};
const abrirModal = id => {
  document.getElementById(id).classList.add('open');
  document.body.style.overflow = 'hidden';
};
document.querySelectorAll('.modal-bd').forEach(m =>
  m.addEventListener('click', e => {
    if (e.target === m) { m.classList.remove('open'); document.body.style.overflow = ''; }
  })
);

window.abrirModalNueva = () => {
  LINEAS = []; REC_SEL = null; PROD_SEL = null;
  renderLista(); resetBuilder();
  document.getElementById('ins-section').style.display = 'none';
  document.getElementById('chk-plantilla').checked = false;
  document.getElementById('inp-guardar-plant').value = '0';
  document.getElementById('plantilla-nombre-fg').style.display = 'none';
  abrirModal('modalNueva');
};

function resetBuilder() {
  document.getElementById('sel-producto').value = '';
  document.getElementById('recetas-area').className = 'recetas-area';
  document.getElementById('recetas-cards').innerHTML = '';
  REC_SEL = null; PROD_SEL = null;
}

window.filtrarEstado = est => {
  const f = document.getElementById('form-filtro');
  f.querySelector('[name=estado]').value = est;
  f.submit();
};

window.abrirConfirm = (folio, url) => {
  document.getElementById('confirm-folio').textContent = folio;
  document.getElementById('form-confirm-iniciar').action = url;
  abrirModal('modalConfirm');
};

window.onProductoChange = () => {
  const sel  = document.getElementById('sel-producto');
  const area = document.getElementById('recetas-area');
  const cards = document.getElementById('recetas-cards');
  REC_SEL = null; PROD_SEL = null;
  cards.innerHTML = '';
  const pid = parseInt(sel.value);
  if (!pid) { area.className = 'recetas-area'; return; }
  
  // Utiliza el obj window.PRODUCTOS_ARR generado desde Flask
  PROD_SEL = window.PRODUCTOS_ARR.find(p => p.id_producto === pid);
  if (!PROD_SEL) { area.className = 'recetas-area'; return; }
  area.className = 'recetas-area visible';
  PROD_SEL.recetas.forEach(r => {
    const card = document.createElement('div');
    card.className = 'receta-card';
    card.dataset.idReceta = r.id_receta;
    card.innerHTML = `
      <div class="receta-rend">${r.rendimiento}<small>pzas</small></div>
      <div class="receta-info">
        <div class="receta-nombre">${r.nombre}</div>
        <div class="receta-stock">${r.rendimiento} piezas por lote</div>
      </div>
      <div class="receta-sel-icon">✔️</div>`;
    card.addEventListener('click', () => selReceta(r, card));
    cards.appendChild(card);
  });
};

function selReceta(receta, cardEl) {
  REC_SEL = receta;
  document.querySelectorAll('#recetas-cards .receta-card').forEach(c => c.classList.remove('sel'));
  cardEl.classList.add('sel');
}

window.agregarLinea = () => {
  if (!PROD_SEL) { toast('Selecciona un producto.', 'warn'); return; }
  if (!REC_SEL)  { toast('Selecciona una receta/rendimiento.', 'warn'); return; }
  LINEAS.push({
    id_producto: PROD_SEL.id_producto, nombre_prod: PROD_SEL.nombre,
    id_receta: REC_SEL.id_receta, nombre_receta: REC_SEL.nombre,
    cantidad_piezas: REC_SEL.rendimiento,
  });
  renderLista(); resetBuilder();
};

function renderLista() {
  const lista   = document.getElementById('lineas-lista');
  const emptyEl = document.getElementById('empty-lineas');
  const resumEl = document.getElementById('resumen-lbl');
  lista.innerHTML = '';
  if (!LINEAS.length) { emptyEl.style.display='block'; resumEl.textContent=''; return; }
  emptyEl.style.display = 'none';
  LINEAS.forEach((l, idx) => {
    const div = document.createElement('div');
    div.className = 'linea-item';
    div.innerHTML = `
      <div class="linea-item-info">
        <div class="linea-nombre">${l.nombre_prod}</div>
        <div class="linea-receta">${l.nombre_receta}</div>
      </div>
      <div class="linea-badge">${l.cantidad_piezas} pzas</div>
      <button class="linea-del" type="button" onclick="eliminarLinea(${idx})">✕</button>`;
    lista.appendChild(div);
  });
  const totalPzs = LINEAS.reduce((s,l)=>s+l.cantidad_piezas,0);
  resumEl.textContent = `${LINEAS.length} producto(s) · ${totalPzs} piezas`;
}

window.eliminarLinea = idx => { LINEAS.splice(idx,1); renderLista(); };

window.verificarInsumos = async () => {
  if (!LINEAS.length) { toast('Agrega al menos un producto.', 'warn'); return; }
  const items = LINEAS.map(l=>({ id_receta:l.id_receta, piezas:l.cantidad_piezas }));
  const sec=document.getElementById('ins-section');
  const load=document.getElementById('ins-loading');
  const res=document.getElementById('ins-result');
  sec.style.display='block'; load.style.display='block'; res.style.display='none';
  try {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
    const r = await fetch('/produccion-diaria/api/verificar-insumos', {
      method:'POST',
      headers:{'Content-Type':'application/json','X-CSRFToken':csrfToken},
      body:JSON.stringify({items}),
    });
    const d = await r.json();
    load.style.display='none'; res.style.display='block';
    const alertEl=document.getElementById('ins-alerta');
    const okEl=document.getElementById('ins-ok-msg');
    const tbody=document.getElementById('ins-tbody');
    if (!d.ok) { alertEl.style.display='block'; alertEl.textContent='⚠ '+d.mensaje; okEl.style.display='none'; tbody.innerHTML=''; return; }
    if (d.hay_faltantes) {
      alertEl.style.display='block';
      alertEl.innerHTML=`⛔ Stock insuficiente: ${d.insumos_ok} de ${d.total_insumos} insumos OK. Se registrará con alerta.`;
      okEl.style.display='none';
    } else {
      okEl.style.display='block'; okEl.textContent=`✅ Stock suficiente para todos los insumos (${d.total_insumos}).`;
      alertEl.style.display='none';
    }
    tbody.innerHTML=d.insumos.map(ins=>{
      const ok=ins.stock_suficiente; const pct=Math.min(ins.pct_disponible||0,100);
      const col=ok?'#10b981':(pct>=50?'#f59e0b':'#ef4444');
      return \`<tr>
        <td style="font-weight:700;">\${ins.nombre_materia}</td>
        <td style="color:var(--brown-lt);">\${ins.unidad_base}</td>
        <td>\${ins.cantidad_requerida.toFixed(2)}</td>
        <td>\${ins.stock_actual.toFixed(2)}<span class="bar-mini"><span class="bar-fill" style="width:\${pct}%;background:\${col};"></span></span></td>
        <td class="\${ok?'ins-ok':'ins-ko'}">\${ok?'✅ OK':'⛔ Faltan '+(ins.cantidad_requerida-ins.stock_actual).toFixed(2)}</td></tr>\`;
    }).join('');
  } catch(e) {
    load.style.display='none'; res.style.display='block';
    document.getElementById('ins-alerta').style.display='block';
    document.getElementById('ins-alerta').textContent='Error: '+e.message;
  }
};

window.togglePlantillaNombre = checked => {
  document.getElementById('plantilla-nombre-fg').style.display=checked?'flex':'none';
  document.getElementById('inp-guardar-plant').value=checked?'1':'0';
};

window.cargarPlantilla = async (id, nombre) => {
  try {
    const r=await fetch(`/produccion-diaria/api/plantilla/${id}`);
    const d=await r.json();
    if (!d.ok) { toast('Error: '+d.mensaje,'error'); return; }
    LINEAS=d.lineas.map(l=>({
      id_producto:l.id_producto, nombre_prod:l.nombre_producto,
      id_receta:l.id_receta, nombre_receta:l.nombre_receta||'',
      cantidad_piezas:l.cantidad_piezas,
    }));
    renderLista();
    const inpNombre=document.querySelector('[name=nombre]');
    if (!inpNombre.value) inpNombre.value=nombre;
  } catch(e) { toast('Error al cargar plantilla: '+e.message,'error'); }
};

window.prepSubmit = () => {
  if (!LINEAS.length) { toast('Agrega al menos un producto antes de crear la producción.','warn'); return false; }
  document.getElementById('inp-cajas-json').value=JSON.stringify(
    LINEAS.map(l=>({id_producto:l.id_producto,id_receta:l.id_receta,cantidad_piezas:l.cantidad_piezas}))
  );
  return true;
};
