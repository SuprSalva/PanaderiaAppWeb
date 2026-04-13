// Flash auto-hide
document.querySelectorAll('.flash-error, .flash-success').forEach(function(el) {
  setTimeout(function() {
    el.style.transition = 'opacity .5s ease';
    el.style.opacity = '0';
    setTimeout(function() { el.style.display = 'none'; }, 500);
  }, 5000);
});

// ── helpers ──────────────────────────────────────────────────────────────────
function mostrarError(elId, msg) {
  var el = document.getElementById(elId);
  if (!el) return;
  el.innerHTML = `<span style="display:inline-flex; align-items:center; gap:0.35rem; vertical-align:middle;"><animated-icons src=\"/static/icons/alert-4ff92fe8.json\" trigger=\"loop\" attributes='{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#E07A52FF","background":"#FFFFFF"}}' height=\"20\" width=\"20\"></animated-icons><span>${msg}</span></span>`;
  el.style.display = 'flex';
  el.style.justifyContent = 'center';
  el.style.alignItems = 'center';
}
function ocultarError(elId) {
  var el = document.getElementById(elId);
  if (el) el.style.display = 'none';
}

function mostrarSeccion(id) {
  ['sec-login', 'sec-forgot-1', 'sec-forgot-2'].forEach(function(s) {
    document.getElementById(s).style.display = (s === id) ? 'block' : 'none';
  });
}

// ── Navegación entre secciones ───────────────────────────────────────────────
// Validar reCAPTCHA antes de enviar el login
document.querySelector('#sec-login form').addEventListener('submit', function(e) {
  var errEl = document.getElementById('login-captcha-error');
  var token = (typeof grecaptcha !== 'undefined') ? grecaptcha.getResponse(_rcLogin) : '';
  if (!token) {
    e.preventDefault();
    errEl.innerHTML = `<span style="display:inline-flex; align-items:center; gap:0.35rem; vertical-align:middle;"><animated-icons src=\"/static/icons/alert-4ff92fe8.json\" trigger=\"loop\" attributes='{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#E07A52FF","background":"#FFFFFF"}}' height=\"20\" width=\"20\"></animated-icons><span> Completa el reCAPTCHA para continuar.</span></span>`;
    errEl.style.display = 'flex';
    errEl.style.justifyContent = 'center';
    errEl.style.alignItems = 'center';
  } else {
    errEl.style.display = 'none';
  }
});

document.getElementById('link-forgot').addEventListener('click', function(e) {
  e.preventDefault();
  ocultarError('forgot1-error');
  mostrarSeccion('sec-forgot-1');
  document.getElementById('forgot-correo').focus();
});

document.getElementById('link-volver-login').addEventListener('click', function(e) {
  e.preventDefault();
  if (typeof grecaptcha !== 'undefined') grecaptcha.reset(_rcForgot);
  ocultarError('forgot1-error');
  ocultarError('forgot-captcha-error');
  mostrarSeccion('sec-login');
});

document.getElementById('link-volver-forgot1').addEventListener('click', function(e) {
  e.preventDefault();
  ocultarError('forgot2-error');
  if (typeof grecaptcha !== 'undefined') grecaptcha.reset(_rcForgot);
  mostrarSeccion('sec-forgot-1');
});

// ── Paso 1: solicitar código ──────────────────────────────────────────────────
document.getElementById('btn-enviar-codigo').addEventListener('click', function() {
  ocultarError('forgot1-error');
  ocultarError('forgot-captcha-error');

  var correo = document.getElementById('forgot-correo').value.trim();
  if (!correo) {
    mostrarError('forgot1-error', 'Ingresa tu correo electrónico.');
    return;
  }

  var captchaToken = (typeof grecaptcha !== 'undefined') ? grecaptcha.getResponse(_rcForgot) : '';
  if (!captchaToken) {
    document.getElementById('forgot-captcha-error').innerHTML = `<span style="display:inline-flex; align-items:center; gap:0.35rem; vertical-align:middle;"><animated-icons src=\"/static/icons/alert-4ff92fe8.json\" trigger=\"loop\" attributes='{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#E07A52FF","background":"#FFFFFF"}}' height=\"20\" width=\"20\"></animated-icons><span> Completa el reCAPTCHA para continuar.</span></span>`;
    document.getElementById('forgot-captcha-error').style.display = 'flex';
    document.getElementById('forgot-captcha-error').style.justifyContent = 'center';
    document.getElementById('forgot-captcha-error').style.alignItems = 'center';
    return;
  }

  var btn = this;
  btn.disabled = true;
  btn.textContent = 'Enviando…';

  var csrf = document.querySelector('input[name="csrf_token"]');
  var formData = new FormData();
  formData.append('correo', correo);
  formData.append('g-recaptcha-response', captchaToken);
  if (csrf) formData.append('csrf_token', csrf.value);

  fetch('/cliente/recuperar/solicitar', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(res) {
      if (res.ok) {
        document.getElementById('forgot2-desc').innerHTML =
          'Se envió un código de 6 dígitos a <strong>' + correo + '</strong>.<br>' +
          'Ingrésalo junto con tu nueva contraseña para continuar.';
        document.getElementById('forgot-codigo').value = '';
        document.getElementById('forgot-nueva-pwd').value = '';
        document.getElementById('forgot-confirmar-pwd').value = '';
        document.getElementById('forgot-match-msg').textContent = '';
        ocultarError('forgot2-error');
        mostrarSeccion('sec-forgot-2');
        document.getElementById('forgot-codigo').focus();
      } else {
        mostrarError('forgot1-error', res.error || 'Error al enviar el código.');
        if (typeof grecaptcha !== 'undefined') grecaptcha.reset(_rcForgot);
      }
    })
    .catch(function() {
      mostrarError('forgot1-error', 'Error de red. Intenta de nuevo.');
      if (typeof grecaptcha !== 'undefined') grecaptcha.reset(_rcForgot);
    })
    .finally(function() {
      btn.disabled = false;
      btn.innerHTML = 'Enviar Código <animated-icons src="https://animatedicons.co/get-icon?name=exit&style=minimalistic&token=6e09845f-509a-4b0a-a8b0-c47e168ad977" trigger="loop" attributes=\'{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#E07A52FF","background":"#FFFFFF"}}\' height="30" width="30"></animated-icons>';
    });
});

// ── Indicador match contraseñas ───────────────────────────────────────────────
(function() {
  var nuevaPwd    = document.getElementById('forgot-nueva-pwd');
  var confirmarPwd = document.getElementById('forgot-confirmar-pwd');
  var matchMsg    = document.getElementById('forgot-match-msg');

  function checkMatch() {
    if (!confirmarPwd.value) { matchMsg.textContent = ''; return; }
    if (nuevaPwd.value === confirmarPwd.value) {
      matchMsg.style.color = '#3a6034';
      matchMsg.textContent = '✔ Las contraseñas coinciden';
    } else {
      matchMsg.style.color = '#9c3a1a';
      matchMsg.textContent = '✖ Las contraseñas no coinciden';
    }
  }
  confirmarPwd.addEventListener('input', checkMatch);
  nuevaPwd.addEventListener('input', checkMatch);
})();

// ── Paso 2: verificar código y cambiar contraseña ────────────────────────────
var PWD_RE = /^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_]).{8,}$/;

document.getElementById('btn-cambiar-pwd').addEventListener('click', function() {
  ocultarError('forgot2-error');

  var codigo   = document.getElementById('forgot-codigo').value.trim();
  var nuevaPwd = document.getElementById('forgot-nueva-pwd').value;
  var confirmar = document.getElementById('forgot-confirmar-pwd').value;

  if (!codigo) {
    mostrarError('forgot2-error', 'Ingresa el código de 6 dígitos.');
    return;
  }
  if (!nuevaPwd) {
    mostrarError('forgot2-error', 'Ingresa tu nueva contraseña.');
    return;
  }
  if (!PWD_RE.test(nuevaPwd)) {
    mostrarError('forgot2-error', 'La contraseña no cumple los requisitos de seguridad.');
    return;
  }
  if (nuevaPwd !== confirmar) {
    mostrarError('forgot2-error', 'Las contraseñas no coinciden.');
    return;
  }

  var btn = this;
  btn.disabled = true;
  btn.textContent = 'Verificando…';

  var csrf = document.querySelector('input[name="csrf_token"]');
  var formData = new FormData();
  formData.append('codigo', codigo);
  formData.append('nueva_password', nuevaPwd);
  formData.append('confirmar_password', confirmar);
  if (csrf) formData.append('csrf_token', csrf.value);

  fetch('/cliente/recuperar/cambiar', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(res) {
      if (res.ok) {
        window.location.href = res.redirect || '/cliente/login';
      } else {
        // Si el código expiró por demasiados intentos, regresar al paso 1
        if (res.error && res.error.indexOf('Demasiados') !== -1) {
          if (typeof grecaptcha !== 'undefined') grecaptcha.reset(_rcForgot);
          mostrarSeccion('sec-forgot-1');
          mostrarError('forgot1-error', res.error);
        } else {
          mostrarError('forgot2-error', res.error || 'Error al actualizar la contraseña.');
        }
        btn.disabled = false;
        btn.innerHTML = 'Actualizar Contraseña <animated-icons src="https://animatedicons.co/get-icon?name=exit&style=minimalistic&token=6e09845f-509a-4b0a-a8b0-c47e168ad977" trigger="loop" attributes=\'{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#E07A52FF","background":"#FFFFFF"}}\' height="30" width="30"></animated-icons>';
      }
    })
    .catch(function() {
      mostrarError('forgot2-error', 'Error de red. Intenta de nuevo.');
      btn.disabled = false;
      btn.innerHTML = 'Actualizar Contraseña <animated-icons src="https://animatedicons.co/get-icon?name=exit&style=minimalistic&token=6e09845f-509a-4b0a-a8b0-c47e168ad977" trigger="loop" attributes=\'{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#E07A52FF","background":"#FFFFFF"}}\' height="30" width="30"></animated-icons>';
    });
});
