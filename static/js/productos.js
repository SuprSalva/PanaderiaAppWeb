/* productos/static/js/productos.js */
var POR_PAGINA   = 10;
var PAG_ACTUAL   = 1;
var FILAS_VISIBLES = [];   

function filterTable() {
  var q       = (document.getElementById('searchInput').value || '').toLowerCase().trim();
  var estatus = (document.getElementById('filterEstatus').value || '');

  var todas = document.querySelectorAll('#productosTable tbody tr[data-nombre]');
  FILAS_VISIBLES = [];

  todas.forEach(function(row) {
    var nombre  = (row.dataset.nombre  || '').toLowerCase();
    var desc    = (row.dataset.desc    || '').toLowerCase();
    var rowEst  = (row.dataset.estatus || '');

    var matchText = !q || nombre.includes(q) || desc.includes(q);
    var matchEst  = !estatus || rowEst === estatus;

    if (matchText && matchEst) {
      FILAS_VISIBLES.push(row);
    } else {
      row.style.display = 'none';
    }
  });

  PAG_ACTUAL = 1;
  renderPagina();
  actualizarContador();
}

function renderPagina() {
  var inicio = (PAG_ACTUAL - 1) * POR_PAGINA;
  var fin    = inicio + POR_PAGINA;

  FILAS_VISIBLES.forEach(function(row, i) {
    row.style.display = (i >= inicio && i < fin) ? '' : 'none';
    var numCell = row.querySelector('.row-num');
    if (numCell) numCell.textContent = inicio + i + 1;
  });

  renderControlPaginador();
}

function renderControlPaginador() {
  var totalPags = Math.ceil(FILAS_VISIBLES.length / POR_PAGINA);
  var wrap      = document.getElementById('paginador-wrap');
  var info      = document.getElementById('pag-info');
  var ctrl      = document.getElementById('pag-controles');

  if (!wrap) return;

  wrap.style.display = FILAS_VISIBLES.length > POR_PAGINA ? 'flex' : 'none';

  if (!wrap.style.display || wrap.style.display === 'none') return;

  var inicio = (PAG_ACTUAL - 1) * POR_PAGINA + 1;
  var fin     = Math.min(PAG_ACTUAL * POR_PAGINA, FILAS_VISIBLES.length);
  if (info) {
    info.innerHTML = 'Mostrando <strong>' + inicio + '</strong> – <strong>' + fin +
                     '</strong> de <strong>' + FILAS_VISIBLES.length + '</strong> producto' +
                     (FILAS_VISIBLES.length !== 1 ? 's' : '');
  }

  if (!ctrl) return;
  ctrl.innerHTML = '';

  var btnPrev = document.createElement('button');
  btnPrev.className = 'pag-btn' + (PAG_ACTUAL === 1 ? ' disabled' : '');
  btnPrev.innerHTML = '‹';
  if (PAG_ACTUAL > 1) btnPrev.addEventListener('click', function() { PAG_ACTUAL--; renderPagina(); });
  ctrl.appendChild(btnPrev);

  for (var n = 1; n <= totalPags; n++) {
    if (n === 1 || n === totalPags || (n >= PAG_ACTUAL - 2 && n <= PAG_ACTUAL + 2)) {
      if (n > 2 && (n - 1) < PAG_ACTUAL - 2) {
        var sp = document.createElement('span');
        sp.className = 'pag-puntos';
        sp.textContent = '…';
        ctrl.appendChild(sp);
      }
      _agregarBtnPag(ctrl, n, n === PAG_ACTUAL ? 'activo' : '');
      if (n < totalPags - 1 && (n + 1) > PAG_ACTUAL + 2) {
        var sp2 = document.createElement('span');
        sp2.className = 'pag-puntos';
        sp2.textContent = '…';
        ctrl.appendChild(sp2);
      }
    }
  }

  var btnNext = document.createElement('button');
  btnNext.className = 'pag-btn' + (PAG_ACTUAL === totalPags ? ' disabled' : '');
  btnNext.innerHTML = '›';
  if (PAG_ACTUAL < totalPags) btnNext.addEventListener('click', function() { PAG_ACTUAL++; renderPagina(); });
  ctrl.appendChild(btnNext);
}

function _agregarBtnPag(contenedor, num, cls) {
  var b = document.createElement('button');
  b.className   = 'pag-btn ' + (cls || '');
  b.textContent = num;
  if (cls !== 'activo') {
    b.addEventListener('click', function() { PAG_ACTUAL = num; renderPagina(); });
  }
  contenedor.appendChild(b);
}

function actualizarContador() {
  var el = document.getElementById('visibleCount');
  if (el) el.textContent = FILAS_VISIBLES.length;
}

function abrirToggleProd(id, nombre, estatus) {
  var act = estatus === 'activo';
  document.getElementById('toggle-prod-title').textContent =
    act ? 'Desactivar Producto' : 'Activar Producto';
  document.getElementById('toggle-prod-icon').textContent  = act ? '🚫' : '✅';
  document.getElementById('toggle-prod-msg').innerHTML     = act
    ? 'El producto <strong>' + nombre + '</strong> quedará inactivo y no podrá usarse en nuevas ventas ni producción.'
    : 'El producto <strong>' + nombre + '</strong> volverá a estar disponible para ventas y producción.';
  var btn = document.getElementById('toggle-prod-btn');
  btn.textContent = act ? 'Sí, desactivar' : 'Sí, activar';
  btn.className   = act ? 'btn btn-danger' : 'btn btn-primary';
  document.getElementById('toggle-prod-header').style.background =
    act ? 'var(--rust)' : '#5a7a52';
  document.getElementById('form-toggle-prod').action = '/productos/toggle/' + id;
  document.getElementById('modal-toggle-prod').classList.add('open');
}

function cerrarToggleProd() {
  document.getElementById('modal-toggle-prod').classList.remove('open');
}

var _imgProductoId = null;
var _imgUrlActual  = '';

function abrirModalImagen(idProducto, nombre, urlActual) {
  _imgProductoId = idProducto;
  _imgUrlActual  = urlActual;

  document.getElementById('img-nombre-prod').textContent = nombre;
  document.getElementById('img-input').value = '';
  document.getElementById('img-error').style.display = 'none';

  var preview = document.getElementById('img-preview-actual');
  var sinImg  = document.getElementById('img-sin-imagen');
  var btnQuit = document.getElementById('btn-quitar-img');

  if (urlActual) {
    preview.src           = urlActual;
    preview.style.display = 'block';
    sinImg.style.display  = 'none';
    btnQuit.style.display = 'inline-flex';
  } else {
    preview.style.display = 'none';
    sinImg.style.display  = 'block';
    btnQuit.style.display = 'none';
  }

  document.getElementById('modalImagen').classList.add('open');
}

function cerrarModalImagen() {
  document.getElementById('modalImagen').classList.remove('open');
}

function previewImagen(input) {
  if (!input.files || !input.files[0]) return;
  var url     = URL.createObjectURL(input.files[0]);
  var preview = document.getElementById('img-preview-actual');
  preview.src           = url;
  preview.style.display = 'block';
  document.getElementById('img-sin-imagen').style.display = 'none';
}

function _getCsrfToken() {
  var meta = document.querySelector('meta[name="csrf-token"]');
  return meta ? meta.getAttribute('content') : '';
}

async function subirImagen() {
  var input = document.getElementById('img-input');
  if (!input.files || !input.files[0]) {
    mostrarErrorImg('Selecciona una imagen primero.');
    return;
  }
  var fd = new FormData();
  fd.append('imagen', input.files[0]);
  fd.append('csrf_token', _getCsrfToken());
  try {
    var resp = await fetch('/productos/' + _imgProductoId + '/imagen', {
      method: 'POST', body: fd,
    });
    var data = await resp.json();
    if (data.ok) { cerrarModalImagen(); location.reload(); }
    else { mostrarErrorImg(data.msg || 'Error al subir la imagen.'); }
  } catch (e) {
    mostrarErrorImg('Error de conexión. Intenta de nuevo.');
  }
}

async function quitarImagen() {
  if (!confirm('¿Eliminar la imagen de este producto?')) return;
  var fd = new FormData();
  fd.append('csrf_token', _getCsrfToken());
  try {
    var resp = await fetch('/productos/' + _imgProductoId + '/imagen/quitar', {
      method: 'POST', body: fd,
    });
    var data = await resp.json();
    if (data.ok) { cerrarModalImagen(); location.reload(); }
    else { mostrarErrorImg(data.msg || 'Error al eliminar la imagen.'); }
  } catch (e) {
    mostrarErrorImg('Error de conexión. Intenta de nuevo.');
  }
}

function mostrarErrorImg(msg) {
  var el = document.getElementById('img-error');
  el.textContent   = msg;
  el.style.display = 'block';
}

document.addEventListener('DOMContentLoaded', function() {
  filterTable();

  var inp = document.getElementById('searchInput');
  if (inp) {
    inp.addEventListener('keydown', function(e) {
      if (e.key === 'Escape') { inp.value = ''; filterTable(); }
    });
  }
});