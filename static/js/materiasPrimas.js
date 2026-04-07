// Debounce para búsqueda
let _debounce = null;
function debounceSubmit() {
  clearTimeout(_debounce);
  _debounce = setTimeout(() => {
    document.getElementById('form-filtro').submit();
  }, 500);
}

// Filtro por nivel de stock (estadísticas)
function filtrarPorNivelStock(nivel) {
  document.getElementById('nivel_stock').value = nivel;
  document.querySelector('input[name="pagina"]').value = '1';
  document.getElementById('form-filtro').submit();
}