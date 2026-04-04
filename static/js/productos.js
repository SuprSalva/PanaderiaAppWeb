var inputBuscar = document.getElementById('buscador')
               || document.querySelector('input[name="buscar"]');
var debounceTimer;

function debounceSubmit() {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(enviarBusqueda, 700);
}

function enviarBusqueda() {
  clearTimeout(debounceTimer);
  if (inputBuscar) {
    sessionStorage.setItem('buscarPos', inputBuscar.selectionStart);
    sessionStorage.setItem('buscarVal', inputBuscar.value);
  }
  document.getElementById('form-filtro').submit();
}

if (inputBuscar) {
  inputBuscar.addEventListener('keydown', function(e) {
    if (e.key === 'Enter') {
      e.preventDefault();
      enviarBusqueda();
    }
    if (e.key === 'Escape') {
      clearTimeout(debounceTimer);
      inputBuscar.value = '';
      enviarBusqueda();
    }
  });
}

document.addEventListener('DOMContentLoaded', function() {
  var val = sessionStorage.getItem('buscarVal');
  var pos = parseInt(sessionStorage.getItem('buscarPos') || '0');
  if (val !== null && inputBuscar && inputBuscar.value === val) {
    inputBuscar.focus();
    try { inputBuscar.setSelectionRange(pos, pos); } catch(e) {}
    sessionStorage.removeItem('buscarPos');
    sessionStorage.removeItem('buscarVal');
  }
});

function abrirToggleProd(id, nombre, estatus) {
  var act = estatus === 'activo';
  document.getElementById('toggle-prod-title').textContent =
    act ? '🚫 Desactivar Producto' : '✅ Activar Producto';
  document.getElementById('toggle-prod-icon').textContent  = act ? '🚫' : '✅';
  document.getElementById('toggle-prod-msg').innerHTML     = act
    ? 'El producto <strong>' + nombre + '</strong> quedará inactivo y no podrá usarse en nuevas ventas ni producción.<br>El historial y las recetas asociadas se conservan.'
    : 'El producto <strong>' + nombre + '</strong> volverá a estar disponible para ventas y producción.';
  var btn = document.getElementById('toggle-prod-btn');
  btn.textContent = act ? '🚫 Sí, desactivar' : '✅ Sí, activar';
  btn.className   = act ? 'btn btn-danger' : 'btn btn-primary';
  document.getElementById('toggle-prod-header').style.background =
    act ? 'var(--rust)' : '#5a7a52';
  document.getElementById('form-toggle-prod').action =
    '/productos/toggle/' + id;
  document.getElementById('modal-toggle-prod').classList.add('open');
}
function cerrarToggleProd() {
  document.getElementById('modal-toggle-prod').classList.remove('open');
}
