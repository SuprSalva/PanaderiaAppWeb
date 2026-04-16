const PRODS = JSON.parse(document.getElementById('data-productos').textContent);
const STOCK_MAP = {};
PRODS.forEach(p => { STOCK_MAP[p.id] = p.stock; });

const carrito = {};
let filtroActivo = 'todos', busqueda = '', ordenActivo = '';

/* ── Drawer ─────────────────────────────────────────────────── */
function abrirDrawer(){
  document.getElementById('txDrawer').classList.add('open');
  document.getElementById('txOverlay').classList.add('open');
  document.body.style.overflow = 'hidden';
  actualizarModo();
}
function cerrarDrawer(){
  document.getElementById('txDrawer').classList.remove('open');
  document.getElementById('txOverlay').classList.remove('open');
  document.body.style.overflow = '';
}
document.addEventListener('keydown', e => { if(e.key === 'Escape') cerrarDrawer(); });

/* ── Pago ───────────────────────────────────────────────────── */
function seleccionarPago(m){
  ['efectivo','tarjeta','transferencia'].forEach(x =>
    document.getElementById('pago-'+x).classList.remove('active'));
  document.getElementById('pago-'+m).classList.add('active');
  document.getElementById('hMetodoPago').value = m;
  document.getElementById('pagoTexto').textContent = m;
}

/* ── Carrito ─────────────────────────────────────────────────── */
function agregarProducto(id, precio, nombre, imgUrl){
  carrito[id] = { id, nombre, imagen_url: imgUrl, precio, qty: 1 };
  document.getElementById('addBtn-'+id).style.display = 'none';
  document.getElementById('step-'+id).style.display   = 'flex';
  document.getElementById('qty-'+id).textContent      = '1';
  document.getElementById('txcard-'+id).classList.add('en-carrito');
  renderCarrito();
  actualizarModo();
  const fab = document.getElementById('fabCarrito');
  fab.style.transform = 'translateY(-4px) scale(1.07)';
  setTimeout(() => fab.style.transform = '', 240);
}

function cambiarQty(id, delta){
  if(!carrito[id]) return;
  const nuevo = carrito[id].qty + delta;
  if(nuevo <= 0){
    delete carrito[id];
    document.getElementById('step-'+id).style.display   = 'none';
    document.getElementById('addBtn-'+id).style.display = 'inline-flex';
    document.getElementById('qty-'+id).textContent      = '0';
    document.getElementById('txcard-'+id).classList.remove('en-carrito');
  } else {
    carrito[id].qty = nuevo;
    document.getElementById('qty-'+id).textContent = nuevo;
  }
  renderCarrito();
  actualizarModo();
}

function quitarDelCarrito(id){
  delete carrito[id];
  const s = document.getElementById('step-'+id);    if(s) s.style.display   = 'none';
  const b = document.getElementById('addBtn-'+id);  if(b) b.style.display   = 'inline-flex';
  const q = document.getElementById('qty-'+id);     if(q) q.textContent     = '0';
  const c = document.getElementById('txcard-'+id);  if(c) c.classList.remove('en-carrito');
  renderCarrito();
  actualizarModo();
}

function renderCarrito(){
  const items = Object.values(carrito);
  const total = items.reduce((s, i) => s + i.precio * i.qty, 0);
  const qty   = items.reduce((s, i) => s + i.qty, 0);
  document.getElementById('cartQtyBadge').textContent    = qty;
  document.getElementById('cartQtyBadge').style.display  = qty > 0 ? 'inline-block' : 'none';
  document.getElementById('fabQty').textContent          = qty;
  document.getElementById('fabQty').style.display        = qty > 0 ? 'inline-block' : 'none';
  document.getElementById('fabTotal').textContent        = qty > 0 ? '$'+total.toFixed(2)+' · Ver pedido' : 'Ver pedido';
  document.getElementById('hCarrito').value              = JSON.stringify(items.map(i => ({id:i.id,qty:i.qty,precio:i.precio})));
  document.getElementById('cartTotal').textContent       = '$'+total.toFixed(2);

  const body = document.getElementById('cartBody');
  if(!items.length){
    body.innerHTML = `<div class="tx-cart-empty"><div class="ico">🛒</div>
      <p>Tu carrito está vacío.<br>Elige un pan del catálogo para empezar.</p></div>`;
    return;
  }
  body.innerHTML = items.map(i => `
    <div class="tx-cart-item">
      <div class="tx-cart-thumb">${i.imagen_url
        ? `<img src="/static/${i.imagen_url}" alt="${i.nombre}"
                onerror="this.style.display='none';this.parentElement.textContent='🥐';">`
        : '🥐'}</div>
      <div class="tx-cart-info">
        <div class="tx-cart-name">${i.nombre}</div>
        <div class="tx-cart-sub">${i.qty} pza${i.qty>1?'s':''} × $${i.precio.toFixed(2)}</div>
      </div>
      <span class="tx-cart-price">$${(i.qty*i.precio).toFixed(2)}</span>
      <button type="button" class="tx-cart-remove" onclick="quitarDelCarrito(${i.id})">✕</button>
    </div>`).join('');
}

/* ══════════════════════════════════════════════════════════════
   LÓGICA DE MODO
   - Si hay stock para todo el carrito → min fecha = HOY
     El cliente puede elegir hoy mismo O mañana O cualquier día.
   - Si falta stock en alguno → min fecha = +24h (solo futuro)
   - es_inmediato se determina dinámicamente: fecha elegida = hoy
   ══════════════════════════════════════════════════════════════ */

function todosConStock(){
  return Object.entries(carrito).every(([id, item]) => {
    const s = STOCK_MAP[parseInt(id)];
    return typeof s === 'number' && s >= item.qty;
  });
}

function hoyISO(){
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
}

function actualizarModo(){
  const hayCart  = Object.keys(carrito).length > 0;
  const conStock = hayCart && todosConStock();

  document.getElementById('modoBanner').style.display  = hayCart ? 'flex' : 'none';
  document.getElementById('seccionFecha').style.display = hayCart ? 'block' : 'none';

  if(!hayCart){ actualizarBtn(); return; }

  const fechaInput = document.getElementById('uiFecha');
  const fechaActual = fechaInput.value;

  if(conStock){
    // Con stock: puede pedir para HOY o para cuando quiera
    document.getElementById('modoBanner').className  = 'tx-modo-banner tx-modo-inmediato';
    document.getElementById('modoIco').textContent   = '';
    document.getElementById('modoBannerTitulo').textContent = 'Todo disponible en tienda';
    document.getElementById('modoBannerDesc').textContent   =
      'Puedes recoger hoy o elegir cualquier otro día.';
    document.getElementById('labelFecha').textContent = '¿Cuándo quieres recoger?';
    fechaInput.min = hoyISO();   // ← permite seleccionar hoy
  } else {
    // Sin stock completo: mínimo 24h
    document.getElementById('modoBanner').className  = 'tx-modo-banner tx-modo-futuro';
    document.getElementById('modoIco').textContent   = '';
    document.getElementById('modoBannerTitulo').textContent = 'Pedido por encargo';
    document.getElementById('modoBannerDesc').textContent   =
      'Algunos productos se prepararán especialmente. Se requieren mínimo 24 h de anticipación.';
    document.getElementById('labelFecha').textContent = 'Fecha de recogida (+24 h mínimo)';
    const min24 = new Date(); min24.setHours(min24.getHours() + 24);
    const min24ISO = `${min24.getFullYear()}-${String(min24.getMonth()+1).padStart(2,'0')}-${String(min24.getDate()).padStart(2,'0')}`;
    fechaInput.min = min24ISO;
    // Si ya tenían hoy seleccionado, limpiar
    if(fechaActual && fechaActual < min24ISO){
      fechaInput.value = '';
      document.getElementById('hFecha').value = '';
      document.getElementById('hHora').value  = '';
    }
  }

  poblarHoras(conStock);
  onFechaChange();
}

function poblarHoras(conStock){
  const fechaInput = document.getElementById('uiFecha');
  const sel        = document.getElementById('uiHora');
  const fechaSel   = fechaInput.value;
  const esHoy      = fechaSel === hoyISO();
  const prevVal    = sel.value;

  sel.innerHTML = '<option value="">— Hora —</option>';

  // Si es hoy y hay stock: empezar desde próxima hora disponible (+30 min)
  // En cualquier otro caso: todas las horas de 9 a 21
  let horaMin = 9;
  if(esHoy && conStock){
    const ahora = new Date();
    horaMin = ahora.getHours() + (ahora.getMinutes() >= 30 ? 2 : 1);
    horaMin = Math.max(9, horaMin);
  }

  for(let h = horaMin; h <= 21; h++){
    const opt  = document.createElement('option');
    const hh   = String(h).padStart(2, '0');
    opt.value  = `${hh}:00`;
    const h12  = h > 12 ? h - 12 : (h === 0 ? 12 : h);
    opt.textContent = `${h12}:00 ${h >= 12 ? 'PM' : 'AM'}`;
    sel.appendChild(opt);
  }

  if(sel.options.length === 1){
    // No hay horarios disponibles hoy — sugerir mañana
    sel.innerHTML = '<option value="">Sin horarios disponibles hoy</option>';
    if(esHoy){
      const manana = new Date(); manana.setDate(manana.getDate() + 1);
      fechaInput.value = `${manana.getFullYear()}-${String(manana.getMonth()+1).padStart(2,'0')}-${String(manana.getDate()).padStart(2,'0')}`;
      poblarHoras(conStock);
    }
    return;
  }

  // Restaurar selección previa si sigue siendo válida
  if(prevVal && [...sel.options].some(o => o.value === prevVal)) sel.value = prevVal;
}

function onFechaChange(){
  const conStock = todosConStock();
  poblarHoras(conStock);

  const fecha  = document.getElementById('uiFecha').value;
  const hora   = document.getElementById('uiHora').value;
  const warn   = document.getElementById('fechaWarn');
  warn.style.display = 'none';

  // Limpiar campos ocultos primero
  document.getElementById('hFecha').value = '';
  document.getElementById('hHora').value  = '';
  document.getElementById('hEsInmediato').value = '0';

  if(!fecha || !hora){ actualizarBtn(); return; }

  const esHoy  = fecha === hoyISO();
  const selDt  = new Date(`${fecha}T${hora}:00`);
  const ahora  = new Date();
  let valido   = true;

  if(esHoy && conStock){
    // Compra del día: solo verificar que la hora no haya pasado
    if(selDt <= ahora){
      warn.style.display = 'block';
      warn.textContent   = '⚠️ Esa hora ya pasó. Elige una hora disponible.';
      valido = false;
    }
  } else {
    // Pedido futuro: mínimo 24h desde ahora
    const minDt = new Date(); minDt.setHours(minDt.getHours() + 24);
    if(selDt < minDt){
      warn.style.display = 'block';
      warn.textContent   = '⚠️ Elige una fecha con al menos 24 h de anticipación.';
      valido = false;
    }
  }

  if(valido){
    document.getElementById('hFecha').value        = fecha;
    document.getElementById('hHora').value         = hora;
    // es_inmediato = 1 solo si la fecha es hoy Y hay stock suficiente
    document.getElementById('hEsInmediato').value  = (esHoy && conStock) ? '1' : '0';
  }
  actualizarBtn();
}

function actualizarBtn(){
  const hayCart = Object.keys(carrito).length > 0;
  const fecha   = document.getElementById('hFecha').value;
  const hora    = document.getElementById('hHora').value;
  document.getElementById('btnConfirmar').disabled = !(hayCart && fecha && hora);
}

function confirmarPedido(){
  if(!Object.keys(carrito).length){
    window.DM && window.DM.toast('Tu carrito está vacío.', 'warning'); return;
  }
  const fecha = document.getElementById('hFecha').value;
  const hora  = document.getElementById('hHora').value;
  if(!fecha || !hora){
    window.DM && window.DM.toast('Selecciona fecha y hora de recogida.', 'warning'); return;
  }
  document.getElementById('btnConfirmar').disabled  = true;
  document.getElementById('btnConfirmar').innerHTML = '⏳ Enviando…';
  document.getElementById('formPedido').submit();
}

/* ── Filtros del catálogo ───────────────────────────────────── */
function setFiltro(filtro, btn){
  filtroActivo = filtro;
  document.querySelectorAll('.tx-chip').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  aplicarFiltros();
}
function setOrden(o){ ordenActivo = o; aplicarFiltros(); }
function filtrar(q){ busqueda = q.toLowerCase(); aplicarFiltros(); }

function aplicarFiltros(){
  const grid  = document.getElementById('txGrid');
  const cards = Array.from(grid.querySelectorAll('.tx-card'));
  if(ordenActivo === 'precio-asc')
    cards.sort((a,b) => parseFloat(a.dataset.precio) - parseFloat(b.dataset.precio));
  else if(ordenActivo === 'precio-desc')
    cards.sort((a,b) => parseFloat(b.dataset.precio) - parseFloat(a.dataset.precio));
  else if(ordenActivo === 'nombre')
    cards.sort((a,b) => a.dataset.name.localeCompare(b.dataset.name));
  cards.forEach(c => grid.appendChild(c));
  let visible = 0;
  cards.forEach(card => {
    const nivel   = card.dataset.nivel;
    const nameOk  = card.dataset.name.includes(busqueda);
    const filtroOk = filtroActivo === 'todos'
      || (filtroActivo === 'disponibles' && nivel !== 'agotado')
      || (filtroActivo === 'encargo'     && nivel === 'agotado');
    const show = nameOk && filtroOk;
    card.style.display = show ? '' : 'none';
    if(show) visible++;
  });
  document.getElementById('txEmpty').style.display =
    visible === 0 ? 'grid' : 'none';
  document.getElementById('txCount').textContent =
    `${visible} producto${visible!==1?'s':''} encontrado${visible!==1?'s':''}`;
}

/* ── Init ────────────────────────────────────────────────────── */
aplicarFiltros();
renderCarrito();
actualizarModo();
