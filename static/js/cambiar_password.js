  const PWD_RE = /^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$/;
  const nueva     = document.getElementById('pwd-nueva');
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

  document.getElementById('form-pwd').addEventListener('submit', function(e) {
    const err = document.getElementById('form-error');
    err.style.display = 'none';

    const actual = this.password_actual.value;
    const nv     = nueva.value;
    const conf   = confirmar.value;

    if (!actual || !nv || !conf) {
      e.preventDefault(); err.textContent = '⚠️ Todos los campos son obligatorios.'; err.style.display = 'block'; return;
    }
    if (!PWD_RE.test(nv)) {
      e.preventDefault(); err.textContent = '⚠️ La contraseña no cumple los requisitos de seguridad.'; err.style.display = 'block'; return;
    }
    if (nv !== conf) {
      e.preventDefault(); err.textContent = '⚠️ Las contraseñas no coinciden.'; err.style.display = 'block'; return;
    }
  });
