    let productos = [];
    let carrito = [];
    let metodoPagoSeleccionado = 'efectivo';
    let ultimaVenta = null;

    // ============================================================
    // CARGA DE DATOS
    // ============================================================

    async function cargarEstadisticas() {
        try {
            const response = await fetch('/ventas/api/estadisticas-caja');
            const data = await response.json();
            if (data.success) {
                const stats = data.estadisticas;
                document.getElementById('totalHoy').textContent = '$' + stats.total_hoy.toFixed(2);
                document.getElementById('ventasHoy').textContent = stats.ventas_hoy;
                document.getElementById('piezasHoy').textContent = stats.total_piezas;
                document.getElementById('totalSemana').textContent = '$' + stats.total_semana.toFixed(2);
            }
        } catch (error) {
            console.error('Error cargando estadísticas:', error);
        }
    }

    async function cargarProductos() {
        mostrarLoading(true);
        try {
            const response = await fetch('/ventas/api/productos-stock');
            const data = await response.json();
            if (data.success) {
                productos = data.productos;
                renderProductos();
            }
        } catch (error) {
            console.error('Error:', error);
        } finally {
            mostrarLoading(false);
        }
    }

    function getImagenUrl(producto) {
        if (!producto.imagen_url) return null;
        // La imagen_url ya contiene la ruta desde static/, ej: "uploads/productos/uuid.webp"
        return producto.imagen_url;
    }

 function renderProductos() {
    const grid = document.getElementById('productosGrid');
    const searchTerm = document.getElementById('searchProducto').value.toLowerCase();
    
    // Primero filtrar
    let filtered = productos.filter(p => 
        p.nombre.toLowerCase().includes(searchTerm)
    );
    
    // Ordenar por stock disponible (mayor a menor) y luego por nombre
    filtered.sort((a, b) => {
        // Los agotados van al final
        if (a.stock_actual === 0 && b.stock_actual > 0) return 1;
        if (a.stock_actual > 0 && b.stock_actual === 0) return -1;
        // Ordenar por stock descendente
        if (a.stock_actual !== b.stock_actual) {
            return b.stock_actual - a.stock_actual;
        }
        // Si mismo stock, ordenar por nombre
        return a.nombre.localeCompare(b.nombre);
    });
    
    if (filtered.length === 0) {
        grid.innerHTML = '<div style="text-align:center; padding:60px; color:var(--brown-lt);">🍞 No se encontraron productos</div>';
        return;
    }
    
    grid.innerHTML = filtered.map(producto => {
        const isAvailable = producto.stock_actual > 0;
        const stockClass = producto.stock_actual === 0 ? 'red' : (producto.stock_actual <= producto.stock_minimo ? 'yellow' : 'green');
        const stockText = producto.stock_actual === 0 ? 'Agotado' : `Stock: ${producto.stock_actual}`;
        
        // Mostrar badge de "Poco stock" si está bajo
        const lowStockBadge = (producto.stock_actual > 0 && producto.stock_actual <= producto.stock_minimo) 
            ? '<div class="low-stock-badge">⚠️ Poco stock</div>' 
            : '';
        
        let imagenHtml = '';
        if (producto.imagen_url) {
            let imgPath = producto.imagen_url;
            if (!imgPath.startsWith('/') && !imgPath.startsWith('http')) {
                imgPath = '/static/' + imgPath;
            }
            imagenHtml = `<img src="${imgPath}" alt="${escapeHtml(producto.nombre)}" 
                              class="product-img-real"
                              onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">`;
            imagenHtml += `<div class="product-img-placeholder" style="display:none;">🥐</div>`;
        } else {
            imagenHtml = `<div class="product-img-placeholder">🥐</div>`;
        }
        
        return `
            <div class="product-card ${!isAvailable ? 'disabled' : ''}" 
                 onclick="${isAvailable ? `agregarAlCarrito(${producto.id_producto})` : ''}">
                <div class="product-img">
                    ${imagenHtml}
                </div>
                <div class="product-name">${escapeHtml(producto.nombre)}</div>
                <div class="product-price">$${producto.precio_venta.toFixed(2)}</div>
                <div class="product-stock">
                    <span class="stock-badge ${stockClass}"></span>
                    ${stockText}
                </div>
                ${lowStockBadge}
            </div>
        `;
    }).join('');
}

    // ============================================================
    // CARRITO
    // ============================================================


    function renderCarrito() {
        const container = document.getElementById('cartItems');
        const subtotalSpan = document.getElementById('subtotal');
        const totalSpan = document.getElementById('total');
        const itemCountSpan = document.getElementById('itemCount');
        const btnCobrar = document.getElementById('btnCobrar');

        if (carrito.length === 0) {
            container.innerHTML = '<div class="empty-cart"><span>🛍️</span><p style="margin-top:10px">Carrito vacío</p></div>';
            subtotalSpan.textContent = '$0.00';
            totalSpan.textContent = '$0.00';
            itemCountSpan.textContent = '0 items';
            btnCobrar.disabled = true;
            return;
        }

        const totalItems = carrito.reduce((sum, item) => sum + item.cantidad, 0);
        itemCountSpan.textContent = totalItems + ' ' + (totalItems === 1 ? 'item' : 'items');

        container.innerHTML = carrito.map((item, idx) => `
        <div class="cart-item">
            <div class="cart-item-info">
                <div class="cart-item-name">${escapeHtml(item.nombre)}</div>
                <div class="cart-item-price">$${item.precio.toFixed(2)} c/u</div>
            </div>
            <div class="cart-item-actions">
                <button class="qty-btn" onclick="modificarCantidad(${idx}, -1)">−</button>
                <input type="number" class="qty-input" value="${item.cantidad}" min="1" 
                       onchange="cambiarCantidad(${idx}, this.value)">
                <button class="qty-btn" onclick="modificarCantidad(${idx}, 1)">+</button>
            </div>
            <div class="cart-item-total">$${item.subtotal.toFixed(2)}</div>
            <div class="cart-remove" onclick="eliminarDelCarrito(${idx})">🗑️</div>
        </div>
    `).join('');

        const subtotal = carrito.reduce((sum, item) => sum + item.subtotal, 0);
        subtotalSpan.textContent = `$${subtotal.toFixed(2)}`;
        totalSpan.textContent = `$${subtotal.toFixed(2)}`;
        btnCobrar.disabled = false;

        calcularCambio();
    }

    function eliminarDelCarrito(idx) {
        carrito.splice(idx, 1);
        renderCarrito();
    }

    async function limpiarCarrito() {
        if (carrito.length === 0) return;
        
        const confirmed = await showConfirm('¿Limpiar todo el carrito?', 'Limpiar carrito');
        if (confirmed) {
            carrito = [];
            renderCarrito();
            document.getElementById('efectivoRecibido').value = '';
            document.getElementById('cambioInfo').innerHTML = '';
            showAlert('Carrito limpiado', 'success');
        }
    }

    // ============================================================
    // MÉTODOS DE PAGO
    // ============================================================

    function seleccionarMetodoPago(metodo) {
        metodoPagoSeleccionado = metodo;

        document.querySelectorAll('.payment-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`.payment-btn[data-metodo="${metodo}"]`).classList.add('active');

        const cashSection = document.getElementById('cashSection');
        if (metodo === 'efectivo') {
            cashSection.style.display = 'block';
            calcularCambio();
        } else {
            cashSection.style.display = 'none';
            document.getElementById('cambioInfo').innerHTML = '';
        }
    }

    function calcularCambio() {
        if (metodoPagoSeleccionado !== 'efectivo') return;

        const efectivo = parseFloat(document.getElementById('efectivoRecibido').value) || 0;
        const total = carrito.reduce((sum, item) => sum + item.subtotal, 0);
        const cambio = efectivo - total;
        const cambioInfo = document.getElementById('cambioInfo');

        if (efectivo >= total && total > 0) {
            cambioInfo.innerHTML = `💰 Cambio: $${cambio.toFixed(2)}`;
            cambioInfo.className = 'change-info positive';
        } else if (efectivo > 0 && efectivo < total) {
            cambioInfo.innerHTML = `⚠️ Faltan $${(total - efectivo).toFixed(2)}`;
            cambioInfo.className = 'change-info negative';
        } else {
            cambioInfo.innerHTML = '';
            cambioInfo.className = 'change-info';
        }
    }

    // ============================================================
    // PROCESAR VENTA
    // ============================================================

    async function generarTicket(idVenta) {
        try {
            const response = await fetch(`/ventas/api/generar-ticket/${idVenta}`, { method: 'POST' });
            const data = await response.json();
            if (data.success) {
                mostrarTicket(data.ticket);
            }
        } catch (error) {
            console.error('Error:', error);
        }
    }

    function mostrarTicket(ticket) {
        const container = document.getElementById('ticketContent');
        const metodoTexto = {
            'efectivo': 'Efectivo',
            'tarjeta': 'Tarjeta',
            'transferencia': 'Transferencia'
        }[ticket.metodo_pago] || ticket.metodo_pago;

        container.innerHTML = `
        <div class="ticket">
            <div class="ticket-header">
                <div class="ticket-logo">🥐</div>
                <div class="ticket-title">Dulce Migaja</div>
                <div class="ticket-sub">Panadería Artesanal</div>
            </div>
            <div class="ticket-divider"></div>
            <div class="ticket-row"><span>Folio:</span><strong>${escapeHtml(ticket.folio)}</strong></div>
            <div class="ticket-row"><span>Fecha:</span><span>${ticket.fecha || new Date().toLocaleString('es-MX')}</span></div>
            <div class="ticket-row"><span>Vendedor:</span><span>${escapeHtml(ticket.vendedor)}</span></div>
            <div class="ticket-divider"></div>
            <div class="ticket-row bold"><span>Producto</span><span>Subtotal</span></div>
            ${ticket.detalles.map(d => `
                <div class="ticket-row">
                    <span>${escapeHtml(d.producto_nombre)} x${d.cantidad}</span>
                    <span>$${d.subtotal.toFixed(2)}</span>
                </div>
            `).join('')}
            <div class="ticket-divider"></div>
            <div class="ticket-row"><span>Subtotal</span><span>$${ticket.total.toFixed(2)}</span></div>
            <div class="ticket-row"><span>Método</span><span>${metodoTexto}</span></div>
            ${ticket.cambio > 0 ? `<div class="ticket-row"><span>Cambio</span><span>$${ticket.cambio.toFixed(2)}</span></div>` : ''}
            <div class="ticket-total"><span>TOTAL</span><span>$${ticket.total.toFixed(2)}</span></div>
            <div class="ticket-divider"></div>
            <div style="text-align:center; font-size:9px; margin-top:10px;">¡Gracias por su compra!<br>Vuelva pronto 🍞</div>
        </div>
    `;
        document.getElementById('modalTicket').classList.add('open');
    }

    function imprimirTicket() {
        const ticketContent = document.getElementById('ticketContent').innerHTML;
        const ventanaPrint = window.open('', '_blank');
        ventanaPrint.document.write(`
        <!DOCTYPE html>
        <html>
        <head><title>Ticket</title><meta charset="UTF-8">
        <style>
            *{margin:0;padding:0;box-sizing:border-box;}
            body{font-family:'Courier New',monospace;padding:20px;background:white;}
            .ticket{max-width:300px;margin:0 auto;}
            .ticket-header{text-align:center;margin-bottom:15px;}
            .ticket-logo{font-size:32px;}
            .ticket-title{font-size:14px;font-weight:700;}
            .ticket-sub{font-size:9px;color:#666;}
            .ticket-divider{border-top:1px dashed #999;margin:10px 0;}
            .ticket-row{display:flex;justify-content:space-between;padding:4px 0;font-size:12px;}
            .ticket-row.bold{font-weight:700;}
            .ticket-total{display:flex;justify-content:space-between;font-size:14px;font-weight:700;margin-top:10px;padding-top:8px;border-top:1px dashed #999;}
        </style>
        </head>
        <body>${ticketContent}<script>window.onload=function(){window.print();setTimeout(function(){window.close();},500);};<\/script></body>
        </html>
    `);
        ventanaPrint.document.close();
    }

    function cerrarModalTicket() {
        document.getElementById('modalTicket').classList.remove('open');
    }

    // ============================================================
    // UTILIDADES
    // ============================================================

    function escapeHtml(text) {
        if (!text) return '';
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    function mostrarLoading(show) {
        const overlay = document.getElementById('loadingOverlay');
        if (overlay) overlay.style.display = show ? 'flex' : 'none';
    }


    // ============================================================
    // INICIALIZACIÓN
    // ============================================================

    document.addEventListener('DOMContentLoaded', () => {
        cargarEstadisticas();
        cargarProductos();
        seleccionarMetodoPago('efectivo');

        document.getElementById('searchProducto').addEventListener('input', () => renderProductos());
        document.getElementById('efectivoRecibido').addEventListener('input', calcularCambio);
    });

    // ============================================================
// MODALES PERSONALIZADOS
// ============================================================

function showAlert(message, type = 'info') {
    return new Promise((resolve) => {
        const modal = document.getElementById('customAlertModal');
        const header = document.getElementById('alertHeader');
        const icon = document.getElementById('alertIcon');
        const title = document.getElementById('alertTitle');
        const messageEl = document.getElementById('alertMessage');
        
        // Configurar según el tipo
        header.className = 'custom-modal-header ' + type;
        
        const config = {
            success: { icon: '✅', title: 'Éxito' },
            error: { icon: '❌', title: 'Error' },
            warning: { icon: '⚠️', title: 'Advertencia' },
            info: { icon: 'ℹ️', title: 'Aviso' }
        };
        
        const cfg = config[type] || config.info;
        icon.textContent = cfg.icon;
        title.textContent = cfg.title;
        messageEl.textContent = message;
        
        modal.classList.add('open');
        
        const closeModal = () => {
            modal.classList.remove('open');
            resolve();
        };
        
        const okBtn = document.getElementById('alertOkBtn');
        okBtn.onclick = closeModal;
        
        // Cerrar al hacer clic fuera
        modal.onclick = (e) => {
            if (e.target === modal) closeModal();
        };
    });
}

function showConfirm(message, title = 'Confirmar') {
    return new Promise((resolve) => {
        const modal = document.getElementById('customConfirmModal');
        const confirmTitle = document.getElementById('confirmTitle');
        const confirmMessage = document.getElementById('confirmMessage');
        
        confirmTitle.textContent = title;
        confirmMessage.textContent = message;
        
        modal.classList.add('open');
        
        const closeModal = () => {
            modal.classList.remove('open');
        };
        
        const okBtn = document.getElementById('confirmOkBtn');
        const cancelBtn = document.getElementById('confirmCancelBtn');
        
        okBtn.onclick = () => {
            closeModal();
            resolve(true);
        };
        
        cancelBtn.onclick = () => {
            closeModal();
            resolve(false);
        };
        
        modal.onclick = (e) => {
            if (e.target === modal) {
                closeModal();
                resolve(false);
            }
        };
    });
}

// Reemplazar las funciones existentes
function mostrarNotificacion(mensaje, tipo = 'info') {
    showAlert(mensaje, tipo);
}

// Modificar limpiarCarrito para usar confirm personalizado
async function limpiarCarrito() {
    if (carrito.length === 0) return;
    
    const confirmed = await showConfirm('¿Limpiar todo el carrito?', 'Limpiar carrito');
    if (confirmed) {
        carrito = [];
        renderCarrito();
        document.getElementById('efectivoRecibido').value = '';
        document.getElementById('cambioInfo').innerHTML = '';
        showAlert('Carrito limpiado', 'success');
    }
}

// Modificar agregarAlCarrito para usar alert personalizado
function agregarAlCarrito(idProducto) {
    const producto = productos.find(p => p.id_producto === idProducto);
    if (!producto) return;
    
    if (producto.estado_stock === 'agotado' || producto.stock_actual <= 0) {
        showAlert('❌ Producto agotado', 'error');
        return;
    }
    
    const existing = carrito.find(item => item.id_producto === idProducto);
    if (existing) {
        if (existing.cantidad + 1 > producto.stock_actual) {
            showAlert(`⚠️ Stock insuficiente. Solo quedan ${producto.stock_actual} unidades`, 'warning');
            return;
        }
        existing.cantidad++;
        existing.subtotal = existing.cantidad * existing.precio;
    } else {
        carrito.push({
            id_producto: producto.id_producto,
            nombre: producto.nombre,
            precio: producto.precio_venta,
            cantidad: 1,
            subtotal: producto.precio_venta
        });
    }
    
    renderCarrito();
}

// Modificar modificarCantidad
async function modificarCantidad(idx, delta) {
    const item = carrito[idx];
    const producto = productos.find(p => p.id_producto === item.id_producto);
    const nuevaCantidad = item.cantidad + delta;
    
    if (nuevaCantidad < 1) {
        const confirmed = await showConfirm(`¿Eliminar "${item.nombre}" del carrito?`, 'Eliminar producto');
        if (confirmed) {
            eliminarDelCarrito(idx);
        }
        return;
    }
    
    if (nuevaCantidad > producto.stock_actual) {
        showAlert(`⚠️ Stock insuficiente. Solo quedan ${producto.stock_actual} unidades`, 'warning');
        return;
    }
    
    item.cantidad = nuevaCantidad;
    item.subtotal = item.cantidad * item.precio;
    renderCarrito();
}

// Modificar cambiarCantidad
async function cambiarCantidad(idx, newValue) {
    let cantidad = parseInt(newValue);
    if (isNaN(cantidad) || cantidad < 1) cantidad = 1;
    
    const item = carrito[idx];
    const producto = productos.find(p => p.id_producto === item.id_producto);
    
    if (cantidad > producto.stock_actual) {
        showAlert(`⚠️ Stock insuficiente. Solo quedan ${producto.stock_actual} unidades`, 'warning');
        cantidad = producto.stock_actual;
        if (cantidad < 1) {
            const confirmed = await showConfirm(`¿Eliminar "${item.nombre}" del carrito?`, 'Eliminar producto');
            if (confirmed) {
                eliminarDelCarrito(idx);
            }
            return;
        }
    }
    
    item.cantidad = cantidad;
    item.subtotal = item.cantidad * item.precio;
    renderCarrito();
}

// Modificar procesarVenta
async function procesarVenta() {
    if (carrito.length === 0) {
        showAlert('🛒 Agrega productos al carrito', 'warning');
        return;
    }
    
    const total = carrito.reduce((sum, item) => sum + item.subtotal, 0);
    const efectivoRecibido = parseFloat(document.getElementById('efectivoRecibido').value) || 0;
    
    if (metodoPagoSeleccionado === 'efectivo' && efectivoRecibido < total) {
        showAlert('⚠️ El efectivo recibido es insuficiente', 'error');
        return;
    }
    
    // Confirmar venta
    const confirmed = await showConfirm(
        `¿Confirmar venta por $${total.toFixed(2)}?\n${metodoPagoSeleccionado === 'efectivo' ? `Efectivo recibido: $${efectivoRecibido.toFixed(2)}` : `Método: ${metodoPagoSeleccionado === 'tarjeta' ? 'Tarjeta' : 'Transferencia'}`}`,
        'Confirmar venta'
    );
    
    if (!confirmed) return;
    
    mostrarLoading(true);
    
    try {
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
        
        const response = await fetch('/ventas/api/registrar-venta-caja', {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json',
                'X-CSRFToken': csrfToken
            },
            credentials: 'same-origin',
            body: JSON.stringify({
                productos: carrito.map(item => ({
                    id_producto: item.id_producto,
                    cantidad: item.cantidad,
                    precio: item.precio
                })),
                metodo_pago: metodoPagoSeleccionado,
                efectivo_recibido: efectivoRecibido
            })
        });
        
        const data = await response.json();
        
        if (data.success) {
            ultimaVenta = data.venta;
            await generarTicket(data.venta.id_venta);
            limpiarCarrito();
            cargarEstadisticas();
            cargarProductos();
            showAlert(`✅ Venta registrada: ${data.venta.folio_venta}`, 'success');
        } else {
            showAlert(data.error || 'Error al procesar la venta', 'error');
        }
    } catch (error) {
        console.error('Error:', error);
        showAlert('❌ Error al procesar la venta', 'error');
    } finally {
        mostrarLoading(false);
    }
}
    