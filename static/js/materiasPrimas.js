// ── Búsqueda AJAX ────────────────────────────────────────────────────
let _debounce = null;

function buscarDebounce() {
  clearTimeout(_debounce);
  _debounce = setTimeout(ejecutarBusqueda, 400);
}

function ejecutarBusqueda() {
  const form   = document.getElementById('form-filtro');
  const params = new URLSearchParams();

  params.set('buscar',      document.querySelector('input[name="buscar"]').value);
  params.set('estatus',     document.querySelector('select[name="estatus"]').value);
  params.set('nivel_stock', document.getElementById('nivel_stock').value);
  params.set('pagina',      '1');

  const url = `${form.action}?${params.toString()}`;

  fetch(url)
    .then(r => r.text())
    .then(html => {
      const doc = new DOMParser().parseFromString(html, 'text/html');

      // Reemplazar estadísticas
      const statsNuevo  = doc.querySelector('.mp-stats');
      const statsActual = document.querySelector('.mp-stats');
      if (statsNuevo && statsActual) statsActual.replaceWith(statsNuevo);

      // Reemplazar tabla completa (incluye paginador)
      const cardNuevo  = doc.querySelector('.table-card');
      const cardActual = document.querySelector('.table-card');
      if (cardNuevo && cardActual) cardActual.replaceWith(cardNuevo);

      // Actualizar URL sin recargar
      history.replaceState(null, '', url);
    });
}

// ── Filtro por nivel de stock (tarjetas de estadísticas) ─────────────
function filtrarPorNivelStock(nivel) {
  document.getElementById('nivel_stock').value = nivel === 'todos' ? '' : nivel;
  ejecutarBusqueda();
}
