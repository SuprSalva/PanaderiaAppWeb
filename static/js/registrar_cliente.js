document.querySelectorAll('.flash-error, .flash-success').forEach(function(el) {
  setTimeout(function() {
    el.style.transition = 'opacity .5s ease';
    el.style.opacity = '0';
    setTimeout(function() { el.style.display = 'none'; }, 500);
  }, 4000);
});

const pwd  = document.getElementById('reg-password');
const conf = document.getElementById('reg-confirmar');
const msg  = document.getElementById('reg-match-msg');

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
