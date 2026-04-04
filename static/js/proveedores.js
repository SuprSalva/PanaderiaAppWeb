var inputBuscar  = document.querySelector('input[name="buscar"]');
var debounceTimer;
function debounceSubmit() {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(function() {
    document.getElementById('form-filtro').submit();
  }, 700);
}

function abrirToggleProv(id, nombre, estatus) {
  var act = estatus === 'activo';
  document.getElementById('toggle-prov-title').textContent =
    act ? '🚫 Desactivar Proveedor' : '✅ Activar Proveedor';
  document.getElementById('toggle-prov-icon').textContent  = act ? '🚫' : '✅';
  document.getElementById('toggle-prov-msg').innerHTML     = act
    ? 'El proveedor <strong>' + nombre + '</strong> quedará inactivo y no podrá seleccionarse en nuevas compras.<br>El historial de compras se conserva.'
    : 'El proveedor <strong>' + nombre + '</strong> volverá a estar disponible para registrar compras.';
  var btn = document.getElementById('toggle-prov-btn');
  btn.textContent = act ? '🚫 Sí, desactivar' : '✅ Sí, activar';
  btn.className   = act ? 'btn btn-danger' : 'btn btn-primary';
  document.getElementById('toggle-prov-header').style.background =
    act ? 'var(--rust)' : '#5a7a52';
  document.getElementById('form-toggle-prov').action =
    '/proveedores/toggle/' + id;
  document.getElementById('modal-toggle-prov').classList.add('open');
}
function cerrarToggleProv() {
  document.getElementById('modal-toggle-prov').classList.remove('open');
}
