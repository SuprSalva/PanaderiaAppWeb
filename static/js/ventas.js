let currentPage = 1;
let itemsPerPage = 10;
let totalVentas = 0;
let ventasData = [];
let currentDetalleData = null;

// ============================================================
// FUNCIONES PRINCIPALES
// ============================================================

async function cargarEstadisticas() {
    try {
        const response = await fetch('/ventas/api/estadisticas');
        const data = await response.json();
        
        if (data.success) {
            const stats = data.estadisticas;
            document.getElementById('totalHoy').textContent = '$' + stats.total_hoy.toFixed(2);
            document.getElementById('ventasHoy').textContent = stats.ventas_hoy;
            document.getElementById('piezasVendidas').textContent = stats.total_piezas;
            document.getElementById('totalSemana').textContent = '$' + stats.total_semana.toFixed(2);
        }
    } catch (error) {
        console.error('Error cargando estadísticas:', error);
    }
}

async function cargarVentas(page = 1) {
    currentPage = page;
    const offset = (page - 1) * itemsPerPage;
    const fecha = document.getElementById('filterFecha').value;
    
    mostrarLoading(true);
    
    try {
        const params = new URLSearchParams({
            offset: offset,
            limit: itemsPerPage
        });
        if (fecha) params.append('fecha_inicio', fecha);
        
        const response = await fetch(`/ventas/api/ventas?${params}`);
        const data = await response.json();
        
        if (data.success) {
            ventasData = data.ventas;
            totalVentas = data.total;
            renderVentasTable(ventasData);
            renderPagination();
            document.getElementById('totalCount').textContent = totalVentas;
        } else {
            console.error('Error:', data.error);
            document.getElementById('ventasTableBody').innerHTML = '<tr><td colspan="7" style="text-align:center">Error al cargar datos</td></tr>';
        }
    } catch (error) {
        console.error('Error cargando ventas:', error);
        document.getElementById('ventasTableBody').innerHTML = '<tr><td colspan="7" style="text-align:center">Error al cargar datos</td></tr>';
    } finally {
        mostrarLoading(false);
    }
}

function resumirProductos(texto, maxLength) {
    if (!texto) return 'Sin productos';
    if (texto.length <= maxLength) return texto;
    return texto.substring(0, maxLength) + '...';
}

function formatearFecha(fechaStr) {
    if (!fechaStr) return '';
    const fecha = new Date(fechaStr);
    const hoy = new Date();
    const ayer = new Date(hoy);
    ayer.setDate(ayer.getDate() - 1);
    
    if (fecha.toDateString() === hoy.toDateString()) {
        return `Hoy ${fecha.toLocaleTimeString('es-MX', {hour:'2-digit', minute:'2-digit'})}`;
    } else if (fecha.toDateString() === ayer.toDateString()) {
        return `Ayer ${fecha.toLocaleTimeString('es-MX', {hour:'2-digit', minute:'2-digit'})}`;
    }
    return fecha.toLocaleDateString('es-MX') + ' ' + fecha.toLocaleTimeString('es-MX', {hour:'2-digit', minute:'2-digit'});
}

function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function renderVentasTable(ventas) {
    const tbody = document.getElementById('ventasTableBody');
    
    if (!ventas.length) {
        tbody.innerHTML = '<tr><td colspan="7" style="text-align:center">No hay ventas registradas</td></tr>';
        document.getElementById('visibleCount').textContent = '0';
        return;
    }
    
    tbody.innerHTML = ventas.map(venta => {
        const origenBadge = venta.origen === 'caja' 
            ? '<span class="badge" style="background:#e2eede; color:#2c5f2d;"> Caja</span>'
            : '<span class="badge" style="background:#fef3d0; color:#8a6200;"> Online</span>';
        
        return `
        <tr>
            <td><span class="folio-chip">${escapeHtml(venta.folio_venta)}</span></td>
            <td>${formatearFecha(venta.fecha_venta)}</td>
            <td>${origenBadge}</td>
            <td><span class="items-pill" title="${escapeHtml(venta.productos_resumen)}">${escapeHtml(resumirProductos(venta.productos_resumen, 40))}</span></td>
            <td><span class="money">$${venta.total.toFixed(2)}</span></td>
            <td>${escapeHtml(venta.vendedor_nombre)}</td>
            <td><div class="actions-cell"><button title="Ver detalle" class="btn btn-outline btn-sm btn-icon" onclick="verDetalleVenta(${venta.id_venta})"><animated-icon><animated-icons src="/static/icons/newspaper-b3a68157.json"
                trigger="loop"
                attributes='{"variationThumbColour":"#536DFE","variationName":"Two Tone","variationNumber":2,"numberOfGroups":2,"backgroundIsGroup":false,"strokeWidth":1.5,"defaultColours":{"group-1":"#000000","group-2":"#E07A52FF","background":"#FFFFFF"}}'
                height="30" width="30"></animated-icons></button></div></td>
        </tr>
    `}).join('');
    
    document.getElementById('visibleCount').textContent = ventas.length;
}

function renderPagination() {
    const totalPages = Math.ceil(totalVentas / itemsPerPage);
    const pagination = document.getElementById('pagination');
    
    if (totalPages <= 1) {
        pagination.innerHTML = '';
        return;
    }
    
    let html = '';
    for (let i = 1; i <= Math.min(totalPages, 5); i++) {
        html += `<div class="page-btn ${i === currentPage ? 'active' : ''}" onclick="cargarVentas(${i})">${i}</div>`;
    }
    if (totalPages > 5) {
        html += `<div class="page-btn">...</div>`;
        html += `<div class="page-btn" onclick="cargarVentas(${totalPages})">${totalPages}</div>`;
    }
    pagination.innerHTML = html;
}

// ============================================================
// DETALLE DE VENTA
// ============================================================

async function verDetalleVenta(idPedido) {
    mostrarLoading(true);
    
    try {
        const response = await fetch(`/ventas/api/ventas/${idPedido}`);
        const data = await response.json();
        
        if (data.success) {
            currentDetalleData = data;
            const venta = data.venta;
            const detalles = data.detalles;
            
            const detallesHtml = `
                <div class="det-grid">
                    <div class="det-item"><label>Folio</label><span>${escapeHtml(venta.folio_venta)}</span></div>
                    <div class="det-item"><label>Fecha de venta</label><span>${formatearFecha(venta.fecha_venta)}</span></div>
                    <div class="det-item"><label>Total</label><span>$${venta.total.toFixed(2)}</span></div>
                    <div class="det-item"><label>Atendido por</label><span>${escapeHtml(venta.vendedor_nombre)}</span></div>
                    ${venta.fecha_recogida ? `<div class="det-item"><label>Fecha de recogida</label><span>${formatearFecha(venta.fecha_recogida)}</span></div>` : ''}
                    ${venta.notas_cliente ? `<div class="det-item"><label>Notas del cliente</label><span>${escapeHtml(venta.notas_cliente)}</span></div>` : ''}
                </div>
                <table class="det-items-table">
                    <thead>
                        <tr><th>Producto</th><th>Cantidad</th><th>Precio</th><th>Subtotal</th></tr>
                    </thead>
                    <tbody>
                        ${detalles.map(det => `
                            <tr>
                                <td>${escapeHtml(det.producto_nombre)}</td>
                                <td>${det.cantidad}</td>
                                <td>$${det.precio_unitario.toFixed(2)}</td>
                                <td>$${det.subtotal.toFixed(2)}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            `;
            document.getElementById('detalleContent').innerHTML = detallesHtml;
            abrirModal('modal-detalle');
        } else {
            mostrarNotificacion('Error al cargar detalle: ' + (data.error || 'Desconocido'));
        }
    } catch (error) {
        console.error('Error cargando detalle:', error);
        mostrarNotificacion('Error al cargar detalle');
    } finally {
        mostrarLoading(false);
    }
}

// ============================================================
// FUNCIÓN PARA IMPRIMIR
// ============================================================

function imprimirDetalle() {
    if (!currentDetalleData) {
        mostrarNotificacion('No hay datos para imprimir');
        return;
    }
    
    const venta = currentDetalleData.venta;
    const detalles = currentDetalleData.detalles;
    
    // Generar HTML del ticket
    const fechaVenta = venta.fecha_venta ? new Date(venta.fecha_venta).toLocaleString('es-MX') : '';
    const fechaRecogida = venta.fecha_recogida ? new Date(venta.fecha_recogida).toLocaleString('es-MX') : '';
    
    const ticketHtml = `
        <div class="ticket-print">
            <div class="ticket-logo">🥐</div>
            <div class="ticket-title">Dulce Migaja</div>
            <div class="ticket-sub">Panadería Artesanal · León, Gto.</div>
            <div class="ticket-divider"></div>
            
            <div class="ticket-row">
                <span>Folio:</span>
                <span><strong>${escapeHtml(venta.folio_venta)}</strong></span>
            </div>
            <div class="ticket-row">
                <span>Fecha venta:</span>
                <span>${fechaVenta}</span>
            </div>
            <div class="ticket-row">
                <span>Atendió:</span>
                <span>${escapeHtml(venta.vendedor_nombre)}</span>
            </div>
            ${fechaRecogida ? `
            <div class="ticket-row">
                <span>Recogida:</span>
                <span>${fechaRecogida}</span>
            </div>
            ` : ''}
            
            <div class="ticket-divider"></div>
            
            <div class="ticket-row ticket-row-header">
                <span>Producto</span>
                <span>Subtotal</span>
            </div>
            
            ${detalles.map(det => `
                <div class="ticket-row">
                    <span>${escapeHtml(det.producto_nombre)} x${det.cantidad}</span>
                    <span>$${det.subtotal.toFixed(2)}</span>
                </div>
            `).join('')}
            
            <div class="ticket-divider"></div>
            
            <div class="ticket-total">
                <span>TOTAL</span>
                <span>$${venta.total.toFixed(2)}</span>
            </div>
            
            <div class="ticket-divider"></div>
            
            <div class="ticket-thanks">
                ¡Gracias por su preferencia!<br>
                Vuelva pronto 🍞
            </div>
        </div>
    `;
    
    // Crear ventana de impresión
    const ventanaPrint = window.open('', '_blank');
    ventanaPrint.document.write(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Ticket - ${escapeHtml(venta.folio_venta)}</title>
            <meta charset="UTF-8">
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                body {
                    font-family: 'Courier New', monospace;
                    margin: 0;
                    padding: 20px;
                    background: white;
                }
                .ticket-print {
                    max-width: 300px;
                    margin: 0 auto;
                    padding: 10px;
                }
                .ticket-logo {
                    text-align: center;
                    font-size: 32px;
                    margin-bottom: 5px;
                }
                .ticket-title {
                    text-align: center;
                    font-family: 'Playfair Display', Georgia, serif;
                    font-size: 18px;
                    font-weight: 700;
                }
                .ticket-sub {
                    text-align: center;
                    font-size: 10px;
                    color: #666;
                    margin-bottom: 15px;
                }
                .ticket-divider {
                    border-top: 1px dashed #999;
                    margin: 10px 0;
                }
                .ticket-row {
                    display: flex;
                    justify-content: space-between;
                    font-size: 12px;
                    padding: 3px 0;
                }
                .ticket-row-header {
                    font-weight: 700;
                    border-bottom: 1px dotted #999;
                    margin-bottom: 5px;
                    padding-bottom: 3px;
                }
                .ticket-total {
                    display: flex;
                    justify-content: space-between;
                    font-size: 14px;
                    font-weight: 700;
                    margin-top: 10px;
                    padding-top: 5px;
                    border-top: 1px dashed #999;
                }
                .ticket-thanks {
                    text-align: center;
                    font-size: 11px;
                    margin-top: 15px;
                    color: #666;
                }
                @media print {
                    body {
                        margin: 0;
                        padding: 0;
                    }
                    .no-print {
                        display: none;
                    }
                }
            </style>
        </head>
        <body>
            ${ticketHtml}
            <script>
                window.onload = function() {
                    window.print();
                    setTimeout(function() {
                        window.close();
                    }, 500);
                };
            <\/script>
        </body>
        </html>
    `);
    ventanaPrint.document.close();
}

// ============================================================
// FUNCIONES UTILITARIAS
// ============================================================

function abrirModal(id) {
    document.getElementById(id).classList.add('open');
}

function cerrarModal(id) {
    document.getElementById(id).classList.remove('open');
}

function mostrarLoading(show) {
    const overlay = document.getElementById('loadingOverlay');
    if (overlay) {
        overlay.style.display = show ? 'flex' : 'none';
    }
}

function mostrarNotificacion(mensaje) {
    alert(mensaje);
}

function filtrarTabla() {
    const busqueda = document.getElementById('searchInput').value.toLowerCase();
    const tbody = document.getElementById('ventasTableBody');
    const rows = tbody.querySelectorAll('tr');
    
    if (!rows.length || rows[0].cells.length === 1) return;
    
    let visible = 0;
    rows.forEach(row => {
        const folio = row.cells[0]?.textContent.toLowerCase() || '';
        const vendedor = row.cells[5]?.textContent.toLowerCase() || '';
        const show = !busqueda || folio.includes(busqueda) || vendedor.includes(busqueda);
        row.style.display = show ? '' : 'none';
        if (show) visible++;
    });
    
    const visibleCount = document.getElementById('visibleCount');
    if (visibleCount) visibleCount.textContent = visible;
}

// ============================================================
// INICIALIZACIÓN
// ============================================================

document.addEventListener('DOMContentLoaded', () => {
    cargarEstadisticas();
    cargarVentas();
    
    document.querySelectorAll('.modal-overlay').forEach(el => {
        el.addEventListener('click', e => {
            if (e.target === el) el.classList.remove('open');
        });
    });
});
