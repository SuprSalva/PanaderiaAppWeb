function cerrarModal(id) {
  var el = document.getElementById(id);
  el.classList.remove('open');
  el.style.display = 'none';
}
function abrirModal(id) {
  var el = document.getElementById(id);
  el.style.display = 'flex';
  el.classList.add('open');
}

function abrirAprobar(folio) {
  document.getElementById('ap-folio').textContent = folio;
  document.getElementById('form-aprobar').action = window.URL_APROBAR_BASE.replace('__FOLIO__', folio);
  abrirModal('mAprobar');
}

function abrirRechazar(folio) {
  document.getElementById('rch-folio').textContent = folio;
  document.getElementById('form-rechazar').action = window.URL_RECHAZAR_BASE.replace('__FOLIO__', folio);
  abrirModal('mRechazar');
}

/* Cerrar al click fuera */
document.addEventListener('DOMContentLoaded', function () {
  ['mAprobar', 'mRechazar'].forEach(function (id) {
    var el = document.getElementById(id);
    if (el) el.addEventListener('click', function (e) {
      if (e.target === this) cerrarModal(id);
    });
  });
});
