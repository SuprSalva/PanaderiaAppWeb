  const TAMANIOS  = JSON.parse(document.getElementById('data-tamanios').textContent);
  const PRODUCTOS = JSON.parse(document.getElementById('data-productos').textContent);

  let tamanio = null;   
  let tipo    = null; 
  let slots   = [];     
  let carrito = [];    

  function numSlots() {
    if (!tipo) return 0;
    if (tipo === 'simple') return 1;
    if (tipo === 'mixta')  return 2;
    if (tipo === 'triple') return 3;
    return 0;
  }

  function piezasPorSlot() {
    if (!tamanio || !tipo) return 0;
    return tamanio.capacidad / numSlots();
  }

  function cajaCompleta() {
    return tamanio && tipo && slots.length === numSlots();
  }

  function elegirTamanio(id, capacidad, nombre) {
    tamanio = { id, capacidad, nombre };
    tipo    = null;
    slots   = [];

    document.querySelectorAll('.size-card').forEach(c => c.classList.remove('selected'));
    document.getElementById('scard-' + id).classList.add('selected');
    document.getElementById('paso3').classList.add('hidden');
    document.querySelectorAll('.tipo-card').forEach(c => c.classList.remove('selected'));

    if (capacidad === 4) {
      document.getElementById('paso2').classList.add('hidden');
      tipo = 'simple';
      irPaso3();
      actualizarSteps(2);
    } else {
      const tripleCard = document.getElementById('tcard-triple');
      const tipoGrid   = document.getElementById('tipoGrid');
      tripleCard.classList.toggle('hidden', capacidad !== 12);
      tipoGrid.classList.toggle('tres-opciones', capacidad === 12);
      document.getElementById('paso2').classList.remove('hidden');
      actualizarSteps(1);
    }
    actualizarBtnAgregar();
  }

  function elegirTipo(t) {
    tipo  = t;
    slots = [];
    document.querySelectorAll('.tipo-card').forEach(c => c.classList.remove('selected'));
    document.getElementById('tcard-' + t).classList.add('selected');
    irPaso3();
    actualizarSteps(2);
    actualizarBtnAgregar();
  }

  function irPaso3() {
    const n   = numSlots();
    const pzs = piezasPorSlot();
    const titulos = {
      1: `Paso 3 — Elige el pan (${tamanio.capacidad} piezas)`,
      2: `Paso 3 — Elige ${n} tipos de pan (${pzs} piezas cada uno)`,
      3: `Paso 3 — Elige ${n} tipos de pan (${pzs} piezas cada uno)`
    };
    document.getElementById('paso3-titulo').textContent = titulos[n] || 'Elige tu pan';
    document.getElementById('paso3').classList.remove('hidden');
    renderSlots();
    actualizarPiezasBar();
    document.getElementById('paso3').scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  function elegirPan(id, precio) {
    if (slots.length >= numSlots()) return;
    slots.push({
      id_producto: parseInt(id),
      nombre:      PRODUCTOS[id].nombre,
      precio:      parseFloat(precio),
      cantidad:    piezasPorSlot()
    });
    renderSlots();
    actualizarPiezasBar();
    actualizarBtnAgregar();
  }

  function quitarSlot(idx) {
    slots.splice(idx, 1);
    renderSlots();
    actualizarPiezasBar();
    actualizarBtnAgregar();
  }

  function renderSlots() {
    const n     = numSlots();
    const lleno = slots.length >= n;

    document.querySelectorAll('.btn-sel-pan').forEach(b => {
      b.disabled = lleno;
      b.style.opacity = lleno ? '0.4' : '1';
    });

    let cont = document.getElementById('slotsSeleccionados');
    if (!cont) {
      cont = document.createElement('div');
      cont.id = 'slotsSeleccionados';
      cont.style.cssText = 'margin-top:16px; display:flex; flex-direction:column; gap:8px;';
      document.getElementById('piezasBar').insertAdjacentElement('afterend', cont);
    }

    if (slots.length === 0) { cont.innerHTML = ''; return; }

    let html = `<div style="font-size:11px;font-weight:700;color:var(--brown-lt);text-transform:uppercase;margin-bottom:4px;">
                  Panes elegidos (${slots.length}/${n})</div>`;
    slots.forEach((s, idx) => {
      html += `
        <div style="display:flex;align-items:center;justify-content:space-between;
                    background:var(--warm-bg);border:1.5px solid var(--tan);
                    border-radius:10px;padding:10px 14px;">
          <div>
            <span style="font-weight:700;font-size:13px;color:var(--brown-dk);">${s.nombre}</span>
            <span style="font-size:12px;color:var(--brown-lt);margin-left:8px;">
              × ${s.cantidad} pzas — $${(s.precio * s.cantidad).toFixed(2)}
            </span>
          </div>
          <button type="button" onclick="quitarSlot(${idx})"
                  style="background:#fce8df;border:none;color:var(--rust);border-radius:7px;
                         padding:4px 10px;font-size:12px;font-weight:700;cursor:pointer;">✕</button>
        </div>`;
    });
    cont.innerHTML = html;
  }

  function actualizarPiezasBar() {
    const n   = numSlots();
    const pzs = slots.reduce((a, s) => a + s.cantidad, 0);
    const pct = n > 0 ? (slots.length / n) * 100 : 0;
    document.getElementById('piezasFill').style.width = pct + '%';
    document.getElementById('piezasTexto').textContent =
      `${slots.length} de ${n} slot${n > 1 ? 's' : ''} — ${pzs} / ${tamanio ? tamanio.capacidad : 0} piezas`;
    document.getElementById('piezasBar').classList.toggle('ok', slots.length === n && n > 0);
  }

  function actualizarBtnAgregar() {
    document.getElementById('btnAgregarCarrito').disabled = !cajaCompleta();
  }

  function actualizarSteps(completado) {
    for (let i = 1; i <= 3; i++) {
      const el = document.getElementById('step' + i + '-ind');
      el.classList.remove('active', 'done');
      if (i <= completado)           el.classList.add('done');
      else if (i === completado + 1) el.classList.add('active');
    }
  }

  function agregarAlCarrito() {
    if (!cajaCompleta()) return;

    carrito.push({
      tamanio: { ...tamanio },
      tipo,
      slots: slots.map(s => ({ ...s }))
    });

    const btn = document.getElementById('btnAgregarCarrito');
    btn.textContent = '¡Caja agregada!';
    btn.style.background = '#3a6034';
    setTimeout(() => { btn.textContent = 'Agregar caja al pedido'; btn.style.background = ''; }, 1200);

    actualizarCarritoEnPagina();
    setTimeout(() => { resetearPasos(); abrirDrawer(); }, 1350);
  }

  function quitarDelCarrito(idx) {
    carrito.splice(idx, 1);
    actualizarCarritoEnPagina();
  }

  function duplicarCaja(idx) {
    const original = carrito[idx];
    carrito.push({
      tamanio: { ...original.tamanio },
      tipo:    original.tipo,
      slots:   original.slots.map(s => ({ ...s }))
    });
    actualizarCarritoEnPagina();
  }

  function resetearPasos() {
    tamanio = null; tipo = null; slots = [];

    document.querySelectorAll('.size-card').forEach(c => c.classList.remove('selected'));
    document.querySelectorAll('.tipo-card').forEach(c => c.classList.remove('selected'));
    document.getElementById('paso2').classList.add('hidden');
    document.getElementById('paso3').classList.add('hidden');

    const cont = document.getElementById('slotsSeleccionados');
    if (cont) cont.innerHTML = '';

    document.querySelectorAll('.btn-sel-pan').forEach(b => { b.disabled = false; b.style.opacity = '1'; });

    actualizarSteps(0);
    document.getElementById('btnAgregarCarrito').disabled = true;
    document.getElementById('stepsBar').scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  function actualizarCarritoEnPagina() {
    const badge = document.getElementById('cartBadge');

    if (carrito.length > 0) {
      badge.textContent   = carrito.length;
      badge.style.display = 'flex';
    } else {
      badge.style.display = 'none';
    }

    document.getElementById('btnEnviar').disabled = carrito.length === 0;

    document.getElementById('h_cajas_json').value = JSON.stringify(
      carrito.map(c => ({
        id_tamanio: c.tamanio.id,
        tipo: c.tipo,
        panes: c.slots.map(s => ({
          id_producto: s.id_producto,
          cantidad:    s.cantidad,
          precio:      s.precio
        }))
      }))
    );

    const icos = { simple: '', mixta: '', triple: '' };
    let total = 0, resHTML = '';

    if (carrito.length === 0) {
      resHTML = `
        <div style="text-align:center; padding:40px 0; color:var(--brown-lt);">
          <div style="font-size:44px; margin-bottom:12px;">🛒</div>
          <div style="font-size:13px; line-height:1.6;">
            Tu carrito está vacío.<br>Arma una caja para empezar.
          </div>
        </div>`;
    } else {
      carrito.forEach((c, idx) => {
        const subtotal = c.slots.reduce((a, s) => a + s.precio * s.cantidad, 0);
        total += subtotal;
        resHTML += `
          <div class="resumen-row" style="flex-direction:column; align-items:flex-start; gap:8px; padding:14px 0;">
            <div style="display:flex; justify-content:space-between; align-items:center; width:100%;">
              <strong style="font-size:14px;">${icos[c.tipo]} Caja ${idx+1} — ${c.tamanio.nombre}</strong>
              <span style="color:var(--rust); font-weight:700; font-size:15px;">$${subtotal.toFixed(2)}</span>
            </div>
            <div style="font-size:12px; color:var(--brown-lt); line-height:1.5;">
              ${c.slots.map(s => `${s.nombre} × ${s.cantidad} pzas`).join(' · ')}
            </div>
            <div style="display:flex; gap:8px; flex-wrap:wrap;">
              <button type="button" onclick="duplicarCaja(${idx})"
                      style="padding:5px 12px; border-radius:8px; border:1.5px solid var(--tan);
                             background:var(--white); color:var(--brown-dk); font-size:12px;
                             font-weight:700; cursor:pointer; transition:background .15s;"
                      onmouseover="this.style.background='var(--warm-bg)'"
                      onmouseout="this.style.background='var(--white)'">
                + Agregar igual
              </button>
              <button type="button" onclick="quitarDelCarrito(${idx})"
                      style="padding:5px 12px; border-radius:8px; border:none;
                             background:#fce8df; color:var(--rust); font-size:12px;
                             font-weight:700; cursor:pointer; transition:background .15s;"
                      onmouseover="this.style.background='#f5c6b0'"
                      onmouseout="this.style.background='#fce8df'">
                ✕ Quitar
              </button>
            </div>
          </div>`;
      });
    }

    document.getElementById('drawerResumen').innerHTML = resHTML;
    document.getElementById('drawerTotal').textContent = '$' + total.toFixed(2);
  }

  function abrirDrawer() {
    document.getElementById('drawerOverlay').classList.add('open');
    document.getElementById('cartDrawer').classList.add('open');
    configurarFechaHora();
  }

  function cerrarDrawer() {
    document.getElementById('drawerOverlay').classList.remove('open');
    document.getElementById('cartDrawer').classList.remove('open');
  }

  function filtrar(q) {
    const query = q.toLowerCase();
    document.querySelectorAll('.prod-card').forEach(c => {
      c.style.display = c.dataset.name.includes(query) ? 'block' : 'none';
    });
  }

  function configurarFechaHora() {
    const dateInput = document.getElementById('uiDate');
    const ahora     = new Date();
    const hoyLocal  = new Date(ahora.getTime() - ahora.getTimezoneOffset() * 60000)
                        .toISOString().split('T')[0];
    dateInput.min = hoyLocal;
    if (!dateInput.value) dateInput.value = hoyLocal;
    actualizarHorarios();
  }

  function actualizarHorarios() {
    const dateVal    = document.getElementById('uiDate').value;
    const timeSelect = document.getElementById('uiTime');
    timeSelect.innerHTML = '';
    if (!dateVal) return;

    const ahora = new Date();
    const [y, m, d] = dateVal.split('-');
    const esHoy = ahora.getFullYear() === +y && ahora.getMonth() === +m - 1 && ahora.getDate() === +d;
    let hI = 9, mI = 0;

    if (esHoy) {
      const minTime = new Date(ahora.getTime() + 3600000);
      if (minTime.getHours() > 21 || (minTime.getHours() === 21 && minTime.getMinutes() > 0)) {
        timeSelect.innerHTML = '<option value="">Cerrado por hoy</option>';
        actualizarHidden(); return;
      }
      hI = Math.max(9, minTime.getHours());
      if (minTime.getHours() === hI) {
        mI = Math.ceil(minTime.getMinutes() / 15) * 15;
        if (mI === 60) { hI++; mI = 0; }
      }
    }

    for (let h = 9; h <= 21; h++) {
      for (let min = 0; min < 60; min += 15) {
        if (h === 21 && min > 0) break;
        if (esHoy && (h < hI || (h === hI && min < mI))) continue;
        const opt = document.createElement('option');
        opt.value = `${String(h).padStart(2,'0')}:${String(min).padStart(2,'0')}`;
        const ampm = h >= 12 ? 'PM' : 'AM';
        const h12  = h > 12 ? h - 12 : (h === 0 ? 12 : h);
        opt.textContent = `${h12}:${String(min).padStart(2,'0')} ${ampm}`;
        timeSelect.appendChild(opt);
      }
    }
    actualizarHidden();
  }

  function actualizarHidden() {
    const d = document.getElementById('uiDate').value;
    const t = document.getElementById('uiTime').value;
    document.getElementById('h_fecha').value = (d && t) ? `${d}T${t}` : '';
  }

  actualizarCarritoEnPagina();
