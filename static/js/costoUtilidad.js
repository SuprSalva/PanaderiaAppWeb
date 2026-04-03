/* ════════════════════════════════════════════
   MÓDULO: Costos y Utilidad por Producto
   costoUtilidad.js
   ════════════════════════════════════════════ */

'use strict';

/* ── Paginación ────────────────────────────────────────────── */
var TODAS_LAS_FILAS = [];
var PAG_ACTUAL = 1;
var POR_PAG    = 10;

function totalPags() {
    return Math.max(1, Math.ceil(TODAS_LAS_FILAS.length / POR_PAG));
}

function renderPag() {
    var total = TODAS_LAS_FILAS.length;
    var tp    = totalPags();
    var desde = (PAG_ACTUAL - 1) * POR_PAG + 1;
    var hasta = Math.min(PAG_ACTUAL * POR_PAG, total);

    /* Mostrar / ocultar filas */
    TODAS_LAS_FILAS.forEach(function (tr, i) {
        tr.style.display = (i >= desde - 1 && i < hasta) ? '' : 'none';
    });

    /* Info */
    var elDesde = document.getElementById('pag-desde');
    var elHasta = document.getElementById('pag-hasta');
    var elTotal = document.getElementById('pag-total');
    if (elDesde) elDesde.textContent = total > 0 ? desde : 0;
    if (elHasta) elHasta.textContent = hasta;
    if (elTotal) elTotal.textContent = total;

    /* Controles */
    var ctrl = document.getElementById('pag-controles');
    if (!ctrl) return;
    ctrl.innerHTML = '';
    if (tp <= 1) return;

    /* Botón anterior */
    agregarBtn(ctrl, '‹', PAG_ACTUAL - 1, PAG_ACTUAL === 1 ? 'disabled' : '');

    /* Números de página con puntos suspensivos */
    for (var n = 1; n <= tp; n++) {
        var enRango = (n >= PAG_ACTUAL - 2 && n <= PAG_ACTUAL + 2);
        if (n === 1 || n === tp || enRango) {
            agregarBtn(ctrl, n, n, n === PAG_ACTUAL ? 'activo' : '');
        } else if (n === PAG_ACTUAL - 3 || n === PAG_ACTUAL + 3) {
            var sp = document.createElement('span');
            sp.className = 'pag-puntos';
            sp.textContent = '…';
            ctrl.appendChild(sp);
        }
    }

    /* Botón siguiente */
    agregarBtn(ctrl, '›', PAG_ACTUAL + 1, PAG_ACTUAL === tp ? 'disabled' : '');
}

function agregarBtn(contenedor, label, page, cls) {
    var b = document.createElement('button');
    b.className = 'pag-btn ' + (cls || '');
    b.innerHTML = label;
    if (cls !== 'disabled' && cls !== 'activo') {
        b.addEventListener('click', function () {
            PAG_ACTUAL = page;
            renderPag();
        });
    }
    contenedor.appendChild(b);
}

/* ── Estado del producto seleccionado ──────────────────────── */
var productoActual = {
    idReceta:    null,
    costo:       0,
    precio:      0,
    rendimiento: 1
};

/* ── Debounce para buscador y rangos ───────────────────────── */
var debTimer;

function debounceSubmit() {
    clearTimeout(debTimer);
    debTimer = setTimeout(function () {
        document.getElementById('form-filtro').submit();
    }, 700);
}

/* ── Selección de fila ─────────────────────────────────────── */
function selectProducto(tr) {
    TODAS_LAS_FILAS.forEach(function (r) { r.classList.remove('fila-activa'); });
    tr.classList.add('fila-activa');

    var idReceta = tr.dataset.idReceta;
    var nombre   = tr.dataset.nombre;
    var costo    = parseFloat(tr.dataset.costo)        || 0;
    var precio   = parseFloat(tr.dataset.precio)       || 0;
    var utilidad = parseFloat(tr.dataset.utilidad)     || 0;
    var margen   = parseFloat(tr.dataset.margen)       || 0;
    var rend     = parseFloat(tr.dataset.rendimiento)  || 1;

    productoActual = { idReceta: idReceta, costo: costo, precio: precio, rendimiento: rend };

    /* Actualizar cabecera del panel */
    var desTitulo = document.getElementById('des-titulo');
    if (desTitulo) desTitulo.textContent = nombre;

    /* Mostrar spinner, ocultar resto */
    var placeholder = document.getElementById('des-placeholder');
    var spinner     = document.getElementById('des-spinner');
    var content     = document.getElementById('des-content');
    if (placeholder) placeholder.style.display = 'none';
    if (content)     content.style.display     = 'none';
    if (spinner)     spinner.style.display      = 'flex';

    fetch('/costo-utilidad/api/detalle/' + idReceta)
        .then(function (r) { return r.json(); })
        .then(function (data) {
            if (spinner) spinner.style.display = 'none';
            if (data.ok) {
                renderDesglose(data.detalle, costo, precio, utilidad, margen, rend);
            } else {
                mostrarPlaceholder('⚠️', 'No se pudo cargar el desglose.');
            }
        })
        .catch(function () {
            if (spinner) spinner.style.display = 'none';
            mostrarPlaceholder('⚠️', 'Error de conexión al servidor.');
        });
}

function mostrarPlaceholder(ico, msg) {
    var pl = document.getElementById('des-placeholder');
    if (!pl) return;
    pl.innerHTML = '<span>' + ico + '</span><p>' + esc(msg) + '</p>';
    pl.style.display = 'flex';
}

/* ── Renderizar desglose de insumos ────────────────────────── */
function renderDesglose(detalle, costo, precio, utilidad, margen, rend) {
    var content = document.getElementById('des-content');
    if (!content) return;
    content.style.display = 'block';

    var costoLote = costo * rend;
    var clsU      = utilidad >= 0 ? 'pos' : 'neg';

    setText('des-costo',  '$' + fmt(costo));
    setText('des-lote',   '$' + fmt(costoLote));
    setText('des-margen', fmt(margen) + '%');

    var elUtil = document.getElementById('des-util');
    if (elUtil) {
        elUtil.textContent = '$' + fmt(utilidad);
        elUtil.className   = 'des-kpi-val ' + clsU;
    }

    /* Insumos */
    var wrap = document.getElementById('des-insumos');
    if (wrap) {
        if (!detalle || !detalle.length) {
            wrap.innerHTML = '<p style="text-align:center;color:var(--brown-lt);padding:14px 0;font-size:13px;">Sin insumos registrados.</p>';
        } else {
            wrap.innerHTML = detalle.map(function (d) {
                var pct = Math.min(parseFloat(d.pct_del_costo) || 0, 100);
                var sub = parseFloat(d.subtotal_costo) || 0;
                return '<div class="ins-row">'
                    + '<div class="ins-left">'
                    +   '<div class="ins-nm">🌾 ' + esc(d.materia_nombre) + '</div>'
                    +   '<div class="ins-qty">'
                    +       fmt4(d.cantidad_requerida) + ' ' + esc(d.unidad_base)
                    +       ' · $' + fmt6(d.costo_base_unitario) + '/' + esc(d.unidad_base)
                    +   '</div>'
                    + '</div>'
                    + '<div class="ins-right">'
                    +   '<div class="ins-pct-bar">'
                    +     '<div class="ins-pct-fill" style="width:' + pct + '%"></div>'
                    +   '</div>'
                    +   '<span class="ins-sub">$' + fmt(sub) + '</span>'
                    + '</div>'
                    + '</div>';
            }).join('');
        }
    }

    /* Totales breakdown */
    setText('des-mat-lote', '$' + fmt(costoLote));
    setText('des-unit',     '$' + fmt(costo));

    /* Inicializar simulador con precio actual */
    var simPrecio = document.getElementById('sim-precio');
    if (simPrecio) simPrecio.value = fmt(precio);
    simular();
}

/* ── Simulador de precio ────────────────────────────────────── */
function simular() {
    if (!productoActual.idReceta) return;

    var simPrecio = document.getElementById('sim-precio');
    var p = simPrecio ? (parseFloat(simPrecio.value) || 0) : 0;
    var u = p - productoActual.costo;
    var m = p > 0 ? (u / p * 100) : 0;

    var eu = document.getElementById('sim-util');
    var em = document.getElementById('sim-margen');
    if (eu) {
        eu.textContent = '$' + fmt(u);
        eu.className   = 'sim-result ' + (u >= 0 ? 'pos' : 'neg');
    }
    if (em) {
        em.textContent = fmt(m) + '%';
        em.className   = 'sim-result ' + (m >= 20 ? 'pos' : 'neg');
    }
}

/* ── Helpers ────────────────────────────────────────────────── */
function setText(id, val) {
    var el = document.getElementById(id);
    if (el) el.textContent = val;
}

function fmt(n)  { return parseFloat(n || 0).toFixed(2); }
function fmt4(n) { return parseFloat(n || 0).toFixed(4).replace(/\.?0+$/, ''); }
function fmt6(n) { return parseFloat(n || 0).toFixed(6).replace(/\.?0+$/, ''); }

function esc(s) {
    return String(s || '')
        .replace(/&/g,  '&amp;')
        .replace(/</g,  '&lt;')
        .replace(/>/g,  '&gt;')
        .replace(/"/g,  '&quot;');
}

/* ── Inicialización ─────────────────────────────────────────── */
document.addEventListener('DOMContentLoaded', function () {
    /* Recopilar filas de la tabla */
    TODAS_LAS_FILAS = Array.from(document.querySelectorAll('#tabla-body .prod-row'));

    /* Paginación */
    renderPag();

    /* Seleccionar primer producto automáticamente */
    var primera = document.querySelector('#tabla-body .prod-row');
    if (primera) selectProducto(primera);

    /* Listeners del buscador */
    var ib = document.getElementById('buscador');
    if (ib) {
        ib.addEventListener('keydown', function (e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                clearTimeout(debTimer);
                document.getElementById('form-filtro').submit();
            }
            if (e.key === 'Escape') {
                ib.value = '';
                debounceSubmit();
            }
        });
    }

    /* Listeners de rangos de utilidad */
    ['utilidad_min', 'utilidad_max'].forEach(function (id) {
        var el = document.getElementById(id);
        if (el) {
            el.addEventListener('keydown', function (e) {
                if (e.key === 'Enter') {
                    e.preventDefault();
                    document.getElementById('form-filtro').submit();
                }
            });
        }
    });
});

/* Exportar para uso en atributos onclick del HTML */
window.selectProducto = selectProducto;
window.simular        = simular;
window.debounceSubmit = debounceSubmit;