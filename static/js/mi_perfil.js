var _originalEmail = document.getElementById('perfil-email').value.trim();
var perfilFormSubmitting = false;

function mostrarErrorPerfil(elId, msg) {
  var el = document.getElementById(elId);
  if (!el) return;
  el.textContent = '⚠️ ' + msg;
  el.style.display = 'block';
}
function ocultarErrorPerfil(elId) {
  var el = document.getElementById(elId);
  if (el) el.style.display = 'none';
}

function volverPerfilForm() {
  document.getElementById('section-perfil-verify').style.display = 'none';
  document.getElementById('section-perfil-form').style.display = 'block';
  ocultarErrorPerfil('perfil-verify-error');
}

// ── Paso 1: guardar cambios (con o sin cambio de correo) ─────────────────────
document.getElementById('form-perfil').addEventListener('submit', function(e) {
  e.preventDefault();
  if (perfilFormSubmitting) {
    return;
  }
  ocultarErrorPerfil('form-error');

  var nombre    = this.nombre.value.trim();
  var nuevoEmail = document.getElementById('perfil-email').value.trim();

  if (!nombre || !nuevoEmail) {
    mostrarErrorPerfil('form-error', 'Nombre y correo son obligatorios.');
    return;
  }

  var emailCambio = nuevoEmail !== _originalEmail;
  perfilFormSubmitting = true;

  if (emailCambio) {
    // Enviar código de verificación al nuevo correo
    var btn = document.getElementById('btn-guardar-perfil');
    btn.disabled = true;
    btn.textContent = 'Enviando…';

    var fd = new FormData(this);
    fetch('/mi-perfil/verificar-email', { method: 'POST', body: fd })
      .then(function(r) { return r.json(); })
      .then(function(res) {
        if (res.ok) {
          document.getElementById('perfil-verify-desc').innerHTML =
            'Se envió un código de 6 dígitos a <strong>' + nuevoEmail + '</strong>.<br>' +
            'Ingrésalo para confirmar el cambio de correo.';
          document.getElementById('perfil-verify-codigo').value = '';
          ocultarErrorPerfil('perfil-verify-error');
          document.getElementById('section-perfil-form').style.display = 'none';
          document.getElementById('section-perfil-verify').style.display = 'block';
          document.getElementById('perfil-verify-codigo').focus();
        } else {
          mostrarErrorPerfil('form-error', res.error || 'Error al enviar el código.');
        }
      })
      .catch(function() { mostrarErrorPerfil('form-error', 'Error de red. Intenta de nuevo.'); })
      .finally(function() {
        btn.disabled = false;
    perfilFormSubmitting = false;
      });

  } else {
    // Sin cambio de correo: guardar directamente
    var btn = document.getElementById('btn-guardar-perfil');
    btn.disabled = true;
    btn.textContent = 'Guardando…';

    var fd = new FormData(this);
    fetch(this.action, { method: 'POST', body: fd })
      .then(function(r) { return r.json(); })
      .then(function(res) {
        if (res.ok) {
          window.location.reload();
        } else {
          mostrarErrorPerfil('form-error', res.error || 'Error al guardar los cambios.');
          btn.disabled = false;
          btn.textContent = '💾 Guardar cambios';
          perfilFormSubmitting = false;
        }
      })
      .catch(function() {
        mostrarErrorPerfil('form-error', 'Error de red. Intenta de nuevo.');
        btn.disabled = false;
        btn.textContent = '💾 Guardar cambios';
        perfilFormSubmitting = false;
      });
  }
});

// ── Paso 2: confirmar código de verificación ─────────────────────────────────
document.getElementById('form-perfil-verify').addEventListener('submit', function(e) {
  e.preventDefault();
  ocultarErrorPerfil('perfil-verify-error');

  var codigo = document.getElementById('perfil-verify-codigo').value.trim();
  if (!codigo) {
    mostrarErrorPerfil('perfil-verify-error', 'Ingresa el código de 6 dígitos.');
    return;
  }

  var btn = document.getElementById('btn-confirmar-perfil');
  btn.disabled = true;
  btn.textContent = 'Verificando…';

  var fd = new FormData(this);
  fetch(this.action, { method: 'POST', body: fd })
    .then(function(r) { return r.json(); })
    .then(function(res) {
      if (res.ok) {
        window.location.reload();
      } else {
        if (res.error && res.error.indexOf('Demasiados') !== -1) {
          volverPerfilForm();
          mostrarErrorPerfil('form-error', res.error);
        } else {
          mostrarErrorPerfil('perfil-verify-error', res.error || 'Código incorrecto.');
        }
        btn.disabled = false;
        btn.textContent = '✅ Confirmar cambio';
      }
    })
    .catch(function() {
      mostrarErrorPerfil('perfil-verify-error', 'Error de red. Intenta de nuevo.');
      btn.disabled = false;
      btn.textContent = '✅ Confirmar cambio';
    });
});
