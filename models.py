import datetime
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

# ══════════════════════════════════════════════════════════════════
#  NOTA DE MIGRACIÓN
#  Se elimina ProductoTerminado y se reemplaza por:
#    · Producto      → catálogo (nombre, precio, descripción)
#    · InventarioPT  → stock    (stock_actual, stock_minimo)
#
#  Los id_producto son los mismos en ambas tablas, por lo que
#  todas las FKs existentes siguen funcionando sin cambiar valores.
# ══════════════════════════════════════════════════════════════════


class Rol(db.Model):
    __tablename__ = 'roles'
    id_rol       = db.Column(db.SmallInteger, primary_key=True, autoincrement=True)
    clave_rol    = db.Column(db.String(10),  nullable=False, unique=True)
    nombre_rol   = db.Column(db.String(50),  nullable=False)
    descripcion  = db.Column(db.Text)

    usuarios = db.relationship('Usuario', back_populates='rol')


class Usuario(db.Model):
    __tablename__ = 'usuarios'
    id_usuario        = db.Column(db.Integer,     primary_key=True, autoincrement=True)
    uuid_usuario      = db.Column(db.String(36),  nullable=False, unique=True)
    nombre_completo   = db.Column(db.String(120), nullable=False)
    username          = db.Column(db.String(60),  nullable=False, unique=True)
    password_hash     = db.Column(db.String(255), nullable=False)
    id_rol            = db.Column(db.SmallInteger, db.ForeignKey('roles.id_rol'), nullable=False)
    estatus           = db.Column(db.Enum('activo','inactivo','bloqueado'), nullable=False, default='activo')
    intentos_fallidos = db.Column(db.SmallInteger, nullable=False, default=0)
    bloqueado_hasta   = db.Column(db.DateTime)
    ultimo_login      = db.Column(db.DateTime)
    token_2fa         = db.Column(db.String(10))
    token_2fa_expira  = db.Column(db.DateTime)
    cambio_pwd_req    = db.Column(db.Boolean, nullable=False, default=False)
    creado_en         = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now)
    actualizado_en    = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now,
                                  onupdate=datetime.datetime.now)
    creado_por        = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'), nullable=True)

    rol = db.relationship('Rol', back_populates='usuarios')


class Proveedor(db.Model):
    __tablename__ = 'proveedores'
    id_proveedor   = db.Column(db.Integer,    primary_key=True, autoincrement=True)
    uuid_proveedor = db.Column(db.String(36), nullable=False, unique=True)
    nombre         = db.Column(db.String(150),nullable=False)
    rfc            = db.Column(db.String(13), unique=True)
    contacto       = db.Column(db.String(120))
    telefono       = db.Column(db.String(20))
    email          = db.Column(db.String(150))
    direccion      = db.Column(db.Text)
    estatus        = db.Column(db.Enum('activo','inactivo'), nullable=False, default='activo')
    creado_en      = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now)
    actualizado_en = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now,
                                onupdate=datetime.datetime.now)
    creado_por     = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'), nullable=True)

    compras = db.relationship('Compra', back_populates='proveedor')


class MateriaPrima(db.Model):
    __tablename__ = 'materias_primas'
    id_materia     = db.Column(db.Integer,       primary_key=True, autoincrement=True)
    uuid_materia   = db.Column(db.String(36),    nullable=False, unique=True)
    nombre         = db.Column(db.String(120),   nullable=False)
    categoria      = db.Column(db.String(60))
    unidad_base    = db.Column(db.String(20),    nullable=False, default='g')
    stock_actual   = db.Column(db.Numeric(12,4), nullable=False, default=0)
    stock_minimo   = db.Column(db.Numeric(12,4), nullable=False, default=0)
    estatus        = db.Column(db.Enum('activo','inactivo'), nullable=False, default='activo')
    creado_en      = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now)
    actualizado_en = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now,
                                onupdate=datetime.datetime.now)
    creado_por     = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'), nullable=True)

    unidades_presentacion = db.relationship('UnidadPresentacion', back_populates='materia',
                                             cascade='all, delete-orphan')


class UnidadPresentacion(db.Model):
    __tablename__ = 'unidades_presentacion'
    id_unidad     = db.Column(db.Integer,       primary_key=True, autoincrement=True)
    id_materia    = db.Column(db.Integer,       db.ForeignKey('materias_primas.id_materia',
                               ondelete='CASCADE'), nullable=False)
    nombre        = db.Column(db.String(80),    nullable=False)
    simbolo       = db.Column(db.String(20),    nullable=False)
    factor_a_base = db.Column(db.Numeric(14,6), nullable=False)
    uso           = db.Column(db.Enum('compra','receta','ambos'), nullable=False, default='ambos')
    activo        = db.Column(db.Boolean,       nullable=False, default=True)
    creado_en     = db.Column(db.DateTime,      nullable=False, default=datetime.datetime.now)

    materia = db.relationship('MateriaPrima', back_populates='unidades_presentacion')

    __table_args__ = (
        db.UniqueConstraint('id_materia', 'simbolo', name='uq_unidad_materia_simbolo'),
    )


class Compra(db.Model):
    __tablename__ = 'compras'
    id_compra     = db.Column(db.Integer,    primary_key=True, autoincrement=True)
    folio         = db.Column(db.String(20), nullable=False, unique=True)
    id_proveedor  = db.Column(db.Integer,    db.ForeignKey('proveedores.id_proveedor'), nullable=False)
    fecha_compra  = db.Column(db.Date,       nullable=False)
    total         = db.Column(db.Numeric(12,2), nullable=False, default=0)
    observaciones = db.Column(db.Text)
    creado_en     = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now)
    creado_por    = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'), nullable=True)

    proveedor = db.relationship('Proveedor', back_populates='compras')
    detalles  = db.relationship('DetalleCompra', back_populates='compra', cascade='all, delete-orphan')


class DetalleCompra(db.Model):
    __tablename__ = 'detalle_compras'
    id_detalle_compra      = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_compra              = db.Column(db.Integer, db.ForeignKey('compras.id_compra',
                              ondelete='CASCADE'), nullable=False)
    id_materia             = db.Column(db.Integer, db.ForeignKey('materias_primas.id_materia'),
                              nullable=False)
    id_unidad_presentacion = db.Column(db.Integer, db.ForeignKey('unidades_presentacion.id_unidad',
                              ondelete='SET NULL'), nullable=True)
    cantidad_comprada      = db.Column(db.Numeric(12,4), nullable=False)
    unidad_compra          = db.Column(db.String(20),    nullable=False)
    factor_conversion      = db.Column(db.Numeric(12,4), nullable=False, default=1)
    cantidad_base          = db.Column(db.Numeric(12,4), nullable=False)
    costo_unitario         = db.Column(db.Numeric(12,4), nullable=False)

    compra              = db.relationship('Compra', back_populates='detalles')
    unidad_presentacion = db.relationship('UnidadPresentacion')

class Producto(db.Model):
    __tablename__ = 'productos'

    id_producto    = db.Column(db.Integer,      primary_key=True, autoincrement=True)
    uuid_producto  = db.Column(db.String(36),   nullable=False, unique=True)
    nombre         = db.Column(db.String(120),  nullable=False)
    descripcion    = db.Column(db.Text)
    precio_venta   = db.Column(db.Numeric(10,2),nullable=False, default=0)
    estatus        = db.Column(db.Enum('activo','inactivo'), nullable=False, default='activo')
    creado_en      = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now)
    actualizado_en = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now,
                                onupdate=datetime.datetime.now)
    creado_por     = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'), nullable=True)

    inventario = db.relationship('InventarioPT', back_populates='producto',
                                  uselist=False,        
                                  cascade='all, delete-orphan')
    recetas    = db.relationship('Receta', back_populates='producto', lazy=True)

    @property
    def stock_actual(self):
        return self.inventario.stock_actual if self.inventario else 0

    @property
    def stock_minimo(self):
        return self.inventario.stock_minimo if self.inventario else 0

    @property
    def nivel_stock(self):
        actual  = float(self.stock_actual)
        minimo  = float(self.stock_minimo)
        if actual <= 0:
            return 'sin_stock'
        if actual <= minimo:
            return 'bajo'
        return 'ok'

class InventarioPT(db.Model):
    __tablename__ = 'inventario_pt'

    id_inventario        = db.Column(db.Integer,      primary_key=True, autoincrement=True)
    id_producto          = db.Column(db.Integer,      db.ForeignKey('productos.id_producto',
                            ondelete='CASCADE'), nullable=False, unique=True)
    stock_actual         = db.Column(db.Numeric(12,2),nullable=False, default=0)
    stock_minimo         = db.Column(db.Numeric(12,2),nullable=False, default=0)
    ultima_actualizacion = db.Column(db.DateTime,     nullable=False,
                            default=datetime.datetime.now, onupdate=datetime.datetime.now)

    producto = db.relationship('Producto', back_populates='inventario')

    def sumar(self, cantidad):
        self.stock_actual         = float(self.stock_actual) + float(cantidad)
        self.ultima_actualizacion = datetime.datetime.now()

    def restar(self, cantidad):
        nuevo = float(self.stock_actual) - float(cantidad)
        if nuevo < 0:
            raise ValueError(
                f"Stock insuficiente para '{self.producto.nombre}': "
                f"disponible {self.stock_actual}, solicitado {cantidad}."
            )
        self.stock_actual         = nuevo
        self.ultima_actualizacion = datetime.datetime.now()

class Receta(db.Model):
    __tablename__ = 'recetas'

    id_receta          = db.Column(db.Integer, primary_key=True)
    uuid_receta        = db.Column(db.String(36), nullable=False, unique=True)
    id_producto        = db.Column(db.Integer, db.ForeignKey('productos.id_producto'),
                          nullable=True)
    nombre             = db.Column(db.String(120), nullable=False)
    descripcion        = db.Column(db.Text)
    rendimiento        = db.Column(db.Numeric(10,2), nullable=False)
    unidad_rendimiento = db.Column(db.String(20),    nullable=False)
    precio_venta       = db.Column(db.Numeric(10,2))
    estatus            = db.Column(db.Enum('activo','inactivo'), nullable=False)
    creado_en          = db.Column(db.DateTime, nullable=False)
    actualizado_en     = db.Column(db.DateTime, nullable=False)
    creado_por         = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'))

    detalles = db.relationship('DetalleReceta', back_populates='receta',
                                lazy=True, cascade='all, delete-orphan')
    producto = db.relationship('Producto', back_populates='recetas')


class DetalleReceta(db.Model):
    __tablename__ = 'detalle_recetas'

    id_detalle_receta      = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_receta              = db.Column(db.Integer, db.ForeignKey('recetas.id_receta',
                              ondelete='CASCADE'), nullable=False)
    id_materia             = db.Column(db.Integer, db.ForeignKey('materias_primas.id_materia'),
                              nullable=False)
    id_unidad_presentacion = db.Column(db.Integer, db.ForeignKey('unidades_presentacion.id_unidad',
                              ondelete='SET NULL'), nullable=True)
    cantidad_requerida     = db.Column(db.Numeric(12,4), nullable=False)
    cantidad_presentacion  = db.Column(db.Numeric(12,4))
    orden                  = db.Column(db.SmallInteger, nullable=False, default=1)

    receta              = db.relationship('Receta', back_populates='detalles')
    materia             = db.relationship('MateriaPrima')
    unidad_presentacion = db.relationship('UnidadPresentacion')

    __table_args__ = (
        db.UniqueConstraint('id_receta', 'id_materia', name='uq_det_receta_materia'),
    )

class Produccion(db.Model):
    __tablename__ = 'produccion'

    id_produccion      = db.Column(db.Integer,    primary_key=True, autoincrement=True)
    folio_lote         = db.Column(db.String(20), nullable=False, unique=True)
    id_producto        = db.Column(db.Integer,    db.ForeignKey('productos.id_producto'),
                          nullable=False)
    id_receta          = db.Column(db.Integer,    db.ForeignKey('recetas.id_receta'),
                          nullable=False)
    cantidad_lotes     = db.Column(db.Numeric(10,2), nullable=False)
    piezas_esperadas   = db.Column(db.Numeric(10,2), nullable=False)
    piezas_producidas  = db.Column(db.Numeric(10,2))
    estado             = db.Column(db.Enum('pendiente','en_proceso','finalizado','cancelado'),
                          nullable=False, default='pendiente')
    fecha_inicio       = db.Column(db.DateTime)
    fecha_fin_estimado = db.Column(db.DateTime)
    fecha_fin_real     = db.Column(db.DateTime)
    operario_id        = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario',
                          ondelete='SET NULL'), nullable=True)
    observaciones      = db.Column(db.Text)
    creado_en          = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now)
    creado_por         = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario',
                          ondelete='SET NULL'), nullable=True)

    producto = db.relationship('Producto')
    receta   = db.relationship('Receta')
    detalles = db.relationship('DetalleProduccion', back_populates='produccion',
                                cascade='all, delete-orphan')


class DetalleProduccion(db.Model):
    __tablename__ = 'detalle_produccion'

    id_det_prod        = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_produccion      = db.Column(db.Integer, db.ForeignKey('produccion.id_produccion',
                          ondelete='CASCADE'), nullable=False)
    id_materia         = db.Column(db.Integer, db.ForeignKey('materias_primas.id_materia'),
                          nullable=False)
    cantidad_requerida = db.Column(db.Numeric(12,4), nullable=False, default=0)

    produccion = db.relationship('Produccion', back_populates='detalles')


class Venta(db.Model):
    __tablename__ = 'ventas'

    id_venta        = db.Column(db.Integer,    primary_key=True, autoincrement=True)
    folio_venta     = db.Column(db.String(20), nullable=False, unique=True)
    fecha_venta     = db.Column(db.DateTime,   nullable=False, default=datetime.datetime.now)
    total           = db.Column(db.Numeric(12,2), nullable=False, default=0)
    metodo_pago     = db.Column(db.Enum('efectivo','tarjeta','transferencia','otro'),
                      nullable=False, default='efectivo')
    cambio          = db.Column(db.Numeric(10,2))
    requiere_ticket = db.Column(db.Boolean, nullable=False, default=False)
    estado          = db.Column(db.Enum('abierta','completada','cancelada'),
                      nullable=False, default='abierta')
    vendedor_id     = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'), nullable=False)
    id_corte        = db.Column(db.Integer, db.ForeignKey('cortes_diarios.id_corte',
                      ondelete='SET NULL'), nullable=True)
    creado_en       = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now)

    detalles = db.relationship('DetalleVenta', back_populates='venta',
                                cascade='all, delete-orphan')


class DetalleVenta(db.Model):
    __tablename__ = 'detalle_ventas'

    id_detalle_venta = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_venta         = db.Column(db.Integer, db.ForeignKey('ventas.id_venta',
                        ondelete='CASCADE'), nullable=False)
    id_producto      = db.Column(db.Integer, db.ForeignKey('productos.id_producto'),
                        nullable=False)                
    cantidad         = db.Column(db.Numeric(10,2), nullable=False)
    precio_unitario  = db.Column(db.Numeric(10,2), nullable=False)
    descuento_pct    = db.Column(db.Numeric(5,2),  nullable=False, default=0)
    subtotal         = db.Column(db.Numeric(12,2), nullable=False)

    venta   = db.relationship('Venta', back_populates='detalles')
    producto = db.relationship('Producto')               


class CorteDiario(db.Model):
    __tablename__ = 'cortes_diarios'
    id_corte      = db.Column(db.Integer, primary_key=True, autoincrement=True)
    fecha_corte   = db.Column(db.Date,    nullable=False, unique=True)
    total_ventas  = db.Column(db.Numeric(12,2), nullable=False, default=0)
    total_tickets = db.Column(db.Integer,       nullable=False, default=0)
    total_piezas  = db.Column(db.Numeric(12,2), nullable=False, default=0)
    efectivo      = db.Column(db.Numeric(12,2), nullable=False, default=0)
    tarjeta       = db.Column(db.Numeric(12,2), nullable=False, default=0)
    transferencia = db.Column(db.Numeric(12,2), nullable=False, default=0)
    cancelaciones = db.Column(db.Integer,       nullable=False, default=0)
    estado        = db.Column(db.Enum('abierto','cerrado'), nullable=False, default='abierto')
    cerrado_por   = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario',
                    ondelete='SET NULL'), nullable=True)
    cerrado_en    = db.Column(db.DateTime)
    creado_en     = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now)


class SalidaEfectivo(db.Model):
    __tablename__ = 'salidas_efectivo'
    id_salida      = db.Column(db.Integer,    primary_key=True, autoincrement=True)
    folio_salida   = db.Column(db.String(20), nullable=False, unique=True)
    id_proveedor   = db.Column(db.Integer,    db.ForeignKey('proveedores.id_proveedor',
                      ondelete='SET NULL'), nullable=True)
    categoria      = db.Column(db.Enum('compra_insumos','servicios_utilities',
                      'mantenimiento','otros'), nullable=False, default='otros')
    descripcion    = db.Column(db.String(255),nullable=False)
    monto          = db.Column(db.Numeric(12,2), nullable=False)
    fecha_salida   = db.Column(db.Date,       nullable=False)
    estado         = db.Column(db.Enum('pendiente','aprobada','rechazada'),
                      nullable=False, default='pendiente')
    id_corte       = db.Column(db.Integer,    db.ForeignKey('cortes_diarios.id_corte',
                      ondelete='SET NULL'), nullable=True)
    registrado_por = db.Column(db.Integer,    db.ForeignKey('usuarios.id_usuario'), nullable=False)
    aprobado_por   = db.Column(db.Integer,    db.ForeignKey('usuarios.id_usuario',
                      ondelete='SET NULL'), nullable=True)
    creado_en      = db.Column(db.DateTime,   nullable=False, default=datetime.datetime.now)
    actualizado_en = db.Column(db.DateTime,   nullable=False, default=datetime.datetime.now,
                      onupdate=datetime.datetime.now)


class AjusteInventario(db.Model):
    __tablename__ = 'ajustes_inventario'
    id_ajuste         = db.Column(db.Integer, primary_key=True, autoincrement=True)
    tipo_inventario   = db.Column(db.Enum('materia_prima','producto_terminado'), nullable=False)
    id_referencia     = db.Column(db.Integer, nullable=False)
    cantidad_anterior = db.Column(db.Numeric(12,4), nullable=False)
    cantidad_nueva    = db.Column(db.Numeric(12,4), nullable=False)
    motivo            = db.Column(db.Text, nullable=False)
    autorizado_por    = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'), nullable=False)
    creado_en         = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now)


class Merma(db.Model):
    __tablename__ = 'mermas'
    id_merma      = db.Column(db.Integer, primary_key=True, autoincrement=True)
    tipo_objeto   = db.Column(db.Enum('materia_prima','producto_terminado','lote_produccion'),
                    nullable=False)
    id_referencia = db.Column(db.Integer, nullable=False)
    cantidad      = db.Column(db.Numeric(12,4), nullable=False)
    unidad        = db.Column(db.String(20), nullable=False)
    causa         = db.Column(db.Enum('caducidad','quemado_horneado','caida_accidente',
                    'error_produccion','rotura_empaque','contaminacion','otro'), nullable=False)
    descripcion   = db.Column(db.Text)
    id_produccion = db.Column(db.Integer, db.ForeignKey('produccion.id_produccion',
                    ondelete='SET NULL'), nullable=True)
    registrado_por = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'), nullable=False)
    fecha_merma   = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now)
    creado_en     = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now)


class LogSistema(db.Model):
    __tablename__ = 'logs_sistema'
    id_log          = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    tipo            = db.Column(db.Enum('error','acceso','cambio_usuario','venta','compra',
                       'produccion','ajuste_inv','merma','solicitud','salida_efectivo','seguridad'),
                       nullable=False)
    nivel           = db.Column(db.Enum('INFO','WARNING','ERROR','CRITICAL'),
                       nullable=False, default='INFO')
    id_usuario      = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario',
                       ondelete='SET NULL'), nullable=True)
    modulo          = db.Column(db.String(60))
    accion          = db.Column(db.String(120))
    descripcion     = db.Column(db.Text)
    ip_origen       = db.Column(db.String(45))
    user_agent      = db.Column(db.String(255))
    referencia_id   = db.Column(db.Integer)
    referencia_tipo = db.Column(db.String(60))
    creado_en       = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now)


class Sesion(db.Model):
    __tablename__ = 'sesiones'
    id_sesion     = db.Column(db.String(64), primary_key=True)
    id_usuario    = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'), nullable=False)
    ip_inicio     = db.Column(db.String(45))
    user_agent    = db.Column(db.String(255))
    csrf_token    = db.Column(db.String(64), nullable=False)
    activa        = db.Column(db.Boolean, nullable=False, default=True)
    expira_en     = db.Column(db.DateTime, nullable=False)
    creado_en     = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now)
    ultimo_acceso = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now,
                    onupdate=datetime.datetime.now)


class Ticket(db.Model):
    __tablename__ = 'tickets'
    id_ticket      = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_venta       = db.Column(db.Integer, db.ForeignKey('ventas.id_venta',
                      ondelete='CASCADE'), nullable=False, unique=True)
    contenido_json = db.Column(db.JSON, nullable=False)
    impreso        = db.Column(db.Boolean, nullable=False, default=False)
    generado_en    = db.Column(db.DateTime, nullable=False, default=datetime.datetime.now)