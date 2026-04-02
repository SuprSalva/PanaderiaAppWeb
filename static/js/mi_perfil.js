  document.getElementById('form-perfil').addEventListener('submit', function(e) {
    const err = document.getElementById('form-error');
    err.style.display = 'none';
    const nombre   = this.nombre.value.trim();
    const username = this.username.value.trim();
    if (!nombre || !username) {
      e.preventDefault();
      err.textContent = '⚠️ Nombre y usuario son obligatorios.';
      err.style.display = 'block';
    }
  });
