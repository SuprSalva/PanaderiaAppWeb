const PEDIDOS_MIS_PEDIDOS_ICONS = {
  markRead: `<animated-icons src="/static/icons/success-2cb0da6b.json" trigger="loop" attributes='{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#559C27FF","background":"#FFFFFF"}}' height="30" width="30"></animated-icons>`
};

function switchTab(tabName, el) {
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
  el.classList.add('active');
  document.getElementById('tab-content-' + tabName).classList.add('active');
}

function injectMisPedidosIcons() {
  const btn = document.getElementById('btn-marcar-leidas');
  if (!btn || btn.dataset.iconInjected) return;
  btn.innerHTML = `${PEDIDOS_MIS_PEDIDOS_ICONS.markRead} Marcar todas como leídas`;
  btn.dataset.iconInjected = '1';
}

document.addEventListener('DOMContentLoaded', injectMisPedidosIcons);

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
