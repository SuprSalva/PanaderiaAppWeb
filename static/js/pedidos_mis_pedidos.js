function switchTab(tabName, el) {
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
  el.classList.add('active');
  document.getElementById('tab-content-' + tabName).classList.add('active');
}

function marcarLeidas() {
  fetch(window.URL_MARCAR_LEIDAS, {
    method: 'POST',
    headers: { 'X-CSRFToken': window.CSRF_TOKEN }
  })
  .then(r => r.json())
  .then(data => {
    if (data.ok) {
      document.querySelectorAll('.notif-item.unread').forEach(el => el.classList.remove('unread'));
      const btn = document.getElementById('btn-marcar-leidas');
      if(btn) btn.remove();
      const badge = document.getElementById('badge-notif-count');
      if(badge) badge.remove();
    }
  });
}
