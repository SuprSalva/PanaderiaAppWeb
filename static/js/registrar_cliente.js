// Flash auto-hide
document.querySelectorAll('.flash-error, .flash-success').forEach(function(el) {
  setTimeout(function() {
    el.style.transition = 'opacity .5s ease';
    el.style.opacity = '0';
    setTimeout(function() { el.style.display = 'none'; }, 4000);
  }, 4000);
});

// ── helpers ──────────────────────────────────────────────────────────────────
function mostrarError(elId, msg) {
  var el = document.getElementById(elId);
  if (!el) return;
  el.textContent = '⚠️ ' + msg;
  el.style.display = 'block';
}
function ocultarError(elId) {
  var el = document.getElementById(elId);
  if (el) el.style.display = 'none';
}

// ── Indicador match contraseñas ───────────────────────────────────────────────
var pwd  = document.getElementById('reg-password');
var conf = document.getElementById('reg-confirmar');
var msg  = document.getElementById('reg-match-msg');

function checkMatch() {
  if (!conf.value) { msg.textContent = ''; return; }
  if (pwd.value === conf.value) {
    msg.style.color = '#3a6034';
    msg.textContent = '✔ Las contraseñas coinciden';
  } else {
    msg.style.color = '#9c3a1a';
    msg.textContent = '✖ Las contraseñas no coinciden';
  }
}
conf.addEventListener('input', checkMatch);
pwd.addEventListener('input', checkMatch);

// ── Paso 1: validar reCAPTCHA y enviar código ────────────────────────────────
document.getElementById('btn-reg-submit').addEventListener('click', function() {
  ocultarError('reg-error-global');

  // Verificar que reCAPTCHA esté completado
  var recaptchaResponse = '';
  if (typeof grecaptcha !== 'undefined') {
    recaptchaResponse = grecaptcha.getResponse();
  }
  if (!recaptchaResponse) {
    mostrarError('reg-error-global', 'Por favor completa el reCAPTCHA antes de continuar.');
    return;
  }

  var btn = this;
  btn.disabled = true;
  btn.textContent = 'Enviando…';

  var form = document.getElementById('form-reg');
  var formData = new FormData(form);

  fetch('/cliente/registro/verificar', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(res) {
      if (res.ok) {
        var emailInput = form.querySelector('input[name="username"]');
        var correo = emailInput ? emailInput.value.trim() : '';
        document.getElementById('verify-desc').innerHTML =
          'Se envió un código de 6 dígitos a <strong>' + correo + '</strong>.<br>' +
          'Ingrésalo a continuación para activar tu cuenta.';
        document.getElementById('section-form').style.display = 'none';
        document.getElementById('section-verify').style.display = 'block';
        document.getElementById('verify-codigo').focus();
      } else {
        mostrarError('reg-error-global', res.error || 'Error al procesar el registro.');
        if (typeof grecaptcha !== 'undefined') grecaptcha.reset();
      }
    })
    .catch(function() {
      mostrarError('reg-error-global', 'Error de red. Intenta de nuevo.');
      if (typeof grecaptcha !== 'undefined') grecaptcha.reset();
    })
    .finally(function() {
      btn.disabled = false;
      btn.textContent = '✅ Continuar';
    });
});

// ── Volver al formulario ──────────────────────────────────────────────────────
document.getElementById('link-volver-reg').addEventListener('click', function(e) {
  e.preventDefault();
  ocultarError('verify-error');
  document.getElementById('section-verify').style.display = 'none';
  document.getElementById('section-form').style.display = 'block';
  if (typeof grecaptcha !== 'undefined') grecaptcha.reset();
});

// ── Paso 2: verificar código y crear cuenta ───────────────────────────────────
document.getElementById('form-verify').addEventListener('submit', function(e) {
  e.preventDefault();
  ocultarError('verify-error');

  var codigo = document.getElementById('verify-codigo').value.trim();
  if (!codigo) {
    mostrarError('verify-error', 'Ingresa el código de 6 dígitos.');
    return;
  }

  var btn = document.getElementById('btn-verify-submit');
  btn.disabled = true;
  btn.textContent = 'Verificando…';

  var formData = new FormData(this);

  fetch('/cliente/registro', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(res) {
      if (res.ok) {
        window.location.href = res.redirect || '/cliente/login';
      } else {
        // Si el código expiró por demasiados intentos, regresar al formulario
        if (res.error && res.error.indexOf('Demasiados') !== -1) {
          document.getElementById('section-verify').style.display = 'none';
          document.getElementById('section-form').style.display = 'block';
          if (typeof grecaptcha !== 'undefined') grecaptcha.reset();
          mostrarError('reg-error-global', res.error);
        } else {
          mostrarError('verify-error', res.error || 'Error al verificar el código.');
        }
        btn.disabled = false;
        btn.textContent = '✅ Crear Cuenta';
      }
    })
    .catch(function() {
      mostrarError('verify-error', 'Error de red. Intenta de nuevo.');
      btn.disabled = false;
      btn.textContent = '✅ Crear Cuenta';
    });
});
