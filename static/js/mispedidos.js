  function openModal(id)  { document.getElementById(id).classList.add('open'); }
  function closeModal(id) { document.getElementById(id).classList.remove('open'); }
  document.querySelectorAll('.modal-overlay').forEach(el => {
    el.addEventListener('click', e => { if (e.target === el) el.classList.remove('open'); });
  });

  const timelines = {
    pendiente: [
      { label: 'Pedido recibido',    time: 'Hoy 09:05', done: true },
      { label: 'Pago confirmado',    time: 'Pendiente',  done: false },
      { label: 'En preparación',     time: '—',          done: false },
      { label: 'Listo / En camino',  time: '—',          done: false },
      { label: 'Entregado',          time: '—',          done: false },
    ],
    preparando: [
      { label: 'Pedido recibido',    time: 'Hoy 11:20', done: true },
      { label: 'Pago confirmado',    time: 'Hoy 11:21', done: true },
      { label: 'En preparación',     time: 'Hoy 11:25', done: true, active: true },
      { label: 'Listo / En camino',  time: '~11:55',    done: false },
      { label: 'Entregado',          time: '~12:05',    done: false },
    ],
    enviado: [
      { label: 'Pedido recibido',    time: 'Mar 18, 14:00', done: true },
      { label: 'Pago confirmado',    time: 'Mar 18, 14:01', done: true },
      { label: 'En preparación',     time: 'Mar 18, 14:10', done: true },
      { label: 'En camino',          time: 'Mar 18, 14:40', done: true, active: true },
      { label: 'Entregado',          time: '~14:55',        done: false },
    ],
    entregado: [
      { label: 'Pedido recibido',    time: 'Ayer 16:30', done: true },
      { label: 'Pago confirmado',    time: 'Ayer 16:30', done: true },
      { label: 'En preparación',     time: 'Ayer 16:35', done: true },
      { label: 'En camino',          time: 'Ayer 17:05', done: true },
      { label: 'Entregado',          time: 'Ayer 17:22', done: true, active: true },
    ],
  };

  function openPedido(folio, estado) {
    document.getElementById('det-folio').textContent = folio;

    // timeline
    const tl = timelines[estado] || timelines.preparando;
    let tlHtml = '';
    tl.forEach((step, i) => {
      const isLast = i === tl.length - 1;
      const dotClass = step.active ? 'done active' : step.done ? 'done' : '';
      const connClass = step.done && !isLast ? 'done' : '';
      tlHtml += `
        <div class="tl-step">
          <div class="tl-line-col">
            <div class="tl-dot ${dotClass}"></div>
            ${!isLast ? `<div class="tl-connector ${connClass}"></div>` : ''}
          </div>
          <div class="tl-content">
            <div class="tl-label" style="color:${step.done ? 'var(--brown-dk)' : 'var(--brown-lt)'}">${step.label}</div>
            <div class="tl-time">${step.time}</div>
          </div>
        </div>`;
    });
    document.getElementById('det-timeline').innerHTML = tlHtml;
    openModal('modal-pedido');
  }

  /* Filtros */
  function filtrarPedidos(q) {
    q = q.toLowerCase();
    let visible = 0;
    document.querySelectorAll('#ordersTableBody tr').forEach(row => {
      const text = row.textContent.toLowerCase();
      row.style.display = text.includes(q) ? '' : 'none';
      if (text.includes(q)) visible++;
    });
    document.getElementById('visibleCount').textContent = visible;
  }

  function filtrarEstado(val) {
    let visible = 0;
    document.querySelectorAll('#ordersTableBody tr').forEach(row => {
      const est = row.dataset.estado || '';
      const show = val === 'todos' || est === val;
      row.style.display = show ? '' : 'none';
      if (show) visible++;
    });
    document.getElementById('visibleCount').textContent = visible;
  }

  function filtrarPeriodo(val) { /* implementar según BD */ }
