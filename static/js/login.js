document.querySelectorAll('.flash-error, .flash-success').forEach(function(el) {
  setTimeout(function() {
    el.style.transition = 'opacity .5s ease';
    el.style.opacity = '0';
    setTimeout(function() { el.style.display = 'none'; }, 500);
  }, 5000);
});

document.querySelector('form').addEventListener('submit', function(e) {
  var errEl = document.getElementById('login-captcha-error');
  var token = (typeof grecaptcha !== 'undefined') ? grecaptcha.getResponse() : '';
  if (!token) {
    e.preventDefault();
    errEl.textContent = '⚠️ Completa el reCAPTCHA para continuar.';
    errEl.style.display = 'block';
  } else {
    errEl.style.display = 'none';
  }
});
