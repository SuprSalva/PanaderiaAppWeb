  /* ══ DELIVERY TOGGLE ══ */
  function selectDelivery(el, tipo) {
    document.querySelectorAll('.delivery-opt').forEach(d => d.classList.remove('selected'));
    el.classList.add('selected');
    el.querySelector('input').checked = true;
    const addr = document.getElementById('addressFields');
    const envioEl = document.getElementById('osEnvio');
    const totalEl = document.getElementById('osTotal');
    const sub = parseFloat((sessionStorage.getItem('dmSubtotal') || '132').replace(',',''));

    if (tipo === 'recoger') {
      addr.style.display = 'none';
      envioEl.textContent = 'Gratis';
      totalEl.textContent = '$' + sub.toFixed(2);
    } else {
      addr.style.display = 'block';
      envioEl.textContent = '$20.00';
      totalEl.textContent = '$' + (sub + 20).toFixed(2);
    }
  }

  /* ══ PAYMENT TOGGLE ══ */
  function selectPayment(el, tipo) {
    document.querySelectorAll('.payment-opt').forEach(p => p.classList.remove('selected'));
    el.classList.add('selected');
    el.querySelector('input').checked = true;
    document.getElementById('cardFields').classList.remove('show');
    document.getElementById('speiFields').style.display = 'none';
    document.getElementById('oxxoFields').style.display = 'none';
    if (tipo === 'tarjeta')       document.getElementById('cardFields').classList.add('show');
    else if (tipo === 'transferencia') document.getElementById('speiFields').style.display = 'block';
    else if (tipo === 'oxxo')     document.getElementById('oxxoFields').style.display = 'block';
  }

  /* ══ CARD FORMATTING ══ */
  function formatCardNum(el) {
    let v = el.value.replace(/\D/g, '').substring(0,16);
    el.value = v.replace(/(.{4})/g,'$1 ').trim();
    const brand = document.getElementById('cardBrand');
    if (v.startsWith('4')) brand.textContent = '💳'; // Visa
    else if (v.startsWith('5')) brand.textContent = '💳'; // MC
    else if (v.startsWith('3')) brand.textContent = '💳'; // Amex
    else brand.textContent = '💳';
  }

  function formatExp(el) {
    let v = el.value.replace(/\D/g,'');
    if (v.length > 2) v = v.substring(0,2) + '/' + v.substring(2,4);
    el.value = v;
  }

  /* ══ LOAD CART FROM SESSION ══ */
  window.addEventListener('DOMContentLoaded', () => {
    const cartRaw = sessionStorage.getItem('dmCart');
    const sub = sessionStorage.getItem('dmSubtotal');
    const total = sessionStorage.getItem('dmTotal');
    if (sub)   document.getElementById('osSub').textContent   = '$' + sub;
    if (total) document.getElementById('osTotal').textContent = '$' + total;

    if (cartRaw) {
      const cart = JSON.parse(cartRaw);
      const ids = Object.keys(cart);
      if (ids.length > 0) {
        const container = document.getElementById('osSummary');
        container.innerHTML = '';
        ids.forEach(id => {
          const item = cart[id];
          const itemSub = (item.price * item.qty).toFixed(2);
          container.innerHTML += `
            <div class="os-item">
              <span class="os-item-emoji">${item.emoji}</span>
              <span class="os-item-name">${item.name}</span>
              <span class="os-item-qty">×${item.qty}</span>
              <span class="os-item-price">$${itemSub}</span>
            </div>`;
        });
      }
    }
  });

  /* ══ CONFIRM ══ */
  function confirmarPedido() {
    window.location.href = '/mis-pedido';
  }
