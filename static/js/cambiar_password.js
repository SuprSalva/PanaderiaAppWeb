const PWD_RE   = /^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_]).{8,}$/;
const nueva    = document.getElementById('pwd-nueva');
const confirmar = document.getElementById('pwd-confirmar');
const matchMsg  = document.getElementById('pwd-match-msg');

confirmar.addEventListener('input', () => {
  if (!confirmar.value) { matchMsg.textContent = ''; return; }
  if (nueva.value === confirmar.value) {
    matchMsg.style.color = '#3a6034';
    matchMsg.textContent = '✔ Las contraseñas coinciden';
  } else {
    matchMsg.style.color = '#9c3a1a';
    matchMsg.textContent = '✖ Las contraseñas no coinciden';
  }
});

function mostrarError(elId, msg) {
  const el = document.getElementById(elId);
  el.textContent = '⚠️ ' + msg;
  el.style.display = 'block';
}
function ocultarError(elId) {
  const el = document.getElementById(elId);
  if (el) el.style.display = 'none';
}

function volverAlFormulario() {
  document.getElementById('section-verify').style.display = 'none';
  document.getElementById('section-form').style.display   = 'block';
  document.getElementById('verify-pwd-codigo').value = '';
  ocultarError('verify-pwd-error');
}

/* ── PASO 1: validar y enviar código ── */
document.getElementById('form-pwd').addEventListener('submit', function(e) {
  e.preventDefault();
  ocultarError('form-error');

  const actual = this.password_actual.value;
  const nv     = nueva.value;
  const conf   = confirmar.value;

  if (!actual || !nv || !conf) {
    mostrarError('form-error', 'Todos los campos son obligatorios.'); return;
  }
  if (!PWD_RE.test(nv)) {
    mostrarError('form-error', 'La contraseña no cumple los requisitos de seguridad.'); return;
  }
  if (nv !== conf) {
    mostrarError('form-error', 'Las contraseñas no coinciden.'); return;
  }

  const btn = document.getElementById('btn-enviar');
  btn.disabled = true;
  btn.textContent = 'Enviando código…';

  const data = new FormData(this);

  fetch('/cambiar-password/verificar', { method: 'POST', body: data })
    .then(r => r.json())
    .then(res => {
      if (res.ok) {
        document.getElementById('section-form').style.display   = 'none';
        document.getElementById('section-verify').style.display = 'block';
        document.getElementById('verify-pwd-codigo').value = '';
        document.getElementById('verify-pwd-desc').innerHTML =
          'Se envió un código de 6 dígitos a <strong>' + res.correo + '</strong>.<br>' +
          'Ingrésalo a continuación para confirmar el cambio de contraseña.';
        document.getElementById('verify-pwd-codigo').focus();
      } else {
        mostrarError('form-error', res.error || 'Error al enviar el código.');
      }
    })
    .catch(() => mostrarError('form-error', 'Error de red. Intenta de nuevo.'))
    .finally(() => {
      btn.disabled = false;
      btn.textContent = '✉️ Enviar Código';
    });
});

/* ── PASO 2: verificar código y cambiar contraseña ── */
document.getElementById('form-verify-pwd').addEventListener('submit', function(e) {
  e.preventDefault();
  ocultarError('verify-pwd-error');

  const codigo = document.getElementById('verify-pwd-codigo').value.trim();
  if (!codigo) {
    mostrarError('verify-pwd-error', 'Ingresa el código de 6 dígitos.'); return;
  }

  const btn = document.getElementById('btn-confirmar');
  btn.disabled = true;
  btn.textContent = 'Verificando…';

  const data = new FormData(this);

  fetch('/cambiar-password', { method: 'POST', body: data })
    .then(r => r.json())
    .then(res => {
      if (res.ok) {
        window.location.href = '/cambiar-password';
      } else {
        // Si el código expiró por demasiados intentos, regresar al formulario
        if (res.error && res.error.indexOf('Demasiados') !== -1) {
          volverAlFormulario();
          mostrarError('form-error', res.error);
        } else {
          mostrarError('verify-pwd-error', res.error || 'Error al verificar.');
        }
        btn.disabled = false;
        btn.textContent = '✅ Confirmar Cambio';
      }
    })
    .catch(() => {
      mostrarError('verify-pwd-error', 'Error de red. Intenta de nuevo.');
      btn.disabled = false;
      btn.textContent = '✅ Confirmar Cambio';
    });
});
