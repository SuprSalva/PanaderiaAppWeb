var inputBuscar = document.querySelector('input[name="buscar"]');
var debounceTimer;
function debounceSubmit() {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(function () {
    document.getElementById('form-filtro').submit();
  }, 700);
}

const ICONS = {
  danger: `<animated-icons src="/static/icons/minus-8e4bd16d.json" trigger="loop" attributes='{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#FF0707FF","background":"#FFFFFF"}}' height="30" width="30"></animated-icons>`,
  success: `<animated-icons src="/static/icons/success-2cb0da6b.json" trigger="loop" attributes='{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#559C27FF","background":"#FFFFFF"}}' height="30" width="30"></animated-icons>`,
  danger_lg: `<animated-icons src="/static/icons/minus-8e4bd16d.json" trigger="loop" attributes='{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#FF0707FF","background":"#FFFFFF"}}' height="60" width="60"></animated-icons>`,
  success_lg: `<animated-icons src="/static/icons/success-2cb0da6b.json" trigger="loop" attributes='{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#559C27FF","background":"#FFFFFF"}}' height="60" width="60"></animated-icons>`
};

function abrirToggleProv(id, nombre, estatus) {
  var act = estatus === 'activo';
  document.getElementById('toggle-prov-title').innerHTML =
    act ? ICONS.danger + ' Desactivar Proveedor' : ICONS.success + ' Activar Proveedor';
  document.getElementById('toggle-prov-msg').innerHTML = act
    ? 'El proveedor <strong>' + nombre + '</strong> quedará inactivo y no podrá seleccionarse en nuevas compras.<br>El historial de compras se conserva.<br><br>'
    : 'El proveedor <strong>' + nombre + '</strong> volverá a estar disponible para registrar compras.<br><br>';
  var btn = document.getElementById('toggle-prov-btn');
  btn.innerHTML = act ? ICONS.danger + ' Desactivar' : ICONS.success + ' Activar';
  btn.className = act ? 'btn btn-danger' : 'btn btn-primary';
  document.getElementById('toggle-prov-header').style.background =
    act ? 'var(--rust)' : '#5a7a52';
  document.getElementById('form-toggle-prov').action =
    '/proveedores/toggle/' + id;
  document.getElementById('modal-toggle-prov').classList.add('open');
}

function cerrarToggleProv() {
  document.getElementById('modal-toggle-prov').classList.remove('open');
}

function aplicarFiltroEstadistica(estatus) {
  const selectEstatus = document.querySelector('select[name="estatus"]');
  if (selectEstatus) {
    selectEstatus.value = estatus;
  }
  const form = document.getElementById('form-filtro');
  if (form) {
    // Resetear a la página 1 al filtrar
    const inputPagina = form.querySelector('input[name="pagina"]');
    if (inputPagina) inputPagina.value = '1';
    form.submit();
  }
}
