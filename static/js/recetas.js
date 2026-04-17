(function () {
  'use strict';

  const POR_PAGINA = 9;

  var TODAS_LAS_CARDS = [];
  var CARDS_VISIBLES  = [];
  var paginaActual    = 1;

  var CFG = {};

  var _filaMiniModal = null;

  document.addEventListener('DOMContentLoaded', function () {
    CFG = window.__RECETAS_CONFIG__ || {};

    TODAS_LAS_CARDS = Array.from(
      document.querySelectorAll('#recetas-grid .receta-card')
    );

    var inp = document.getElementById('buscador-recetas');
    var sel = document.getElementById('filtro-estatus');
    if (inp) inp.addEventListener('input',  filtrarYRenderizar);
    if (sel) sel.addEventListener('change', filtrarYRenderizar);

    filtrarYRenderizar();

    var miFactor = document.getElementById('mini-factor');
    var miSimbolo= document.getElementById('mini-simbolo');
    if (miFactor) miFactor.addEventListener('input', actualizarHintFactor);
    if (miSimbolo)miSimbolo.addEventListener('input', actualizarHintFactor);

    _initEditarInsumos();
  });

  function filtrarYRenderizar() {
    var q       = (document.getElementById('buscador-recetas') || {}).value || '';
    var estatus = (document.getElementById('filtro-estatus')   || {}).value || 'todos';
    q = q.toLowerCase().trim();

    CARDS_VISIBLES = TODAS_LAS_CARDS.filter(function (card) {
      var nombre   = (card.dataset.nombre   || '').toLowerCase();
      var producto = (card.dataset.producto || '').toLowerCase();
      var ok_q   = !q || nombre.includes(q) || producto.includes(q);
      var ok_est = estatus === 'todos' || card.dataset.estatus === estatus;
      return ok_q && ok_est;
    });

    paginaActual = 1;
    renderizarPagina();
  }

  function renderizarPagina() {
    var total  = CARDS_VISIBLES.length;
    var paginas = Math.max(1, Math.ceil(total / POR_PAGINA));
    if (paginaActual > paginas) paginaActual = paginas;

    var desde = (paginaActual - 1) * POR_PAGINA;
    var hasta = desde + POR_PAGINA;

    TODAS_LAS_CARDS.forEach(function (c) { c.style.display = 'none'; });
    CARDS_VISIBLES.forEach(function (c, i) {
      c.style.display = (i >= desde && i < hasta) ? '' : 'none';
    });

    var vacioEl = document.getElementById('recetas-vacio');
    if (vacioEl) vacioEl.style.display = total === 0 ? '' : 'none';

    _renderPaginador(total, paginas);
  }

  function _renderPaginador(total, paginas) {
    var desde = total === 0 ? 0 : (paginaActual - 1) * POR_PAGINA + 1;
    var hasta = Math.min(paginaActual * POR_PAGINA, total);

    var infoEl = document.getElementById('pag-info');
    if (infoEl) {
      infoEl.innerHTML = total === 0
        ? 'Sin resultados'
        : 'Mostrando <strong>' + desde + '</strong>–<strong>' + hasta +
          '</strong> de <strong>' + total + '</strong> receta' + (total !== 1 ? 's' : '');
    }

    var ctrl = document.getElementById('pag-controles');
    if (!ctrl) return;
    if (paginas <= 1) { ctrl.innerHTML = ''; return; }

    var html = '';
    html += paginaActual > 1
      ? '<button class="pag-btn" onclick="window._recetasIrPagina(' + (paginaActual - 1) + ')">‹</button>'
      : '<span class="pag-btn disabled">‹</span>';

    for (var n = 1; n <= paginas; n++) {
      var cercano = (n >= paginaActual - 2 && n <= paginaActual + 2);
      var extremo = (n === 1 || n === paginas);
      if (!cercano && !extremo) {
        if (n === paginaActual - 3 || n === paginaActual + 3) {
          html += '<span class="pag-puntos">…</span>';
        }
        continue;
      }
      var cls = n === paginaActual ? 'pag-btn activo' : 'pag-btn';
      html += '<button class="' + cls + '" onclick="window._recetasIrPagina(' + n + ')">' + n + '</button>';
    }

    html += paginaActual < paginas
      ? '<button class="pag-btn" onclick="window._recetasIrPagina(' + (paginaActual + 1) + ')">›</button>'
      : '<span class="pag-btn disabled">›</span>';

    ctrl.innerHTML = html;
  }

  window._recetasIrPagina = function (n) {
    paginaActual = n;
    renderizarPagina();
    var grid = document.getElementById('recetas-grid');
    if (grid) grid.scrollIntoView({ behavior: 'smooth', block: 'start' });
  };

  window.cargarUnidades = async function (idMateria, selUnidad, unidadBase, idUnidadSel) {
    if (!idMateria) {
      selUnidad.innerHTML = '<option value="">— unidad base —</option>';
      return;
    }
    selUnidad.classList.add('cargando');
    try {
      var res  = await fetch(CFG.urlUnidades + idMateria);
      var data = await res.json();
      var html = '<option value="">— ' + data.unidad_base + ' (base) —</option>';
      data.unidades.forEach(function (u) {
        var sel = (idUnidadSel && parseInt(u.id) === parseInt(idUnidadSel)) ? 'selected' : '';
        html += '<option value="' + u.id + '" data-factor="' + u.factor +
                '" data-simbolo="' + u.simbolo + '" ' + sel + '>' +
                u.nombre + ' (' + u.simbolo + ')</option>';
      });
      selUnidad.innerHTML = html;
      window.actualizarHint(selUnidad);
    } catch (e) {
      selUnidad.innerHTML = '<option value="">— unidad base —</option>';
    } finally {
      selUnidad.classList.remove('cargando');
    }
  };

  window.actualizarHint = function (selUnidad) {
    var fila   = selUnidad.closest('.ins-row');
    var hint   = fila ? fila.nextElementSibling : null;
    if (!hint || !hint.classList.contains('hint-row')) return;
    var inpCant = fila.querySelector('.inp-cantidad');
    var inpVal  = fila.querySelector('.insumo-val');
    var cant    = parseFloat(inpCant ? inpCant.value : 0) || 0;
    var opt     = selUnidad.options[selUnidad.selectedIndex];
    var factor  = opt ? parseFloat(opt.dataset.factor) : NaN;
    var simbolo = opt ? opt.dataset.simbolo : '';
    var uBase   = inpVal ? inpVal.dataset.unidadBase : '';
    if (cant > 0 && factor && simbolo) {
      var base = Math.round(cant * factor * 10000) / 10000;
      hint.innerHTML = '<span style="color:var(--brown)">↳ ' + cant + ' ' + simbolo +
                       ' = <strong>' + base + ' ' + uBase + '</strong> (se descuenta del inventario)</span>';
    } else {
      hint.innerHTML = '';
    }
  };

  window.seleccionarOpcion = function (op) {
    var wrap      = op.closest('.insumo-wrap');
    var input     = wrap.querySelector('.insumo-buscar');
    var val       = wrap.querySelector('.insumo-val');
    var lista     = wrap.querySelector('.insumo-lista');
    var fila      = wrap.closest('.ins-row');
    var selUnidad = fila.querySelector('.sel-unidad');
    input.value            = op.dataset.txt;
    val.value              = op.dataset.val;
    val.dataset.unidadBase = op.dataset.unidadBase || '';
    input.classList.remove('abierto');
    lista.classList.remove('abierta');
    lista.querySelectorAll('.insumo-opcion').forEach(function (o) { o.classList.remove('activo'); });
    op.classList.add('activo');
    window.cargarUnidades(parseInt(op.dataset.val), selUnidad, op.dataset.unidadBase, null);
  };

  window.abrirLista = function (input) {
    var lista = input.closest('.insumo-wrap').querySelector('.insumo-lista');
    document.querySelectorAll('.insumo-lista.abierta').forEach(function (l) {
      if (l !== lista) l.classList.remove('abierta');
    });
    lista.classList.add('abierta');
    input.classList.add('abierto');
    lista.querySelectorAll('.insumo-opcion').forEach(function (op) { op.classList.remove('oculto'); });
    lista.querySelector('.insumo-sin-res').style.display = 'none';
  };

  window.buscarInsumo = function (input) {
    var q    = input.value.toLowerCase().trim();
    var wrap = input.closest('.insumo-wrap');
    var lista = wrap.querySelector('.insumo-lista');
    var hay   = false;
    if (!q) wrap.querySelector('.insumo-val').value = '';
    lista.querySelectorAll('.insumo-opcion').forEach(function (op) {
      var ok = op.dataset.txt.toLowerCase().includes(q);
      op.classList.toggle('oculto', !ok);
      if (ok) hay = true;
    });
    lista.querySelector('.insumo-sin-res').style.display = hay ? 'none' : 'block';
    lista.classList.add('abierta');
  };

  window.cerrarListaDelay = function (input) {
    setTimeout(function () {
      var wrap  = input.closest('.insumo-wrap');
      var lista = wrap.querySelector('.insumo-lista');
      var val   = wrap.querySelector('.insumo-val');
      lista.classList.remove('abierta');
      input.classList.remove('abierto');
      if (!val.value) input.value = '';
    }, 150);
  };

  window.agregarFila = function (contenedorId) {
    var tpl  = document.getElementById('tpl-fila');
    if (!tpl) return;
    var cont  = document.getElementById(contenedorId);
    var clone = tpl.content.cloneNode(true);
    clone.querySelectorAll('input[type=text],input[type=number]').forEach(function (i) { i.value = ''; });
    clone.querySelectorAll('input[type=hidden]').forEach(function (i) {
      i.value = ''; i.dataset.unidadBase = '';
    });
    clone.querySelectorAll('select').forEach(function (s) {
      s.innerHTML = '<option value="">— unidad base —</option>';
    });
    cont.appendChild(clone);
  };

  window.quitarFila = function (btn) {
    var fila = btn.closest('.ins-row');
    var cont = fila.parentElement;
    if (cont.querySelectorAll('.ins-row').length > 1) {
      var hint = fila.nextElementSibling;
      if (hint && hint.classList.contains('hint-row')) hint.remove();
      fila.remove();
    }
  };

  function _initEditarInsumos() {
    document.querySelectorAll('#insumos-edit .ins-row').forEach(function (fila) {
      var valEl     = fila.querySelector('.insumo-val');
      var selUnidad = fila.querySelector('.sel-unidad');
      if (!valEl || !selUnidad) return;
      var idMateria = parseInt(valEl.value) || 0;
      var rawIdUP   = fila.dataset.idUp;
      var idUP      = (rawIdUP && rawIdUP !== '' && rawIdUP !== 'None')
                      ? parseInt(rawIdUP) : null;
      if (idMateria) {
        window.cargarUnidades(idMateria, selUnidad, valEl.dataset.unidadBase || '', idUP);
      }
    });
  }

  window.abrirMiniModal = function (btn) {
    _filaMiniModal = btn.closest('.ins-row');

    var valEl     = _filaMiniModal.querySelector('.insumo-val');
    var buscarEl  = _filaMiniModal.querySelector('.insumo-buscar');
    var idMateria = valEl ? parseInt(valEl.value) : 0;
    var uBase     = valEl ? (valEl.dataset.unidadBase || '—') : '—';

    if (!idMateria) {
      window.DM && window.DM.toast('Selecciona primero un insumo.', 'warning');
      return;
    }

    var nombreEl = document.getElementById('mini-materia-nombre');
    var baseEl   = document.getElementById('mini-unidad-base');
    var nomText  = buscarEl ? buscarEl.value.replace(/\s*\(.*\)$/, '').trim() : '—';
    if (nombreEl) nombreEl.textContent = nomText;
    if (baseEl)   baseEl.textContent   = uBase;

    ['mini-nombre', 'mini-simbolo', 'mini-factor'].forEach(function (id) {
      var el = document.getElementById(id);
      if (el) el.value = '';
    });
    var usoEl = document.getElementById('mini-uso');
    if (usoEl) usoEl.value = 'receta';
    _setMiniError('');
    actualizarHintFactor();

    document.getElementById('mini-overlay-unidad').classList.add('open');
  };

  window.cerrarMiniModal = function () {
    document.getElementById('mini-overlay-unidad').classList.remove('open');
    _filaMiniModal = null;
  };

  function actualizarHintFactor() {
    var factor  = parseFloat((document.getElementById('mini-factor')  || {}).value) || 0;
    var simbolo = ((document.getElementById('mini-simbolo') || {}).value || '').trim();
    var uBase   = (document.getElementById('mini-unidad-base') || {}).textContent || '?';
    var hintEl  = document.getElementById('mini-hint-factor');
    if (!hintEl) return;
    if (factor > 0 && simbolo) {
      hintEl.textContent = '1 ' + simbolo + ' = ' + factor + ' ' + uBase;
    } else {
      hintEl.textContent = '';
    }
  }

  function _setMiniError(msg) {
    var el = document.getElementById('mini-error');
    if (!el) return;
    if (msg) {
      el.textContent  = msg;
      el.style.display = 'block';
    } else {
      el.style.display = 'none';
    }
  }

  window.guardarNuevaUnidad = async function () {
    if (!_filaMiniModal) return;

    var valEl     = _filaMiniModal.querySelector('.insumo-val');
    var idMateria = valEl ? parseInt(valEl.value) : 0;
    var nombre    = (document.getElementById('mini-nombre')  || {}).value.trim();
    var simbolo   = (document.getElementById('mini-simbolo') || {}).value.trim();
    var factor    = parseFloat((document.getElementById('mini-factor') || {}).value);
    var uso       = (document.getElementById('mini-uso') || {}).value || 'receta';

    if (!nombre || !simbolo || !factor || factor <= 0) {
      _setMiniError('Completa todos los campos con valores válidos.');
      return;
    }

    var btnGuardar = document.getElementById('mini-btn-guardar');
    btnGuardar.disabled   = true;
    btnGuardar.textContent = 'Guardando…';
    _setMiniError('');

    try {
      var res = await fetch(CFG.urlNuevaUnidad, {
        method:  'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRFToken':  CFG.csrfToken,
        },
        body: JSON.stringify({
          id_materia:    idMateria,
          nombre:        nombre,
          simbolo:       simbolo,
          factor_a_base: factor,
          uso:           uso,
        }),
      });

      var data = await res.json();

      if (!res.ok) {
        _setMiniError(data.error || 'Error al guardar la unidad.');
        return;
      }

      var selUnidad = _filaMiniModal.querySelector('.sel-unidad');
      var opt = document.createElement('option');
      opt.value              = data.id;
      opt.dataset.factor     = data.factor_a_base;
      opt.dataset.simbolo    = data.simbolo;
      opt.textContent        = data.nombre + ' (' + data.simbolo + ')';
      opt.selected           = true;
      selUnidad.appendChild(opt);
      window.actualizarHint(selUnidad);

      window.DM && window.DM.toast('Unidad "' + nombre + '" agregada.', 'success');
      window.cerrarMiniModal();

    } catch (e) {
      _setMiniError('Error de conexión. Intenta de nuevo.');
    } finally {
      btnGuardar.disabled   = false;
      btnGuardar.innerHTML  = '<animated-icons src="/static/icons/save-0c38d9a8.json" trigger="loop" attributes=\'{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#FFFFFF","background":"#FFFFFF"}}\' height="20" width="20"></animated-icons> Guardar unidad';
    }
  };

  document.addEventListener('click', function (e) {
    var overlay = document.getElementById('mini-overlay-unidad');
    if (overlay && e.target === overlay) {
      window.cerrarMiniModal();
    }

    var toggleOverlay = document.getElementById('modal-toggle');
    if (toggleOverlay && e.target === toggleOverlay) {
      _closeToggle();
    }

    if (e.target.closest('#toggle-close-btn') || e.target.closest('#toggle-cancel-btn')) {
      _closeToggle();
    }

    var btn = e.target.closest('.btn-toggle-receta');
    if (btn) {
      _openToggle(btn.dataset.id, btn.dataset.nombre, btn.dataset.estatus);
    }
  });

  var TOGGLE_ICONS = {
    danger:  '<animated-icons src="/static/icons/minus-8e4bd16d.json" trigger="loop" attributes=\'{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#FF0707FF","background":"#FFFFFF"}}\' height="22" width="22"></animated-icons>',
    success: '<animated-icons src="/static/icons/success-2cb0da6b.json" trigger="loop" attributes=\'{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#559C27FF","background":"#FFFFFF"}}\' height="22" width="22"></animated-icons>',
  };

  function _openToggle(id, nombre, estatus) {
    var desactivar = (estatus === 'activo');
    var overlay    = document.getElementById('modal-toggle');
    var form       = document.getElementById('form-toggle');
    if (!overlay || !form) return;

    form.action = CFG.urlToggleBase + id;

    if (desactivar) {
      document.getElementById('toggle-header').style.background     = 'var(--rust)';
      document.getElementById('toggle-header-title').innerHTML       = TOGGLE_ICONS.danger + ' Desactivar Receta';
      document.getElementById('toggle-title').textContent            = '¿Desactivar esta receta?';
      document.getElementById('toggle-msg').innerHTML                =
        'La receta <strong>' + nombre + '</strong> no podrá usarse en nuevas órdenes de producción.<br>El historial se conserva.';
      document.getElementById('toggle-confirm-btn').innerHTML        = TOGGLE_ICONS.danger + ' Desactivar';
      document.getElementById('toggle-confirm-btn').className        = 'btn btn-danger';
    } else {
      document.getElementById('toggle-header').style.background     = '#5a7a52';
      document.getElementById('toggle-header-title').innerHTML       = TOGGLE_ICONS.success + ' Activar Receta';
      document.getElementById('toggle-title').textContent            = '¿Activar esta receta?';
      document.getElementById('toggle-msg').innerHTML                =
        'La receta <strong>' + nombre + '</strong> volverá a estar disponible para producción.';
      document.getElementById('toggle-confirm-btn').innerHTML        = TOGGLE_ICONS.success + ' Activar';
      document.getElementById('toggle-confirm-btn').className        = 'btn btn-primary';
    }

    overlay.classList.add('open');
    overlay.style.display = 'flex';
  }

  function _closeToggle() {
    var overlay = document.getElementById('modal-toggle');
    if (!overlay) return;
    overlay.classList.remove('open');
    overlay.style.display = 'none';
  }

})();