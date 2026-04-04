  document.querySelectorAll('.flash-error, .flash-success').forEach(function(el) {
    setTimeout(function() {
      el.style.transition = 'opacity .5s ease';
      el.style.opacity = '0';
      setTimeout(function() { el.style.display = 'none'; }, 500);
    }, 5000);
  });
