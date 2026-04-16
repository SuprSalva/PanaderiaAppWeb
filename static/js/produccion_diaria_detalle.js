window.cerrarModal = id => {
  document.getElementById(id).classList.remove('open');
  document.body.style.overflow = '';
};
const abrirModal = id => {
  document.getElementById(id).classList.add('open');
  document.body.style.overflow = 'hidden';
};
document.querySelectorAll('.modal-bd').forEach(m =>
  m.addEventListener('click', e => {
    if (e.target === m) { m.classList.remove('open'); document.body.style.overflow = ''; }
  })
);
window.abrirFinalizar        = () => abrirModal('modalFinalizar');
window.abrirCancelar         = () => abrirModal('modalCancelar');
window.abrirGuardarPlantilla = () => abrirModal('modalPlantilla');
window.abrirConfirm          = () => abrirModal('modalConfirm');
