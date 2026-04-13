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
    errEl.innerHTML = `<span style="display:inline-flex; align-items:center; gap:0.35rem; vertical-align:middle;"><animated-icons src=\"/static/icons/alert-4ff92fe8.json\" trigger=\"loop\" attributes='{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#E07A52FF","background":"#FFFFFF"}}' height=\"20\" width=\"20\"></animated-icons><span>Completa el reCAPTCHA para continuar.</span></span>`;
    errEl.style.display = 'flex';
    errEl.style.justifyContent = 'center';
    errEl.style.alignItems = 'center';
  } else {
    errEl.style.display = 'none';
  }
});
