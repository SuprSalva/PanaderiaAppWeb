/* ── Módulo Usuarios ── */

function openModal(id) {
  const el = document.getElementById(id);
  el.classList.add('open');
  el.style.display = 'flex';
}
function closeModal(id) {
  const el = document.getElementById(id);
  el.classList.remove('open');
  el.style.display = 'none';
}

// Cierra el modal al hacer clic en el backdrop
document.querySelectorAll('.modal-overlay').forEach(overlay => {
  overlay.addEventListener('click', e => {
    if (e.target === overlay) closeModal(overlay.id);
  });
  const modal = overlay.querySelector('.modal');
  if (modal) modal.addEventListener('click', e => e.stopPropagation());
});

function openEdit(idUsuario, nombre, usuario, idRol, estatus) {
  document.getElementById('edit-nombre').value    = nombre;
  document.getElementById('edit-usuario').value   = usuario;
  document.getElementById('edit-rol').value       = idRol;
  document.getElementById('edit-estatus').value   = estatus;
  document.getElementById('edit-password').value  = '';
  document.getElementById('edit-confirmar').value = '';
  document.getElementById('edit-match-msg').textContent = '';
  limpiarErrorModal('modal-edit');
  document.getElementById('form-edit').action = '/usuarios/editar/' + idUsuario;
  openModal('modal-edit');
}

function openDelete(idUsuario, nombre, estatus) {
  const reactivar = (estatus !== 'activo');
  document.getElementById('delete-name').textContent = nombre;
  document.getElementById('form-delete').action = '/usuarios/estatus/' + idUsuario;
  if (reactivar) {
    document.getElementById('delete-estatus-input').value    = 'activo';
    document.getElementById('delete-header').style.background = '#5a7a52';
    document.getElementById('delete-header-title').textContent = '✅ Reactivar Usuario';
    document.getElementById('delete-icon').textContent        = '✅';
    document.getElementById('delete-title').textContent       = '¿Reactivar este usuario?';
    document.getElementById('delete-confirm-btn').textContent = '✅ Reactivar';
    document.getElementById('delete-confirm-btn').className   = 'btn btn-primary';
    document.getElementById('delete-msg').innerHTML =
      'El usuario <strong id="delete-name">' + nombre + '</strong> podrá iniciar sesión nuevamente.';
  } else {
    document.getElementById('delete-estatus-input').value    = 'inactivo';
    document.getElementById('delete-header').style.background = 'var(--rust)';
    document.getElementById('delete-header-title').textContent = '🚫 Desactivar Usuario';
    document.getElementById('delete-icon').textContent        = '🚫';
    document.getElementById('delete-title').textContent       = '¿Desactivar este usuario?';
    document.getElementById('delete-confirm-btn').textContent = '🚫 Desactivar';
    document.getElementById('delete-confirm-btn').className   = 'btn btn-danger';
    document.getElementById('delete-msg').innerHTML =
      'El usuario <strong id="delete-name">' + nombre + '</strong> no podrá iniciar sesión.<br>Esta acción es reversible desde la misma pantalla.';
  }
  openModal('modal-delete');
}

/* ── Validación de contraseña ── */
const PWD_RE = /^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_]).{8,}$/;

function validarPassword(pwd, confirmar, esNuevo) {
  if (esNuevo && !pwd) return 'La contraseña es obligatoria.';
  if (pwd) {
    if (!PWD_RE.test(pwd))
      return 'La contraseña debe tener mínimo 8 caracteres, una mayúscula, un número y un carácter especial (@$!%*?&_).';
    if (pwd !== confirmar) return 'Las contraseñas no coinciden.';
  } else if (confirmar) {
    return 'Escribe la nueva contraseña antes de confirmarla.';
  }
  return null;
}

function mostrarErrorModal(modalId, mensaje) {
  let el = document.getElementById(modalId + '-error');
  if (!el) {
    el = document.createElement('div');
    el.id = modalId + '-error';
    el.style.cssText = 'margin:0 26px 14px;padding:9px 14px;border-radius:8px;font-size:13px;font-weight:600;background:#fce8df;color:#9c3a1a;border:1px solid #f5c6b0;';
    const body = document.querySelector('#' + modalId + ' .modal-body');
    body.parentNode.insertBefore(el, body.nextSibling);
  }
  el.textContent = '⚠️ ' + mensaje;
  el.style.display = 'block';
  clearTimeout(el._t);
  el._t = setTimeout(() => { el.style.display = 'none'; }, 4000);
}

function limpiarErrorModal(modalId) {
  const el = document.getElementById(modalId + '-error');
  if (el) el.style.display = 'none';
}

/* ── Indicador de coincidencia de contraseñas ── */
function setupMatchIndicator(pwdId, confirmId, msgId) {
  const pwd  = document.getElementById(pwdId);
  const conf = document.getElementById(confirmId);
  const msgEl = document.getElementById(msgId);
  function check() {
    if (!conf.value) { msgEl.textContent = ''; return; }
    if (pwd.value === conf.value) {
      msgEl.style.color = '#3a6034';
      msgEl.textContent = '✔ Las contraseñas coinciden';
    } else {
      msgEl.style.color = '#9c3a1a';
      msgEl.textContent = '✖ Las contraseñas no coinciden';
    }
  }
  conf.addEventListener('input', check);
  pwd.addEventListener('input', check);
}
setupMatchIndicator('add-password',  'add-confirmar',  'add-match-msg');
setupMatchIndicator('edit-password', 'edit-confirmar', 'edit-match-msg');

function abrirModalNuevo() {
  document.querySelector('#modal-add form').reset();
  document.getElementById('add-match-msg').textContent = '';
  limpiarErrorModal('modal-add');
  openModal('modal-add');
}

/* Validar form de NUEVO usuario */
document.querySelector('#modal-add form').addEventListener('submit', function(e) {
  limpiarErrorModal('modal-add');
  const nombre    = this.nombre.value.trim();
  const username  = this.username.value.trim();
  const id_rol    = this['id_rol'].value;
  const pwd       = this.password.value;
  const confirmar = this.confirmar.value;

  if (!nombre || !username || !id_rol || id_rol === '0') {
    e.preventDefault();
    mostrarErrorModal('modal-add', 'Todos los campos son obligatorios.');
    return;
  }
  const err = validarPassword(pwd, confirmar, true);
  if (err) { e.preventDefault(); mostrarErrorModal('modal-add', err); }
});

/* Validar form de EDITAR usuario */
document.getElementById('form-edit').addEventListener('submit', function(e) {
  limpiarErrorModal('modal-edit');
  const nombre    = this.nombre.value.trim();
  const username  = this.username.value.trim();
  const id_rol    = this['id_rol'].value;
  const pwd       = this.password.value;
  const confirmar = this.confirmar.value;

  if (!nombre || !username || !id_rol) {
    e.preventDefault();
    mostrarErrorModal('modal-edit', 'Nombre, usuario y rol son obligatorios.');
    return;
  }
  const err = validarPassword(pwd, confirmar, false);
  if (err) { e.preventDefault(); mostrarErrorModal('modal-edit', err); }
});

/* Limpiar errores al hacer clic en el backdrop */
['modal-add', 'modal-edit'].forEach(id => {
  document.getElementById(id).addEventListener('click', function(e) {
    if (e.target === this) limpiarErrorModal(id);
  });
});

/* ── Filtro de tabla ── */
function filterTable() {
  const q       = document.getElementById('searchInput').value.toLowerCase();
  const rol     = document.getElementById('filterRol').value;
  const estatus = document.getElementById('filterEstatus').value;
  const rows    = document.querySelectorAll('#usuariosTable tbody tr');
  let visible   = 0;
  rows.forEach(row => {
    const text      = row.textContent.toLowerCase();
    const rowRol    = row.dataset.rol;
    const rowEst    = row.dataset.estatus;
    const matchText = !q       || text.includes(q);
    const matchRol  = !rol     || rowRol === rol;
    const matchEst  = !estatus || rowEst === estatus;
    const show = matchText && matchRol && matchEst;
    row.style.display = show ? '' : 'none';
    if (show) visible++;
  });
  document.getElementById('visibleCount').textContent = visible;
}
