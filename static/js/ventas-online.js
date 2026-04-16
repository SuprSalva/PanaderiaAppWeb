  /* ══ CART STATE ══ */
  let cart = {}; // { id: { name, emoji, price, qty, maxStock } }

  function openCart()  { document.getElementById('cartDrawer').classList.add('open'); document.getElementById('cartOverlay').classList.add('open'); }
  function closeCart() { document.getElementById('cartDrawer').classList.remove('open'); document.getElementById('cartOverlay').classList.remove('open'); }

  function addToCartOl(id, name, emoji, price, stock) {
    if (cart[id]) {
      if (cart[id].qty >= cart[id].maxStock) { showToast('⚠️ Stock máximo alcanzado'); return; }
      cart[id].qty++;
    } else {
      cart[id] = { name, emoji, price, qty: 1, maxStock: stock };
    }
    renderCart();
    renderCardControls(id);
    showToast(`✅ ${name} agregado`);
  }

  function changeQty(id, delta) {
    if (!cart[id]) return;
    cart[id].qty += delta;
    if (cart[id].qty <= 0) { delete cart[id]; }
    else if (cart[id].qty > cart[id].maxStock) { cart[id].qty = cart[id].maxStock; }
    renderCart();
    renderCardControls(id);
  }

  function removeItem(id) {
    delete cart[id];
    renderCart();
    renderCardControls(id);
  }

  function clearCart() {
    const ids = Object.keys(cart);
    cart = {};
    ids.forEach(id => renderCardControls(id));
    renderCart();
  }

  function renderCart() {
    const ids = Object.keys(cart);
    const cartItemsEl = document.getElementById('cartItems');
    const cartEmptyEl = document.getElementById('cartEmpty');
    const cartTotals  = document.getElementById('cartTotals');
    const btnCheckout = document.getElementById('btnCheckout');
    const btnClear    = document.getElementById('btnClear');
    const badge       = document.getElementById('cartBadge');

    if (ids.length === 0) {
      cartItemsEl.innerHTML = '';
      cartEmptyEl.style.display = 'flex';
      cartTotals.style.display  = 'none';
      btnCheckout.disabled = true;
      btnClear.style.display = 'none';
      badge.classList.add('hidden');
      return;
    }

    cartEmptyEl.style.display = 'none';
    cartTotals.style.display  = 'block';
    btnCheckout.disabled = false;
    btnClear.style.display = 'block';

    let subtotal = 0;
    let totalPzas = 0;
    let html = '';

    ids.forEach(id => {
      const item = cart[id];
      const sub = item.price * item.qty;
      subtotal += sub;
      totalPzas += item.qty;
      html += `
        <div class="cart-item">
          <div class="cart-item-emoji">${item.emoji}</div>
          <div class="cart-item-info">
            <div class="cart-item-name">${item.name}</div>
            <div class="cart-item-price">$${item.price.toFixed(2)} c/u</div>
          </div>
          <div class="cart-item-controls">
            <button class="qty-btn" onclick="changeQty(${id},-1)">−</button>
            <span class="qty-num">${item.qty}</span>
            <button class="qty-btn" onclick="changeQty(${id},1)">+</button>
          </div>
          <div class="cart-item-subtotal">$${sub.toFixed(2)}</div>
          <button class="btn-remove-item" onclick="removeItem(${id})">✕</button>
        </div>`;
    });

    cartItemsEl.innerHTML = html;

    const total = subtotal + 20;
    document.getElementById('cartSubtotal').textContent = '$' + subtotal.toFixed(2);
    document.getElementById('cartTotal').textContent    = '$' + total.toFixed(2);
    document.getElementById('cartItemCount').textContent = totalPzas;

    badge.textContent = totalPzas;
    badge.classList.remove('hidden');

    /* Save for checkout page */
    sessionStorage.setItem('dmCart', JSON.stringify(cart));
    sessionStorage.setItem('dmSubtotal', subtotal.toFixed(2));
    sessionStorage.setItem('dmTotal', total.toFixed(2));
  }

  function renderCardControls(id) {
    const ctrl = document.getElementById('ctrl-' + id);
    if (!ctrl) return;
    if (cart[id]) {
      ctrl.innerHTML = `
        <button class="qty-btn" style="width:26px;height:26px;border-radius:7px;border:1.5px solid var(--tan);background:var(--warm-bg);color:var(--brown-dk);font-size:14px;font-weight:700;cursor:pointer;display:flex;align-items:center;justify-content:center;" onclick="changeQty(${id},-1)">−</button>
        <span class="qty-chip">${cart[id].qty}</span>
        <button class="qty-btn" style="width:26px;height:26px;border-radius:7px;border:1.5px solid var(--tan);background:var(--warm-bg);color:var(--brown-dk);font-size:14px;font-weight:700;cursor:pointer;display:flex;align-items:center;justify-content:center;" onclick="changeQty(${id},1)">+</button>`;
    } else {
      ctrl.innerHTML = `<button class="btn-add-cart" onclick="addToCartOl(${id},'${getCartName(id)}','${getCartEmoji(id)}',${getCartPrice(id)},${getCartStock(id)})">+</button>`;
    }
  }

  /* Helpers para reconstruir addToCartOl desde el botón renderizado */
  const prodData = {
    1: {name:'Concha de Vainilla',   emoji:'🍞', price:22, stock:96},
    2: {name:'Cuernito Mantequilla', emoji:'🥐', price:28, stock:75},
    3: {name:'Dona Glaseada',        emoji:'🍩', price:20, stock:6},
    4: {name:'Pan de Chocolate',     emoji:'🍫', price:25, stock:9},
    5: {name:'Empanada de Cajeta',   emoji:'🥧', price:18, stock:48},
    6: {name:'Bolillo Relleno',      emoji:'🥖', price:18, stock:60},
    7: {name:'Telera Integral',      emoji:'🫓', price:15, stock:32},
    8: {name:'Bagel de Sésamo',      emoji:'🥯', price:32, stock:24},
    9: {name:'Pastel Tres Leches',   emoji:'🎂', price:55, stock:5},
    10:{name:'Cheesecake de Fresa',  emoji:'🍰', price:65, stock:8},
    11:{name:'Galleta Chispas',      emoji:'🍪', price:12, stock:80},
    12:{name:'Polvorón Naranja',     emoji:'⭐', price:10, stock:55},
  };
  function getCartName(id)  { return prodData[id]?.name  || ''; }
  function getCartEmoji(id) { return prodData[id]?.emoji || ''; }
  function getCartPrice(id) { return prodData[id]?.price || 0;  }
  function getCartStock(id) { return prodData[id]?.stock || 0;  }

  /* ══ FILTROS ══ */
  let currentCat = 'todos';

  function filtrarCat(el, cat) {
    currentCat = cat;
    document.querySelectorAll('.cat-tab').forEach(t => t.classList.remove('active'));
    el.classList.add('active');
    aplicarFiltros();
  }

  function filtrarOnline(q) { aplicarFiltros(q); }

  function aplicarFiltros(q) {
    const query = (q || document.getElementById('searchInput').value).toLowerCase().trim();
    let visible = 0;
    document.querySelectorAll('.prod-card').forEach(card => {
      const cat  = card.dataset.cat || '';
      const name = card.dataset.name || '';
      const catOk  = currentCat === 'todos' || cat === currentCat;
      const nameOk = !query || name.includes(query);
      card.style.display = (catOk && nameOk) ? '' : 'none';
      if (catOk && nameOk) visible++;
    });
    document.getElementById('prodCount').textContent = `${visible} producto${visible !== 1 ? 's' : ''} disponible${visible !== 1 ? 's' : ''}`;
  }

  /* ══ TOAST ══ */
  function showToast(msg) {
    const wrap = document.getElementById('toastWrap');
    const t = document.createElement('div');
    t.className = 'toast'; t.textContent = msg;
    wrap.appendChild(t);
    setTimeout(() => t.remove(), 2400);
  }
